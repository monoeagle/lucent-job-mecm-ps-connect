# Gemeinsame Helfer fuer alle Demo-Skripte. Wird per `source` geladen.
#
# Erwartete Env-Variablen:
#   CONFIGMGR_SQL_HOST  - FQDN des ConfigMgr-SQL-Servers
#   CONFIGMGR_DB_NAME   - z.B. CM_P01
# Optional fuer SQL-Auth statt Kerberos:
#   SQL_USER, SQL_PASS

set -euo pipefail

: "${CONFIGMGR_SQL_HOST:?Bitte CONFIGMGR_SQL_HOST setzen, z.B. sql.corp.local}"
: "${CONFIGMGR_DB_NAME:?Bitte CONFIGMGR_DB_NAME setzen, z.B. CM_P01}"

if [[ -n "${SQL_USER:-}" ]]; then
    SQL_AUTH=(-U "$SQL_USER" -P "${SQL_PASS:-}")
else
    SQL_AUTH=(-E)   # Windows-Auth via Kerberos
fi

# Fuehrt eine Query aus und gibt sie als Pipe-getrennte Ergebniszeilen aus.
# Nutzbar fuer 'while IFS="|" read ...' in Aufrufer-Skripten.
sql_query() {
    local query="$1"
    sqlcmd -S "$CONFIGMGR_SQL_HOST" -d "$CONFIGMGR_DB_NAME" "${SQL_AUTH[@]}" \
           -h -1 -W -s '|' -Q "SET NOCOUNT ON; $query"
}

# Wrapper, der mit Header zurueckgibt — fuer column -t-Tabellenausgabe.
sql_query_with_header() {
    local header="$1"
    local query="$2"
    {
        echo "$header"
        sql_query "$query"
    } | column -t -s '|'
}

# Aufloesung Computer-Name -> ResourceID
resolve_resource_id() {
    local name="$1"
    local id
    id=$(sql_query "SELECT TOP 1 ResourceID FROM v_R_System WHERE Name0 = N'${name}'" | tr -d ' ')
    if [[ -z "$id" ]] || [[ "$id" == "NULL" ]]; then
        echo "Device '$name' nicht gefunden." >&2
        return 1
    fi
    echo "$id"
}
