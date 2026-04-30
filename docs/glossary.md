# Glossary

Quick-Lookup fuer Tofu-Engineers und Operations-Teams ohne tiefen
ConfigMgr-Background. Begriffe innerhalb einer Sektion alphabetisch.

## ConfigMgr / SMS

**Boundary** — Definition eines Netzwerk-Bereichs (IP-Subnet, AD-Site,
IP-Range, IPv6-Praefix) zur Zuordnung von Clients zu Site-Systemen.

**Boundary Group** — Logische Gruppierung von Boundaries. Ordnet einer
Boundary einen Distribution Point, Management Point oder Software Update
Point zu. Steuert: "Welcher Server bedient welchen Client?"

**Client** — Der ConfigMgr-Agent (Windows-Service `CcmExec`) auf einem
Endgeraet. Kommuniziert mit Management Points, fuehrt Deployments aus,
sammelt Inventory.

**Co-Management** — Hybrid-Setup: ein Geraet wird gleichzeitig von
ConfigMgr und Microsoft Intune verwaltet. Workloads (Updates, Apps,
Compliance, …) lassen sich pro Workload auf eine der beiden Seiten legen.

**Collection** — Logische Gruppe von Resources (Devices oder User).
Kann Direct-Membership-Rules (statisch) oder Query-Rules (dynamisch via
WQL) enthalten. Deployments zielen auf Collections, nicht auf einzelne
Devices.

**ConfigMgr / ConfigurationManager / SCCM / MCM / MECM** — Alles dasselbe
Produkt zu verschiedenen Marketing-Aeren. Heute offiziell: **Microsoft
Configuration Manager**. Siehe [`configmgr-versions.md`](configmgr-versions.md).

**Console** — Win32-GUI fuer ConfigMgr-Admins. Kann lokal auf dem Site-
Server laufen oder remote installiert werden. Bringt das
ConfigurationManager-PowerShell-Modul mit.

**Current Branch (CB)** — Standard-Release-Channel mit ~2 Releases pro
Jahr (YYMM-Schema, z.B. 2503). Gegenstueck: LTSC.

**Direct Membership Rule** — Explizit: "Diese Resource ist Mitglied
dieser Collection." Statisch, manuell oder per API gepflegt.

**Discovery** — Mechanismus, mit dem ConfigMgr Resources im Netz/AD
findet (AD System Discovery, Network Discovery, AD User Discovery, …).
Discovery-Daten landen als `SMS_R_*`-Klassen.

**Distribution Point (DP)** — Site-System, das Content (Apps, Pakete,
Updates) zu Clients verteilt. In grossen Umgebungen oft pro Standort
einer.

**Endpoint Manager** — Frueheres Marketing-Klammer-Wort fuer
"ConfigMgr + Intune". Wird seit ~2022 nicht mehr offiziell gefuehrt.

**FeatureType** — Kategorie eines Deployments. Werte: 1 Application,
2 Program, 5 Software Update, 6 Configuration Baseline, 7 Task Sequence,
8 Device Setting.

**Hardware Inventory** — Vom Client gesammelte Daten ueber Hardware/OS,
abrufbar via `SMS_G_System_*`-Klassen oder `v_GS_*`-Views.

**Imaging / Task Sequence (TS)** — Skript-aehnliche Abfolge zur
OS-Installation und Konfiguration. Standard-Mechanismus fuer "PC neu
ausrollen".

**Long-Term Servicing Channel (LTSC)** — Eingefrorene Version mit
verlaengertem Support, ohne neue Features. Fuer Umgebungen, die nicht
mit dem CB-Update-Tempo mithalten koennen/wollen.

**Management Point (MP)** — Site-System, das den primaeren Kommunikations-
Endpoint fuer Clients darstellt. Gibt Policy aus, nimmt State-Messages
entgegen.

**MECM** — Frueherer Name (Ende 2019 – ~2022). Heute: ConfigMgr.

**Primary Site** — Vollwertige ConfigMgr-Site mit eigener DB, Site-Server
und Site-Systemen. Kann Clients direkt managen.

**Resource** — Alles, was in ConfigMgr verwaltet wird (Device, User,
User Group, IP-Subnet). Hat eine eindeutige `ResourceID`.

**ResourceID** — Numerische ID einer Resource in ConfigMgr (z.B.
`16777345`). Stabil pro Site, NICHT zwischen Sites portabel.

