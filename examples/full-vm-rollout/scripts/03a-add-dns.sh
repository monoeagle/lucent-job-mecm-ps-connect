#!/usr/bin/env bash
# Stage 3a: DNS-A-Record anlegen (simuliert)
#
# Echte Provider:
#   - cloudflare_record         (registry.terraform.io/providers/cloudflare/cloudflare)
#   - powerdns_record           (registry.terraform.io/providers/pan-net/powerdns)
#   - dns_a_record_set          (registry.terraform.io/providers/hashicorp/dns)
#   - infoblox_a_record         (registry.terraform.io/providers/infobloxopen/infoblox)
#   - aws_route53_record / azurerm_dns_a_record
#
# Diese Pattern ersetzen die null_resource — der Wait-Module-Output
# computer_name wird als hostname-Input genutzt.

set -euo pipefail

HOSTNAME="${1:?hostname required}"
ZONE="${2:?zone required}"
DRY_RUN="${DRY_RUN:-true}"

FQDN="${HOSTNAME}.${ZONE}"

echo "[$(date -Iseconds)] STAGE 3a → DNS A-Record fuer ${FQDN}"

if [[ "$DRY_RUN" == "true" ]]; then
    echo "  (dry-run) wuerde A-Record ${FQDN} -> <ip> anlegen"
    sleep 1
else
    # Beispiel mit nsupdate (BIND):
    # nsupdate -k /etc/krb5.keytab <<EOF
    # update add ${FQDN} 3600 A ${IP_FROM_STAGE1}
    # send
    # EOF
    echo "  ERROR: Real-Mode nicht implementiert."
    exit 1
fi

echo "[$(date -Iseconds)] STAGE 3a ✓ DNS-Record gesetzt"
