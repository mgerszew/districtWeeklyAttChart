# PowerSchool PSHTML Development Guide for AI Assistants

A comprehensive reference for PowerSchool custom page development. This guide is structured for quick lookup when actively coding.

---

## Table of Contents

1. [Tag Syntax Fundamentals](#1-tag-syntax-fundamentals)
2. [Current Context Tags](#2-current-context-tags)
3. [Date & Time Handling](#3-date--time-handling)
4. [Logic & Conditionals](#4-logic--conditionals)
5. [SQL & tlist_sql](#5-sql--tlistsql)
6. [Character & String Manipulation](#6-character--string-manipulation)
7. [GPV Handling & URL Parameters](#7-gpv-handling--url-parameters)
8. [API Integration](#8-api-integration)
9. [Modifiers Reference](#9-modifiers-reference)
10. [Object Reports](#10-object-reports)
11. [Security & Permissions](#11-security--permissions)
12. [Miscellaneous Patterns](#12-miscellaneous-patterns)
13. [VS Code Completions Reference](#13-vs-code-completions-reference)

---

## 1. Tag Syntax Fundamentals

PowerSchool uses several tag syntaxes:

| Syntax | Purpose | Example |
|--------|---------|---------|
| `~()` | DAT field expressions, functions | `~(first_name)`, `~(f.add;6;2)` |
| `~[]` | Display/wildcard tags, variables | `~[x:userid]`, `~[yearname]` |
| `~(*evaluate)` | Evaluate engine expressions | `~(*evaluate round(1.507,2))` |
| `~[if...]...[/if]` | Conditional blocks | `~[if.expression][else][/if]` |
| `~[]` with `;` | Field modifiers | `~([table]field;uppercase)` |

### Key Conventions
- `~()` = DAT (Database Access Tags) — fetches data from database
- `~[]` = Display tags — retrieves system info, user context, etc.
- Parentheses inside `~[]` like `~[x:userid]` are PowerSchool variables/wildcards
- Semicolons `;` separate function names from parameters

---

## 2. Current Context Tags

### Student & School Context

| Tag | Description | Example |
|-----|-------------|---------|
| `~(curstudid)` | Current student ID | `1706` |
| `~(curschoolid)` | Current school ID | `100` |
| `~(curschooldcid)` | Current school DCID | `100` |
| `~(v.schoolID)` | Current school ID (alternate) | `100` |
| `~(cursecid)` | Current section ID | `0` |
| `~(curtchid)` | Current teacher ID | `0` |
| `~(studentname)` | Current student name | `Franklin, Ben` |
| `~[x:studentfrn]` | FRN of current student | `00131` |
| `~(f.frn;table=students)` | FRN (alternate syntax) | `00131` |
| `(rn)` | RN (DCID) of current file | `31` |
| `~[x:totalenrollmentcount]` | Enrollment count | `655` |
| `~[x:studsinset]` | # of currently selected students | `655` |
| `~[x:tchrsinset]` | # of currently selected staff | — |

### School & District Info

| Tag | Description | Example |
|-----|-------------|---------|
| `~(v.districtname)` | District name | `Apple Grove Unified School District` |
| `(v.districtnumber)` | District identifier | `training60` |
| `(v.districtstate)` | State abbreviation | `CA` |
| `(schoolabbr)` | School name abbreviation | `AGHS1` |
| `(schoolname)` or `~[x:schoolname]` | Full school name | `Apple Grove High School` |

### User Information

| Tag | Description | Example |
|-----|-------------|---------|
| `~[x:userid]` or `~(v.userid)` | Current user ID | `4560` |
| `~[x:users_dcid]` | DCID of logged-in user | `3751` |
| `~[x:username]` | Last, First Middle format | `Last, First Middle` |
| `~[x:username;firstlast]` | First Middle Last format | `First Middle Last` |
| `~[x:usersroles]` | User groups/roles as comma string | `9,18` |
| `~[x:usertypename]` | User type | `Faculty` |
| `~[x:useremail]` | User email | `unknown@` if blank |
| `~[x:loginusername]` | Login username | `hurdy.gurdy` |
| `~[x:lastlogin]` | Last login info | `07/22/2019 at 09:44 AM ended normally.` |
| `~[ip address]` | User IP address | `192.168.1.1` |

### Version & System Info

| Tag | Description | Example |
|-----|-------------|---------|
| `~[version]` or `~[x:version]` | PowerSchool version | `19.4` |
| `~[x:version;short]` | Short version | `19.4.0` |
| `~[x:version;long]` | Long version | `19.4.0.0` |
| `~[x:version;full]` | Full version with build | `19.4.0.0.1376745` |
| `~[sr-version]` | State Reporting version | `USA-CA 19.4.1.1.12.0` |
| `~[wc:_powerteacher_version]` | PowerTeacher Gradebook version | `PowerTeacher Gradebook: 2.8.0.14` |
| `~[displaypref:lastversionnumber]` | Version from prefs (more reliable in if statements) | — |

### Prefs

| Tag | Description |
|-----|-------------|
| `~[displaypref:pref_name;default_optional]` | Pref value by name. SQL: `select value from prefs where lower(name)=lower('pref_name')` |
| `~[displayprefschool:prefname]` | School-specific pref (`prefname-S{curschoolid}`) |
| `~[displayprefyearschool:prefname]` | Year + school specific pref |
| `~[displayprefschoolid:prefname]` | Pref for specific school ID |
| `~[displayprefyear:{pref_name}]` | Pref for current year |
| `~(f.pref;fn=get;name=prefname)` | Pref in object reports |

---

## 3. Date & Time Handling

### Year & Term Tags

| Tag | Description | Example |
|-----|-------------|---------|
| `(yearname)` or `~[yearname]` | Long year format | `2018-2019` |
| `(yearabbr)` | Short year | `18-19` |
| `(termabbr)` | Term abbreviation | `S1` |
| `~[x:termname]` | Full term name | `18-19 Semester 1` |
| `(curtermid)` or `~[x:termid]` | Current term ID | `2801` |
| `(curyearid)` | Current year ID | `28` |
| `(schedule.yearidcurrent)` | 4-digit current year ID | `2800` |
| `(schedule.yearidfuture)` | 4-digit next year ID (from PowerScheduler) | `2900` |
| `~[pref:coursearchiveyear]` | Year ID of most recent school year (EOY incremented) | `29` |
| `~[pref:lastpromotiondate]` | Last EOY process date | `6/20/2019` |
| `~[curservertermid]` | Current server term ID | `2802` |

**New in 19.11.0+:**

| Tag | Description | Example |
|-----|-------------|---------|
| `~[x:getbase_termid]` or `~[x:getbase_termid;schoolid]` | Base (shortest current) term ID | `3101` |
| `~[x:getbase_termname]` or with schoolid param | Base term name | `Semester 1` |
| `~[x:getbase_termid_public]` | Parent portal term ID | `3100` |
| `~[x:getbase_termname_public]` | Parent portal term name | `2021-2022` |

### Date Format Operators

| Tag | Description | Example |
|-----|-------------|---------|
| `~[date]` or `~[short.date]` | Today's date (leading zeros) | `07/22/2019` |
| `~(f.currentdate)` | Today's date (no leading zeros) | `7/22/2019` |
| `~(f.currentdate;format=DDD MMMM[comma] D[comma] YYYY)` | Custom format | `Mon July, 22, 2019` |
| `~[eaodate]` | Enrolled As Of Date | `7/22/2019` |
| `~[dateformat]` | System locale date format (for TO_CHAR) | `MM/dd/yyyy` |
| `~[datetext:mmddyyyy]` | Locale format in all caps (for TO_CHAR) | `MM/DD/YYYY` |
| `~[bulletindate]` | Long date with day of week | `Monday, July 22, 2019` |
| `~[letter.date]` | Long date without day of week | `July 22, 2019` |

### Date Format Modifiers (on any date field)

Use: `~(entrydate;dateformat=FORMAT)`

| Format | Description | Example |
|--------|-------------|---------|
| `M` | Month, no leading zero | `8` |
| `MM` | Month, with leading zero | `08` |
| `MMM` | Month abbreviation | `Aug` |
| `MMMM` | Full month name | `August` |
| `D` | Day of month, no leading zero | `7` |
| `DD` | Day of month, with leading zero | `07` |
| `DDD` | Day abbreviation | `Tue` |
| `DDDD` | Full day name | `Tuesday` |
| `YY` | 2-digit year | `18` |
| `YYYY` | 4-digit year | `2018` |
| `MMMM DD` | Example combined | `August 07` |
| `DDD MMM DD YY` | Example combined | `Tue Aug 07 18` |

### ~(date.information) — Advanced Date Functions (20.11.1+)

Syntax: `~(date.information;type=[type];schoolid=[id];yearid=[id];termabbr=[abbr];offset=[n];dateformat=[format])`

| Type | Description |
|------|-------------|
| `today` | Today's date (always required, no caching) |
| `current_term_start` | Current term start date |
| `current_term_end` | Current term end date |
| `current_year_start` | Current year start date |
| `current_year_end` | Current year end date |
| `term_start` | Requires `termabbr` parameter |
| `term_end` | Requires `termabbr` parameter |

Optional parameters:
- `schoolid` — Defaults to current school (0 = district)
- `yearid` — Defaults to current year
- `offset` — Positive or negative number to shift date
- `dateformat` — Case-sensitive Java DateTimeFormatter symbols (`MM-dd-yyyy`)

### Date Math

```
~(f.dates_gen;startdate=^([01]fieldname); unit=day; nbunits=-1; nbdates=1; fn_format=MM/DD/YYYY)
```
Use `"current"` as startdate for today. Subtract or add days/months/years.

### Attendance Week Dates

| Tag | Description | Example |
|-----|-------------|---------|
| `~[x.att_thisStartWeek]` | This week's attendance start | `09/25/2017` if today is Tue 9/26 |
| `~[x.att_thisEndWeek]` | This week's attendance end | `09/29/2017` |

### Time Format Operators

| Tag | Description | Example |
|-----|-------------|---------|
| `~[time]` | Current time | `01:44 PM` |
| `~[current.time.no.colon]` | HH24MI format | `1344` |
| `~(f.currenttime)` | HH24:MI:SS | `13:44:30` |
| `~(f.currenttime;format=HHMM)` | HH24:MI | `13:44` |
| `~(f.currenttime;format=HHMM_AMPM)` | HH:MI AM/PM | `1:44 PM` |
| `~(f.currenttime;format=HHMMSS)` | HH24:MI:SS | `13:44:30` |
| `~(f.currenttime;format=HHMMSS,nocolon)` | HH24MISS | `161930` |
| `~(f.currenttime;format=[h])` | 24-hour, no leading zero | `13` |
| `~(f.currenttime;format=[hh])` | 24-hour, with leading zero | `13` |
| `~(f.currenttime;format=[m])` | Minute, no leading zero | `44` |
| `~(f.currenttime;format=[mm])` | Minute, with leading zero | `44` |
| `~(f.currenttime;format=[ampm])` | am/pm lowercase | `pm` |

Custom separators use brackets: `[semicolon]`, `[comma]`, `[space]`, etc.

---

## 4. Logic & Conditionals

### Basic IF Syntax

```
~[if.expression]
  Content when true
[else]
  Content when false (optional)
[/if]
```

**Hashtag aliases** — especially helpful for nesting:

```
~[if#aliasname][else#aliasname][/if#aliasname]
```

### Examples

```html
<!-- Simple condition -->
~[if.~(curschoolid)=100]
  Do stuff for school 100
[/if]

<!-- AND with nested ifs and aliases -->
~[if#1.~(grade_level)=3]
  ~[if#2.~(gender)=M]
    This student is grade 3 and male
  [/if#2]
~[/if#1]

<!-- OR using f.in function -->
~[if.~(f.in;value=~(grade_level);in=3,4,5)=1]
  Student is in grade 3, 4, or 5
[/if]

<!-- Complex nested with else -->
~[if#cond1.CONDITION1]
  ~[if#cond2.CONDITION2]
    Both conditions true
  [else#cond2]
    Condition 1 true, condition 2 false
  [/if#cond2]
[else#cond1]
  Condition 1 false
[/if#cond1]
```

### Case Statement (Alternative)

```html
~[case.{variable}]
[of.{expression_1}]Do this[/of]
[of.{expression_2}]Do that[/of]
[of.{expression_n}]Do something else[/of]
[/case]
```

**Note:** Without a matching "of" condition, you'll get an "Invalid tag value" error. No built-in "else" support.

### DAT Logic Tags

| Tag | Description | Example |
|-----|-------------|---------|
| `(gender;if.fieldvalue.f.then=Female;if.fieldvalue.m.then=Male)` | Conditional display based on field value | `Female` |
| `(nickname;if.blank.then=No Nickname)` | Default if blank | `No Nickname` |
| `(first_name;if.not.blank.then=Has First Name)` | Display if has value | `Has First Name` |

### Decode DAT

```
~(decode;FIELD;VALUE1;DISPLAY1;VALUE2;DISPLAY2;DEFAULT)
```

Example:
```
~(decode;~(gender);M;Male;F;Female;Not Specified)
```

---

## 5. SQL & tlist_sql

### Basic tlist_sql Structure

```html
~[tlist_sql;
    SELECT column1, column2 FROM table WHERE condition
;]
    Row output: ~(column1) — ~(column2)
[/tlist_sql]
```

Add a row counter inside tlist_sql: `~(count;-)`

### tlist_sql Modifiers

Apply modifiers to fields within tlist_sql output: `~(fieldname;MODIFIER)`

| Modifier | Description | Example |
|----------|-------------|---------|
| `;d` | Format DATE/TIMESTAMP to user locale | `~(sysdate;d)` → `2/2/2015` |
| `;l;format=time` | Convert NUMBER (seconds) to HH:MM | `~(start_time;l;format=time)` → `9:34 AM` |
| `;url` | URL-encode for links | `~(myLink;url)` → `hello+world` |
| `;js` | JavaScript-escape string | `~(schoolName;js)` → `Every \"High\" \'School\'` |
| `;json` | JSON-escape string | `~(schoolName;json)` → `Every \"High\" 'School'` |
| `;html` | HTML-escape to prevent injection | `~(gtLt;html)` → `&lt; &gt;` |
| `;xml10` or `;xml11` | XML v1.0/v1.1 escape | `~(gtLt;xml10)` → `&lt; &gt; &apos;` |
| `;ReplaceCRLFWithBR` | Replace CR/LF with `<br/>` (20.11.0.1+) | — |

### Date/Time Math on Fields

```
^(dob;+3,0,-1)  -- Add 3 years, 0 months, subtract 1 day
```

### DirectTable.Select — Row Context

Sets PowerSchool's row context for a table:
```
~[DirectTable.Select:<TABLE_NAME>;<KEY_COLUMN>:<KEY_VALUE>]
```

After this, standard field tags work: `~([TABLE_NAME]column_name)`

Example:
```html
~[DirectTable.Select:U_USER_TABLE;USERSDCID:~[x:users_dcid]]
<form action="/admin/user_proto/user_test.html" method="post">
  <input type="hidden" name="ac" value="prim" />
  <input type="text" value="" name="[u_user_table]my_column"><br>
</form>
```

### Useful SQL Queries & Patterns

**Find all tables using a field:**
```sql
SELECT table_name, column_name
FROM all_tab_columns
WHERE lower(column_name) = 'coursesdcid'
```

**Current date (timezone-aware):**
```sql
SELECT sysdate, current_date FROM dual
```

**Next in-session Wednesday beyond current week:**
```sql
SELECT to_char(min(date_value), 'MM/DD/YYYY')
FROM Calendar_Day
WHERE SchoolID = ~(curschoolid)
  AND InSession = 1
  AND date_value > (sysdate - to_char(sysdate, 'D') + 4)
  AND to_char(date_value, 'D') = 4
```

**Current final grade name:**
```sql
JOIN prefs
    ON prefs.name='curfgname-S' || sections.schoolid
    AND pgfinalgrades.finalgradename = to_char(substr(prefs.value,1,2))
```

**All valid current terms (including overlapping):**
```sql
FROM Sections sec
INNER JOIN terms t
    ON sec.termid = t.id
    AND sec.schoolid = t.schoolid
INNER JOIN terms t2
    ON t2.schoolid = t.schoolid
    AND t2.id = ~(curtermid)
    AND t2.firstday < t.lastday
    AND t2.lastday > t.firstday
```

**Today or first day of year (for class rosters in summer):**
```sql
SELECT
    CASE
        WHEN t.firstday > sysdate THEN t.firstday
        ELSE sysdate
    END effdate
FROM terms t
WHERE t.id = (extract(year from add_months(sysdate,-6)) - 1990) * 100
  AND t.schoolid = 0
  AND t.isyearrec = 1
```

**Current server year (using pref, not date math):**
```sql
SELECT TO_NUMBER(Value) FROM Prefs WHERE Name = 'coursearchiveyear'
```

### Trailing Delimiter Fix in JSON Generation

```html
[~[tlist_sql;
    SELECT period_number period
         , to_char(to_date(bi.start_time,'sssss'),'hh'||chr(58)||'mi AM') start_time
         , to_char(to_date(bi.end_time,'sssss'),'hh'||chr(58)||'mi AM') end_time
         , lead (',') OVER (ORDER BY null) delim
    FROM bell_schedule_items bi
    INNER JOIN bell_schedule bs ON bs.id = bi.bell_schedule_id
        AND bs.name LIKE '%Regular Schedule%'
        AND bs.schoolid = ~(curschoolid)
        AND bs.year_id = ~(curyearid)
    INNER JOIN period p ON p.id = bi.period_id
    ORDER BY period
]{
    "period": "~(period)",
    "start": "~(start_time)",
    "end": "~(end_time)"
}~(delim)[/tlist_sql]]
```

### Current Selection in SQL

```sql
SELECT dcid FROM ~[temp.table.current.selection:Students]
```

---

## 6. Character & String Manipulation

### Case Modifiers (on any field)

| Modifier | Description | Example |
|----------|-------------|---------|
| `;uppercase` | All caps | `(ExampleField;uppercase)` → `FRANKLIN, BEN` |
| `;lowercase` | All lowercase | `(ExampleField;lowercase)` → `franklin, ben` |
| `;smartcase` | Smart case | `(ExampleField;smartcase)` → `Franklin, ben` |

### String Operations

| Modifier/Function | Description | Example | Result |
|-------------------|-------------|---------|--------|
| `;replace=find,replace` | Replace characters | `(field;;replace=in,azz)` | `Franklazz, Ben` |
| `;substring=start,len` | Substring | `(field;substring=5,3)` | `kli` |
| `;allafter=string` | All chars after string | `(field;allafter=kli)` | `n, Ben` |
| `;allfrom=string` | All chars from string onward | `(field;allfrom=kli)` | `klin, Ben` |
| `;allbefore=string` | All chars before string | `(field;allbefore=kli)` | `Fran` |
| `;allthrough=string` | All chars through string | `(field;allthrough=kli)` | `Frankli` |
| `;keep_ascii=RANGE,RANGE` | Keep only ASCII in ranges | `(field;keep_ascii=65-70,97-102)` | `FaBe` |
| `;nohtml` or `;striphtml` | Remove HTML tags | — | — |

### Function Tags for Numbers & Strings

| Function | Description | Example | Result |
|----------|-------------|---------|--------|
| `(f.char_from_ascii;ascii=#)` | ASCII code to character | — | — |
| `(f.ascii;string=abc)` | Character to ASCII code | — | — |
| `(f.length;string=text)` | String length | `(f.length;string=~(first_name))` | `6` |
| `(f.add;n1;n2;...)` | Add numbers | `(f.add;6;2;1)` | `9` |
| `(f.sub;n1;n2)` | Subtract | `(f.sub;6;2)` | `4` |
| `(f.mult;n1;n2)` | Multiply | `(f.mult;6;2)` | `12` |
| `(f.div;n1;n2;error_msg=0)` | Divide | `(f.div;6;2;error_msg=0)` | `3` |
| `(f.sqrt;n;error_msg=0)` | Square root | — | — |
| `(f.exp;n1;n2;error_msg=0)` | Exponent (n1^n2) | — | — |
| `(f.in;value=val;in=v1,v2,v3)` | Returns 1 if value in list | `(f.in;value=~(grade_level);in=0,1,2,3)` | `1` |
| `(f.numbers_gen;startnumber=N;lastnumber=N;delim=CMA\|,\|ASCII(13)\|Text\|<HTML>)` | Generate number series | — | `10,11,12,13,14,` |

### Evaluate Tags — Numeric Functions

Syntax: `~(*evaluate FUNCTION(args))`

| Expression | Description | Example Result |
|------------|-------------|----------------|
| `int(15.75)` | Whole number (truncate) | `15` |
| `abs(-123)` | Absolute value | `123` |
| `dec(1.23)` or `frac(1.23)` | Decimal portion | `0.23` |
| `int("4e3")` | Scientific notation | `4000` |
| `3+3+3` or `sum(3,3,3)` | Sum | `9` |
| `3-3` | Difference | `0` |
| `3/3` | Quotient | `1` |
| `3*3` | Product | `9` |
| `exp(3)` | e^x | `20.0855...` |
| `ln(20.0855...)` | Natural log | `3` |
| `log2(8)` | Base-2 log | `3` |
| `log10(100)` | Base-10 log | `2` |
| `log(9,3)` | Log base x of n | `2` |
| `pi()` | Pi constant | `3.14159...` |
| `rand()` | Random 0–1 | `0.537...` |
| `int(rand(100))` | Random integer 0–100 | `68` |
| `round(1.507,2)` | Round to n digits | `1.51` |
| `sign(-54)` | Sign (-1, 0, 1) | `-1` |
| `sqrt(16)` | Square root | `4` |
| `trunc(123.456,2)` | Truncate to n digits | `123.45` |
| `3^3` or `power(3,3)` | Exponentiation | `27` |
| `fact(4)` | Factorial | `24` |
| `4%3` or `mod(11,2)` | Remainder | `1` |

### Evaluate Tags — String Functions

| Expression | Description | Example Result |
|------------|-------------|----------------|
| `char(65)` | ASCII code to char | `A` |
| `code("A")` | Char to ASCII code | `65` |
| `concat(3,3)` or `concatenate(3,3)` | Join strings | `33` |
| `left("Hello",2)` | Chars from left | `He` |
| `right("Hello",4)` | Chars from right | `ello` |
| `len("Hello World")` | String length | `11` |
| `lower("Hello World")` | Lowercase | `hello world` |
| `upper("Hello World")` | Uppercase | `HELLO WORLD` |
| `proper("hello world")` | Title case | `Hello World` |
| `mid("Hello World",3,5)` | Substring from position | `llo W` |
| `replace("Hello World",6,5,"User")` | Replace at position | `Hello User` |
| `rept("Hello",3)` | Repeat string | `HelloHelloHello` |

### Evaluate Tags — Logical Functions

| Expression | Description | Example Result |
|------------|-------------|----------------|
| `exact("ABC","ABc")` | Case-sensitive compare | `0` (false) |
| `and(1=1,2=2,3=3)` | All true | `1` |
| `and(1=1,2=2,4=3)` | One false | `0` |
| `or(1=2,2=3,3=3)` | At least one true | `1` |
| `if(1=1,"Match","No Match")` | Ternary if | `Match` |
| `isblank("")` | Is blank check | `1` (true) |
| `4=3`, `4<>3`, `6>5`, `6<5` | Boolean comparisons | `0` or `1` |

### Other Useful Tags

| Tag | Description | Example |
|-----|-------------|---------|
| `~(current.final.grade.name)` | Current final grade name | — |
| `~[x:studsinset;viewlink]` | Student count with link to selection page | — |
| `~[x:dothisfor;selected]` | "The selected 655 students" format | — |
| `~[self]` | Current relative URL (with params, no leading /) | `admin/students/allenrollments.html?frn=12345` |
| `~[self.page]` | Current URL without params | `admin/students/allenrollments.html` |
| `~[directory]` | Portal name | `admin`, `teachers`, `guardian` |
| `(JSFieldParam;[table]field)` | PowerSchool UF- form variable name | — |
| `~[x:usmnumrecs]` | Number of selected records | `655` |
| `~[urlpostvalues]` | URL GPVs as query string | `?frn=0017836` |
| `~[x:GetDoThisForStudents]` | Requires `dothisfor=selected` in querystring | — |
| `~[RepeatForEach:Students]...[/RepeatForEach:Students]` | Iterate over students | — |
| `~[x:WEB_GetServerInfo;name=HostName]` | Server hostname | `train01.domain.net` |
| `(person_id)` | Person ID for relationship table lookups | Assumes FRN on student page |

### Student & Scheduling Info

| Tag | Description |
|-----|-------------|
| `(age)` or `(age;long)` | Student age |
| `(he/she)`, `(He/She)`, `(him/her)`, `(His/Her)`, `(son/daughter)` | Gender pronouns |
| `(Fee_GetStudentBalance)` | Current fee balance | `98.00` |
| `~[x:scheduleinfo;curcatalogname]` | PowerScheduler current catalog name |
| `~[x:scheduleinfo;curcatalogid]` | PowerScheduler current catalog ID |
| `~[x:scheduleinfo;curbuildname]` | PowerScheduler current build name |
| `~[x:scheduleinfo;curbuildid]` | PowerScheduler current build ID |

### Grade Level Arithmetic

```
(grade_level;+1)   -- Add to static field value (result: 10 if grade is 9)
```

Supports: `+`, `-`, `*`, `/` operators.

---

## 7. GPV Handling & URL Parameters

### GPV Encoding Modifiers

| Modifier | Description | Use Case | Example Input → Output |
|----------|-------------|----------|------------------------|
| `(gpv.name;urlencode)` | URL-encode | In links | `it's >< alive` → `it%27s+%3E%3C+alive` |
| `(gpv.name;encodejsstring)` | JavaScript-encode | In JS strings | `it's >< alive` → `it\'s >< alive` |
| `(gpv.name;encodehtml)` | HTML-encode | Display in webpage | `it's >< alive` → `it&#39;s &gt;&lt; alive` |
| `(gpv.name;sqlText)` | SQL-encode | In tlist_sql queries | `it's >< alive` → `it''s >< alive` |

### GPV Validation & Filtering (21.4.2+)

| Modifier | Description |
|----------|-------------|
| `(gpv.name;if.blank.then=default_value)` | Default if blank |
| `(gpv.name;num)` | Force numeric (non-numeric → `0`) |
| `(gpv.name;onlynumeric)` | Remove non-numeric chars: `+-.,0123456789` |
| `(gpv.name;onlyalpha)` | Keep only a-Z |
| `(gpv.name;onlyalphanumeric)` | Keep alphanumeric + `+-.,` |
| `(gpv.name;onlydatecharacters)` | Keep only date chars: `,-./0123456789` |

### SetPostValue

Set values accessible via GPV tags:
```
~[SetPostValue:Name=Value]
```

### URL Redirects on Login

| URL Pattern | Effect |
|-------------|--------|
| `/admin/pw.html?loginTarget=/path/here.html` | Redirect to page after admin login |
| `/teachers/pw.html?loginTarget=/path/here.html` | Redirect to page after teacher login |
| `/public/home.html?loginTarget=/path/here.html` | Redirect to page after parent/student login |

### Other URL Parameters

| Parameter | Effect |
|-----------|--------|
| `lsp=/url` | Sets last student page |
| `no-store-lp=1` | Doesn't change last student page |

---

## 8. API Integration

### Debugging PowerQueries

Add `"__debug_query": "true"` to JSON payload on API calls to log the executed query (with DRF applied) to psj-runtime.

**JavaScript/JQuery:**
```javascript
// FAIL - data must be a string, not an object:
data: {"__debug_query": "true"}

// SUCCESS:
data: `{"__debug_query": "true"}`
// or
data: JSON.stringify({"__debug_query": "true"})
```

### PowerQuery Flattened Parameter Behavior

- `flattened="true"` — Null fields are **stripped** from response records (keys won't exist)
- `flattened="false"` — Null fields included as `"field": null`

When using `flattened="false"`, use a fake table name for easy access:
```xml
<column column="students.student_number">fake.student_number</column>
<column column="students.dcid">fake.dcid</column>
<column column="students.last_name">fake.last_name</column>
```

### PowerQuery Arguments

Arguments can be used as variables in WHERE clauses:
```xml
<args>
    <arg name="active" required="false" description="Student Active (1) or Inactive (0)" type="primitive" default="1" />
</args>
```
```sql
WHERE (:active=1 AND students.enroll_status=0) OR :active=0
```

### WITH Clauses in PowerQueries

WITH clauses can be problematic due to DRF. Workaround: join to `(SELECT * FROM with_name)` instead.

### FIQL Filtering

Use `table.field` format matching the column definition:
```xml
<column name="students.enroll_status">enroll_status</column>
<!-- FIQL filter: -->
students.enroll_status==1

<!-- Or with fake table name: -->
<column name="students.enroll_status">faketable.enroll_status</column>
<!-- FIQL filter: -->
faketable.enroll_status==1
```

### V1 API — Posting Data (JSON)

Update a student field:
```json
{
    "students": {
        "student": [{
            "id": row['dcid'],
            "client_uid": row['dcid'],
            "action": "UPDATE",
            "contact_info": {
                "email": row['email_custom']
            }
        }]
    }
}
```

### V1 API — Posting Data (XML)

Insert a test score:
```xml
<test>
  <client_uid>100</client_uid>
  <action>INSERT</action>
  <student_id>1234</student_id>
  <school_number>0</school_number>
  <grade_level>11</grade_level>
  <term_id>14563</term_id>
  <test_id>260</test_id>
  <test_date>2021-04-15</test_date>
  <test_scores>
    <test_score>
      <test_score_id>524</test_score_id>
      <numeric>229</numeric>
      <percent>59</percent>
    </test_score>
    <test_score>
      <test_score_id>526</test_score_id>
      <alpha>1250</alpha>
    </test_score>
  </test_scores>
</test>
```

### Multiple PowerQuery XML Files

Supported — each query used in a plugin can be in its own file (useful for source control).

### Guardian Portal & DRF

DRF is based on the Data Access flag on the contact. The Parent Access checkbox on a student record has **no impact** as of PowerSchool 21.4.2.

### Testing Tools

- **Postman** — V9+: use Authorization tab, Bearer type, enter token there
- **ARC** — Supports cookie pass-through (XHR) from browser
- **Browser Console** — Useful for testing internal API
- **Python + Jupyter Notebooks** — Use `keyring` library to store OAuth credentials:

```python
import keyring
keyring.set_password("server.com", "oauth", '{"server":"server.com","client_id":"some client","secret":"some secret"}')
keyring.get_password("server.com", "oauth")
```

---

## 9. Modifiers Reference

### Field Modifiers (applied with `~()` or `^()`)

```html
~([table]field;replace=whattofind,whattoreplacewith)
~([table]field;substring=start_position,how_many)
~([table]field;decode=value1=display1,value2=display2)
~([table]field;uppercase)
~([table]field;lowercase)
~([table]field;smartcase)
~([table]field;keep_ascii=1-100,106)
```

### External Expression Modifier `^()`

Similar to `~()` but uses different syntax:

| Modifier | Description |
|----------|-------------|
| `^(field;allfrom=xyz)` | All characters from string onward |
| `^(field;allthrough=xyz)` | All characters through string |
| `^(field;removeallbut=xyz)` | Remove all except specified chars |
| `^(field;substring=x,y)` | Skip x chars, keep y chars |
| `^(field;fixedleft=x)`, `^(field;fx=x)`, `^(field;fxl=x)` | Keep x characters from left |
| `^(transfercomment;nohtml)` | Remove HTML when exporting |

### Decode Modifier

```html
~([table]field;decode=value1=display1,value2=display2)
```

### External Expression with SQL Insertion

```html
~(expression;t;externalexpression)
```
If not pulling properly, add the table field to your SQL and use `~(sections.schoolid;l)` (wrap in comments if display is undesired).

---

## 10. Object Reports

### Repeat a Symbol

```html
Signature:<tabl 7.5 _>
```
Repeats underscore from 7.5 inches to the left margin.

### f.pref in Object Reports

```
^(f.pref;fn=get;name=superintendent)
```

### Multi-line Listing Pattern (Enrollment History Example)

Use 6 objects with layering for positioning. Y values based on 12pt font.

**Header object:**
```html
<b>Enrollment History</b>~(f.table_info;table=reenrollments;dothisfor=all;fn=sel;*studentid=~([01]id))~(f.order_by;table=reenrollments;object1=$([reenrollments]entrydate);type1=INT;direction1=.lt.)
Entry Date<tabl 2>Exit Date<tabc 3>Grade<tabl 3.5>School
```

**Current enrollment row:**
```html
~([01]entrydate;dateformat=m/d/yyyy)<tabl 2>~([01]exitdate;dateformat=m/d/yyyy)<tabl 3>~([01]grade_level)<tabl 3.5>~([schools]name)
```

**Individual field objects (repeating rows):**
```html
~(f.table_sel;table=reenrollments;fn=first_rec)
~(decode;~(f.sqrt;~(f.sub;~(f.table_sel;table=reenrollments;fn=count);0);error_msg=0);0; ;~(f.table_info;table=schools;dothisfor=all;fn=value;field=name;*school_number=~([reenrollments]schoolid)))
~(f.table_sel;table=reenrollments;fn=next_rec)
```

**Key pattern:** Subtract `(row_number - 1)` from count, take square root. At zero or below, sqrt errors → return `0` via `error_msg=0` → decode suppresses display. Creates N rows of data.

### Dynamic "Legal LastFirst" — California Edition

```html
~([students]StudentCoreFields.PSCORE_LEGAL_LAST_NAME;if.blank.then=~(Last_Name))
~([students]StudentCoreFields.PSCORE_LEGAL_SUFFIX;if.not.blank.then= ~([students]StudentCoreFields.PSCORE_LEGAL_SUFFIX);if.blank.then=~([students]S_CA_STU_X.NameSuffix;if.not.blank.then= ~([students]S_CA_STU_X.NameSuffix);if.blank.then=<>))
, ~([students]StudentCoreFields.PSCORE_LEGAL_FIRST_NAME;if.blank.then=~(First_Name))
~([students]StudentCoreFields.PSCORE_LEGAL_MIDDLE_NAME;if.blank.then=~(Middle_Name))
```

---

## 11. Security & Permissions

### User Role & Permission Checks

| Tag | Description |
|-----|-------------|
| `~[if.ismaintenance]` | User is Maintenance account |
| `~[if.is_prod]` (19.11.0+) | Server is Production (not Test) |
| `~[if.sched_scheduleraccess]` | Authorized for PowerScheduler |
| `~[if.has_role_capability=ERMANAGE]` | Has Manage permissions for Enterprise Reporting |
| `~[if.has_role_capability=LOCKPTPRO]` | Admin has access to lock PTPro sections |
| `~[if.has_role_capability=PTPRO]` | Admin has access to PTPro |
| `~[if.has_role_capability=SCHED]` | Can schedule Data Export Manager exports |

### Security Group & Page Access

| Tag | Description |
|-----|-------------|
| `~[if.security.inrole={group_number(s)}]` | User is in group (comma-separated = OR). Role 999 = Maintenance. |
| `~[if.security.pagenone={path/page}]` | User has **no** access to page |
| `~[if.security.pageview={path/page}]` | User has read-only access (not modify) |
| `~[if.security.pagemod={path/page}]` | User has modify access to page |

### Field-Level Security

| Tag | Description |
|-----|-------------|
| `~[if.security.canmodifyfield={Table.Field}]` | User can modify field |
| `~[if.security.canviewfield={Table.Field}]` | User can view field |
| `~[if.security.noaccessfield={Table.Field}]` | User cannot access field |
| `~[if.security.fieldlevel={Table.Field}{Operator}{Access_level}]` | Field access level check |

**Operators:** `>=`, `<=`, `!=`, `>`, `<`, `=`
**Access levels:** `NoAccess`, `ViewOnly`, `FullAccess`

Example:
```html
~[if.security.fieldLevel=Students.Dob>NoAccess]Has view or modify access[/if]
```

### Page & User Type Checks

| Tag | Description |
|-----|-------------|
| `~[if.modaccess]` | User has modify access to current page |
| `~[if.isstudent]` | Student account logged into parent portal |
| `~[if.isguardian]` | Guardian account logged into parent portal |

### Plugin & System Checks

| Tag | Description |
|-----|-------------|
| `~[if.plugin.isEnabled.Plugin_Name][/if]` | Plugin is enabled |
| `~[if.database.sql]` | Database is SQL (Oracle) |
| `~[if.district.office][else][/if]` | User is at district office |
| `~[if.is.a.school][else][/if]` | User is at a school |
| `~[if.win][/if]` | User on Windows |
| `~[if.mac][/if]` | User on Mac (also true on iOS; false on Chrome OS) |

**Best practice for browser detection:** Evaluate mac first, put rest in else:
```html
Hold down the ~[if.mac]command[else]control (ctrl)[/if] button to select multiple options
```

### Pref-Based Conditionals

| Tag | Description |
|-----|-------------|
| `~[if.pref.prefname={value}][/if]` | Pref has specific value |
| `~[if.pref.mobile_access-U~[x:users_dcid]=1]` | User-specific pref check |
| `~[if.prefyearschool.prefname={value}][/if]` | Pref where yearid=curyearid AND schoolid=curschoolid |
| `~[if.prefschool.prefname={value}][/if]` | Pref where schoolid=curschoolid |
| `~[if.~(gpv.my_gpv)={value}][/if]` | Named GPV has value (alternate: `~[if.gpv.my_gpv={value}]`) |

---

## 12. Miscellaneous Patterns

### Action Codes (ac=)

| Code | Usage |
|------|-------|
| `prim` | Insert/update/delete data on Admin portal |
| `webasmt` | Insert/update/delete data on Teacher portal |
| `autosendupdate` | Insert/update/delete data on Guardian portal |
| `buildsel` | Build selection from list of student/staff DCIDs |

```html
<!-- Build selection -->
value="buildsel;table=students;list=[comma-separated DCIDs]"
value="buildsel;table=teachers;list=[comma-separated DCIDs]"
```

### Building Student Selections (New Method)

Best in POST requests (handles larger lists). IDs are `students.ID`, not DCID. Limit of 1000 records for `ac=buildsel`.

**Replace selection:**
```html
/admin/SaveSelectedStudentsToSelection.action?forward=/admin/home.html&ids=1&ids=2&selectionAction=replace
```

**Add to selection:**
```html
/admin/SaveSelectedStudentsToSelection.action?forward=/admin/home.html&ids=3&selectionAction=add
```

**HTML form example:**
```html
<form method="post" action="/admin/SaveSelectedStudentsToSelection.action">
    <input type="hidden" name="forward" value="/admin/home.html">
    <input type="hidden" name="ids" value="<id>">
    <input type="hidden" name="selectionAction" value="replace">
</form>
```

### Duplicaterow — Repeat Content N Times

Walks up DOM to nearest `<tr>` and repeats contents:
```html
<table>
    <tr><td>~[duplicaterow;15;xx;count]
        ~[tlist_sql;SELECT xx FROM dual;]
            ~(1)
        [/tlist_sql]
    </td></tr>
</table>
```

### Execute Command

| Endpoint | `/admin/tech/executecommand.html` |
|----------|-----------------------------------|

| Command | Description |
|---------|-------------|
| `**DALX_SETGLOBALSYNCOFF` | Disable Atomic Sync |
| `**DALX_SETGLOBALSYNCON` | Enable Atomic Sync (may be disabled in PS 11.0.3+) |
| `**INITDAILYSCHEDULES` | Initialize all calendars (necessary when adding new days to a term) |
| `**MSYNC_RESYNCMAIN` | Resync PowerTeacher & PowerSchool tables; eliminates duplicated prefs and terms |
| `**PUTPREF("prefname")` | Delete pref from Prefs table |
| `**PUTPREF("prefname";"value")` | Set/update pref in Prefs table |
| `**SETUPHTMLWCS` | Refresh wildcards + full CPM refresh |

### Disable Custom Page Caching (Dev Server Only)

Path: `[Drive]:\Program Files\PowerSchool\configuration\services\tomcat-oltp\apps\powerschool`

In `application.properties`:
```properties
com.pearson.pss.reporting.resource.custom.cachebytes = 0
default.com.pearson.pss.reporting.resource.custom.cachebytes = 0
```
Then restart PowerSchool.

### Enable GUID Setup

URL: `/admin/tech/special/guidSetup.action`

### Enable JavaScript Debugging

URL: `/webutil/jsdebug.html` (not under `/admin`)

### Codeset Options for Select Dropdowns

```html
~[x:codesetoptions;codetype=State;includeblank;value=~([01]state)]
```

| Parameter | Description |
|-----------|-------------|
| `codetype=` | Category from codesets |
| `includeblank` | Adds blank option before list |
| `value=~()` | Pre-selected value |

### PowerScheduler SQL Example

```sql
FROM schedulerequests sr
JOIN schedulecoursecatalogs scc
    ON scc.coursecatalogid = ~[x:scheduleinfo;curcatalogid]
    AND scc.course_number = sr.coursenumber
```

### person_id — Relationship Table Lookup

```sql
SELECT s.lastfirst
     , s.grade_level
     , s.enroll_status
FROM relationship rel
INNER JOIN students s ON s.person_id = rel.person_id
WHERE rel.relatedperson_id = ~(person_id)
ORDER BY s.grade_level
```

### Angular Auto-Bootstrapping

**Old method:**
```javascript
require(['angular', 'components/myComponent/index'], function(angular) {
    angular.bootstrap(document, ['myModule']);
});
```

**New method:**
```html
<div data-require-path="components/myComponent/index"
     data-module-name="myModule">
    my angular stuff here
</div>
```

---

## 13. VS Code Completions Reference

The file `VS Code PS completions.json` (in the same directory) provides autocomplete snippets for Visual Studio Code. Key snippets organized by category:

### PowerSchool Tags & Context

| Prefix | Expands To |
|--------|------------|
| `psCurDate` | `~[short.date]` |
| `psCurUserId` | `~[x:userid]` |
| `psCurUserName` | `~[x:username]` |
| `psSchool` | `~(curschoolid)` |
| `psSchoolName` | `~(schoolname)` |
| `psStudent` | `~(curstudid)` |
| `psYearid` | `~(curyearid)` |
| `psYearname` | `~(yearname)` |
| `psVersion` | `~[x:version]` |
| `psPref` | `~[displaypref:{prefname}]` |
| `psPrefSchool` | `~[prefschool:{prefname}]` |
| `psPrefUser` | `~[displaypref:{prefname}-U~[x:userid]]` |
| `psStudentCount` | `~[x:studsinset]` |
| `psgpv` | `~[duplicate;6;xx;count]...[/duplicate]` |
| `psif` | `~[if.~[gpv:{param}]=][else][/if]` |
| `pstlist` | `~[tlist_sql;{query};]{rowTemplate}[/tlist_sql]` |
| `pswc` | `~[wc:{filename}]` |
| `psinsertFile` | `~[x:insertfile;{filename}.{ext}]` |
| `psJsfieldparam` | `~(JSFieldParam;[01]fieldName)` |

### Conditional Tags

| Prefix | Expands To |
|--------|------------|
| `psIfDistrict` | `~[if.district.office][/if]` |
| `psIfSchool` | `~[if.is.a.school][/if]` |
| `psIfStudent` | `~[if.isstudent][/if]` |
| `psIfGuardian` | `~[if.isguardian][/if]` |
| `psAuthorizeXRFE` | `~[AuthorizeXFRE:{DC-.*}]` |

### Forms & Fields

| Prefix | Expands To |
|--------|------------|
| `psFormAdmin` | Admin form with `ac=prim` |
| `psFormParent` | Parent portal form with `ac=autosendupdate` |
| `psFormTch` | Teacher portal form with `ac=webasmt` |
| `psInput` | `<input type="text" name="" value="">` |
| `psInputHidden` | `<input type="hidden" name="" value="">` |
| `psAcPrim` | `<input type="hidden" name="ac" value="prim">` |
| `psFieldExtended` | `[students.{extensionName}]{fieldName}` input |
| `psFieldChildEdit` | Child table edit field CF-[] |
| `psFieldChildNew` | Child table new record field |
| `psFieldChildDelete` | Child table delete field |

### Tables & Layout

| Prefix | Expands To |
|--------|------------|
| `psTableFilter` | `<table class="linkDescList" data-pstablefilter="">` |
| `psTableGrid` | `<table class="grid">` |
| `psTableLinkDesc` | `<table class="linkDescList">` |
| `psButtonRow` | `<div class="button-row">...</div>` |
| `psDialogDocked` | Docked dialog link |
| `psFeedbackAlert` | Feedback alert div |
| `psFeedbackConfirm` | Feedback confirm div |
| `psFeedbackError` | Feedback error div |
| `psDateWidget` | Date widget input |
| `psTimeEntry` | Time entry widget (includes script) |

### Repeat & Loop Patterns

| Prefix | Expands To |
|--------|------------|
| `psRepeatForEachStudent` | `~[studentlist2]...~[RepeatForEach:Students]...[/RepeatForEach:Students]` |
| `psDirectTableSelect` | `~[DirectTable.Select:{tableName};id:{idvalue}]` |

### jQuery Helpers

| Prefix | Expands To |
|--------|------------|
| `jqReady` | `$j(document).ready(function(){...});` |
| `jqAjaxStop` | `$j(document).ajaxStop(function(){...});` |
| `jqGetJson` | `$j.getJSON({url},function(data){...});` |
| `jqPost` | `$j.post({url},function(data){...});` |
| `jqOn` | `$j({selector}).on({event},function(){...});` |
| `jqEach` | `$j({selector}).each(function(){...});` |
| `jqFind` | `$j({selector}).find(...)` |
| `jqClosest` | `$j({selector}).closest(...)` |
| `jqAttr` | `$j({selector}).attr({attr},{value})` |
| `jqVal` | `$j({selector}).val(...)` |
| `jqHtml` | `$j({selector}).html(...)` |
| `jqShow` / `jqHide` | Show/hide element |
| `jqAddClass` / `jqRemoveClass` | Toggle CSS class |
| `jqAppend` | Append content |
| `jqChange` | Change event handler |
| `jqThis` | `$j(this).(...)` |

### JavaScript Helpers

| Prefix | Expands To |
|--------|------------|
| `alert` | `alert("")` |
| `consoleLog` | `console.log("")` |
| `ifJavaScript` | `if(){} ` |
| `jsSetTimeout` | `setTimeout(function(){}, 3000)` |
| `jslintIgnore` | JSHint ignore block |

### SQL Character Helpers

| Prefix | Expands To |
|--------|------------|
| `chrCaret` | `CHR(94)` |
| `chrCarriageReturn` | `CHR(13)` |
| `chrLineFeed` | `CHR(10)` |
| `chrColon` | `CHR(58)` |
| `chrLeftBracket` | `CHR(91)` |
| `chrRightBracket` | `CHR(93)` |

---

