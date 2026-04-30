#!/usr/bin/env bash
# Stage 4: Final Notification (simuliert)
#
# Echte Wege:
#   - Slack: curl -X POST <webhook> -d '{"text":"..."}'
#   - MS Teams: curl -X POST <webhook> -H "Content-Type: application/json" -d '{...}'
#   - E-Mail via msmtp/sendmail
#   - PagerDuty Events API
#   - Tofu-Provider: mailgun_route, slack_*

set -euo pipefail

HOSTNAME="${1:?hostname required}"
CHANNEL="${2:?channel required}"
DRY_RUN="${DRY_RUN:-true}"

MSG="✓ Rollout abgeschlossen: ${HOSTNAME} ist deployed, im DNS, im Monitoring und in der CMDB."

echo "[$(date -Iseconds)] STAGE 4 → Notification an ${CHANNEL}"

if [[ "$DRY_RUN" == "true" ]]; then
    echo "  (dry-run) wuerde an ${CHANNEL} senden:"
    echo "    \"${MSG}\""
    sleep 1
else
    # Beispiel Slack:
    # curl -X POST "${SLACK_WEBHOOK_URL}" \
    #     -H "Content-Type: application/json" \
    #     -d "{\"channel\":\"${CHANNEL}\",\"text\":\"${MSG}\"}"
    echo "  ERROR: Real-Mode nicht implementiert."
    exit 1
fi

echo "[$(date -Iseconds)] STAGE 4 ✓ Rollout-Pipeline abgeschlossen"
