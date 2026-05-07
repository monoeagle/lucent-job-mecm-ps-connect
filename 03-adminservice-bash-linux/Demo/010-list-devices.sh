#!/usr/bin/env bash
# 010-list-devices.sh
#
# Listet Devices aus SMS_R_System mit Filter, Sortierung und Pagination.
# Demonstriert OData $filter, $select, $orderby, $top + @odata.nextLink.
#
# Usage:
#   ./010-list-devices.sh                         # erste 50 Devices
#   ./010-list-devices.sh PC 200                  # NameFilter='PC', Top=200

source "$(dirname "$0")/_common.sh"

NAME_FILTER="${1:-}"
TOP="${2:-50}"

QUERY="\$select=ResourceID,Name,Client,Domain,LastLogonUserName,OperatingSystemNameandVersion"
QUERY+="&\$orderby=Name"
QUERY+="&\$top=${TOP}"
if [[ -n "$NAME_FILTER" ]]; then
    QUERY+="&\$filter=startswith(Name,'${NAME_FILTER}')"
fi

{
    printf 'Name\tResourceID\tClient\tDomain\tLastLogonUser\tOS\n'
    as_get_paged "wmi/SMS_R_System" "$QUERY" | jq -r '
        [.Name, (.ResourceID|tostring), (.Client|tostring),
         (.Domain // ""), (.LastLogonUserName // ""),
         (.OperatingSystemNameandVersion // "")] | @tsv'
} | column -t -s $'\t'
