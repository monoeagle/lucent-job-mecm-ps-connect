#!/usr/bin/env bash
# 100-modeled-api.sh
#
# Tour durch den /AdminService/v1.0/-Namespace (modeled REST-API).
# Der v1.0-Namespace ist die kuratierte, sauberere Variante des wmi/-Mappings.
#
# Usage:
#   ./100-modeled-api.sh                # Service-Root + Sample
#   ./100-modeled-api.sh PC123          # zusaetzlich Device-Vollbild

source "$(dirname "$0")/_common.sh"

NAME="${1:-}"

echo "=== Service Root /v1.0/ ==="
as_get "v1.0/" | jq -r '.value | sort_by(.name)[] |
    [.name, .kind, .url] | @tsv' | column -t -s $'\t'

echo
echo "=== Erste 5 Devices via /v1.0/Device ==="
as_get "v1.0/Device" '$top=5' | jq -r '
    .value[] | [(.MachineId|tostring), .Name, (.ClientVersion // ""),
                (.Domain // ""), (.ADSiteName // "")] | @tsv' |
    column -t -s $'\t'

if [[ -n "$NAME" ]]; then
    echo
    echo "=== Vollbild fuer $NAME ==="
    RID=$(resolve_resource_id "$NAME")
    as_get "v1.0/Device(${RID})" | jq '.'
fi

echo
echo "=== Erste 3 Collections via /v1.0/Collection ==="
as_get "v1.0/Collection" '$top=3' | jq -r '
    .value[] | [.CollectionId, .Name, (.MemberCount|tostring),
                (.CollectionType|tostring)] | @tsv' |
    column -t -s $'\t'
