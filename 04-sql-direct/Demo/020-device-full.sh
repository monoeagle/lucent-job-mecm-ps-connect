#!/usr/bin/env bash
# 020-device-full.sh
#
# Kombiniert Stammdaten + Hardware-Inventory eines Device ueber
# mehrere v_GS_*-Views.
#
# Usage:
#   ./020-device-full.sh PC123

source "$(dirname "$0")/_common.sh"

NAME="${1:?ComputerName required}"
RID=$(resolve_resource_id "$NAME")
echo "ResourceID = $RID"
echo

dump_view() {
    local label="$1" view="$2" cols="${3:-*}"
    echo "=== $label ($view) ==="
    sql_query "SELECT ${cols} FROM ${view} WHERE ResourceID = ${RID}"
    echo
}

dump_view 'Stammdaten'        'v_R_System' \
    'Name0, ResourceID, Client0, Full_Domain_Name0, User_Name0, AD_Site_Name0, Operating_System_Name_and0'
dump_view 'Computer System'   'v_GS_COMPUTER_SYSTEM'   'Manufacturer0, Model0, SystemType0, NumberOfProcessors0, TotalPhysicalMemory0'
dump_view 'Operating System'  'v_GS_OPERATING_SYSTEM'  'Caption0, Version0, BuildNumber0, InstallDate0, LastBootUpTime0'
dump_view 'BIOS'              'v_GS_PC_BIOS'           'Manufacturer0, SMBIOSBIOSVersion0, ReleaseDate0, SerialNumber0'
dump_view 'Processor'         'v_GS_PROCESSOR'         'Name0, NumberOfCores0, NumberOfLogicalProcessors0, MaxClockSpeed0'
dump_view 'Logical Disks'     'v_GS_LOGICAL_DISK'      'DeviceID0, FileSystem0, Size0, FreeSpace0'
