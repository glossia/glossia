%{
  title: "Account-Tokens",
  summary:
    "Erstellen und Verwalten von Account-Tokens zur Authentifizierung mit der Glossia-API.",
  category: "Referenz",
  subcategory: "APIs",
  order: 3
}
---
Account-Tokens bieten einen einfachen Weg, API-Anfragen zu authentifizieren, ohne den vollständigen OAuth-Flow durchlaufen zu müssen. Sie sind ideal für Skripte, CI/CD-Pipelines und die persönliche Automatisierung.

## Token erstellen

1. Melden Sie sich bei Glossia an und navigieren Sie zu Ihrem Account-Dashboard.
2. Öffnen Sie den **API** Abschnitt in der Seitenleiste.
3. Klicken Sie **Account-Tokens**, dann **Neuer Token**.
4. Gib dem Token einen beschreibenden **Name** (zum Beispiel, "CI deploy" oder "CLI access")
5. Wähle die **Bereiche** die der Token benötigt. Weisen Sie nur die minimal erforderlichen Berechtigungen zu.
6. Stellen Sie ein **Ablaufdatum** oder lassen Sie es leer für einen Token, der niemals abläuft.
7. Klicken Sie **Token erstellen**.

Nach der Erstellung wird der vollständige Token-Wert angezeigt. **einmal**. Kopieren Sie es unverzüglich und speichern Sie es sicher. Sie werden den vollständigen Wert nie wieder sehen können.

## Verwendung eines Tokens

Fügen Sie das Token in das `Authorization` Header Ihrer HTTP-Anfragen:

    Authorization: Bearer glsa_abc123def456...

Beispielsweise mit `curl`:

```bash
curl -H "Authorization: Bearer glsa_abc123def456..." \
  https://glossia.ai/api/projects
```

Konto-Tokens folgen demselben [Autorisierungsmodell](/docs/reference/apis/authorization) als OAuth-Token. Die Token-Berechtigungen definieren den maximalen Satz an Aktionen, die es ausführen kann, und Richtlinien auf Ressourcenebene gelten weiterhin basierend auf den Beziehungen Ihres Kontos.

## Token-Format

Alle Konto-Token beginnen mit dem `glsa_` Präfix gefolgt von einer zufälligen Hex-Zeichenfolge. Dieses Präfix erleichtert die Identifizierung von Glossia-Token in Logs und Secret-Scannern.

## Berechtigungen

Konto-Token unterstützen dieselben Berechtigungen wie OAuth-Token. Siehe die [Berechtigungsreferenz](/docs/reference/apis/authorization) für die vollständige Liste.

Beim Erstellen eines Tokens wählen Sie nur die Bereiche aus, die Ihr Szenario benötigt. Zum Beispiel:

- Eine Read-only-Integration benötigt `project:read` und `voice:read`.
- Eine CI-Pipeline, die Projekte erstellt, benötigt `project:read` und `project:write`.
- Ein Skript, das Mitglieder einer Organisation verwaltet, benötigt `members:read` und `members:write`.

## Tokens verwalten

### Tokens anzeigen

Die **Konto-Token** Seite listet alle aktiven Token mit ihrem Namen, ihren Bereichen, dem Datum der letzten Nutzung und dem Ablaufdatum auf. Token, die noch nie verwendet wurden, zeigen "Nie" in der Spalte "Letzte Nutzung" an.

### Token bearbeiten

Klicken Sie auf den Namen eines Tokens, um dessen **Namen** und **Beschreibung**. Berechtigungen und Ablaufdatum können nach der Erstellung nicht geändert werden. Wenn Sie andere Berechtigungen benötigen, erstellen Sie einen neuen Token und widerrufen Sie den alten.

### Token widerrufen

Um einen Token zu widerrufen, klicken Sie **Widerrufen** in der Token-Liste oder öffnen Sie die Bearbeitungsseite des Tokens und verwenden Sie die **Token widerrufen** Schaltfläche im Warnbereich. Widerrufene Tokens werden sofort unwirksam und können nicht wiederhergestellt werden.

## Beste Sicherheitspraktiken

- **Speichern Sie Tokens sicher.** Verwenden Sie Umgebungsvariablen oder einen Secrets Manager. Fügen Sie Tokens niemals in die Versionskontrolle ein.
- **Verwenden Sie kurzlebige Tokens.** Legen Sie ein Ablaufdatum fest, sofern möglich.
- **Minimieren Sie die Scopes.** Gewähren Sie nur die Berechtigungen, die der Token tatsächlich benötigt.
- **Rotieren Sie Token regelmäßig.** Erstellen Sie neue Tokens und widerrufen Sie alte Token nach Zeitplan.
- **Überwachen Sie die Nutzung.** Prüfen Sie das Datum \\"letzter Verwendung\\" regelmäßig. Widerrufen Sie Token, die nicht mehr genutzt werden.
- **Verwenden Sie ein Token pro Integration.** Auf diese Weise beeinträchtigt die Widerrufung eines Tokens keine anderen Arbeitsabläufe.

## API-Verwaltung

Sie können Kontoken auch über die REST API und den MCP-Server verwalten.

### REST API

| Methode | Endpunkt | Beschreibung |
|--------|----------|-------------|
| `GET` | `/api/tokens` | Aktive Token auflisten |
| `POST` | `/api/tokens` | Neues Token erstellen |
| `DELETE` | `/api/tokens/:id` | Token widerrufen |

### MCP

Der MCP-Server stellt bereit `list_tokens`, `create_token`, und `revoke_token` Werkzeuge, die die REST API abbilden.