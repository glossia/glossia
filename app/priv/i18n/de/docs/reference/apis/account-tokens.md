%{
  title: "Account-Tokens",
  summary:
    "Erstellen und Verwalten von Account-Tokens für die Authentifizierung mit der Glossia-API.",
  category: "Referenz",
  subcategory: "APIs",
  order: 2
}
---
Konto-Tokens bieten eine einfache Möglichkeit, API-Anfragen ohne den vollständigen OAuth-Flow zu authentifizieren. Sie eignen sich ideal für Skripte, CI/CD-Pipelines und persönliche Automatisierung.

## Token erstellen

1. Melden Sie sich bei Glossia an und navigieren Sie zu Ihrem Kontodashboard.
2. Öffnen Sie den **API** Abschnitt aus der Seitenleiste.
3. Klicken **Konto-Tokens**, dann **Neuer Token**,
4. Geben Sie dem Token einen aussagekräftigen **Namen** (zum Beispiel "CI deploy" oder "CLI access").
5. Wählen Sie die **Bereiche** was der Token benötigt. Gewähren Sie nur die minimal erforderlichen Berechtigungen.
6. Legen Sie ein **Ablaufdatum** oder lassen Sie es leer für einen Token, der nie abläuft.
7. Klicken **Token erstellen**.

Nach der Erstellung wird der vollständige Token-Wert angezeigt. **einmal**. Kopieren Sie es sofort und speichern Sie es sicher. Sie werden den vollständigen Wert nie wieder sehen können.

## Verwendung eines Tokens

Fügen Sie den Token in den `Authorization` Header Ihrer HTTP-Anfragen:

    Authorization: Bearer glsa_abc123def456...

Zum Beispiel bei der Verwendung von `curl`:

```bash
curl -H "Authorization: Bearer glsa_abc123def456..." \
  https://glossia.ai/api/projects
```

Konto-Tokens folgen demselben [Autorisierungsmodell](/docs/reference/apis/authentication) als OAuth-Tokens. Die Token-Bereiche definieren die maximale Menge an Aktionen, die es ausführen darf, und Ressourcen-Richtlinien gelten weiterhin basierend auf den Beziehungen Ihres Kontos.

## Token-Format

Alle Kontotoken beginnen mit dem `glsa_` ein Präfix gefolgt von einem zufälligen Hex-String. Dieses Präfix erleichtert die Identifizierung von Glossia-Tokens in Logs und Secret-Scannern.

## Bereiche

Kontotoken unterstützen dieselben Bereiche wie OAuth-Tokens. Siehe die [Bereiche-Referenz](/docs/reference/apis/authentication) für die vollständige Liste.

Beim Erstellen eines Tokens wählen Sie nur die Berechtigungen aus, die Ihr Anwendungszweck erfordert. Zum Beispiel:

- Eine read-only-Integration benötigt `project:read` und `voice:read`.
- Eine CI-Pipeline, die Projekte erstellt, benötigt `project:read` und `project:write`.
- Ein Skript, das Mitglieder einer Organisation verwaltet, benötigt `members:read` und `members:write`.

## Tokens verwalten

### Tokens einsehen

Die **Kontoken** Seite listet alle aktiven Tokens mit ihrem Namen, ihren Bereichen, dem Datum der letzten Nutzung und dem Ablaufdatum auf. Tokens, die noch nie verwendet wurden, zeigen den Wert "Nie" in der Spalte der letzten Nutzung an.

### Tokens bearbeiten

Klicken Sie auf den Namen eines Tokens, um dessen **Name** und **Beschreibung**. Bereiche und Ablaufzeit können nach der Erstellung nicht geändert werden. Wenn Sie andere Bereiche benötigen, erstellen Sie einen neuen Token und widerrufen Sie den alten.

### Tokens widerrufen

Um einen Token zu widerrufen, klicken Sie auf **Widerrufen** auf der Tokenliste oder öffnen Sie die Bearbeitungsseite des Tokens und verwenden Sie die **Token widerrufen** Schaltfläche im Gefahrenbereich. Widerrufene Token funktionieren sofort nicht mehr und können nicht wiederhergestellt werden.

## Beste Sicherheitspraktiken

- **Speichern Sie Token sicher.** Verwenden Sie Umgebungsvariablen oder einen Secrets Manager. Commiten Sie Token niemals in die Versionskontrolle.
- **Verwenden Sie kurzlebige Token.** Legen Sie bei jeder Möglichkeit ein Ablaufdatum fest.
- **Minimieren Sie die Scopes.** Gewähren Sie nur die Berechtigungen, die das Token tatsächlich benötigt.
- **Rotieren Sie regelmäßig.** Erstellen Sie neue Tokens und widerrufen Sie die alten auf Zeitplan.
- **Überwachen Sie die Nutzung.** Prüfen Sie das "letzte Nutzung" Datum regelmäßig. Widerrufen Sie Tokens, die nicht mehr genutzt werden.
- **Verwenden Sie ein Token pro Integration.** Auf diese Weise beeinträchtigt das Widerrufen eines Tokens keine anderen Workflows.

## API-Management

Sie können Account-Tokens zudem über die REST API und den MCP-Server verwalten.

### REST API

| Methode | Endpunkt | Beschreibung |
|--------|----------|-------------|
| `GET` | `/api/tokens` | Aktive Token auflisten |
| `POST` | `/api/tokens` | Neues Token erstellen |
| `DELETE` | `/api/tokens/:id` | Token widerrufen |

### MCP

Der MCP-Server bietet `list_tokens`, `create_token`, und `revoke_token` Werkzeuge, die die REST API widerspiegeln.