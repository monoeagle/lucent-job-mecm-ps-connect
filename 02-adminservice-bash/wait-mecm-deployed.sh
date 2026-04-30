#!/usr/bin/env bash
set -euo pipefail

COMPUTER_NAME="${1:?computer name required}"
SMS_PROVIDER="${2:?sms provider required}"
SITE_CODE="${3:?site code required}"
TIMEOUT="${TIMEOUT_SECONDS:-3600}"
INTERVAL="${POLL_INTERVAL_SECONDS:-30}"

BASE="https://${SMS_PROVIDER}/AdminService/wmi"
CURL=(curl --silent --show-error --fail --negotiate -u : -H 'Accept: application/json')

query() {
    "${CURL[@]}" "$1"
}

deadline=$(( $(date +%s) + TIMEOUT ))

while [ "$(date +%s)" -lt "$deadline" ]; do
    device_json=$(query "${BASE}/SMS_R_System?\$filter=Name%20eq%20'${COMPUTER_NAME}'&\$select=ResourceID,Client" || echo '{"value":[]}')
    resource_id=$(echo "$device_json" | jq -r '.value[0].ResourceID // empty')
    client_ready=$(echo "$device_json" | jq -r '.value[0].Client // 0')

    if [ -n "$resource_id" ]; then
        ts_json=$(query "${BASE}/SMS_TaskSequenceDeploymentStatus?\$filter=ResourceID%20eq%20${resource_id}&\$orderby=StatusTime%20desc" || echo '{"value":[]}')
        ts_status=$(echo "$ts_json" | jq -r '.value[0].StatusType // 0')

        echo "[$(date -Iseconds)] ${COMPUTER_NAME} resource=${resource_id} client=${client_ready} ts_status=${ts_status}"

        if [ "$client_ready" = "1" ] && [ "$ts_status" = "5" ]; then
            echo "DEPLOYED"
            exit 0
        fi
    else
        echo "[$(date -Iseconds)] ${COMPUTER_NAME} noch nicht in MECM bekannt"
    fi

    sleep "$INTERVAL"
done

echo "Timeout nach ${TIMEOUT}s — ${COMPUTER_NAME} nicht deployed." >&2
exit 1
