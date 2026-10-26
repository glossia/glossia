%{
  title: "Autorisierung",
  summary:
    "Berechtigungs-Bereiche, Organisationsrollen und Zugriffskontrollen auf Ressourcenebene.",
  category: "Referenz",
  subcategory: "APIs",
  order: 2
}
---

Authentifizierung definiert eine Identität; Autorisierung entscheidet, welche Aktionen diese Identität ausführen kann. Siehe [Authentifizierung](/docs/reference/apis/authentication) für Anmelde- und Token-Flows.

## Bereiche

Bereiche steuern, welche Aktionen ein Token ausführen kann. Sie folgen dem `object:action`-Muster.

| Bereich | Beschreibung |
|-------|-------------|
| `admin:read` | Lesen von Plattform-Verwaltungsdaten (nur für Plattform-Administratoren) |
| `admin:write` | Ändern von Plattform-Verwaltungsdaten (nur für Plattform-Administratoren) |
| `ops:read` | Lesen von Plattform-Betriebsdaten (nur für Plattform-Administratoren) |
| `user:read` | Lesen von Benutzerprofilinformationen |
| `user:write` | Aktualisieren des Benutzerprofils |
| `account:read` | Liste der Organisation-Konten, auf die Sie Zugriff haben |
| `organization:read` | Lesen der Organisationsdetails (und Liste Ihrer Organisationen) |
| `organization:write` | Erstellen oder Aktualisieren von Organisationen |
| `organization:claim` | Aneignen einer Organisation |
| `organization:delete` | Löschen von Organisationen |
| `organization:admin` | Administrative Organisationsaktionen |
| `members:read` | Lesen von Organisationsmitgliedern und Einladungen |
| `members:write` | Verwalten von Organisationsmitgliedern und Einladungen |
| `project:read` | Lesen von Projekten |
| `project:write` | Erstellen oder Aktualisieren von Projekten |
| `project:admin` | Administrative Projektaktionen |
| `project:delete` | Löschen von Projekten |
| `voice:read` | Lesen der Stimmenkonfiguration |
| `voice:write` | Erstellen oder Aktualisieren der Stimmenkonfiguration |
| `voice:admin` | Administrative Stimmenaktionen |
| `glossary:read` | Lesen von Glossar-Einträgen |
| `glossary:write` | Erstellen oder Aktualisieren von Glossar-Einträgen |
| `glossary:admin` | Verwalten der Glossar-Einstellungen |
| `discussion:read` | Lesen von Diskussionen |
| `discussion:write` | Erstellen oder Aktualisieren von Diskussionen |
| `discussion:admin` | Administrative Diskussionsaktionen |
| `ticket:read` | Lesen von Tickets |
| `ticket:write` | Erstellen oder Aktualisieren von Tickets |
| `ticket:admin` | Administrative Ticketaktionen |
| `llm_model:read` | Lesen der Sprachmodelle des Kontos |
| `llm_model:write` | Verwalten der Sprachmodelle des Kontos |
| `translation:read` | Lesen der Projektübersetzungsaktivität |
| `translation:write` | Schreiben von Übersetzungsdaten |
| `analytics:read` | Lesen der Projektwebsite-Analytik |
| `toki:read` | Lesen Ihrer eigenen privaten Projektgespräche |
| `toki:write` | Erstellen privater Gespräche und Begleitantworten in die Warteschlange stellen |
| `api_credentials:read` | Lesen von Zugangsdaten |
| `api_credentials:write` | Verwalten von Zugangsdaten |

Der Authentifizierungsserver veröffentlicht die für Clients verfügbaren [Discovery-Metadaten](/docs/reference/apis/authentication#discovery-endpoints). Das Vorhandensein eines Bereichs gewährt keinen Zugriff von sich aus.

## Autorisierungsmodell

Glossia durchsetzt **zwei Ebenen** für die [Representational State Transfer](https://developer.mozilla.org/en-US/docs/Glossary/REST)-Anwendungsschnittstelle und den [Model Context Protocol](https://modelcontextprotocol.io)-Server:

1. **Bereichsprüfung**: Das Zugriffstoken muss den erforderlichen `object:action`-Bereich umfassen.
2. **Ressourcensebene-Beschränkung**: Der aktuelle Benutzer muss für die spezifische Ressource über explizite Mitgliedschaftsberechtigungen oder die rollenbasierte Politik autorisiert werden.

Bereiche repräsentieren die *maximale* Fähigkeit eines Tokens. Ressourcensebenen-Prüfungen erzwingen die *tatsächliche* Berechtigung für eine spezifische Ressource.

### Rollen

| Rolle | Beschreibung |
|------|-------------|
| `self` | Der Benutzer, der auf seine eigenen Ressourcen zugreift |
| `organization_member` | Ein Mitglied der Organisation, zu der die Ressource gehört |
| `organization_admin` | Ein Administrator der Organisation, zu der die Ressource gehört |
| `public_account` | Die Ressource gehört einem öffentlichen Konto |

### Mitgliedschaftsberechtigungen

Mitgliedschaften ohne Administratorrechte können explizite Berechtigungsbereiche beinhalten. Neue Mitglieder beginnen mit Lesezugriff auf Konto, Organisation, Projekte, Stimme, Glossar, Diskussionen, Tickets, Übersetzungsaktivität und Analytik, sowie Zugang zu ihren eigenen privaten Toki-Gesprächen. Ein Organisationsadministrator kann diese Bereiche durch [Mitglieder → Berechtigungen](/docs/how-to/member-permissions) ersetzen. Eine angeforderte Aktion muss in den erlaubten Bereichen des Mitglieds sowie den Token-Bereichen enthalten sein, wenn ein Token verwendet wird.

Das Eigentum privater Toki wird vor Mitgliedschaftsbereichsoverrides geprüft. Weder die Mitgliedschaft noch Administratorrollen erlauben den Zugriff auf das Gespräch eines anderen Benutzers. Projektsichtbarkeit wird separat geprüft. Siehe die [Mobil- und Begleit-API](/docs/reference/apis/mobile) für Endpunktbereiche und Limits.

Organisationsadministratoren behalten ihre Administratorrolle. Bestehende Mitgliedschaften ohne explizite Bereiche verwenden weiterhin die rollenbasierte Politik unten, bis Berechtigungen gespeichert werden.

### Rollenberechtigungen

Die folgende Tabelle zeigt gängige rollenbasierte Regeln für Mitgliedschaften ohne explizite Bereiche. Es ist nicht die vollständige Politik: Leseanfragen, vorübergehender Zugriff und Plattformadministratoren haben zusätzliche Regeln.

| Bereich | selbst | Organisationsmitglied | Organisationsadministrator | Öffentliches Konto |
|-------|------|----------------------|--------------------|----------------|
| `user:read` | Ja | Ja | | |
| `user:write` | Ja | | | |
| `account:read` | | Ja | Ja | Ja |
| `organization:read` | | Ja | Ja | |
| `organization:write` | | | Ja | |
| `organization:delete` | | | Ja | |
| `organization:admin` | | | Ja | |
| `members:read` | | Ja | Ja | |
| `members:write` | | | Ja | |
| `project:read` | | Ja | Ja | Ja |
| `project:write` | | | Ja | |
| `project:admin` | | | Ja | |
| `project:delete` | | | Ja | |
| `voice:read` | | Ja | Ja | Ja |
| `voice:write` | | | Ja | |
| `voice:admin` | | | Ja | |
| `glossary:read` | | Ja | Ja | |
| `glossary:write` | | | Ja | |
| `glossary:admin` | | | Ja | |
