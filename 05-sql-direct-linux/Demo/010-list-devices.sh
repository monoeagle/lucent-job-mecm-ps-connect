#!/usr/bin/env bash
# 010-list-devices.sh
#
# Listet Devices aus v_R_System mit optionalem Filter.
#
# Usage:
#   ./010-list-devices.sh                 # erste 50
#   ./010-list-devices.sh PC 200          # NameFilter, Top=200

source "$(dirname "$0")/_common.sh"

FILTER="${1:-}"
TOP="${2:-50}"

WHERE=""
if [[ -n "$FILTER" ]]; then
    WHERE="WHERE Name0 LIKE N'%${FILTER}%'"
fi

QUERY="SELECT TOP ${TOP}
    Name0,
    ResourceID,
    Client0,
    Full_Domain_Name0,
    User_Name0,
    Operating_System_Name_and0
FROM v_R_System
${WHERE}
ORDER BY Name0;"

sql_query_with_header 'Name|ResourceID|Client|Domain|LastLogonUser|OS' "$QUERY"
