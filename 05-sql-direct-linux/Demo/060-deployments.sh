#!/usr/bin/env bash
# 060-deployments.sh
#
# Listet Deployments — laufend und/oder zukuenftig geplant.
# View: v_DeploymentSummary (aggregiert) bzw. v_Advertisement / v_CIAssignment.
# Fuer maximale Sichtbarkeit nutzen wir v_DeploymentSummary.
#
# FeatureType (in v_DeploymentSummary spaltenname FeatureType):
#   1 Application, 2 Program, 5 SoftwareUpdate, 6 Baseline,
#   7 TaskSequence, 8 DeviceSetting
#
# Usage:
#   ./060-deployments.sh                 # alle
#   ./060-deployments.sh active          # nur bereits gestartete
#   ./060-deployments.sh future          # nur zukuenftig geplante

source "$(dirname "$0")/_common.sh"

MODE="${1:-all}"
TOP="${2:-100}"

case "$MODE" in
    active) WHERE="WHERE StartTime <= GETUTCDATE()" ;;
    future) WHERE="WHERE StartTime > GETUTCDATE()" ;;
    all)    WHERE="" ;;
    *) echo "Mode muss active|future|all sein" >&2; exit 1 ;;
esac

QUERY="SELECT TOP ${TOP}
    CASE FeatureType
        WHEN 1 THEN 'App'
        WHEN 2 THEN 'Program'
        WHEN 5 THEN 'Update'
        WHEN 6 THEN 'Baseline'
        WHEN 7 THEN 'TaskSeq'
        WHEN 8 THEN 'Setting'
        ELSE CAST(FeatureType AS NVARCHAR(10))
    END AS Type,
    DeploymentName,
    CollectionName,
    StartTime,
    DeploymentIntent
FROM v_DeploymentSummary
${WHERE}
ORDER BY StartTime DESC;"

sql_query_with_header 'Type|DeploymentName|Collection|StartTime|Intent' "$QUERY"
