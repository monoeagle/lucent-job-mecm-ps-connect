#!/usr/bin/env bash
# 080-client-health.sh
#
# Client-Health-Summary aus v_CH_ClientSummary. Optional pro Device oder
# nur unhealthy.
#
# Usage:
#   ./080-client-health.sh                   # alle
#   ./080-client-health.sh PC123             # nur Device
#   ./080-client-health.sh "" unhealthy      # nur inactive Clients
#   ./080-client-health.sh "" "" 50          # mit Top=50

source "$(dirname "$0")/_common.sh"

NAME="${1:-}"
ONLY_UNHEALTHY="${2:-}"
TOP="${3:-200}"

CONDS=()
if [[ -n "$NAME" ]]; then
    RID=$(resolve_resource_id "$NAME")
    CONDS+=("ResourceID = ${RID}")
fi
if [[ "$ONLY_UNHEALTHY" == "unhealthy" ]]; then
    CONDS+=("ClientActiveStatus = 0")
fi

WHERE=""
if (( ${#CONDS[@]} > 0 )); then
    WHERE="WHERE $(IFS=' AND '; echo "${CONDS[*]}")"
fi

QUERY="SELECT TOP ${TOP}
    Name,
    ClientStateDescription,
    CASE ClientActiveStatus WHEN 1 THEN 'yes' ELSE 'no' END AS Active,
    LastActiveTime,
    LastHardwareScan,
    LastPolicyRequest
FROM v_CH_ClientSummary
${WHERE}
ORDER BY LastActiveTime DESC;"

sql_query_with_header 'Name|State|Active|LastActive|LastHWScan|LastPolicy' "$QUERY"
