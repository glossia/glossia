%{
  title: "Konto-Token",
  summary: "Erstellen und Verwalten von Konto-Token zur Authentifizierung mit der Glossia-API.",
  category: "Referenz",
  subcategory: "APIs",
  order: 2
}
---
Account-Tokens bieten eine einfache Möglichkeit, API-Anfragen ohne den vollständigen OAuth-Workflow zu authentifizieren. Sie sind ideal für Skripte, CI/CD-Pipelines und persönliche Automatisierung.

## Token erstellen

1. Melden Sie sich bei Glossia an und navigieren Sie zu Ihrem Kontodashboard.
2. Öffnen Sie den **API** Abschnitt in der Seitenleiste.
3. Klicken Sie **Account-Token**$, dann **Neues Token**.
4. Geben Sie dem Token einen aussagekräftigen **Name** (beispielsweise \\"CI deploy\\" oder \\"CLI-Zugriff\\")
5. Wählen Sie die **Bereiche** die der Token benötigt. Erteilen Sie nur die minimal erforderlichen Berechtigungen.
6. Legen Sie ein **Ablaufdatum** oder lassen Sie es leer für einen Token, der nie abläuft.
7. Klicken **Token erstellen**.

Nach der Erstellung wird der vollständige Token-Wert angezeigt. **einmal**. Kopieren Sie es sofort und speichern Sie es sicher. Sie werden den vollständigen Wert nie wieder sehen können.

## Ein Token verwenden

Fügen Sie das Token in den `Authorization` Header Ihrer HTTP-Anfragen:

    Authorization: Bearer glsa_abc123def456...

Beispielsweise unter Verwendung von `curl`:

```bash
curl -H "Authorization: Bearer glsa_abc123def456..." \
  https://glossia.ai/api/projects
```

Konto-Tokens folgen dem gleichen [Autorisierungsmodell](/docs/reference/apis/authentication) als OAuth-Tokens. Die Token-Berechtigungen definieren den maximalen Satz von Aktionen, die es ausführen kann, und Richtlinien auf Ressourcenebene gelten weiterhin basierend auf den Beziehungen Ihres Kontos.

## Token-Format

Alle Kontotoken beginnen mit dem `glsa_` Präfix, gefolgt von einem zufälligen Hex-String. Dieses Präfix ermöglicht eine einfache Identifizierung von Glossia-Tokens in Logs und Secret-Scannern.

## Berechtigungen

Kontotoken unterstützen dieselben Berechtigungen wie OAuth-Tokens. Siehe die [Berechtigungsreferenz](/docs/reference/apis/authentication) für die vollständige Liste.

Beim Erstellen eines Tokens wählen Sie nur die Berechtigungen aus, die Ihr Anwendungszweck erfordert. Zum Beispiel:

- Eine schreibgeschützte Integration benötigt `project:read` und `voice:read`.
- Eine CI-Pipeline, die Projekte erstellt, benötigt `project:read` und `project:write`.
- Ein Skript, das Organisationsmitglieder verwaltet, benötigt `members:read` und `members:write`.

## Tokens verwalten

### Tokens anzeigen

Die **Account-Tokens** Seite listet alle aktiven Tokens mit ihrem Namen, ihren Berechtigungen, dem letzten Nutzungsdatum und dem Ablaufdatum auf. Tokens, die noch nie verwendet wurden, zeigen "Niemals" in der Spalte "Letzte Nutzung" an.

### Token bearbeiten

Klicken Sie den Namen eines Tokens, um dessen **Name** und **Beschreibung**. Berechtigungen und Ablaufzeit können nach der Erstellung nicht geändert werden. Wenn Sie andere Berechtigungen benötigen, erstellen Sie einen neuen Token und widerrufen Sie den alten.

### Token widerrufen

Um ein Token zu widerrufen, klicken **Widerrufen** in der Token-Liste oder öffnen Sie die Token-Bearbeitungsseite und verwenden Sie die **Token widerrufen** Schaltfläche im Gefahrenbereich. Widerrufene Tokens hören sofort auf zu funktionieren und können nicht wiederhergestellt werden.

## Beste Sicherheitspraktiken

- **Speichern Sie Tokens sicher.** Verwenden Sie Umgebungsvariablen oder einen Secrets Manager. Vermeiden Sie es, Tokens in die Versionskontrolle zu committen.
- **Verwenden Sie kurzlebige Tokens.** Legen Sie ein Ablaufdatum fest, wenn möglich.
- **Minimieren Sie die Scopes.** Gewähren Sie nur die Berechtigungen, die das Token tatsächlich benötigt.
- **Rotieren Sie Token regelmäßig.** Erstellen Sie neue Tokens und widerrufen Sie alte in regelmäßigen Abständen.
- **Überwachen Sie die Nutzung.** Prüfen Sie das Datum "Zuletzt verwendet" regelmäßig. Widerrufen Sie Token, die nicht mehr genutzt werden.
- **Verwenden Sie pro Integration ein Token.** Auf diese Weise beeinträchtigt der Widerruf eines Tokens andere Arbeitsabläufe nicht.

## API-Management

Sie können auch Account-Tokens über die REST API und den MCP-Server verwalten.

### REST API

| Methode | Endpunkt | Beschreibung |
|--------|----------|-------------|
| `GET` | `/api/tokens` | Aktive Tokens auflisten |
| `POST` | `/api/tokens` | Neuen Token erstellen |
| `DELETE` | `/api/tokens/:id` | Token widerrufen |

### MCP

Der MCP-Server bietet `list_tokens`, `create_token`, und `revoke_token` Werkzeuge, die die REST API abbilden.