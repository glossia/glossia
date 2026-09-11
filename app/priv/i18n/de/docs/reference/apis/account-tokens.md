%{
  title: "Account-Tokene",
  summary: "Erstellen und Verwalten von Account-Token zur Authentifizierung mit der Glossia API.",
  category: "Referenz",
  subcategory: "APIs",
  order: 2
}
---
Kontotoken bieten einen einfachen Weg, API-Anfragen zu authentifizieren, ohne den vollständigen OAuth-Workflow durchlaufen zu müssen. Sie eignen sich ideal für Skripte, CI/CD-Pipelines und persönliche Automatisierung.

## Token erstellen

1. Melden Sie sich bei Glossia an und navigieren Sie zu Ihrem Kontodashboard.
2. Öffnen Sie die **API** Sektion in der Seitenleiste.
3. Klicken Sie **Kontotoken**, dann **Neuer Token**.
4. Geben Sie dem Token einen aussagekräftigen **Name** (beispielsweise "CI deploy" oder "CLI access").
5. Wählen Sie die **Bereiche** die der Token benötigt. Gewähren Sie nur die erforderlichen Mindestberechtigungen.
6. Legen Sie ein **Ablaufdatum** oder lassen Sie es leer für einen Token, der nie abläuft.
7. Klicken **Token erstellen**.

Nach der Erstellung wird der vollständige Token-Wert angezeigt. **einmal**. Kopieren Sie es sofort und speichern Sie es sicher. Sie werden den vollen Wert nicht mehr sehen können.

## Token verwenden

Fügen Sie das Token in den `Authorization` Header Ihrer HTTP-Anfragen:

    Authorization: Bearer glsa_abc123def456...

Zum Beispiel, mit `curl`:

```bash
curl -H "Authorization: Bearer glsa_abc123def456..." \
  https://glossia.ai/api/projects
```

Konto-Token folgen demselben [Autorisierungsmodell](/docs/reference/apis/authentication) als OAuth-Tokens. Die Berechtigungen des Tokens definieren den maximalen Satz an Aktionen, die er ausführen kann, und Richtlinien auf Ressourcenlevel-Richtlinien gelten weiterhin basierend auf den Beziehungen Ihres Kontos.

## Token-Format

Alle Kontotoken beginnen mit dem `glsa_` Präfix gefolgt von einer zufälligen Hex-Zeichenfolge. Dieses Präfix erleichtert die Identifizierung von Glossia-Token in Protokollen und Secret-Scannern.

## Berechtigungen

Kontotoken unterstützen die gleichen Berechtigungen wie OAuth-Tokens. Siehe die [Berechtigungsreferenz](/docs/reference/apis/authentication) für die vollständige Liste.

Beim Erstellen eines Tokens wählen Sie nur die Scopes aus, die Ihr Anwendungsfall benötigt. Zum Beispiel:

- Eine schreibgeschützte Integration benötigt `project:read` und `voice:read`.
- Eine CI-Pipeline, die Projekte erstellt, benötigt `project:read` und `project:write`.
- Ein Skript, das Organisationsmitglieder verwaltet, benötigt `members:read` und `members:write`.

## Token verwalten

### Token ansehen

Die **Account-Token** Seite listet alle aktiven Token mit Name, Bereichen, Datum der letzten Nutzung und Ablaufdatum auf. Token, die noch nie verwendet wurden, zeigen "Nie" in der Spalte "Zuletzt verwendet".

### Token bearbeiten

Klicken Sie auf den Token-Namen, um dessen **Namen** und **Beschreibung**. Bereiche und Ablauf können nach der Erstellung nicht geändert werden. Wenn Sie verschiedene Bereiche benötigen, erstellen Sie ein neues Token und widerrufen Sie das alte.

### Token widerrufen

Um ein Token zu widerrufen, klicken **Widerrufen** auf der Tokenliste oder öffnen Sie die Bearbeitungsseite des Tokens und verwenden Sie die **Token widerrufen** Schaltfläche in der Gefahrenzone. Widerrufene Tokens funktionieren sofort nicht mehr und können nicht wiederhergestellt werden.

## Sicherheitsempfehlungen

- **Speichern Sie Tokens sicher.** Verwenden Sie Umgebungsvariablen oder einen Secrets-Manager. Laden Sie Token niemals in die Versionskontrolle hoch.
- **Verwenden Sie kurzlebige Tokens.** Legen Sie ein Ablaufdatum fest, wann immer möglich.
- **Minimieren Sie die Berechtigungsbereiche.** Gewähren Sie nur die Berechtigungen, die dem Token tatsächlich benötigt werden.
- **Rotieren Sie Token regelmäßig.** Erstellen Sie neue Token und widerrufen Sie alte Token nach einem Zeitplan.
- **Überwachen Sie die Nutzung.** Prüfen Sie das Datum "zuletzt verwendet" regelmäßig. Widerrufen Sie Token, die nicht mehr genutzt werden.
- **Verwenden Sie ein Token pro Integration.** Auf diese Weise beeinträchtigt das Widerrufen eines Tokens andere Workflows nicht.

## API-Management

Sie können auch Kontotoken über die REST API und den MCP-Server verwalten.

### REST API

| Methode | Endpunkt | Beschreibung |
|--------|----------|-------------|
| `GET` | `/api/tokens` | Aktive Tokens auflisten |
| `POST` | `/api/tokens` | Neuen Token erstellen |
| `DELETE` | `/api/tokens/:id` | Token widerrufen |

### MCP

Der MCP-Server bietet `list_tokens`, `create_token`, und `revoke_token` Werkzeuge, die die REST-API spiegeln.