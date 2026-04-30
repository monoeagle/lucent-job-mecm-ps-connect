#!/usr/bin/env bash
# Stage 3c: CMDB-Eintrag anlegen/updaten (simuliert)
#
# Echte Provider/APIs:
#   - ServiceNow REST API: POST /api/now/table/cmdb_ci_computer
#   - iTop REST: POST /webservices/rest.php
#   - Snipe-IT API: POST /api/v1/hardware
#   - Netbox: netbox_device (Tofu-Provider)
#   - eigene CMDB: passender REST-Endpoint
#
# Quelldaten kommen aus ConfigMgr (RID, Hardware-Inventory) und/oder
# aus dem VM-Provider (vCenter, Cloud).

set -euo pipefail

HOSTNAME="${1:?hostname required}"
CMDB_URL="${2:?cmdb url required}"
DRY_RUN="${DRY_RUN:-true}"

echo "[$(date -Iseconds)] STAGE 3c → CMDB-Eintrag fuer ${HOSTNAME}"

if [[ "$DRY_RUN" == "true" ]]; then
    echo "  (dry-run) wuerde POST ${CMDB_URL} mit body:"
    cat <<EOF
    {
      "name": "${HOSTNAME}",
      "category": "server",
      "operational_status": "in_use",
      "managed_by": "configmgr",
      "discovered_via": "opentofu-rollout",
      "rollout_date": "$(date -Iseconds)"
    }
EOF
    sleep 1
else
    # curl -H "Authorization: Bearer ${CMDB_TOKEN}" -X POST "${CMDB_URL}" ...
    echo "  ERROR: Real-Mode nicht implementiert."
    exit 1
fi

echo "[$(date -Iseconds)] STAGE 3c ✓ CMDB updated"
