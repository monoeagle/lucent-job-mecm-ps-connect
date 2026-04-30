#!/usr/bin/env bash
# 020-device-full.sh
#
# Holt fuer ein Device die Stammdaten und ausgewaehlte Hardware-Inventory-
# Klassen aus dem AdminService. Demonstriert, dass ein Device aus mehreren
# WMI-Klassen besteht (SMS_R_System + SMS_G_System_*).
#
# Usage:
#   ./020-device-full.sh PC123

source "$(dirname "$0")/_common.sh"

NAME="${1:?ComputerName required}"
RESOURCE_ID=$(resolve_resource_id "$NAME")
echo "ResourceID = $RESOURCE_ID"

dump_class() {
    local label="$1" path="$2" filter_field="$3"
    echo
    echo "=== $label ==="
    local query="\$filter=${filter_field}%20eq%20${RESOURCE_ID}"
    if as_get "$path" "$query" | jq -e '.value[0]' >/dev/null 2>&1; then
        as_get "$path" "$query" | jq '.value'
    else
        echo "(keine Daten oder Klasse nicht abrufbar)"
    fi
}

dump_class 'Stammdaten (SMS_R_System)'  'wmi/SMS_R_System'                'ResourceId'
dump_class 'Computer System'            'wmi/SMS_G_System_COMPUTER_SYSTEM' 'ResourceID'
dump_class 'Operating System'           'wmi/SMS_G_System_OPERATING_SYSTEM' 'ResourceID'
dump_class 'BIOS'                       'wmi/SMS_G_System_PC_BIOS'         'ResourceID'
dump_class 'Processor'                  'wmi/SMS_G_System_PROCESSOR'       'ResourceID'
dump_class 'Logical Disks'              'wmi/SMS_G_System_LOGICAL_DISK'    'ResourceID'
