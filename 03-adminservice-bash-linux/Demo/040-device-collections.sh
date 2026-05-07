#!/usr/bin/env bash
# 040-device-collections.sh
#
# Zeigt, in welchen Collections ein Device Mitglied ist. Zwei-Stufen-Resolve:
# 1. ComputerName -> ResourceID
# 2. SMS_FullCollectionMembership filterm nach ResourceID
# 3. SMS_Collection pro CollectionID fuer den Namen.
#
# Usage:
#   ./040-device-collections.sh PC123

source "$(dirname "$0")/_common.sh"

NAME="${1:?ComputerName required}"
RESOURCE_ID=$(resolve_resource_id "$NAME")

# CollectionIDs holen
COLL_IDS=$(as_get_paged "wmi/SMS_FullCollectionMembership" \
    "\$filter=ResourceID%20eq%20${RESOURCE_ID}&\$select=CollectionID" |
    jq -r '.CollectionID' | sort -u)

if [[ -z "$COLL_IDS" ]]; then
    echo "Device $NAME ist in keiner Collection."
    exit 0
fi

{
    printf 'CollectionID\tName\tMembers\tComment\n'
    while IFS= read -r cid; do
        as_get "wmi/SMS_Collection" \
            "\$filter=CollectionID%20eq%20'${cid}'&\$select=CollectionID,Name,Comment,MemberCount" |
            jq -r '.value[] | [.CollectionID, .Name, (.MemberCount|tostring), (.Comment // "")] | @tsv'
    done <<< "$COLL_IDS"
} | column -t -s $'\t'
