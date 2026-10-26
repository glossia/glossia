%{
  title: "Konto-Token",
  summary:
    "Erstellen und Verwalten von Konto-Token für die Authentifizierung mit der Glossia-API.",
  category: "Referenz",
  subcategory: "APIs",
  order: 3
}
---

Konto-Token bieten eine einfache Möglichkeit, API-Anfragen ohne den vollständigen OAuth-Workflow zu authentifizieren. Sie sind ideal für Skripte, CI/CD-Pipelines und persönliche Automatisierung.

## Erstellen eines Tokens

1. Melden Sie sich bei Glossia an und navigieren Sie zu Ihrem Konto-Dashboard.
2. Öffnen Sie den Abschnitt **API** aus der Seitenleiste.
3. Klicken Sie auf **Konto-Token**, dann auf **Neues Token**.
4. Geben Sie dem Token einen beschreibenden **Namen** (beispielsweise "CI deploy" oder "CLI access").
5. Wählen Sie die **Bereiche** aus, die der Token benötigt. Gewähren Sie nur die minimal erforderlichen Berechtigungen.
6. Legen Sie ein **Ablaufdatum** fest oder lassen Sie es leer für ein Token, das nicht abläuft.
7. Klicken Sie auf **Token erstellen**.

Nach der Erstellung wird der vollständige Token-Wert **einmal** angezeigt. Kopieren Sie ihn sofort und speichern Sie ihn sicher. Sie werden den vollständigen Wert nicht mehr sehen können.

## Nutzung eines Tokens

Fügen Sie das Token in den `Authorization`-Header Ihrer HTTP-Anfragen ein:

```
Authorization: Bearer glsa_abc123def456...
```

Beispielsweise mit `curl`:

```bash
curl -H "Authorization: Bearer glsa_abc123def456..." \
  https://glossia.ai/api/projects
```

Konto-Token folgen demselben [Authentifizierungsmodell](/docs/reference/apis/authorization) wie OAuth-Token. Die Bereiche des Tokens definieren die maximale Menge an Aktionen, die dieser ausführen kann, und Ressourcenbezogene Richtlinien gelten weiterhin basierend auf den Beziehungen Ihres Kontos.

## Token-Format

Alle Konto-Token beginnen mit dem `glsa_`-Präfix gefolgt von einer zufälligen Hexadezimalzeichenkette. Dieses Präfix erleichtert die Identifizierung von Glossia-Token in Protokollen und Geheimnisscannern.

## Bereiche

Konto-Token unterstützen die gleichen Bereiche wie OAuth-Token. Siehe die [Referenz zu den Bereichen](/docs/reference/apis/authorization) für die vollständige Liste.

Wählen Sie beim Erstellen eines Tokens nur die Bereiche aus, die Ihr Anwendungsfall benötigt. Beispielsweise:

- Eine Read-only-Integration benötigt `project:read` und `voice:read`.
- Eine CI-Pipeline, die Projekte erstellt, benötigt `project:read` und `project:write`.
- Ein Skript, das Mitglieder der Organisation verwaltet, benötigt `members:read` und `members:write`.

## Verwalten von Tokens

### Anzeigen von Tokens

Die **Konto-Token**-Seite listet alle aktiven Tokens mit ihrem Namen, ihren Bereichen, dem Datum der letzten Nutzung und dem Ablaufdatum auf. Tokens, die noch nie verwendet wurden, zeigen "Nie" in der Spalte der letzten Nutzung an.

### Bearbeiten von Tokens

Klicken Sie auf den Namen eines Tokens, um dessen **Name** und **Beschreibung** zu bearbeiten. Bereiche und Ablaufdatum können nach der Erstellung nicht geändert werden. Wenn Sie andere Bereiche benötigen, erstellen Sie ein neues Token und widerrufen Sie das alte.

### Widerrufen von Tokens

Um ein Token zu widerrufen, klicken Sie auf **Widerrufen** in der Token-Liste oder öffnen Sie die Bearbeitungsseite des Tokens und verwenden Sie den **Token widerrufen**-Button im Gefahrenbereich. Widerrufene Tokens hören sofort auf zu funktionieren und können nicht wiederhergestellt werden.

## Sicherheitsbest Practices

- **Speichern Sie Token sicher.** Verwenden Sie Umgebungsvariablen oder einen Secrets-Manager. Stellen Sie sicher, dass Token niemals in die Versionskontrolle kommittet sind.
- **Verwenden Sie kurzlebig Token.** Legen Sie ein Ablaufdatum fest, wann immer möglich.
- **Minimieren Sie Bereiche.** Gewähren Sie nur die Berechtigungen, die der Token tatsächlich benötigt.
- **Rotieren Sie Token regelmäßig.** Erstellen Sie neue Token und widerrufen Sie alte nach einem Zeitplan.
- **Überwachen Sie die Nutzung.** Prüfen Sie das Datum der "letzten Nutzung" regelmäßig. Widerrufen Sie Token, die nicht mehr verwendet werden.
- **Verwenden Sie pro Integration nur ein Token.** Auf diese Weise verhindert das Widerrufen eines Tokens nicht die anderen Workflows.

## API-Verwaltung

Sie können Konto-Token auch durch das REST API und den MCP-Server verwalten.

### REST API

| Methode | Endpunkt | Beschreibung |
|--------|----------|-------------|
| `GET` | `/api/tokens` | Aktive Tokens auflisten |
| `POST` | `/api/tokens` | Neuen Token erstellen |
| `DELETE` | `/api/tokens/:id` | Token widerrufen |

### MCP

Der MCP-Server stellt `list_tokens`, `create_token` und `revoke_token` Werkzeuge bereit, die das REST API widerspiegeln.
