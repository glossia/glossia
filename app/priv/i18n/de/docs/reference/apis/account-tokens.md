%{
  title: "Account-Token",
  summary:
    "Account-Token erstellen und verwalten, um sich mit der Glossia API zu authentifizieren.",
  category: "Referenz",
  subcategory: "APIs",
  order: 2
}
---
Account-Tokens bieten einen einfachen Weg, API-Anfragen ohne den vollständigen OAuth-Workflow zu authentifizieren. Sie sind ideal für Skripte, CI/CD-Pipelines und persönliche Automatisierung.

## Token erstellen

1. Melden Sie sich bei Glossia an und navigieren Sie zu Ihrem Account-Dashboard.
2. Öffnen Sie das **API** Abschnitt aus der Seitenleiste.
3. Klicken Sie auf **Account-Tokens**, dann **Neues Token**.
4. Verleihen Sie dem Token einen beschreibenden **Name** (beispielsweise "CI deploy" oder "CLI-Zugriff").
5. Wählen Sie die **Bereiche** die das Token benötigt. Gewähren Sie nur die minimal erforderlichen Berechtigungen.
6. Legen Sie ein **Ablaufdatum** oder lassen Sie es leer für ein Token, das nie abläuft.
7. Klicken Sie **Token erstellen**.

Nach der Erstellung wird der vollständige Token-Wert angezeigt **einmal**. Kopieren Sie es sofort und speichern Sie es sicher. Sie werden den vollständigen Wert nicht mehr einsehen können.

## Ein Token verwenden

Fügen Sie das Token in den `Authorization` Header Ihrer HTTP-Anfragen:

    Authorization: Bearer glsa_abc123def456...

Beispielsweise unter Verwendung von `curl`:

```bash
curl -H "Authorization: Bearer glsa_abc123def456..." \
  https://glossia.ai/api/projects
```

Konto-Token folgen demselben [Auth-Modell](/docs/reference/apis/authentication) als OAuth-Token. Die Token-Berechtigungen definieren die maximale Menge an Aktionen, die es ausführen kann, und Richtlinien auf Ressourcensebene gelten weiterhin basierend auf den Beziehungen zu Ihrem Konto.

## Token-Format

Alle Konto-Token beginnen mit dem `glsa_` Präfix gefolgt von einem zufälligen Hexadezimalstring. Dieses Präfix erleichtert die Identifizierung von Glossia-Token in Logs und Secret-Scannern.

## Berechtigungen

Konto-Token unterstützen dieselben Berechtigungen wie OAuth-Token. Siehe die [Berechtigungs-Referenz](/docs/reference/apis/authentication) für die vollständige Liste.

Beim Erstellen eines Tokens wählen Sie nur die Berechtigungen aus, die Ihr Anwendungsfall benötigt. Zum Beispiel:

- Eine nur-lesende Integration benötigt `project:read` und `voice:read`.
- Eine CI-Pipeline, die Projekte erstellt, benötigt `project:read` und `project:write`.
- Ein Skript, das Organisationsmitglieder verwaltet, benötigt `members:read` und `members:write`.

## Tokenverwaltung

### Tokenanzeige

Die **Account-Token** Seite listet alle aktiven Token mit deren Namen, Berechtigungen, dem Datum der letzten Nutzung und dem Ablaufdatum auf. Token, die noch nie genutzt wurden, zeigen "Niemals" in der Spalte "Letzter Gebrauch" an.

### Tokens bearbeiten

Klicken Sie auf den Namen eines Tokens, um diesen **Name** und **Beschreibung**. Bereiche und Ablaufdatum können nach der Erstellung nicht geändert werden. Wenn Sie andere Bereiche benötigen, erstellen Sie einen neuen Token und widerrufen Sie den alten.

### Tokens widerrufen

Um einen Token zu widerrufen, klicken Sie **Widerrufen** in der Tokenliste oder öffnen Sie die Bearbeitungsseite des Tokens und nutzen Sie die **Token widerrufen** Schaltfläche im Gefahrenbereich. Widerrufene Tokens funktionieren sofort nicht mehr und können nicht wiederhergestellt werden.

## Beste Sicherheitspraktiken

- **Speichern Sie Tokens sicher.** Verwenden Sie Umgebungsvariablen oder einen Secrets Manager. Laden Sie Tokens niemals in die Versionskontrolle ein.
- **Verwenden Sie kurzlebige Tokens.** Legen Sie ein Ablaufdatum fest, wenn möglich.
- **Minimieren Sie die Bereiche.** Gewähren Sie nur die Berechtigungen, die das Token tatsächlich benötigt.
- **Rotieren Sie regelmäßig.** Erstellen Sie neue Tokens und widerrufen Sie alte nach Zeitplan.
- **Überwachen Sie die Nutzung.** Prüfen Sie das Datum \\"zuletzt verwendet\\" regelmäßig. Widerrufen Sie Tokens, die nicht mehr verwendet werden.
- **Verwenden Sie ein Token pro Integration.** Auf diese Weise wird das Widerrufen eines Tokens andere Workflows nicht beeinträchtigen.

## API-Management

Sie können Account-Token auch über die REST API und den MCP-Server verwalten.

### REST API

| Methode | Endpunkt | Beschreibung |
|--------|----------|-------------|
| `GET` | `/api/tokens` | Aktive Tokens auflisten |
| `POST` | `/api/tokens` | Ein neues Token erstellen |
| `DELETE` | `/api/tokens/:id` | Ein Token widerrufen |

### MCP

Der MCP-Server bietet `list_tokens`, `create_token`, und `revoke_token` Werkzeuge, die die REST API abbilden.