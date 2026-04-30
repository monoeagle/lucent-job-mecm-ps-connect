#!/usr/bin/env bash
# 030-device-software.sh
#
# Installierte Software fuer ein Device aus dem Software-Inventory.
# View: v_GS_INSTALLED_SOFTWARE
#
# Usage:
#   ./030-device-software.sh PC123
#   ./030-device-software.sh PC123 Microsoft

source "$(dirname "$0")/_common.sh"

NAME="${1:?ComputerName required}"
PUBLISHER="${2:-}"
RID=$(resolve_resource_id "$NAME")

WHERE="ResourceID = ${RID}"
if [[ -n "$PUBLISHER" ]]; then
    WHERE+=" AND Publisher0 LIKE N'%${PUBLISHER}%'"
fi

QUERY="SELECT
    ProductName0,
    ProductVersion0,
    Publisher0,
    InstallDate0
FROM v_GS_INSTALLED_SOFTWARE
WHERE ${WHERE}
ORDER BY ProductName0;"

sql_query_with_header 'ProductName|Version|Publisher|InstallDate' "$QUERY"
