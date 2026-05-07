#!/usr/bin/env bash
# 070-task-sequence-status.sh
#
# Zeigt Task-Sequence-Deployment-Status (SMS_TaskSequenceDeploymentStatus).
# Optional auf ein Device einschraenken.
#
# Usage:
#   ./070-task-sequence-status.sh                # alle, Top=100
#   ./070-task-sequence-status.sh PC123          # nur fuer Device
#   ./070-task-sequence-status.sh PC123 25       # mit Top=25

source "$(dirname "$0")/_common.sh"

NAME="${1:-}"
TOP="${2:-100}"

FILTER=""
if [[ -n "$NAME" ]]; then
    RESOURCE_ID=$(resolve_resource_id "$NAME")
    FILTER="ResourceID%20eq%20${RESOURCE_ID}"
fi

QUERY="\$select=ResourceID,DeviceName,PackageID,AdvertisementID,StatusType,LastStatusMessageID,StatusTime"
QUERY+="&\$orderby=StatusTime%20desc&\$top=${TOP}"
[[ -n "$FILTER" ]] && QUERY="\$filter=${FILTER}&${QUERY}"

# StatusType: 1=Compliant 2=NonCompliant 3=Failed 4=Unknown 5=Success
{
    printf 'Device\tPackageID\tAdvID\tStatus\tLastMsgID\tStatusTime\n'
    as_get_paged "wmi/SMS_TaskSequenceDeploymentStatus" "$QUERY" | jq -r '
        ((.StatusType|tostring) as $s |
         ({"1":"Compliant","2":"NonCompliant","3":"Failed","4":"Unknown","5":"Success"}[$s] // $s)) as $st |
        [.DeviceName, .PackageID, .AdvertisementID, $st,
         (.LastStatusMessageID|tostring), .StatusTime] | @tsv'
} | column -t -s $'\t'
