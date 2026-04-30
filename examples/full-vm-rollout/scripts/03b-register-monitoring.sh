#!/usr/bin/env bash
# Stage 3b: Host im Monitoring registrieren (simuliert)
#
# Echte Provider/APIs:
#   - icinga2 REST: POST /v1/objects/hosts/<name>
#   - datadog_host (Tofu-Provider) oder Datadog-Agent-Auto-Discovery
#   - zabbix_host (Tofu-Provider Community)
#   - prometheus: file_sd-Eintrag generieren
#   - dynatrace_host_settings, newrelic_one_dashboard, etc.

set -euo pipefail

HOSTNAME="${1:?hostname required}"
MON_URL="${2:?monitoring url required}"
DRY_RUN="${DRY_RUN:-true}"

echo "[$(date -Iseconds)] STAGE 3b → Monitoring-Registrierung fuer ${HOSTNAME}"

if [[ "$DRY_RUN" == "true" ]]; then
    echo "  (dry-run) wuerde POST ${MON_URL} mit body:"
    cat <<EOF
    {
      "hostname": "${HOSTNAME}",
      "templates": ["windows-base", "configmgr-client"],
      "groups": ["windows", "managed-by-configmgr"],
      "check_command": "hostalive"
    }
EOF
    sleep 1
else
    # curl --negotiate -u : -X POST "${MON_URL}" \
    #     -H "Content-Type: application/json" \
    #     -d "{\"hostname\":\"${HOSTNAME}\",...}"
    echo "  ERROR: Real-Mode nicht implementiert."
    exit 1
fi

echo "[$(date -Iseconds)] STAGE 3b ✓ Im Monitoring eingetragen"
