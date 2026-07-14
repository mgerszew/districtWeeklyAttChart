#!/bin/bash
# PSHTML Validation Script
# Checks for common PowerSchool PSHTML issues

set -e

FILE="${1}"

if [[ -z "$FILE" ]]; then
    echo "Usage: $0 <file.html>"
    exit 1
fi

if [[ ! -f "$FILE" ]]; then
    echo "Error: File not found: $FILE"
    exit 1
fi

echo "Validating: $FILE"
echo "========================="

ERRORS=0
WARNINGS=0

check() {
    local pattern="$1"
    local message="$2"
    local level="$3"
    
    if grep -qE "$pattern" "$FILE"; then
        if [[ "$level" == "error" ]]; then
            echo "ERROR: $message"
            ((ERRORS++))
        else
            echo "WARNING: $message"
            ((WARNINGS++))
        fi
    fi
}

check_not() {
    local pattern="$1"
    local message="$2"
    local level="$3"
    
    if ! grep -qE "$pattern" "$FILE"; then
        if [[ "$level" == "error" ]]; then
            echo "ERROR: $message"
            ((ERRORS++))
        else
            echo "WARNING: $message"
            ((WARNINGS++))
        fi
    fi
}

# Required tags
check_not "~\[wc:commonscripts\]" "Missing ~[wc:commonscripts]" "error"
check_not "~\[wc:admin_header_frame_css\]" "Missing ~[wc:admin_header_frame_css]" "error"
check_not "~\[wc:admin_navigation_frame_css\]" "Missing ~[wc:admin_navigation_frame_css]" "error"
check_not "~\[wc:title_student_begin_css\].*~\[wc:title_student_end_css\]" "Missing title block" "error"
check_not "~\[wc:admin_footer_frame_css\]" "Missing ~[wc:admin_footer_frame_css]" "error"

# Form structure
check_not "action=\"/~\[self\.page\]\?frn=~\(studentfrn\)&changesSaved=true\"" "Form action missing student FRN or changesSaved" "error"
check_not "method=\"POST\"" "Form missing POST method" "error"
check_not "<input type=\"hidden\" name=\"ac\" value=" "Missing hidden 'ac' field" "error"
check_not "~\[submitbutton\]" "Missing ~[submitbutton]" "error"

# Success message pattern
check_not "~\[if\.~\(gpv\.changesSaved\)=true\].*~\[text:psx\.common\.changes_recorded\].*\[/if\]" "Missing success message conditional" "warning"

# Box-round container
check_not "<div class=\"box-round\">" "Missing box-round container" "warning"
check_not "<div class=\"button-row\">" "Missing button-row container" "warning"

# Common mistakes
check "href=\"[^\"]*\$[^\"]*\"" "Unescaped \$ in href (use ~[self.page] or literal)" "warning"
check "\\\$j\\(\" "Using \$ instead of \$j for jQuery" "warning"
check "const |let |=>" "ES6 syntax detected (use ES5)" "warning"
check "document\\.getElementById" "Direct DOM access (use \$j)" "warning"

# DAT tag balance
IF_COUNT=$(grep -o "~\[if\." "$FILE" | wc -l)
ENDIF_COUNT=$(grep -o "\[/if\]" "$FILE" | wc -l)
if [[ $IF_COUNT -ne $ENDIF_COUNT ]]; then
    echo "WARNING: Mismatched ~[if]...[/if] blocks ($IF_COUNT open, $ENDIF_COUNT close)"
    ((WARNINGS++))
fi

TLIST_OPEN=$(grep -o "~\[tlist_sql:" "$FILE" | wc -l)
TLIST_CLOSE=$(grep -o "~\[/tlist_sql\]" "$FILE" | wc -l)
if [[ $TLIST_OPEN -ne $TLIST_CLOSE ]]; then
    echo "WARNING: Mismatched tlist_sql blocks ($TLIST_OPEN open, $TLIST_CLOSE close)"
    ((WARNINGS++))
fi

# File extension
if [[ ! "$FILE" =~ \.html$ ]]; then
    echo "WARNING: File should have .html extension"
    ((WARNINGS++))
fi

echo "========================="
echo "Errors: $ERRORS"
echo "Warnings: $WARNINGS"

if [[ $ERRORS -gt 0 ]]; then
    exit 1
fi

exit 0