#!/usr/bin/env bash
# 030-device-software.sh
#
# Listet die installierte Software fuer ein Device aus dem Software-Inventory
# (SMS_G_System_INSTALLED_SOFTWARE). Optional Filter nach Publisher.
#
# Usage:
#   ./030-device-software.sh PC123
#   ./030-device-software.sh PC123 Microsoft

source "$(dirname "$0")/_common.sh"

NAME="${1:?ComputerName required}"
PUBLISHER="${2:-}"
RESOURCE_ID=$(resolve_resource_id "$NAME")

FILTER="ResourceID%20eq%20${RESOURCE_ID}"
if [[ -n "$PUBLISHER" ]]; then
    FILTER+="%20and%20contains(Publisher,'${PUBLISHER}')"
fi
QUERY="\$filter=${FILTER}&\$select=ProductName,ProductVersion,Publisher,InstallDate&\$orderby=ProductName"

{
    printf 'ProductName\tVersion\tPublisher\tInstallDate\n'
    as_get_paged "wmi/SMS_G_System_INSTALLED_SOFTWARE" "$QUERY" | jq -r '
        [(.ProductName // ""), (.ProductVersion // ""),
         (.Publisher // ""), (.InstallDate // "")] | @tsv'
} | column -t -s $'\t'
