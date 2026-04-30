# MECM / ConfigMgr — Versionierung & Stand 2026

## Versionierungs-Schema

ConfigMgr Current Branch nutzt **YYMM**: zwei Stellen Jahr + zwei Stellen Monat
des GA-Release. Beispiel: **2503** = März 2025.

Daneben existiert die **Long-Term Servicing Channel (LTSC)**, eingefroren auf
einen bestimmten CB-Stand mit verlängertem Support, aber ohne neue Features.

## Release-Cadence

Seit ~2023 zwei Releases pro Jahr, typisch **März/April** und
**September/Oktober**. Davor drei pro Jahr.

## Bekannter Verlauf (relevant für AdminService-Era ab 1810)

| Version | Release | Anmerkung |
|---|---|---|
| 1810 | Q4 2018 | **AdminService eingeführt** |
| 1902 / 1906 / 1910 | 2019 | |
| 2002 / 2006 / 2010 | 2020 | |
| 2103 / 2107 / 2111 | 2021 | 2107 auch als LTSC |
| 2203 / 2207 / 2211 | 2022 | |
| 2303 / 2309 | 2023 | Cadence-Wechsel auf 2× p.a. |
| 2403 / 2409 | 2024 | |
| 2503 | ~April 2025 | |
| 2509 | ~Oktober 2025 | letzte vor unserem Wissensstand belegte GA |
| 2603 | erwartet ~April 2026 | evtl. gerade GA / Tech-Preview |

> **Hinweis:** Stand dieser Doku ist Wissensstand Januar 2026. Versionen nach
> 2509 sind extrapoliert aus der bekannten Cadence — aktuelle Lage bitte vor
> Verlass auf konkrete Features verifizieren (Microsoft-Docs / Console).

## Stand April 2026 — was läuft typisch in Produktion?

Erfahrungswert: Firmen sind 1-2 Releases hinter "latest current".

- Konservative Umgebungen: **2403** oder **2409**
- Standard: **2503**
- Aktiv aktualisierende: **2509**, evtl. **2603** falls released
- LTSC-Umgebungen: **2107 LTSC** (Support bis 2027) — selten, aber noch
  anzutreffen

## Interne Build-Nummer

Console-Properties zeigen eine vierteilige Nummer wie `5.00.9128.1000`. Die
**dritte Stelle** mappt grob auf das YYMM-Release:

| Build | Release |
|---|---|
| 9106 | 2107 |
| 9128 | 2303 |
| 9132 | 2309 |
| 9136 | 2403 |
| 9144 | 2409 |
| ~9152+ | 2503+ |

(Mapping-Tabelle ist nicht offiziell standardisiert; im Zweifel
Microsoft-Doku des jeweiligen Release konsultieren.)

## Version detecten

### Auf dem Site-Server (PowerShell)

```powershell
Get-CimInstance -Namespace root\SMS\site_<SiteCode> -ClassName SMS_Site |
    Select-Object SiteCode, Version, BuildNumber
```

### Per AdminService (von beliebigem Client)

```bash
curl --negotiate -u : \
  "https://sccm.corp.local/AdminService/wmi/SMS_Site?\$select=SiteCode,Version,BuildNumber"
```

### Per ConfigMgr-Console

**Administration → Site Configuration → Sites → \[Site auswählen\] →
Properties → Tab "About"**

## Relevanz für unser Tofu-Projekt

Für die vier in [`OVERVIEW.md`](../OVERVIEW.md) skizzierten Wege:

| Weg | Min-Version |
|---|---|
| 01 AdminService + pwsh | **1810** |
| 02 AdminService + bash | **1810** |
| 03 WinRM-Jumphost (CM-Modul) | jede |
| 04 SQL direkt (Views) | jede (View-Schema kann pro CB leicht variieren) |

**Konsequenz:** In jeder realistischen 2026er-Umgebung sind alle vier Wege
verfügbar. Die Wahl hängt nicht an der MECM-Version, sondern an **AdminService-
Aktivierung**, **Netzwerk-/Auth-Setup** und **Betriebs-Constraints**.
