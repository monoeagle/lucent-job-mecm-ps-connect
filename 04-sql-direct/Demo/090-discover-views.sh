#!/usr/bin/env bash
# 090-discover-views.sh
#
# Listet alle dokumentierten v_*-Views in der CM-DB. Damit findest du,
# was an Reporting-Daten verfuegbar ist.
#
# Usage:
#   ./090-discover-views.sh                  # alle Views, max 200
#   ./090-discover-views.sh v_GS_           # Pattern-Match
#   ./090-discover-views.sh v_GS_ schema    # mit Spalten-Schema

source "$(dirname "$0")/_common.sh"

PATTERN="${1:-v_}"
SHOW_SCHEMA="${2:-}"

QUERY_VIEWS="SELECT TOP 500
    TABLE_NAME
FROM INFORMATION_SCHEMA.VIEWS
WHERE TABLE_NAME LIKE N'${PATTERN}%'
ORDER BY TABLE_NAME;"

echo "=== Views mit Pattern '${PATTERN}*' ==="
VIEWS=$(sql_query "$QUERY_VIEWS")
echo "$VIEWS" | column -t

if [[ "$SHOW_SCHEMA" == "schema" ]]; then
    echo
    echo "=== Spalten pro View ==="
    while IFS= read -r view; do
        view_trim=$(echo "$view" | tr -d ' ')
        [[ -z "$view_trim" ]] && continue
        echo
        echo "-- $view_trim --"
        sql_query "SELECT COLUMN_NAME, DATA_TYPE
                   FROM INFORMATION_SCHEMA.COLUMNS
                   WHERE TABLE_NAME = N'${view_trim}'
                   ORDER BY ORDINAL_POSITION;" | column -t
    done <<< "$VIEWS"
fi