**RBAC (Role-Based Access Control)** — ConfigMgr-eigenes Permission-
System: Rolle (was darf der User tun?) + Scope (auf welche Objekte?) +
Collection-Limit (welche Devices/User?).

**SCCM** — System Center Configuration Manager. Der Name zwischen 2007
und 2019. Funktional dasselbe Produkt wie heutiges ConfigMgr.

**Secondary Site** — Eingeschraenkte Site fuer entfernte Standorte mit
schmaler Bandbreite. Kein eigenes RBAC-Modell, replication-only.

**Site** — Eine ConfigMgr-Installation. Hat einen 3-Zeichen-Site-Code
(z.B. P01).

**Site Code** — 3 Zeichen, eindeutig pro Site. PSDrive-Name in der
Console. Datenbankname-Praefix (`CM_<SiteCode>`).

**Site Server** — Windows-Server, auf dem die Site-Komponenten laufen
(SMS Provider, SMS Executive, Component Manager, etc.).

**SMS Provider** — WMI-basierter API-Layer auf dem Site-Server. Der
AdminService haengt davor, die Console und PowerShell-Cmdlets
kommunizieren intern damit.

**SMS_R_System** — WMI-Klasse / Endpoint, der Device-Stammdaten
zurueckgibt. `SMS_R_User` analog fuer User.

**SMS_G_System_\*** — WMI-Klassen-Familie der Hardware-Inventory-Daten.
Pro Klasse ein Aspekt (`COMPUTER_SYSTEM`, `OPERATING_SYSTEM`, ...).

**State Message** — Statusbericht eines Clients an den Management Point
("App XY erfolgreich installiert", "Boot-Sektor nicht gefunden", ...).

**Task Sequence Deployment Status** — Aggregierter Status pro Device pro
TS-Deployment. Werte: 1 Compliant, 2 NonCompliant, 3 Failed, 4 Unknown,
5 Success.

**v_*-Views** — SQL-Views in der `CM_<SiteCode>`-DB als offiziell
dokumentierter Read-Layer. Beispiele: `v_R_System`, `v_GS_*`,
`v_FullCollectionMembership`.

---

## Auth / Kerberos / AD

**AD-Site** — Active-Directory-eigenes Konzept fuer Standort-Topologie.
Wird von ConfigMgr fuer Boundary-Groups konsumiert.

**ASCII-Realm** — Grossgeschriebene Form des AD-Domain-Namens fuer
Kerberos-Konfiguration (`DOMAIN.LOCAL`).

**Bearer-Token** — Auth-Token-Form bei Azure-AD-Authentifizierung.
Alternative zu Kerberos in CMG-Setups.

**Cloud Management Gateway (CMG)** — Azure-Service, der AdminService /
Management Points internet-erreichbar macht. Auth via Azure-AD-Token.

**gMSA (Group Managed Service Account)** — AD-Account mit
auto-rotierendem Passwort. Fuer Service-Accounts vorzuziehen, aber auf
Linux komplex zu nutzen.

**Keytab** — Datei mit Kerberos-Credentials (Principal + verschluesseltem
Schluessel). Erlaubt nicht-interaktiven Login per `kinit -kt`.

**KDC (Key Distribution Center)** — Der Kerberos-Server. Bei AD: jeder
Domain-Controller.

**Kerberos** — Auth-Protokoll auf Basis von Tickets. Default-Auth fuer
Windows-Domain-Logins. Linux-Clients reden via MIT-Kerberos.

**ktpass** — Windows-Tool zur Keytab-Erzeugung. Side-Effect: kann das
AD-Passwort rotieren.

**ktutil** — Linux-Tool zur Keytab-Erzeugung (kein AD-Side-Effect, aber
braucht das Passwort lokal im Klartext zur Eingabe).

**Negotiate / SPNEGO** — HTTP-Auth-Mechanismus, der Kerberos und NTLM
abdeckt. Header: `WWW-Authenticate: Negotiate`.

**Pre-Authentication** — Kerberos-Sicherheitsfeature. "Required" sollte
fuer Service-Accounts an sein (Default), sonst Kerberoasting-Risiko.

**Principal** — Eindeutiger Kerberos-Identifier, Form `name@REALM`. User-
Principal: `svc-tofu@DOMAIN.LOCAL`. Service-Principal:
`HTTP/sccm.corp.local@DOMAIN.LOCAL`.

