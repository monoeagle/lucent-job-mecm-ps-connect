# Gemeinsame Auth- und Request-Helfer fuer alle Demo-Skripte.
# Wird per `source "$(dirname "$0")/_common.sh"` geladen.
#
# Erwartete Env-Variablen:
#   CONFIGMGR_ADMINSERVICE_BASE  - z.B. https://sccm.corp.local/AdminService
#   CONFIGMGR_SKIP_CERT_CHECK    - 'true', um TLS-Validierung zu ueberspringen
#                                  (nur fuer Demos / Test-Umgebungen!)

set -euo pipefail

: "${CONFIGMGR_ADMINSERVICE_BASE:?Bitte CONFIGMGR_ADMINSERVICE_BASE setzen}"

CURL_ARGS=(--silent --show-error --fail --negotiate -u : -H 'Accept: application/json')
if [[ "${CONFIGMGR_SKIP_CERT_CHECK:-}" == "true" ]]; then
    CURL_ARGS+=(--insecure)
fi

# GET ohne Pagination
as_get() {
    local path="$1"
    local query="${2:-}"
    local url="${CONFIGMGR_ADMINSERVICE_BASE}/${path}"
    [[ -n "$query" ]] && url+="?${query}"
    curl "${CURL_ARGS[@]}" "$url"
}

# Streamt alle Items aus paginierten Endpoints als JSON-Objekte (jq-kompatibel)
as_get_paged() {
    local path="$1"
    local query="${2:-}"
    local url="${CONFIGMGR_ADMINSERVICE_BASE}/${path}"
    [[ -n "$query" ]] && url+="?${query}"
    while [[ -n "$url" ]]; do
        local resp
        resp=$(curl "${CURL_ARGS[@]}" "$url")
        echo "$resp" | jq -c '.value[]'
        url=$(echo "$resp" | jq -r '."@odata.nextLink" // empty')
    done
}

# Computername -> ResourceID
resolve_resource_id() {
    local name="$1"
    local query
    query="\$filter=Name%20eq%20'${name}'&\$select=ResourceID"
    local id
    id=$(as_get "wmi/SMS_R_System" "$query" | jq -r '.value[0].ResourceID // empty')
    if [[ -z "$id" ]]; then
        echo "Device '$name' nicht gefunden." >&2
        return 1
    fi
    echo "$id"
}
