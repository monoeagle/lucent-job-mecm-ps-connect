#!/usr/bin/env bash
# 080-client-health.sh
#
# Client-Health-Summary (SMS_CH_ClientSummary). Aggregiert Heartbeat-,
# Inventory-, Status- und Policy-Health pro Device.
#
# Usage:
#   ./080-client-health.sh                       # alle
#   ./080-client-health.sh PC123                 # nur Device
#   ./080-client-health.sh "" unhealthy          # nur inactive Clients
#   ./080-client-health.sh "" "" 50              # mit Top=50

source "$(dirname "$0")/_common.sh"

NAME="${1:-}"
ONLY_UNHEALTHY="${2:-}"
TOP="${3:-200}"

CONDS=()
if [[ -n "$NAME" ]]; then
    RID=$(resolve_resource_id "$NAME")
    CONDS+=("ResourceID%20eq%20${RID}")
fi
if [[ "$ONLY_UNHEALTHY" == "unhealthy" ]]; then
    CONDS+=("ClientActiveStatus%20eq%200")
fi

QUERY="\$select=ResourceID,Name,ClientActiveStatus,ClientStateDescription,LastActiveTime,LastOnline,LastHardwareScan,LastPolicyRequest"
QUERY+="&\$orderby=LastActiveTime%20desc&\$top=${TOP}"
if (( ${#CONDS[@]} > 0 )); then
    FILTER=$(IFS='%20and%20'; echo "${CONDS[*]}")
    QUERY="\$filter=${FILTER}&${QUERY}"
fi

{
    printf 'Name\tState\tActive\tLastActive\tLastHWScan\tLastPolicy\n'
    as_get_paged "wmi/SMS_CH_ClientSummary" "$QUERY" | jq -r '
        (if .ClientActiveStatus == 1 then "yes" else "no" end) as $active |
        [.Name, (.ClientStateDescription // ""), $active,
         (.LastActiveTime // ""), (.LastHardwareScan // ""),
         (.LastPolicyRequest // "")] | @tsv'
} | column -t -s $'\t'
