#!/usr/bin/env bash
# 090-discover-classes.sh
#
# Listet alle EntitySets (= queryable Klassen) aus dem OData-$metadata-
# Dokument. Damit findest du heraus, welche SMS_*- und SMS_G_System_*-
# Klassen in EURER Site verfuegbar sind, inkl. custom-erweiterter
# Hardware-Inventory-Klassen.
#
# Usage:
#   ./090-discover-classes.sh
#   ./090-discover-classes.sh SMS_G_System_           # Pattern (grep)
#   ./090-discover-classes.sh SMS_G_System_ properties  # mit Property-Liste
#
# Voraussetzung: xmllint (libxml2-utils) fuer sauberes XPath-Parsing.

source "$(dirname "$0")/_common.sh"

PATTERN="${1:-}"
SHOW_PROPS="${2:-}"

# $metadata zurueckholen — Server liefert XML
META=$(curl "${CURL_ARGS[@]/-H Accept: application\/json/}" \
    -H 'Accept: application/xml' \
    "${CONFIGMGR_ADMINSERVICE_BASE}/wmi/\$metadata")

if ! command -v xmllint >/dev/null; then
    echo "Hinweis: xmllint nicht gefunden — Fallback auf grep." >&2
    echo "$META" | grep -oP '<EntitySet Name="[^"]+"[^>]*EntityType="[^"]+"' |
        sed -E 's/<EntitySet Name="([^"]+)"[^>]*EntityType="([^"]+)".*/\1\t\2/' |
        awk -F'\t' -v pat="$PATTERN" 'pat=="" || $1 ~ pat { print $1, "->", $2 }' |
        column -t
    exit 0
fi

# EntitySets via XPath
ENTITY_SETS=$(echo "$META" | xmllint --xpath \
    "//*[local-name()='EntityContainer']/*[local-name()='EntitySet']" - 2>/dev/null)

# Liste extrahieren
echo "$ENTITY_SETS" | grep -oE 'Name="[^"]+"[^/]*EntityType="[^"]+"' |
    sed -E 's/Name="([^"]+)"[^/]*EntityType="([^"]+)"/\1\t\2/' |
    awk -F'\t' -v pat="$PATTERN" 'pat=="" || $1 ~ pat' |
    sort | column -t -s $'\t'

# Optional: Properties pro EntityType
if [[ "$SHOW_PROPS" == "properties" ]]; then
    echo
    echo "--- Properties pro EntityType ---"
    echo "$META" | xmllint --xpath "//*[local-name()='EntityType']" - 2>/dev/null |
        grep -oE '<EntityType Name="[^"]+"[^>]*>([^<]|<[^/]|<[^E])*' |
        head -200
fi
