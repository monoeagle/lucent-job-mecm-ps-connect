#!/usr/bin/env bash
# 040-device-collections.sh
#
# Collections, in denen ein Device Mitglied ist. JOIN ueber
# v_FullCollectionMembership + v_Collection.
#
# Usage:
#   ./040-device-collections.sh PC123

source "$(dirname "$0")/_common.sh"

NAME="${1:?ComputerName required}"
RID=$(resolve_resource_id "$NAME")

QUERY="SELECT
    c.CollectionID,
    c.Name,
    c.MemberCount,
    LEFT(ISNULL(c.Comment, ''), 60) AS Comment
FROM v_FullCollectionMembership m
JOIN v_Collection c ON c.CollectionID = m.CollectionID
WHERE m.ResourceID = ${RID}
ORDER BY c.Name;"

sql_query_with_header 'CollectionID|Name|Members|Comment' "$QUERY"
