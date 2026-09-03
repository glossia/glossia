%{
  title: "Account-Token",
  summary: "Erstellen und Verwalten von Account-Token zur Authentifizierung mit der Glossia API.",
  category: "Referenz",
  subcategory: "APIs",
  order: 2
}
---
Account-Tokens bieten einen einfachen Weg, API-Anfragen zu authentifizieren, ohne den vollständigen OAuth-Flow zu durchlaufen. Sie sind ideal für Skripte, CI/CD-Pipelines und persönliche Automatisierung.

## Token erstellen

1. Melden Sie sich bei Glossia an und navigieren Sie zu Ihrem Account-Dashboard.
2. Öffnen Sie den **API** Abschnitt aus der Seitenleiste.
3. Klicken Sie **Account-Tokens**, dann **Neues Token**.
4. Geben Sie dem Token einen beschreibenden **Namen** (beispielsweise "CI-Bereitstellung" oder "CLI-Zugriff").
5. Wählen Sie die **Bereiche** das Token benötigt. Gewähren Sie nur die minimal erforderlichen Berechtigungen.
6. Legen Sie ein **Ablaufdatum** oder lassen Sie es leer für ein Token, das niemals abläuft.
7. Klicken **Token erstellen**.

Nach der Erstellung wird der vollständige Token-Wert angezeigt. **einmal**. Kopieren Sie ihn sofort und speichern Sie ihn sicher. Sie werden den vollständigen Wert nicht wieder einsehen können.

## Verwendung eines Tokens

Fügen Sie den Token in den `Authorization` Header Ihrer HTTP-Anfragen:

    Authorization: Bearer glsa_abc123def456...

Beispielsweise verwenden `curl`:

```bash
curl -H "Authorization: Bearer glsa_abc123def456..." \
  https://glossia.ai/api/projects
```

Account-Tokens folgen demselben [Autorisierungsmodell](/docs/reference/apis/authentication) als OAuth-Token. Die Token-Bereiche definieren die maximalen Aktionen, die es ausführen kann, und Richtlinien auf Ressourcenebene gelten weiterhin basierend auf den Beziehungen Ihres Kontos.

## Token-Format

Alle Kontotoken beginnen mit dem `glsa_` Prefix, gefolgt von einem zufälligen Hex-String. Dieser Prefix erleichtert die Identifizierung von Glossia-Token in Logs und Secret Scannern.

## Bereiche

Kontotoken unterstützen die gleichen Bereiche wie OAuth-Token. Siehe die [Bereiche-Referenz](/docs/reference/apis/authentication) für die vollständige Liste.

Bei der Erstellung eines Tokens wählen Sie nur die Bereiche aus, die Ihr Anwendungsfall benötigt. Zum Beispiel:

- Eine schreibgeschützte Integration benötigt `project:read` und `voice:read`.
- Eine CI-Pipeline, die Projekte erstellt, benötigt `project:read` und `project:write`.
- Ein Script, das Organisationsmitglieder verwaltet, benötigt `members:read` und `members:write`.

## Token verwalten

### Token ansehen

Die **Konto-Token** Seite listet alle aktiven Token mit deren Namen, Berechtigungen, letztem Nutzungsdatum und Ablaufdatum auf. Token, die noch nie verwendet wurden, zeigen "Niemals" in der Spalte für letzte Nutzung.

### Tokens bearbeiten

Klicken Sie auf den Namen eines Tokens, um dessen **Namen** und **die Beschreibung**. Bereiche und Laufzeit können nach der Erstellung nicht geändert werden. Wenn Sie andere Bereiche benötigen, erstellen Sie einen neuen Token und widerrufen Sie den alten.

### Tokens widerrufen

Um einen Token zu widerrufen, klicken Sie **Widerrufen** in der Tokenliste oder öffnen Sie die Bearbeitungsseite des Tokens und verwenden Sie die **Token widerrufen** Schaltfläche im Warnbereich. Widerrufene Tokens funktionieren sofort nicht mehr und können nicht wiederhergestellt werden.

## Beste Sicherheitspraktiken

- **Bewahren Sie Tokens sicher auf.** Verwenden Sie Umgebungsvariablen oder einen Secrets Manager. Vermeiden Sie das Speichern von Tokens in der Versionskontrolle.
- **Verwenden Sie kurzlebige Tokens.** Legen Sie ein Ablaufdatum fest, falls möglich.
- **Minimieren Sie die Scopes.** Erteilen Sie nur die Berechtigungen, die das Token tatsächlich benötigt.
- **Rotieren Sie regelmäßig.** Erstellen Sie neue Tokens und widerrufen Sie die alten nach Zeitplan.
- **Überwachen Sie die Token-Nutzung.** Überprüfen Sie das Datum "Zuletzt verwendet" regelmäßig. Widerrufen Sie Tokens, die nicht mehr genutzt werden.
- **Verwenden Sie ein Token pro Integration.** Auf diese Weise beeinträchtigt das Widerrufen eines Tokens keine anderen Arbeitsabläufe.

## API-Verwaltung

Sie können auch Account-Tokens über die REST API und den MCP-Server verwalten.

### REST API

| Methode | Endpunkt | Beschreibung |
|--------|----------|-------------|
| `GET` | `/api/tokens` | Aktive Tokene auflisten |
| `POST` | `/api/tokens` | Einen neuen Token erstellen |
| `DELETE` | `/api/tokens/:id` | Ein Token widerrufen |

### MCP

Der MCP-Server bietet `list_tokens`, `create_token`, und `revoke_token` Werkzeuge, die die REST-API abbilden.