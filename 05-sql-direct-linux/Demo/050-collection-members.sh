#!/usr/bin/env bash
# 050-collection-members.sh
#
# Members einer Collection — Resolve Name -> CollectionID, JOIN ueber
# v_FullCollectionMembership + v_R_System fuer lesbare Device-Daten.
#
# Usage:
#   ./050-collection-members.sh "All Workstations"
#   ./050-collection-members.sh --id SMS00001

source "$(dirname "$0")/_common.sh"

if [[ "${1:-}" == "--id" ]]; then
    COLL_ID="${2:?CollectionID required}"
else
    COLL_NAME="${1:?CollectionName or --id <CollectionID> required}"
    COLL_ID=$(sql_query "SELECT TOP 1 CollectionID FROM v_Collection WHERE Name = N'${COLL_NAME}'" | tr -d ' ')
    if [[ -z "$COLL_ID" || "$COLL_ID" == "NULL" ]]; then
        echo "Collection '$COLL_NAME' nicht gefunden." >&2
        exit 1
    fi
    echo "Collection '$COLL_NAME' = $COLL_ID"
fi

QUERY="SELECT
    s.Name0,
    s.ResourceID,
    s.Full_Domain_Name0,
    s.Client0,
    s.User_Name0
FROM v_FullCollectionMembership m
JOIN v_R_System s ON s.ResourceID = m.ResourceID
WHERE m.CollectionID = '${COLL_ID}'
ORDER BY s.Name0;"

sql_query_with_header 'Name|ResourceID|Domain|IsClient|LastLogonUser' "$QUERY"
