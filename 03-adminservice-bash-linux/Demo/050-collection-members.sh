#!/usr/bin/env bash
# 050-collection-members.sh
#
# Listet alle Member einer Collection. Resolve Collection-Name zu CollectionID,
# dann SMS_FullCollectionMembership filtern (mit Pagination).
#
# Usage:
#   ./050-collection-members.sh "All Workstations"
#   ./050-collection-members.sh --id SMS00001

source "$(dirname "$0")/_common.sh"

if [[ "${1:-}" == "--id" ]]; then
    COLL_ID="${2:?CollectionID required}"
else
    COLL_NAME="${1:?CollectionName or --id <CollectionID> required}"
    COLL_ID=$(as_get "wmi/SMS_Collection" \
        "\$filter=Name%20eq%20'${COLL_NAME}'&\$select=CollectionID" |
        jq -r '.value[0].CollectionID // empty')
    if [[ -z "$COLL_ID" ]]; then
        echo "Collection '$COLL_NAME' nicht gefunden." >&2
        exit 1
    fi
    echo "Collection '$COLL_NAME' = $COLL_ID"
fi

QUERY="\$filter=CollectionID%20eq%20'${COLL_ID}'&\$select=ResourceID,Name,Domain,SMSID,IsClient,IsActive&\$orderby=Name"

{
    printf 'Name\tResourceID\tDomain\tIsClient\tIsActive\n'
    as_get_paged "wmi/SMS_FullCollectionMembership" "$QUERY" | jq -r '
        [.Name, (.ResourceID|tostring), (.Domain // ""),
         (.IsClient|tostring), (.IsActive|tostring)] | @tsv'
} | column -t -s $'\t'
