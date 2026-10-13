%{
  title: "Account-Token",
  summary: "Account-Token erstellen und verwalten zur Authentifizierung mit der Glossia API.",
  category: "Referenz",
  subcategory: "APIs",
  order: 3
}
---

Kontotoken bieten einen einfachen Weg, API-Anfragen zu authentifizieren, ohne den vollständigen OAuth-Workflow zu durchlaufen. Sie sind ideal für Skripte, CI/CD-Pipelines und persönliche Automatisierung.

## Erstellen eines Tokens

1. Melden Sie sich bei Glossia an und navigieren Sie zu Ihrem Kontodashboard.
2. Öffnen Sie den **API**-Bereich in der Seitenleiste.
3. Klicken Sie auf **Kontotoken**, dann auf **Neuen Token**.
4. Geben Sie dem Token einen beschreibenden **Name** an (zum Beispiel "CI deploy" oder "CLI access").
5. Wählen Sie die **Bereiche** aus, die der Token benötigt. Erteilen Sie nur die minimal erforderlichen Berechtigungen.
6. Stellen Sie ein **Ablaufdatum** ein oder belassen Sie es leer für einen Token, der niemals abläuft.
7. Klicken Sie auf **Token erstellen**.

Nach der Erstellung wird der vollständige Token-Wert **einmal** angezeigt. Kopieren Sie ihn sofort und speichern Sie ihn sicher. Sie können den vollständigen Wert nicht mehr einsehen.

## Verwendung eines Tokens

Fügen Sie den Token im `Authorization`-Header Ihrer HTTP-Anfragen ein:

```
Authorization: Bearer glsa_abc123def456...
```

Zum Beispiel, mit `curl`:

```bash
curl -H "Authorization: Bearer glsa_abc123def456..." \
  https://glossia.ai/api/projects
```

Kontotoken folgen demselben [Berechtigungsmodell](/docs/reference/apis/authorization) wie OAuth-Token. Die Bereiche des Tokens definieren den maximalen Satz von Aktionen, die er ausführen kann, und Ressourcenersicherungsrichtlinien gelten weiter, basierend auf Beziehungen zu Ihrem Konto.

## Token-Format

Alle Kontotoken beginnen mit dem `glsa_`-Präfix gefolgt von einer zufälligen Hexadezimalziffernfolge. Dieses Präfix erleichtert die Identifizierung von Glossia-Tokens in Logs und Secrets-Scannern.

## Bereiche

Kontotoken unterstützen die gleichen Bereiche wie OAuth-Token. Siehe die [Bereiche-Referenz](/docs/reference/apis/authorization) für die vollständige Liste.

Beim Erstellen eines Tokens legen Sie nur die Bereiche fest, die Ihr Anwendungsfall benötigt. Beispielsweise:

- Eine schreibgeschützte Integration benötigt `project:read` und `voice:read`.
- Eine CI-Pipeline, die Projekte erstellt, benötigt `project:read` und `project:write`.
- Ein Skript, das Organisationsmitglieder verwaltet, benötigt `members:read` und `members:write`.

## Verwaltung von Tokens

### Anzeigen von Tokens

Die **Kontotoken**-Seite listet alle aktiven Tokens mit Namen, Bereichen, Datum der letzten Nutzung und Ablaufdatum auf. Tokens, die noch nie verwendet wurden, zeigen "Nie" in der Spalte "Letzte Nutzung" an.

### Bearbeiten von Tokens

Klicken Sie auf den Namen eines Tokens, um dessen **Name** und **Beschreibung** zu bearbeiten. Bereiche und Ablaufdatum können nach der Erstellung nicht geändert werden. Wenn Sie andere Bereiche benötigen, erstellen Sie einen neuen Token und widerrufen Sie den alten.

### Widerruf von Tokens

Um einen Token zu widerrufen, klicken Sie auf **Widerrufen** auf der Token-Liste oder öffnen Sie die Edit-Seite des Tokens und verwenden Sie den **Token widerrufen** -Button im Gefahrenbereich. Widerrufene Tokens funktionieren sofort nicht mehr und können nicht wiederhergestellt werden.

## Sicherheitsempfehlungen

- **Speichern Sie Tokens sicher.** Verwenden Sie Umgebungsvariablen oder einen Secrets Manager. Geben Sie Tokens niemals in Versionskontrollsysteme ein.
- **Verwenden Sie kurzlebige Tokens.** Stellen Sie ein Ablaufdatum so oft wie möglich ein.
- **Minimieren Sie Bereiche.** Erteilen Sie nur die Berechtigungen, die der Token tatsächlich benötigt.
- **Erneuern Sie regelmäßig.** Erstellen Sie neue Tokens und widerrufen Sie alte nach einem Zeitplan.
- **Überwachen Sie die Nutzung.** Prüfen Sie das Datum der "letzten Nutzung" regelmäßig. Widerrufen Sie Tokens, die nicht mehr genutzt werden.
- **Verwenden Sie pro Integration einen Token.** Auf diese Weise beeinträchtigt das Widerrufen eines Tokens andere Arbeitsabläufe nicht.

## API-Verwaltung

Methode

### REST-API

| Methode | Endpunkt | Beschreibung |
|--------|----------|-------------|
| `GET` | `/api/tokens` | Aktive Tokens auflisten |
| `POST` | `/api/tokens` | Neuen Token erstellen |
| `DELETE` | `/api/tokens/:id` | Token widerrufen |

### MCP

Der MCP-Server stellt `list_tokens`, `create_token` und `revoke_token`-Tools bereit, die die REST-API spiegeln.