**RBAC** — Im Auth-Kontext: AD-/MECM-Berechtigungssystem. ConfigMgr hat
sein eigenes, getrennt von AD-Group-Memberships.

**Realm** — Kerberos-Begriff fuer "AD-Domain" (gross geschrieben).

**Security Scope** — ConfigMgr-Konzept: schraenkt ein, welche Objekt-
Klassen ein Admin-User sieht.

**Service Account** — AD-Konto fuer nicht-interaktive Nutzung
(Skripte/Tools), nicht fuer Personen. Konvention: `svc-`-Praefix.

**SPN (Service Principal Name)** — Name, unter dem ein Service erreichbar
ist. AD-Konten haben SPN-Listen, an denen Kerberos die Service-Tickets
ausgibt.

**TGT / TGS** — Ticket Granting Ticket / Ticket Granting Service. TGT =
"Du bist authentifiziert". TGS = "Hier ist ein Token fuer Service X".

---

## OData / AdminService

**AdminService** — REST-API von ConfigMgr, gehostet im IIS auf dem
SMS Provider. Siehe [`adminservice.md`](adminservice.md).

**`@odata.context`** — Field in OData-Responses, das auf das Schema
verweist.

**`@odata.nextLink`** — Field, das beim Paginated-Response auf die
naechste Seite zeigt. Folgt man bis es leer ist.

**`$filter`** — OData-Operator: Filter im Query-String. Operatoren:
`eq`, `ne`, `gt`, `lt`, `ge`, `le`, `and`, `or`, `not`. Funktionen:
`startswith`, `endswith`, `contains`, `year(date)`, `month(date)`.

**`$metadata`** — XML-Endpoint mit Schema-Beschreibung (CSDL/EDMX).
Listet alle Entity Sets und EntityTypes mit Properties.

**`$orderby`** — Sortierung: `$orderby=Name` oder `$orderby=StartTime desc`.

**`$select`** — Feld-Auswahl. Reduziert Response-Groesse drastisch
gegenueber Default (alle Felder).

**`$top`** — Paginations-Limit pro Page.

**EDMX / CSDL** — XML-Schema-Format hinter `$metadata`. Common Schema
Definition Language.

**Entity Set** — Eine Collection von gleichartigen Entities (z.B.
`/AdminService/wmi/SMS_R_System`).

**Entity Type** — Definiert die Struktur einer Entity (welche Properties,
welche Typen).

**Modeled API** — Bezeichnung fuer den `/v1.0/`-Namespace im AdminService:
kuratiert, sauberer als das rohe `/wmi/`-Mapping.

**OData v4** — Spec-Version, der der AdminService folgt
(odata.org).

**Service Document** — Wurzel-Response unter `/v1.0/` mit Liste aller
EntitySets.

**WMI-Mapping** — Der `/wmi/`-Namespace bildet WMI-Klassen 1:1 als
OData-EntitySets ab.

---

## Tofu / IaC (knapp, da meist bekannt)

**`depends_on`** — Explizite Abhaengigkeits-Deklaration zwischen
Resources/Modulen. Wir nutzen es, um Folge-Tasks am ConfigMgr-Wait
aufzuhaengen.

**`local-exec` Provisioner** — Fuehrt einen Befehl auf der Tofu-Maschine
selbst aus (nicht auf der Ziel-Resource). Wir nutzen ihn fuer das
Wait-Polling.

**Module** — Ordner mit `.tf`-Dateien, der via `module "name"
{ source = "..." }` eingebunden wird. Unsere Variant-Ordner sind alle
Module.

**`null_resource`** — Resource ohne State, dient als Aufhaenger fuer
Provisioner. Klassisches Workaround fuer "ich muss was ausfuehren,
das kein eigener Provider ist".

**`triggers`** — Map am `null_resource`, die kontrolliert, wann es neu
laeuft. Aenderung der Werte → Tofu wertet als "muss erneuert werden".

---

## Querverweise

- Auth-How-To → [`auth-setup.md`](auth-setup.md)
- AdminService-Architektur → [`adminservice.md`](adminservice.md)
- Wege-Vergleich → [`../OVERVIEW.md`](../OVERVIEW.md)
- Versionen → [`configmgr-versions.md`](configmgr-versions.md)
- Compat 2026 → [`compatibility-2026.md`](compatibility-2026.md)
- Troubleshooting → [`troubleshooting.md`](troubleshooting.md)
