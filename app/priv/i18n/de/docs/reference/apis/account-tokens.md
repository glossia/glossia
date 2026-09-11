%{
  title: "Account-Token",
  summary: "Account-Token erstellen und verwalten zur Authentifizierung mit der Glossia-API.",
  category: "Referenz",
  subcategory: "APIs",
  order: 2
}
---
Account-Token bieten eine einfache Möglichkeit, API-Anfragen zu authentifizieren, ohne den vollständigen OAuth-Flow durchlaufen zu müssen. Sie eignen sich ideal für Skripte, CI/CD-Pipelines und persönliche Automatisierung.

## Token erstellen

1. Melden Sie sich bei Glossia an und navigieren Sie zu Ihrem Konto-Dashboard.
2. Öffnen Sie den **API** Abschnitt in der Seitenleiste.
3. Klicken Sie **Account-Token**, dann **Neuer Token**.
4. Geben Sie dem Token einen beschreibenden **Namen** (zum Beispiel "CI deploy" oder "CLI access").
5. Wählen Sie die **Bereiche** das das Token benötigt. Gewähren Sie nur die minimal erforderlichen Berechtigungen.
6. Geben Sie ein **Ablaufdatum** oder lassen Sie es leer für ein Token, das nie abläuft.
7. Klicken Sie **Token erstellen**.

Nach der Erstellung wird der vollständige Token-Wert angezeigt. **einmal**. Kopieren Sie diesen Wert unverzüglich und speichern Sie ihn sicher. Sie werden den vollständigen Wert danach nicht mehr einsehen können.

## Verwendung eines Tokens

Fügen Sie das Token in den `Authorization` Header Ihrer HTTP-Anfragen:

    Authorization: Bearer glsa_abc123def456...

Zum Beispiel verwenden `curl`:

```bash
curl -H "Authorization: Bearer glsa_abc123def456..." \
  https://glossia.ai/api/projects
```

Account-Token folgen demselben [Autorisierungsmodell](/docs/reference/apis/authentication) als OAuth-Token. Die Scopes des Tokens definieren die maximale Menge an Aktionen, die dieser ausführen kann, und Richtlinien auf Ressourcenebene gelten weiterhin basierend auf den Beziehungen Ihres Accounts.

## Token-Format

Alle Account-Token beginnen mit dem `glsa_` Präfix gefolgt von einem zufälligen Hex-String. Dieses Präfix macht es einfach, Glossia-Token in Logs und Secret-Scannern zu identifizieren.

## Scopes

Account-Token unterstützen dieselben Scopes wie OAuth-Token. Siehe die [Scopes-Referenz](/docs/reference/apis/authentication) für die vollständige Liste.

Beim Erstellen eines Tokens wählen Sie nur die Scopes aus, die Ihr Anwendungsfall benötigt. Zum Beispiel:

- Eine Read-Only-Integration benötigt `project:read` und `voice:read`.
- Eine CI-Pipeline, die Projekte erstellt, benötigt `project:read` und `project:write`.
- Ein Skript, das Organisationsmitglieder verwaltet, benötigt `members:read` und `members:write`.

## Tokens verwalten

### Tokens anzeigen

Die **Kontotoken** Seite führt alle aktiven Tokens mit ihren Namen, Bereichen, Datum der letzten Nutzung und Ablaufdatum auf. Tokens, die noch nie verwendet wurden, zeigen \\"Nie\\" in der Spalte \\"letzte Nutzung\\" an.

### Token bearbeiten

Klicken Sie den Namen eines Tokens an, um **Name** und **Beschreibung**. Bereiche und Ablaufdatum können nach der Erstellung nicht geändert werden. Wenn Sie unterschiedliche Bereiche benötigen, erstellen Sie ein neues Token und widerrufen Sie das alte.

### Token widerrufen

Um ein Token zu widerrufen, klicken Sie **Widerrufen** in der Token-Liste oder öffnen Sie die Bearbeitungsseite des Tokens und verwenden Sie den **Token widerrufen** Button im Gefahrenbereich. Widerrufene Tokens funktionieren sofort nicht mehr und können nicht wiederhergestellt werden.

## Beste Sicherheitspraktiken

- **Speichern Sie Tokens sicher.** Verwenden Sie Umgebungsvariablen oder einen Secrets-Manager. Laden Sie niemals Tokens in die Versionskontrolle.
- **Verwenden Sie Tokens mit kurzer Gültigkeitsdauer.** Legen Sie, wenn möglich, ein Ablaufdatum fest.
- **Minimieren Sie den Anwendungsbereich.** Gewähren Sie nur die Berechtigungen, die das Token tatsächlich benötigt.
- **Rotieren Sie die Tokens regelmäßig.** Erstellen Sie neue Tokens und widerrufen Sie alte Tokens nach Zeitplan.
- **Überwachen Sie die Token-Nutzung.** Prüfen Sie das Datum "letzte Nutzung" regelmäßig. Widerrufen Sie Tokens, die nicht mehr verwendet werden.
- **Verwenden Sie pro Integration ein Token.** Auf diese Weise wird der Widerruf eines Tokens andere Workflows nicht beeinträchtigen.

## API-Verwaltung

Sie können Account-Tokens auch über das REST API und den MCP-Server verwalten.

### REST API

| Methode | Endpunkt | Beschreibung |
|--------|----------|-------------|
| `GET` | `/api/tokens` | Aktive Token anzeigen |
| `POST` | `/api/tokens` | Neues Token erstellen |
| `DELETE` | `/api/tokens/:id` | Token widerrufen |

### MCP

Der MCP-Server bietet `list_tokens`, `create_token`, und `revoke_token` Werkzeuge, die die REST API widerspiegeln.