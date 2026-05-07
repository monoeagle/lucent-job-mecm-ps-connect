#!/usr/bin/env bash
# 060-deployments.sh
#
# Listet Deployments aus SMS_DeploymentInfo - aktuell laufende oder
# zukuenftig geplante. StartTime ist OData-datetime, "gt now" filtert
# zukuenftige Deployments.
#
# Usage:
#   ./060-deployments.sh                # Default: alle
#   ./060-deployments.sh active         # nur bereits gestartete
#   ./060-deployments.sh future         # nur zukuenftig geplante
#   ./060-deployments.sh future 50      # mit Top=50

source "$(dirname "$0")/_common.sh"

MODE="${1:-all}"
TOP="${2:-100}"
NOW_UTC=$(date -u +%Y-%m-%dT%H:%M:%SZ)

case "$MODE" in
    active) FILTER="StartTime%20le%20${NOW_UTC}" ;;
    future) FILTER="StartTime%20gt%20${NOW_UTC}" ;;
    all)    FILTER="" ;;
    *) echo "Mode muss active|future|all sein" >&2; exit 1 ;;
esac

QUERY="\$select=DeploymentID,DeploymentName,FeatureType,CollectionName,StartTime,DeploymentIntent"
QUERY+="&\$orderby=StartTime%20desc&\$top=${TOP}"
[[ -n "$FILTER" ]] && QUERY="\$filter=${FILTER}&${QUERY}"

# FeatureType-Mapping: 1=App, 2=Prog, 5=Update, 6=Baseline, 7=TS, 8=Setting
{
    printf 'Type\tDeploymentName\tCollection\tStartTime\tIntent\n'
    as_get_paged "wmi/SMS_DeploymentInfo" "$QUERY" | jq -r '
        ((.FeatureType|tostring) as $ft |
         ({"1":"App","2":"Program","5":"Update","6":"Baseline","7":"TaskSeq","8":"Setting"}[$ft] // $ft)) as $type |
        [$type, .DeploymentName, .CollectionName, .StartTime, (.DeploymentIntent|tostring)] | @tsv'
} | column -t -s $'\t'
