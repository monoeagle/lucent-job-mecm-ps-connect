#!/usr/bin/env bash
set -euo pipefail

COMPUTER_NAME="${1:?computer name required}"
SQL_HOST="${2:?sql host required}"
DB_NAME="${3:?database name (e.g. CM_P01) required}"
TIMEOUT="${TIMEOUT_SECONDS:-3600}"
INTERVAL="${POLL_INTERVAL_SECONDS:-30}"

# Auth: Kerberos (-E) oder User/Pass via env SQL_USER/SQL_PASS
if [ -n "${SQL_USER:-}" ]; then
    AUTH_ARGS=(-U "$SQL_USER" -P "$SQL_PASS")
else
    AUTH_ARGS=(-E)
fi

read -r -d '' QUERY <<SQL || true
SET NOCOUNT ON;
DECLARE @name nvarchar(64) = N'${COMPUTER_NAME}';
SELECT TOP 1
    r.ResourceID,
    r.Client0                          AS ClientReady,
    ISNULL(t.LastStatusType, 0)        AS TsStatus
FROM v_R_System r
OUTER APPLY (
    SELECT TOP 1 LastStatusType
    FROM v_TaskExecutionStatus
    WHERE ResourceID = r.ResourceID
    ORDER BY ExecutionTime DESC
) t
WHERE r.Name0 = @name;
SQL

deadline=$(( $(date +%s) + TIMEOUT ))

while [ "$(date +%s)" -lt "$deadline" ]; do
    result=$(sqlcmd -S "$SQL_HOST" -d "$DB_NAME" "${AUTH_ARGS[@]}" -h -1 -W -s '|' -Q "$QUERY" 2>/dev/null | grep -E '^[0-9]+\|' || true)

    if [ -n "$result" ]; then
        IFS='|' read -r resource_id client_ready ts_status <<< "$result"
        echo "[$(date -Iseconds)] ${COMPUTER_NAME} resource=${resource_id} client=${client_ready} ts_status=${ts_status}"

        if [ "$client_ready" = "1" ] && [ "$ts_status" = "5" ]; then
            echo "DEPLOYED"
            exit 0
        fi
    else
        echo "[$(date -Iseconds)] ${COMPUTER_NAME} nicht in DB gefunden"
    fi

    sleep "$INTERVAL"
done

echo "Timeout nach ${TIMEOUT}s — ${COMPUTER_NAME} nicht deployed." >&2
exit 1
