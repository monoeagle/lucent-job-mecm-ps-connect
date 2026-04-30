#!/usr/bin/env bash
# 100-complex-aggregation.sh
#
# Beispiel fuer eine komplexere Aggregation, die der AdminService nicht
# trivial ausspuckt: "Wieviele Devices pro Collection sind tatsaechlich
# active Clients und haben Windows 11?"
# Demonstriert Multi-View-JOIN mit GROUP BY.
#
# Usage:
#   ./100-complex-aggregation.sh
#   ./100-complex-aggregation.sh "Windows 11"    # OS-Pattern

source "$(dirname "$0")/_common.sh"

OS_PATTERN="${1:-Windows 11}"

QUERY="SELECT
    c.Name AS CollectionName,
    COUNT(DISTINCT s.ResourceID) AS Devices,
    SUM(CASE WHEN ch.ClientActiveStatus = 1 THEN 1 ELSE 0 END) AS ActiveClients,
    SUM(CASE WHEN os.Caption0 LIKE N'%${OS_PATTERN}%' THEN 1 ELSE 0 END) AS MatchOS
FROM v_FullCollectionMembership m
JOIN v_Collection           c   ON c.CollectionID = m.CollectionID
JOIN v_R_System             s   ON s.ResourceID    = m.ResourceID
LEFT JOIN v_CH_ClientSummary ch ON ch.ResourceID   = s.ResourceID
LEFT JOIN v_GS_OPERATING_SYSTEM os ON os.ResourceID = s.ResourceID
WHERE c.CollectionType = 2   -- 2 = Device-Collection
GROUP BY c.Name
HAVING COUNT(DISTINCT s.ResourceID) > 0
ORDER BY Devices DESC;"

sql_query_with_header "CollectionName|Devices|ActiveClients|with_${OS_PATTERN// /_}" "$QUERY"
