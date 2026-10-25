%{
  title: "Autorisierung",
  summary:
    "Berechtigungsgebiete, Organisationsrollen und Zugriffskontrollen auf Ressourcensebene.",
  category: "Referenz",
  subcategory: "APIs",
  order: 2
}
---

Authentifizierung definiert eine Identität; Autorisierung legt fest, welche Aktionen diese Identität ausführen darf. Siehe [Authentifizierung](/docs/reference/apis/authentication) für Anmelde- und Tokenabläufe.

## Bereiche

Bereiche steuern, welche Aktionen ein Token ausführen kann. Sie folgen dem `object:action` Muster.

| Bereich | Beschreibung |
|-------|-------------|
| `admin:read` | Lesen von Plattformverwaltungsdaten (nur Plattformadministratoren) |
| `admin:write` | Bearbeiten von Plattformverwaltungsdaten (nur Plattformadministratoren) |
| `ops:read` | Lesen von Plattformbetriebsdaten (nur Plattformadministratoren) |
| `user:read` | Lesen von Benutzerprofilinformationen |
| `user:write` | Bearbeiten von Benutzerprofil |
| `account:read` | Auflisten der Organisationskonten, auf die Sie zugreifen können |
| `organization:read` | Lesen der Organisationsdetails (und Auflisten Ihrer Organisationen) |
| `organization:write` | Erstellen oder Bearbeiten von Organisationen |
| `organization:claim` | Eine Organisation beanspruchen |
| `organization:delete` | Löschen von Organisationen |
| `organization:admin` | Verwaltungsaktionen für Organisationen |
| `members:read` | Lesen der Organisationsmitglieder und Einladungen |
| `members:write` | Verwalten von Organisationsmitgliedern und Einladungen |
| `project:read` | Lesen von Projekten |
| `project:write` | Erstellen oder Bearbeiten von Projekten |
| `project:admin` | Verwaltungsaktionen für Projekte |
| `project:delete` | Löschen von Projekten |
| `voice:read` | Lesen der Stimme-Konfiguration |
| `voice:write` | Erstellen oder Bearbeiten der Stimme-Konfiguration |
| `voice:admin` | Verwaltungsaktionen für Stimmen |
| `glossary:read` | Lesen von Glossarbegriffen |
| `glossary:write` | Erstellen oder Bearbeiten von Glossarbegriffen |
| `glossary:admin` | Verwalten der Glossar-Einstellungen |
| `discussion:read` | Lesen von Diskussionen |
| `discussion:write` | Erstellen oder Bearbeiten von Diskussionen |
| `discussion:admin` | Verwaltungsaktionen für Diskussionen |
| `ticket:read` | Lesen von Tickets |
| `ticket:write` | Erstellen oder Bearbeiten von Tickets |
| `ticket:admin` | Verwaltungsaktionen für Tickets |
| `llm_model:read` | Lesen der Kontensprachmodelle |
| `llm_model:write` | Verwalten der Kontensprachmodelle |
| `translation:read` | Lesen der Projektübersetzungsaktivität |
| `translation:write` | Schreiben von Übersetzungsdaten |
| `analytics:read` | Lesen der Projektwebsite-Analytics |
| `toki:read` | Lesen Ihrer eigenen privaten Projektkonversationen |
| `toki:write` | Erstellen privater Konversationen und in der Warteschlange anlegen von Begleiterantworten |
| `api_credentials:read` | Lesen von Zugangscertifikaten |
| `api_credentials:write` | Verwalten von Zugangscertifikaten |

Die [Entdeckungsmetadaten](/docs/reference/apis/authentication#discovery-endpoints) des Authentifizierungsservers veröffentlichen die Bereiche, die für Clients verfügbar sind. Dass ein Bereich verfügbar ist, gewährt keinen Zugriff von sich aus.

## Autorisierungsmodell

Glossia erzwingt **zwei Ebenen** für die [Representational State Transfer](https://developer.mozilla.org/en-US/docs/Glossary/REST)-Anwendungsschnittstelle und die [Model Context Protocol](https://modelcontextprotocol.io)-Server:

1. **Bereichsprüfung**: Das Zugriffstoken muss den erforderlichen `object:action` Bereich enthalten.
2. **Mediumsebene-Policy**: Der aktuelle Benutzer muss für die spezifische Ressource durch explizite Mitwirkberechtigungen oder die rollenbasierte Policy autorisiert sein.

Bereiche stellen die *maximale* Funktionalität eines Tokens dar. Mediumsebene-Checks erzwingen die *tatsächliche* Berechtigung für eine spezifische Ressource.

### Rollen

| Rolle | Beschreibung |
|------|-------------|
| `self` | Der Benutzer, der auf ihre eigenen Ressourcen zugreift |
| `organization_member` | Ein Mitglied der Organisation, die die Ressource拥itzt |
| `organization_admin` | Ein Administrator der Organisation, die die Ressource besitzt |
| `public_account` | Die Ressource gehört einem öffentlichen Konto |

### Mitwirkberechtigungen

Nicht-administratorische Organisationsmitgliedschaften können explizite Berechtigungsbereiche tragen. Neue Mitglieder starten mit Lesezugriff auf das Konto, die Organisation, Projekte, Stimme, Glossar, Diskussionen, Tickets, Übersetzungsaktivität und Analytics, zusätzlich Zugriff auf ihre eigenen privaten Toki-Konversationen. Ein Organisationsadministrator kann diese Bereiche durch [Members → Permissions](/docs/how-to/member-permissions) ersetzen. Eine angeforderte Aktion muss in den erlaubten Bereichen des Mitglieds sowie in den Token-Bereichen enthalten sein, wenn ein Token verwendet wird.

Private Toki-Besitz wird vor Organisationsmitglied-Bereichs-Overrides geprüft. Weder die Mitgliedschaft noch Administratorrollen gewähren Zugriff auf die Konversation eines anderen Benutzers. Projektsichtbarkeit wird separat geprüft. Siehe die [mobile und companion API](/docs/reference/apis/mobile) für Endpunktbereiche und Limits.

Organisationsadministratoren behalten ihre Administratorrolle bei. Bestehende Mitgliedschaften ohne explizite Bereiche nutzen weiterhin die nachfolgende rollenbasierte Policy, bis Berechtigungen gespeichert werden.

### Rollberechtigungen

Die folgende Tabelle zeigt häufige rollenbasierte Regeln für Mitgliedschaften ohne explizite Bereiche. Es ist nicht die vollständige Policy: Sammelanfragen, temporärer Zugriff und Plattformadministratoren haben zusätzliche Regeln.

| Bereich | selbst | organisation_member | organisation_admin | public_account |
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
