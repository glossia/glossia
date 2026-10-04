%{
  title: "Autorisierung",
  summary:
    "Berechtigungsgebiete, Organisationsrollen und Zugriffsüberprüfungen auf Ressourcenebene.",
  category: "Referenz",
  subcategory: "APIs",
  order: 2
}
---
Authentifizierung etabliert eine Identität; Autorisierung entscheidet, welche Aktionen diese Identität ausführen darf. Siehe [Authentifizierung](/docs/reference/apis/authentication) für Anmelden und Token-Flüsse.

## Bereiche

Bereiche steuern, welche Aktionen ein Token ausführen darf. Sie folgen dem `object:action` Muster.

| Bereich | Beschreibung |
|-------|-------------|
| `admin:read` | Plattformverwaltungsdaten lesen (nur für Plattformadministratoren) |
| `admin:write` | Plattformverwaltungsdaten aktualisieren (nur für Plattformadministratoren) |
| `ops:read` | Plattformbetriebsdaten lesen (nur für Plattformadministratoren) |
| `user:read` | Benutzerprofilinformationen lesen |
| `user:write` | Benutzerprofil aktualisieren |
| `account:read` | Zugängliche Organisationskonten auflisten |
| `organization:read` | Organisationsdetails lesen (und Ihre Organisationen auflisten) |
| `organization:write` | Organisationen erstellen oder aktualisieren |
| `organization:claim` | Eine Organisation übernehmen |
| `organization:delete` | Organisationen löschen |
| `organization:admin` | Verwaltung von Organisationen |
| `members:read` | Mitglieder und Einladungen einsehen |
| `members:write` | Organisationsmitglieder und Einladungen verwalten |
| `project:read` | Projekte einsehen |
| `project:write` | Projekte erstellen oder bearbeiten |
| `project:admin` | Administrative Projektmaßnahmen |
| `project:delete` | Projekte löschen |
| `voice:read` | Stimmenkonfiguration lesen |
| `voice:write` | Stimmenkonfiguration erstellen oder aktualisieren |
| `voice:admin` | Verwaltungsstimmaktionen |
| `glossary:read` | Wörterbucheinträge lesen |
| `glossary:write` | Wörterbucheinträge erstellen oder aktualisieren |
| `glossary:admin` | Wörterbucheinstellungen verwalten |
| `discussion:read` | Diskussionen lesen |
| `discussion:write` | Diskussionen erstellen oder aktualisieren |
| `discussion:admin` | Administrative Diskussionsaktionen |
| `ticket:read` | Tickets lesen |
| `ticket:write` | Tickets erstellen oder aktualisieren |
| `ticket:admin` | Verwaltungs-Ticket-Aktionen |
| `llm_model:read` | Konto-Sprachmodelle lesen |
| `llm_model:write` | Konto-Sprachmodelle verwalten |
| `translation:write` | Übersetzungsdaten schreiben |
| `api_credentials:read` | Lesezugriffsanmeldedaten |
| `api_credentials:write` | Zugriffsanmeldedaten verwalten |

Des Authentifizierungsservers [Discovery-Metadaten](/docs/reference/apis/authentication#discovery-endpoints) veröffentlicht die für Clients verfügbaren Berechtigungen. Eine verfügbare Berechtigung gewährt allein keinen Zugriff.

## Autorisierungsmodell

Glossia erzwingt **zwei Schichten** für die [Representational State Transfer](https://developer.mozilla.org/en-US/docs/Glossary/REST) Anwendungsprogrammierschnittstelle und die [Model Context Protocol](https://modelcontextprotocol.io) Server:

1. **Bereichsprüfung**: das Zugriffstoken muss das erforderliche `object:action` Berechtigungs-Bereich.
2. **Ressourcenbasierte Richtlinie**: der aktuelle Benutzer muss für die spezifische Ressource autorisiert sein, entweder durch explizite Berechtigungen oder die rollenbasierte Richtlinie.

Berechtigungs-Bereiche repräsentieren die *maximale* Fähigkeit eines Tokens. Überprüfungen auf Ressourcenebene erzwingen die *tatsächliche* Berechtigung für eine bestimmte Ressource.

### Rollen

| Rolle | Beschreibung |
|------|-------------|
| `self` | Der Benutzer, der auf seine eigenen Ressourcen zugreift |
| `organization_member` | Ein Mitglied der Organisation, die die Ressource besitzt |
| `organization_admin` | Ein Administrator der Organisation, die die Ressource besitzt |
| `public_account` | Die Ressource gehört einem öffentlichen Konto |

### Mitgliederberechtigungen

Nichtadministrative Organisationsmitgliedschaften können explizite Berechtigungsbereiche umfassen. Neue Mitglieder beginnen mit Lesezugriff auf das Konto, die Organisation, Projekte, Stimmen, Glossare, Diskussionen und Tickets. Ein Organisationsadministrator kann diese Bereiche über [Mitglieder → Berechtigungen](/docs/how-to/member-permissions). Eine angeforderte Aktion muss sowohl in den erlaubten Bereichen des Mitglieds als auch in den Token-Bereichen enthalten sein, wenn ein Token verwendet wird.

Organisationsadministratoren behalten ihre Administratorrolle. Bestehende Mitgliedschaften ohne explizite Bereiche verwenden weiterhin die unten aufgeführte rollenbasierte Richtlinie, bis Berechtigungen gespeichert werden.

### Rollenberechtigungen

Die folgende Tabelle zeigt gängige, rollenbasierte Regeln für Mitgliedschaften ohne explizite Bereiche. Sie ist nicht die vollständige Richtlinie: Sammelanfragen, temporärer Zugriff und Plattformadministratoren unterliegen zusätzlichen Regeln.

| Bereiche | self | organization\_member | organization\_admin | public\_account |
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