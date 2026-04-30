#!/usr/bin/env bash
# Stage 1: VM-Provisioning (simuliert)
#
# Im echten Setup hier statt null_resource ein passender Provider-Resource:
#   - vsphere_virtual_machine
#   - libvirt_domain
#   - proxmox_vm_qemu
#   - aws_instance / azurerm_virtual_machine / google_compute_instance
#   - oder eigene Provisioning-Pipeline (Foreman, Razor, MAAS)
#
# Outputs aus dem Provider (z.B. IP-Adresse) wuerden dann an Stage 2 weiter-
# gereicht.

set -euo pipefail

HOSTNAME="${1:?hostname required}"
DRY_RUN="${DRY_RUN:-true}"

echo "[$(date -Iseconds)] STAGE 1 → VM '${HOSTNAME}' provisionieren"

if [[ "$DRY_RUN" == "true" ]]; then
    echo "  (dry-run) wuerde Provider-API aufrufen und VM erstellen"
    sleep 1
else
    # Hier wuerde z.B. govc, virsh, proxmox-cli stehen — aber typischerweise
    # macht das eh der Tofu-Provider, nicht ein local-exec-Skript.
    echo "  ERROR: Real-Mode in 01-create-vm.sh nicht implementiert."
    echo "  In Production: ersetze die null_resource in main.tf durch"
    echo "  einen echten VM-Provider-Resource."
    exit 1
fi

echo "[$(date -Iseconds)] STAGE 1 ✓ VM bereit, ConfigMgr uebernimmt jetzt"
