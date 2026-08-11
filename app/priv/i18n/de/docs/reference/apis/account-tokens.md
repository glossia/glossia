%{
  title: "Konto-Token",
  summary: "Erstellen und verwalten Sie Konto-Token zur Authentifizierung bei der Glossia-API.",
  category: "Referenz",
  subcategory: "APIs",
  order: 2
}
---
Konto-Token bieten eine einfache Möglichkeit, API-Anfragen zu authentifizieren, ohne den vollständigen OAuth-Ablauf zu durchlaufen. Sie eignen sich ideal für Skripte, CI/CD-Pipelines und persönliche Automatisierungen.

## Erstellen eines Tokens

1. Melden Sie sich bei Glossia an und navigieren Sie zu Ihrem Konto-Dashboard.
2. Öffnen Sie den Bereich **API** in der Seitenleiste.
3. Klicken Sie auf **Konto-Token** und anschließend auf **Neues Token**.
4. Vergeben Sie einen aussagekräftigen **Namen** für das Token (z. B. "CI-Deployment" oder "CLI-Zugriff").
5. Wählen Sie die benötigten **Scopes** für das Token aus. Erteilen Sie nur die minimal erforderlichen Berechtigungen.
6. Legen Sie ein **Ablaufdatum** fest oder lassen Sie das Feld leer, damit das Token unbegrenzt gültig bleibt.
7. Klicken Sie auf **Token erstellen**.

Nach der Erstellung wird der vollständige Token-Wert nur **einmal** angezeigt. Kopieren Sie ihn sofort und bewahren Sie ihn sicher auf. Sie können den vollständigen Wert später nicht mehr einsehen.

## Verwenden eines Tokens

Fügen Sie das Token in den Header `Authorization` Ihrer HTTP-Anfragen ein:

```
Authorization: Bearer glsa_abc123def456...
```

Zum Beispiel unter Verwendung von `curl`:

```bash
curl -H "Authorization: Bearer glsa_abc123def456..." \
  https://glossia.ai/api/projects
```

Konto-Token folgen demselben [Autorisierungsmodell](/docs/reference/apis/authentication) wie OAuth-Token. Die Scopes des Tokens definieren den maximalen Umfang der ausführbaren Aktionen, und Richtlinien auf Ressourcenebene gelten weiterhin basierend auf den Beziehungen Ihres Kontos.

## Token-Format

Alle Konto-Token beginnen mit dem Präfix `glsa_`, gefolgt von einer zufälligen Hex-Zeichenfolge. Dieses Präfix erleichtert die Identifizierung von Glossia-Token in Protokollen und Secret-Scannern.

## Scopes

Konto-Token unterstützen dieselben Scopes wie OAuth-Token. Die vollständige Liste finden Sie in der [Scope-Referenz](/docs/reference/apis/authentication).

Wählen Sie beim Erstellen eines Tokens nur die Scopes aus, die für Ihren Anwendungsfall erforderlich sind. Zum Beispiel:

- Eine Nur-Lese-Integration benötigt `project:read` und `voice:read`.
- Eine CI-Pipeline, die Projekte erstellt, benötigt `project:read` und `project:write`.
- Ein Skript zur Verwaltung von Organisationsmitgliedern benötigt `members:read` und `members:write`.

## Verwalten von Token

### Token anzeigen

Die Seite **Konto-Token** listet alle aktiven Token mit ihrem Namen, ihren Scopes, dem Datum der letzten Verwendung und dem Ablaufdatum auf. Token, die noch nie verwendet wurden, weisen in der Spalte für die letzte Verwendung den Wert "Nie" auf.

### Token bearbeiten

Klicken Sie auf den Namen eines Tokens, um dessen **Namen** und **Beschreibung** zu bearbeiten. Scopes und Ablaufdatum können nach der Erstellung nicht mehr geändert werden. Wenn Sie andere Scopes benötigen, erstellen Sie ein neues Token und widerrufen Sie das alte.

### Token widerrufen

Um ein Token zu widerrufen, klicken Sie in der Token-Liste auf **Widerrufen** oder öffnen Sie die Bearbeitungsseite des Tokens und klicken Sie auf die Schaltfläche **Token widerrufen** im Gefahrenbereich. Widerrufene Token sind sofort ungültig und können nicht wiederhergestellt werden.

## Best Practices für die Sicherheit

- **Token sicher aufbewahren.** Verwenden Sie Umgebungsvariablen oder einen Secrets-Manager. Checken Sie Token niemals in die Versionsverwaltung ein.
- **Kurzlebige Token verwenden.** Legen Sie nach Möglichkeit immer ein Ablaufdatum fest.
- **Scopes minimieren.** Erteilen Sie nur die Berechtigungen, die das Token tatsächlich benötigt.
- **Regelmäßig rotieren.** Erstellen Sie in regelmäßigen Abständen neue Token und widerrufen Sie alte.
- **Nutzung überwachen.** Überprüfen Sie regelmäßig das Datum der letzten Verwendung. Widerrufen Sie Token, die nicht mehr in Gebrauch sind.
- **Ein Token pro Integration verwenden.** Auf diese Weise unterbricht das Widerrufen eines Tokens keine anderen Arbeitsabläufe.

## API-Verwaltung

Sie können Konto-Token auch über die REST-API und den MCP-Server verwalten.

### REST-API

| Methode | Endpunkt | Beschreibung |
|--------|----------|-------------|
| `GET` | `/api/tokens` | Aktive Token auflisten |
| `POST` | `/api/tokens` | Neues Token erstellen |
| `DELETE` | `/api/tokens/:id` | Token widerrufen |

### MCP

Der MCP-Server stellt die Tools `list_tokens`, `create_token` und `revoke_token` bereit, die die REST-API widerspiegeln.