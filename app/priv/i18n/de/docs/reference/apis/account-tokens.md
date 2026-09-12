%{
  title: "Account-Token",
  summary: "Erstellen und Verwalten von Account-Token zur Authentifizierung mit der Glossia-API.",
  category: "Referenz",
  subcategory: "APIs",
  order: 2
}
---
Account-Tokens bieten einen einfachen Weg, um API-Anfragen ohne den vollständigen OAuth-Ablauf zu authentifizieren. Sie eignen sich ideal für Skripte, CI/CD-Pipelines und persönliche Automatisierung.

## Token erstellen

1. Melden Sie sich bei Glossia an und navigieren Sie zu Ihrem Account-Dashboard.
2. Öffnen Sie den **API** Bereich in der Seitenleiste.
3. Klicken Sie auf **Account-Tokens**, dann **Neuer Token**.
4. Geben Sie dem Token einen beschreibenden **Name** (beispielsweise "CI deploy" oder "CLI access").
5. Wählen Sie die **Bereiche** das Token benötigt. Erteilen Sie nur die minimal erforderlichen Berechtigungen.
6. Geben Sie **Ablaufdatum** oder lassen Sie es leer, für ein Token, das nie abläuft.
7. Klicken **Token erstellen**.

Nach der Erstellung wird der vollständige Tokenwert angezeigt. **einmal**. Kopieren Sie es sofort und speichern Sie es sicher. Sie werden den vollständigen Wert nicht mehr sehen können.

## Verwendung eines Tokens

Fügen Sie den Token in den `Authorization` Header Ihrer HTTP-Anfragen:

    Authorization: Bearer glsa_abc123def456...

Beispielsweise mit `curl`:

```bash
curl -H "Authorization: Bearer glsa_abc123def456..." \
  https://glossia.ai/api/projects
```

Konto-Tokens folgen demselben [Autorisierungsmodell](/docs/reference/apis/authentication) als OAuth-Tokens. Die Berechtigungen des Tokens definieren die maximalen Aktionen, die es ausführen kann, und Richtlinien auf Ressourcenebene gelten weiterhin basierend auf den Beziehungen Ihres Kontos.

## Token-Format

Alle Kontotokens beginnen mit dem `glsa_` Präfix, gefolgt von einem zufälligen Hex-String. Dieses Präfix macht es einfach, Glossia-Tokens in Protokollen und Secret-Scannern zu identifizieren.

## Berechtigungen

Kontotokens unterstützen dieselben Berechtigungen wie OAuth-Tokens. Siehe die [Berechtigungsreferenz](/docs/reference/apis/authentication) für die vollständige Liste.

Beim Erstellen eines Tokens wählen Sie nur die Bereiche aus, die Ihr Anwendungszweck benötigt. Zum Beispiel:

- Eine read-only-Integration benötigt `project:read` und `voice:read`.
- Eine CI-Pipeline, die Projekte erstellt, benötigt `project:read` und `project:write`.
- Ein Skript, das Organisationsmitglieder verwaltet, benötigt `members:read` und `members:write`.

## Tokens verwalten

### Tokens anzeigen

Die **Account-Token** Seite listet alle aktiven Tokens mit ihrem Namen, Scopes, dem Datum der letzten Nutzung und dem Ablaufdatum auf. Tokens, die noch nie verwendet wurden, zeigen "Niemals" in der Spalte "letztverwendet".

### Token bearbeiten

Klicken Sie auf den Namen eines Token, um dessen **Name** und **Beschreibung**. Bereiche und Ablaufdatum können nach der Erstellung nicht geändert werden. Wenn Sie andere Bereiche benötigen, erstellen Sie ein neues Token und widerrufen Sie das alte.

### Token widerrufen

Um ein Token zu widerrufen, klicken **Widerrufen** in der Token-Liste oder öffnen Sie die Bearbeitungsseite des Tokens und verwenden Sie den **Token widerrufen** Button im Gefahrenbereich. Widerrufene Tokens funktionieren sofort nicht mehr und können nicht wiederhergestellt werden.

## Bewährte Sicherheitspraktiken

- **Speichern Sie Tokens sicher.** Verwenden Sie Umgebungsvariablen oder einen Secrets Manager. Geben Sie Tokens niemals in die Versionskontrolle ein.
- **Verwenden Sie kurzlebige Tokens.** Setzen Sie bei jeder Möglichkeit ein Ablaufdatum.
- **Scopes minimieren.** Genehmigen Sie nur die Berechtigungen, die das Token tatsächlich benötigt.
- **Rotieren Sie Token regelmäßig.** Erstellen Sie neue Token und widerrufen Sie alte Token nach Zeitplan.
- **Nutzung überwachen.** Prüfen Sie das Datum "letzter Nutzung" regelmäßig. Widerrufen Sie Token, die nicht mehr verwendet werden.
- **Verwenden Sie pro Integration ein Token.** Auf diese Weise bricht das Widerrufen eines Tokens keine anderen Workflows.

## API-Management

Sie können auch Account-Token über die REST API und den MCP-Server verwalten.

### REST API

| Methode | Endpunkt | Beschreibung |
|--------|----------|-------------|
| `GET` | `/api/tokens` | Aktive Tokens anzeigen |
| `POST` | `/api/tokens` | Einen neuen Token erstellen |
| `DELETE` | `/api/tokens/:id` | Einen Token widerrufen |

### MCP

Der MCP-Server exponiert `list_tokens`, `create_token`, und `revoke_token` Werkzeuge, die die REST-API spiegeln.