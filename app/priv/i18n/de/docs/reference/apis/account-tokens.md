%{
  title: "Konto-Token",
  summary: "Erstellen und Verwalten von Konto-Token zur Authentifizierung mit der Glossia API.",
  category: "Referenz",
  subcategory: "APIs",
  order: 2
}
---
Accounttokens bieten einen einfachen Weg, um API-Anfragen zu authentifizieren, ohne den vollständigen OAuth-Flow durchlaufen zu müssen. Sie sind ideal für Skripte, CI/CD-Pipelines und persönliche Automatisierung.

## Token erstellen

1. Melden Sie sich bei Glossia an und navigieren Sie zu Ihrem Kontodashboard.
2. Öffnen Sie den **API** Abschnitt in der Seitenleiste.
3. Klicken Sie **Accounttokens**, dann **Neues Token**.
4. Geben Sie dem Token einen beschreibenden **Namen** (beispielsweise "CI deploy" oder "CLI access").
5. Wählen Sie **Bereiche** die das Token benötigt. Gewähren Sie nur die minimal erforderlichen Berechtigungen.
6. Legen Sie ein **Ablaufdatum** oder lassen Sie es leer für ein Token, das niemals abläuft.
7. Klicken **Token erstellen**.

Nach der Erstellung wird der vollständige Token-Wert angezeigt. **einmal**. Kopieren Sie es umgehend und speichern Sie es sicher. Sie werden den vollen Wert nicht erneut sehen können.

## Token verwenden

Fügen Sie das Token in den `Authorization` Header Ihrer HTTP-Anfragen:

    Authorization: Bearer glsa_abc123def456...

Zum Beispiel, unter Verwendung von `curl`:

```bash
curl -H "Authorization: Bearer glsa_abc123def456..." \
  https://glossia.ai/api/projects
```

Account-Tokens folgen demselben [Autorisierungsmodell](/docs/reference/apis/authentication) als OAuth-Token. Die Token-Bereiche definieren die maximale Menge an Aktionen, die das Token ausführen kann, und Ressourcebene-Richtlinien gelten weiterhin basierend auf den Beziehungen Ihres Kontos.

## Token-Format

Alle Account-Token beginnen mit dem `glsa_` Präfix gefolgt von einer zufälligen Hex-Zeichenfolge. Dieses Präfix macht es einfach, Glossia-Token in Logs und Secret-Scannern zu identifizieren.

## Bereiche

Account-Token unterstützen dieselben Bereiche wie OAuth-Token. Siehe den [Bereiche-Referenz](/docs/reference/apis/authentication) für die vollständige Liste.

Beim Erstellen eines Tokens wählen Sie nur die Berechtigungen aus, die Ihren Anwendungszweck benötigen. Zum Beispiel:

- Eine Read-Only-Integration benötigt `project:read` und `voice:read`.
- Eine CI-Pipeline, die Projekte erstellt, benötigt `project:read` und `project:write`.
- Ein Skript, das Mitglieder einer Organisation verwaltet, benötigt `members:read` und `members:write`.

## Tokens verwalten

### Tokens anzeigen

Die **Account-Token** Seite listet alle aktiven Token mit ihren Namen, ihren Bereichen, dem Datum der letzten Nutzung und dem Ablauf auf. Token, die noch nie genutzt wurden, zeigen "Niemals" in der Spalte der letzten Nutzung an.

### Tokens bearbeiten

Klicken Sie auf den Namen eines Tokens, um dessen **Name** und **Beschreibung**. Scopes und Ablaufdatum können nach der Erstellung nicht geändert werden. Wenn Sie andere Scopes benötigen, erstellen Sie einen neuen Token und widerrufen Sie den alten.

### Tokens widerrufen

Um einen Token zu widerrufen, klicken **Widerrufen** auf der Token-Liste oder öffnen Sie die Bearbeitungsseite des Tokens und verwenden Sie den **Token widerrufen** Button in der Gefahrenzone. Widerrufene Token funktionieren sofort nicht mehr und können nicht wiederhergestellt werden.

## Beste Sicherheitspraktiken

- **Speichern Sie Tokens sicher.** Verwenden Sie Umgebungsvariablen oder einen Secrets Manager. Speichern Sie Tokens niemals in der Versionskontrolle.
- **Verwenden Sie kurzlebige Token.** Stellen Sie ein Ablaufdatum ein, wenn möglich.
- **Minimieren Sie die Bereiche.** Gewähren Sie nur die Berechtigungen, die das Token wirklich benötigt.
- **Rotieren Sie Tokens regelmäßig.** Erstellen Sie neue Tokens und widerrufen Sie alte Tokens nach Zeitplan.
- **Überwachen Sie die Nutzung.** Überprüfen Sie das Datum der "letzten Nutzung" regelmäßig. Widerrufen Sie Tokens, die nicht mehr verwendet werden.
- **Verwenden Sie pro Integration ein Token.** Auf diese Weise unterbricht das Widerrufen eines Tokens keine anderen Workflows.

## API-Verwaltung

Sie können auch Account-Tokens über die REST-API und den MCP-Server verwalten.

### REST-API

| Methode | Endpunkt | Beschreibung |
|--------|----------|-------------|
| `GET` | `/api/tokens` | Aktive Token auflisten |
| `POST` | `/api/tokens` | Ein neues Token erstellen |
| `DELETE` | `/api/tokens/:id` | Ein Token widerrufen |

### MCP

Der MCP-Server bietet `list_tokens`, `create_token`, und `revoke_token` Werkzeuge, die die REST API abbilden.