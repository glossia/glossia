%{
  title: "Autorisierung",
  summary:
    "Berechtigungs-Bereiche, Organisationsrollen und Zugriffskontrollen auf Ressourcensebene.",
  category: "Referenz",
  subcategory: "APIs",
  order: 2
}
---

Authentifizierung erstellt eine Identität; Autorisierung entscheidet, welche Aktionen diese Identität ausführen kann. Siehe [Authentifizierung](/docs/reference/apis/authentication) für Sign-in- und Token-Flows.

## Bereiche

Bereiche steuern, welche Aktionen ein Token ausführen kann. Sie folgen dem `object:action`-Muster.

| Bereich | Beschreibung |
|-------|-------------|
| `admin:read` | Lesen von Plattform-Verwaltungsdaten (nur Plattformadministratoren) |
| `admin:write` | Ändern von Plattform-Verwaltungsdaten (nur Plattformadministratoren) |
| `ops:read` | Lesen von Plattform-Betriebsdaten (nur Plattformadministratoren) |
| `user:read` | Benutzerprofileinhalte lesen |
| `user:write` | Benutzerprofil aktualisieren |
| `account:read` | Liste der Organisationskonten, auf die Sie zugreifen können |
| `organization:read` | Organisations Details lesen (und Ihre Organisationen auflisten) |
| `organization:write` | Organisationen erstellen oder aktualisieren |
| `organization:claim` | Organisation beanspruchen |
| `organization:delete` | Organisationen löschen |
| `organization:admin` | Administrative Organisationsakctionen |
| `members:read` | Organisationsmitglieder und Einladungen einsehen |
| `members:write` | Organisationsmitglieder und Einladungen verwalten |
| `project:read` | Projekte einsehen |
| `project:write` | Projekte erstellen oder aktualisieren |
| `project:admin` | Administrative Projektaktionen |
| `project:delete` | Projekte löschen |
| `voice:read` | Sprachkonfiguration einsehen |
| `voice:write` | Sprachkonfiguration erstellen oder aktualisieren |
| `voice:admin` | Administrative Sprachaktionen |
| `glossary:read` | Wörterbücherinträge einsehen |
| `glossary:write` | Wörterbucheinträge erstellen oder aktualisieren |
| `glossary:admin` | Wörterbucheinstellungen verwalten |
| `discussion:read` | Diskussionen einsehen |
| `discussion:write` | Diskussionen erstellen oder aktualisieren |
| `discussion:admin` | Administrative Diskussionsaktionen |
| `ticket:read` | Tickets einsehen |
| `ticket:write` | Tickets erstellen oder aktualisieren |
| `ticket:admin` | Administrative Ticketaktionen |
| `llm_model:read` | Kontosprachmodelle einsehen |
| `llm_model:write` | Kontosprachmodelle verwalten |
| `translation:write` | Übersetzungsdaten schreiben |
| `api_credentials:read` | Zugangsdaten einsehen |
| `api_credentials:write` | Zugangsdaten verwalten |

Die [Discovery-Metadaten](/docs/reference/apis/authentication#discovery-endpoints) des Authentifizierungsservers veröffentlichen die für Clients verfügbaren Scopes. Die Verfügbarkeit eines Scops allein gewährt keinen Zugriff.

## Autorisierungsmodell

Glossia durchsetzt **zwei Ebenen** für die [Darstellbare Zustandsübertragung](https://developer.mozilla.org/en-US/docs/Glossary/REST)-Anwendungsprogrammierschnittstelle und die [Modellkontextprotokoll](https://modelcontextprotocol.io)-Server:

1. **Bereichsprüfung**: Das Zugriffstoken muss den erforderlichen `object:action` Bereich enthalten.
2. **Ressourcen-Level-Richtlinie**: Der aktuelle Benutzer muss für die spezifische Ressource über explizite Mitgliederberechtigungen oder die Rollenrichtlinie autorisiert sein.

Bereiche repräsentieren die *maximale* Fähigkeit eines Tokens. Ressourcen-Level-Prüfungen setzen die *tatsächliche* Berechtigung für eine bestimmte Ressource durch.

### Rollen

| Rolle | Beschreibung |
|------|-------------|
| `self` | Der Benutzer, der auf seine eigenen Ressourcen zugreift |
| `organization_member` | Ein Mitglied der Organisation, die die Ressource besitzt |
| `organization_admin` | Ein Administrator der Organisation, die die Ressource besitzt |
| `public_account` | Die Ressource gehört zu einem öffentlichen Konto |

### Mitgliederberechtigungen

Mitgliedschaften ohne Administratorstatus können explizite Berechtigungs-Bereiche enthalten. Neue Mitglieder beginnen mit Lesezugriff auf Konto, Organisation, Projekte, Sprache, Wörterbuch, Diskussionen und Tickets. Ein Organisationsadministrator kann diese Bereiche durch [Mitglieder → Berechtigungen](/docs/how-to/member-permissions) ersetzen. Eine angeforderte Aktion muss in den erlaubten Bereichen des Mitglieds sowie den Token-Bereichen enthalten sein, wenn ein Token verwendet wird.

Organisationsadministratoren behalten ihre Administratorrolle. Bestehende Mitgliedschaften ohne explizite Bereiche继续使用 die unten aufgeführten Rollenrichtlinien, bis Berechtigungen gespeichert sind.

### Rollenberechtigungen

Die Tabelle unten zeigt gängige rollenbasierte Regeln für Mitgliedschaften ohne explizite Bereiche. Es handelt sich nicht um die vollständige Richtlinie: Sammlungsanfragen, temporärer Zugriff und Plattformadministratoren haben zusätzliche Regeln.

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
