#!/usr/bin/env bash
# PowerSchool Oracle SQL Validation Script
# Checks for common anti-patterns per AGENTS.md §3 and project conventions
#
# Usage: ./scripts/validate-sql.sh <sql-file> [--quiet]
#
# Exit codes:
#   0 = PASS (no errors, warnings allowed)
#   1 = FAIL (errors found)
#   2 = USAGE ERROR

set -euo pipefail

# Colors for output
RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

QUIET=false
FILE=""

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --quiet)
            QUIET=true
            shift
            ;;
        -*)
            echo "Unknown option: $1"
            echo "Usage: $0 <sql-file> [--quiet]"
            exit 2
            ;;
        *)
            if [[ -z "$FILE" ]]; then
                FILE="$1"
            else
                echo "Multiple files not supported"
                exit 2
            fi
            shift
            ;;
    esac
done

if [[ -z "$FILE" ]]; then
    echo "Usage: $0 <sql-file> [--quiet]"
    exit 2
fi

if [[ ! -f "$FILE" ]]; then
    echo "File not found: $FILE"
    exit 2
fi

ERRORS=0
WARNINGS=0

log_error() {
    ((ERRORS++))
    if [[ "$QUIET" != "true" ]]; then
        echo -e "${RED}[ERROR]${NC} $1"
    fi
}

log_warn() {
    ((WARNINGS++))
    if [[ "$QUIET" != "true" ]]; then
        echo -e "${YELLOW}[WARN]${NC} $1"
    fi
}

log_info() {
    if [[ "$QUIET" != "true" ]]; then
        echo -e "${GREEN}[INFO]${NC} $1"
    fi
}

# Read file content
CONTENT=$(cat "$FILE")

# 1. Check for SELECT *
if echo "$CONTENT" | grep -qiE 'SELECT\s+\*'; then
    log_error "SELECT * found - use explicit column lists"
fi

# 2. Check for bind variables (:var or &var)
if echo "$CONTENT" | grep -E '[:&][a-zA-Z_][a-zA-Z0-9_]*' | grep -vE '^(--|/\*)' | grep -v 'SYSDATE' | grep -v 'TO_DATE' | grep -v 'GPV' | grep -v 'curstudid' | grep -v 'curschoolid' | grep -v 'curyearid' | grep -q .; then
    log_error "Bind variables found (:var or &var) - use CTE params instead"
fi

# 3. Check for PL/SQL blocks
if echo "$CONTENT" | grep -qiE '\bDECLARE\b|\bBEGIN\b|\bEND\b\s*;'; then
    log_error "PL/SQL block found (DECLARE/BEGIN/END) - not supported in tlist_sql"
fi

# 4. Check for comma joins (legacy)
if echo "$CONTENT" | grep -qiE 'FROM\s+\w+\s*,\s*\w+'; then
    log_warn "Comma join syntax found - prefer ANSI JOIN ... ON"
fi

# 5. Check for params CTE at top
if ! echo "$CONTENT" | grep -qiE '^\s*WITH\s+params\s+AS\s*\('; then
    log_error "Missing 'params' CTE at top of query"
fi

# 6. Check for hardcoded yearid/schoolid (2+ digits)
if echo "$CONTENT" | grep -iE 'yearid\s*=\s*[0-9]{2,}' | grep -v 'params' | grep -v 'SELECT' | grep -q .; then
    log_warn "Hardcoded yearid found - move to params CTE"
fi
if echo "$CONTENT" | grep -iE 'schoolid\s*=\s*[0-9]{2,}' | grep -v 'params' | grep -v 'SELECT' | grep -q .; then
    log_warn "Hardcoded schoolid found - move to params CTE"
fi

# 7. Check school FK uses school_number not schoolid (DCID)
if echo "$CONTENT" | grep -iE 'schoolid\s*=\s*schools\.schoolid' | grep -q .; then
    log_error "School FK uses schools.schoolid (DCID) - should be schools.school_number"
fi

# 8. Check SYSDATE without -1 offset (attendance queries)
if echo "$CONTENT" | grep -iE 'SYSDATE\s*(?!-\s*1)' | grep -q .; then
    log_warn "SYSDATE used without -1 offset - may include current day"
fi

# 9. Check for UNION vs UNION ALL
if echo "$CONTENT" | grep -iE '\bUNION\b' | grep -v 'UNION ALL' | grep -q .; then
    log_warn "UNION found (not UNION ALL) - verify deduplication is needed"
fi

# 10. Check for explicit columns in CTEs (no SELECT * in CTEs)
if echo "$CONTENT" | grep -iE 'WITH\s+\w+\s+AS\s*\(\s*SELECT\s+\*' | grep -q .; then
    log_warn "SELECT * in CTE - use explicit columns"
fi

# 11. Check for DECODE where CASE is clearer (optional)
if echo "$CONTENT" | grep -iE 'DECODE\s*\(' | grep -q .; then
    log_info "DECODE found - consider CASE for readability (optional)"
fi

# 12. Check for comments explaining non-obvious logic
# Not enforced, just info

# Summary
if [[ "$QUIET" != "true" ]]; then
    echo ""
    echo "=== Validation Summary ==="
    echo "File: $FILE"
    echo "Errors: $ERRORS"
    echo "Warnings: $WARNINGS"
fi

if [[ $ERRORS -gt 0 ]]; then
    if [[ "$QUIET" != "true" ]]; then
        echo -e "${RED}FAIL${NC}"
    fi
    exit 1
else
    if [[ "$QUIET" != "true" ]]; then
        echo -e "${GREEN}PASS${NC}"
    fi
    exit 0
fi