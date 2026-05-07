#!/usr/bin/env bash
# 070-task-sequence-status.sh
#
# Task-Sequence-Status-Historie aus v_TaskExecutionStatus, optional pro
# Device gefiltert.
# LastStatusType: 1=Compliant, 2=NonCompliant, 3=Failed, 4=Unknown, 5=Success
#
# Usage:
#   ./070-task-sequence-status.sh                # alle, Top=100
#   ./070-task-sequence-status.sh PC123          # nur Device
#   ./070-task-sequence-status.sh PC123 25       # mit Top=25

source "$(dirname "$0")/_common.sh"

NAME="${1:-}"
TOP="${2:-100}"

WHERE=""
if [[ -n "$NAME" ]]; then
    RID=$(resolve_resource_id "$NAME")
    WHERE="WHERE t.ResourceID = ${RID}"
fi

QUERY="SELECT TOP ${TOP}
    s.Name0 AS DeviceName,
    t.PackageID,
    t.AdvertisementID,
    CASE t.LastStatusType
        WHEN 1 THEN 'Compliant'
        WHEN 2 THEN 'NonCompliant'
        WHEN 3 THEN 'Failed'
        WHEN 4 THEN 'Unknown'
        WHEN 5 THEN 'Success'
        ELSE CAST(t.LastStatusType AS NVARCHAR(10))
    END AS Status,
    t.LastStatusMessageID,
    t.ExecutionTime
FROM v_TaskExecutionStatus t
JOIN v_R_System s ON s.ResourceID = t.ResourceID
${WHERE}
ORDER BY t.ExecutionTime DESC;"

sql_query_with_header 'Device|PackageID|AdvID|Status|LastMsgID|ExecutionTime' "$QUERY"
