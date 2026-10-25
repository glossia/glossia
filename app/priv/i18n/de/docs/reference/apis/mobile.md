%{
  title: "Mobil- und Companion-API",
  summary:
    "Natives Aussehen, Profil, Übersetzungsaktivität, Analytik und private Toki-Gespräche.",
  category: "Referenz",
  subcategory: "APIs",
  order: 4
}
---

Alle Endpunkte außer das öffentliche native appearance catalog benötigen einen Bearer-Token. Die [OpenAPI specification](/api/openapi.json) beschreibt die vollständigen Schemas. Holen Sie sich Tokens durch den bestehenden [OAuth PKCE flow](/docs/reference/apis/authentication). Verpacken Sie niemals einen Inference-Provider-Key in einem Client.

## Autorisierung / Authentifizierung

| Endpunkt | Token-Scope |
|---|---|
| `GET /api/native/themes` | Kein (öffentliche Erscheinungs-Metadaten) |
| `GET /api/me` | `user:read` |
| `GET /api/:handle/projects/:project/translations` | `translation:read` |
| `GET /api/:handle/projects/:project/translations/:id` | `translation:read` |
| `GET /api/:handle/projects/:project/analytics` | `analytics:read` |
| `GET /api/:handle/projects/:project/toki/conversations` | `toki:read` |
| `POST /api/:handle/projects/:project/toki/conversations` | `toki:write` |
| `GET /api/:handle/projects/:project/toki/conversations/:id` | `toki:read` |
| `POST /api/:handle/projects/:project/toki/conversations/:id/messages` | `toki:write` |

Token-Scope sind ein Maximum, keine Gewährung. Jeder Projekt-Endpunkt prüft zusätzlich die Projekt-Lese-Berechtigung des Benutzers. Ein zweiter `project:read` **token** Scope ist nicht erforderlich, aber ein Organisations-Mitglied mit expliziten Berechtigungen muss sowohl Projekt-Lesezugriff als auch die angeforderte Fähigkeit erlauben. Neue Mitgliedschaften umfassen diese mobilen Fähigkeiten; bestehende explizite Mitgliedschaften werden nicht automatisch erweitert.

Private Projekte folgen den bestehenden persönlichen-Organisations-Mitgliedschaftsregeln. Kontosichtbarkeit steuert öffentliche Projekt-Lesezugriffe; ein authentifizierter Außenstehender mit dem erforderlichen Scope kann Übersetzungsaktivität und Analysen eines öffentlichen Projekts lesen. Toki-Schreiben erfordern Kontozugehörigkeit, so dass alleinige öffentliche Sichtbarkeit nicht die Inference-Credits eines Kontos verbraucht. Toki-Gespräche bleiben privat für ihren erstellenden Benutzer innerhalb ihres Projekts, sogar auf öffentlichen Konten. Organisations- und Plattform-Administratoren können kein Gespräch eines anderen Benutzers lesen. Das Wissen über einen Gesprächs-UUID gewährt keinen Zugriff.

## Native-Erscheinungsbild

`GET /api/native/themes` liefert projektwiden appearances-Metadaten vom ausgewählten Glossia-Server, ohne Authentifizierung oder Benutzer/Projekt-Daten. Antworten beinhalten `Cache-Control: public, max-age=300`. Dies ändert die Autorisierung für keinen Projekt-Endpunkt.

Die Antwort hat vier erforderliche Felder:

| Feld | Wert |
|---|---|
| `schema_version` | Integer `1` |
| `revision` | Unblan-erkonten-Revision, maximal 128 Zeichen |
| `default_theme_id` | `"glossia"` |
| `themes` | Array enthält das Standard-Glossia-Theme |

Das Standard-Theme hat `id: "glossia"`, `name: "Glossia"`, eine unblan-erkente `description`, `typography: "standard"`, `button_radius: 8`, `card_radius: 12` und `light` und `dark` Paletten. Radien sind numerische logische Pixel. Jede Palette enthält alle unten aufgeführten neun Felder, ausgedrückt als opake `#RRGGBB` Farben:

| Palette-Feld | Hell | Dunkel |
|---|---|---|
| `background` | `#FAF8F5` | `#1C1917` |
| `surface` | `#FFFFFF` | `#2A2621` |
| `subtle` | `#F2EFE9` | `#2A2621` |
| `text` | `#1C1917` | `#FAF8F5` |
| `secondary_text` | `#5C564E` | `#D1CDC5` |
| `border` | `#E4E0D9` | `#3D3833` |
| `accent` | `#6D3CC4` | `#D0BCFF` |
| `on_accent` | `#FFFFFF` | `#381E72` |
| `tint` | `#6D3CC4` | `#D0BCFF` |

Der Katalog wird aus den kanonischen `:root`-Farb- und Radius-Token in `app/priv/static/assets/styles.css` kompiliert. Die dunkle Palette verwendet nur nativen semantischen Token und ändert die Webbol精緻ung nicht. Neubildung nach einem Token-Änderung aktualisiert den Katalog und dessen deterministische Revision. Die Revision erfasst Kataloginhalt, keine unbeteiligten Stylesheet-Änderungen. Keine Benutzervorlieben oder Laufzeit-Theme-Konfiguration sind enthalten.

## Profil

`GET /api/me` gibt zurück nur das Profil des authentifizierten Benutzers:

```json
{
  "user": {
    "id": "30c92fe9-4477-4ba6-ae0a-0d874f9ff650",
    "name": "Alex Chen",
    "email": "alex@example.com",
    "handle": "alex"
  },
  "server_version": "0.1.0"
}
```

`name` kann `null` sein. Das Handle gehört zum persönlichen Konto des Benutzers, nicht zur ausgewählten Organisation. `server_version` ist die Version der laufenden Anwendung.

## Paginierung

Übersetzungs- und Gesprächslisten akzeptieren `page` (Standard `1`, Bereich `1–10000`) und `page_size` (Standard `20`, Bereich `1–50`). Ungültige Werte kehren `400` zurück, statt dies stumm zu begrenzen. Metadaten verwenden die gleiche Struktur wie andere Glossia-API-Listen:

```json
{
  "total_count": 23,
  "total_pages": 2,
  "current_page": 1,
  "page_size": 20,
  "has_next_page?": true,
  "has_previous_page?": false
}
```

Listen spiegeln den aktuellen Zustand wider, nicht einen eingefrorenen Snapshot. Die Gesprächsreihenfolge spiegelt das zuletzt geupdatede Datum voran, wobei die UUID als deterministischer Tiebreaker dient.

## Übersetzungsaktivität

`GET /api/:handle/projects/:project/translations?page=1` gibt zurück:

```json
{
  "sessions": [{
    "id": "e4183cef-2b43-42a8-a60f-78b4fbb02bbf",
    "status": "completed",
    "commit_message": "Update installation guide",
    "source_language": "en",
    "target_languages": ["es", "ja"],
    "translated_content_count": 8,
    "inserted_at": "2026-10-25T10:00:00Z",
    "summary": "Translated eight documents."
  }],
  "meta": {"total_count": 1, "total_pages": 1, "current_page": 1, "page_size": 20, "has_next_page?": false, "has_previous_page?": false}
}
```

Zustände sind `pending`, `running`, `completed`, `failed` oder `cancelled`. Commit-Nachricht, Ursprungssprache und Zusammenfassung können `null` sein, während die Arbeit pendet oder diese nicht verfügbar ist. Ergebnisse sind von Neuesten zuerst und auf das angesprochene Projekt beschränkt.

`GET /api/:handle/projects/:project/translations/:id` gibt `{session: {...}}` mit exakt den Liste-Sessions-Feldern sowie optionalen `commit_sha` zurück. Dies ist eine direkte, exakte UUID-Nachschlüssung innerhalb des angesprochenen Projekts und Kontos, unabhängig von Paginierung oder dem Alter der Sitzung. Defektes, fehlendes und fremdprojekt-IDs kehren `404` mit `error: "not_found"` zurück; Authentifizierung und Projekt-Autorisierung laufen zuerst (`401`/`403`). Öffnen dieses Ressourcen erstellt niemals eine Konversation, sendet keine Nachricht oder startet keine Inferenz. Es bietet **Sitzung-Zusammenfassungsebene-Herkunftsnachweis**, keinen übersetzten Segmenttext oder eine Überprüfung des übersetzten Outputs.

## Analytics

`GET /api/:handle/projects/:project/analytics?days=30` gibt zurück:

```json
{
  "summary": {
    "pageviews": 1350,
    "unique_visitors": 900,
    "locale_gap_visits": 180,
    "top_country": "DE",
    "top_browser_language": "de"
  },
  "top_pages": [{"pathname": "/docs", "pageviews": 420}],
  "days": 30
}
```

`days` standardisiert auf `30` und muss eine ganze Zahl von `1` bis `365` sein. Das rollierende UTC-Report-Fenster endet zum Zeitpunkt der Anforderung. Diese sind identischen projekt-begrenzten ClickHouse-Aggregationen wie das Dashboard, einschließlich seiner täglichen-rotierenden Besucher-Identifikatoren. Die Top-Pages-Liste enthält bis zu zehn Einträge. Leere Datensätze geben null-Zählungen zurück, leere Top-Wert-Strings und eine leere Seitenliste. Speicherausfälle kehren `503` mit `error: "analytics_unavailable"` zurück, niemals erfundene null-Metriken.

## Toki-Gespräche

### Erstellen und auflisten

`POST /api/:handle/projects/:project/toki/conversations` akzeptiert ein client-generiertes UUID:

```json
{"id": "52a3b55c-c2db-4b3f-a83f-d7d3542ae46b"}
```

Es gibt `201` mit `{conversation, messages: []}` zurück. Leere Gespräche haben Titel `New conversation` und Status `completed` (wartend, nicht generierend). Wiederholen derselben UUID für denselben Akteur, das Projekt und die Herkunft gibt das bestehende Detail zurück, ohne eine weitere Konversation zu erstellen. Wiederverwendung für einen anderen Akteur, Projekt oder Herkunft gibt `409` mit `error: "id_conflict"` zurück.

`GET /api/:handle/projects/:project/toki/conversations` gibt `{conversations: [...], meta: {...}}` zurück. Ein Gespräch enthält `id`, `title`, `status`, `updated_at`, optionalen `error` und optionalen `translation_session_id`. Titel leiten sich aus der ersten Benutzer-Nachricht ab, nicht aus einem zweiten Modellaufruf ab.

### Übersetzungsursprung

Die Erstellung akzeptiert optional ein Übersetzungssessions-UUID aus demselben Projekt:

```json
{
  "id": "52a3b55c-c2db-4b3f-a83f-d7d3542ae46b",
  "translation_session_id": "e4183cef-2b43-42a8-a60f-78b4fbb02bbf"
}
```

Der Ursprung ist unveränderbar; `null` und Unterlassen bedeuten keinen Ursprung. Eine Wiederholung muss den gleichen Ursprung bereitstellen, auch nach dem Senden von Nachrichten. Einen Ursprung später anhängen oder durch eine Wiederholung entfernen ist nicht möglich. Ein fehlerhafter Ursprung kehr `422` zurück; eine fehlende oder fremdprojektbezogene Quelle kehr `404` zurück. Quellverknüpftes Erstellen benötigt zusätzlich den `translation:read` Token-Scope und gleichzeitige policy-Berechtigung, neben `toki:write` und project-read permission. Client bereitgestellte Quell-Zusammenfassungen, Metadaten, Rollen und Eigentum werden ignoriert. Nur das UUID wird gespeichert; der Server löst seinen berechtigten Kontext zum Zeitpunkt der Antwort auf.

**Quellverknüpfte Konversationen schließen im Fehlerfall ab**, statt lediglich das UUID zu verdecken: Ohne aktuellen `translation:read` Scope oder Richtlinie permission kehren Detail, match-origin create replay, Nachrichtensendung und Nachrichtenwiedergabe `403` zurück. Ein nicht übereinstimmender Ursprung gilt auch `409` zurück, ohne Verlauf oder Quell-Metadaten zu liefern. Listen entwerfen die gesamte quellverknüpfte Konversation, einschliesslich ihres Titels und ihres Beitrags zu Paginierungsanzahl. Dies schützt frühere Assistentennachrichten, die die Quelle erwähnen könnten. Fehlende Scopes beinhalten die normale `WWW-Authenticate` Anforderung. Unverbundene Konversationen behalten ihr bestehendes Toki-only authorization behavior.

Gelöschte oder verschobene Quellen versagen ebenfalls abgeschlossener: Quellverknüpften Details, Sendungen und passenden create repeats kehr `404` zurück, und Listen entfernen die Konversation. Das unveränderliche UUID bleibt nach Quellentfernung gespeichert, damit eine Wiederholung nicht stumm unverwandt wird. Die Referenz hat keinen kaskadierenden Fremdschlüssel; jede Nutzung prüft die aktuelle Quell-Existenz und sein genaues Projekt/Konto. Keine Quellenreferenz gewährt Zugriff oder ändert eine Stimme, Glossar oder gemeinsame Kontext.

Erstellen oder Öffnen einer quellverknüpften Konversation kehr **nicht** verschwenden eine Nachricht oder Warteschlange-Inferenz. Native Navigation sollte den Übersetzungs-Details zuerst出勤; nur eine explizite Benutzeraktion sollte die Konversation erstellen, und eine getrennte explizite Nachrichtensegmentierung startet eine Runde. Keine Vorschlagsveröffentlichung, gemeinsame Diskussion oder Agent Schreibwerkzeuge bereitgestellt.

### Senden und Abfragen

`POST /api/:handle/projects/:project/toki/conversations/:id/messages` akzeptiert einen separaten client-generierten **Nachricht** UUID:

```json
{"id": "17c3b189-80f0-4382-b7bb-1305b1db70ad", "content": "Which translations have completed?"}
```

Die Anforderung persistentiert Benutzer-Nachricht und Oban-Job in einer einzigen Datenbank-Transaktion. Es rüft kein Modell auf. Es kehr `202` mit Konversationsstatus `queued` und aktuellen Nachrichten zurück. Abfragen `GET /api/:handle/projects/:project/toki/conversations/:id` solange Status `queued` oder `running` ist; hören auf `completed` oder `failed`.

Detail-Antworten haben diese Form:

```json
{
  "conversation": {
    "id": "52a3b55c-c2db-4b3f-a83f-d7d3542ae46b",
    "translation_session_id": null,
    "title": "Which translations have completed?",
    "status": "queued",
    "updated_at": "2026-10-25T10:00:00Z",
    "error": null
  },
  "messages": [{
    "id": "17c3b189-80f0-4382-b7bb-1305b1db70ad",
    "role": "user",
    "content": "Which translations have completed?",
    "inserted_at": "2026-10-25T10:00:00Z"
  }]
}
```

Nachrichten haben Rollen `user` oder `assistant` und sind chronologisch. Eine Konversation fasst maximal 100 Nachrichten, sodass das Detail-Endpunkt seinen gesamten begrenzten Verlauf zurückgibt, ohne eine zusätzliche Seitenanfrage.

Die Wiederspielen eines Nachricht-UUIDs mit identischem Inhalt wartet niemals weitere Inferenz an, einschließlich nach Abschluss oder Fehler. Eine hergestellte Wiedergabe kehr `200` zurück; eine ausstehende Wiedergabe kehr `202` zurück. Wiederverwendung eines UUIDs mit anderem Inhalt oder in einer anderen Konversation kehr `409` zurück. Eine andere während einer aktiven Runde übergebene Nachricht kehr `409` mit `error: "conversation_busy"` zurück.

### Modellverhalten und Grenzen

- Jede Benutzer-Nachricht ist nicht-leerer Text, maximal 8.000 Zeichen und 32.000 UTF-8 Bytes. Ungültige UUIDs, Typen oder Inhalte kehr `422` zurück.
- Jeder Benutzer kann maximal pro Projekt 100 Konversationen und fünf Warteschlangen/Laufende Konversationen über Projekte halten. Mehr als fünf ausstehenden Runden kehr `429` zurück; Konversation/Geschichts-Grenzen kehr `422` zurück.
- Neue Nachrichten sind auf 30 pro Stunde pro Benutzer pro Server begrenzt, zusätzlich zu normalen API-Rate-Limits. Wiedergaben verbrauchen kein Inferenz-Kontingent.
- Die dedizierte Oban-Warteschlange führt pro Server zwei Aufgaben gleichzeitig aus. Jede Runde macht maximal einen Provider HTTP-Anforderung: ReqLLM bereitet die Provider-Anforderung vor, dann führt der Oban-Worker sie synchron mit HTTP-Retrys und Redirects deaktiviert nach Provider-Anbindung aus. Keine Condukt-Sitzung, getrennte Inferenzaufgabe, Werkzeuge, Subagenten oder Dateisystem-Instruction-Ladung beteiligt. Der Provider erhält ein Deckel von 2.048 Output-Token; Assistentenantworten sind ebenfalls auf 8.000 Zeichen und 32.000 Bytes begrenzt.
- HTTP-Anschluss- und Pool-Warten sind auf fünf Sekunden begrenzt und Socket-Empfangswarten auf sechzig Sekunden. Der Oban-Worker hat eine 90-Sekunden-Hardwall-clock-Deadline inkl. Trickling-Responses. Worker-Terminierung terminiert auch seine lokale Inferenz-Ausführung. Trennen kann keine Absage von bereits von einem Remote-Provider angenommenen Berechnungen garantieren, so dass mehrdeutige Fehler niemals automatisch wiederholt werden.
- Das Modell erhält begrenzte Projekt-Metadaten und maximal drei kürzliche Übersetzungszusammenfassungen, wenn Token und aktuelle Mitgliedschaft `translation:read` erlauben. Die letzten zehn Gesprächsausgaben sind unabhängig von der Speicherung begrenzt. Es hat keine Schreibfähigkeiten oder allgemeinen Repository-Zugriff, und keine Analytics werden dem Modell bereitgestellt.
- Für eine quellverknüpfte Konversation erhält das Modell zusätzlich die genaue gespeicherte Quelle, auch wenn sie nicht aktuell ist: UUID, Status, Commit-Metadaten, Sprachen, Zählung und maximal 1.000 Zusammenfassungszeichen. Kontext ist markiert `provenance: "session_summary"` und Requires Prompt dieses Zusammenfassungsebene-Begrenzung zu berichten. Kein Segmenttext, Repository-Dateien oder Client-Quelle-Kontexte wurden geladen.
- Berechtigungen lösen sich über Konto's bestehenden generativen Modell und Server-Inferenz-Konfiguration. Interaktive CLI/OAuth-Sitzungen werden nicht für Toki verwendet. Fehlende oder ununterstützte Berechtigung generieren Status `failed` mit `error: "provider_unavailable"`.
- Provider-Fehler generieren `inference_failed`; Leeres oder überdimensioniertes Ausgabe generiert `invalid_provider_response`. Roh-Provider-Fehler und Geheimnisse werden nicht zurückgegeben. Kein synthetischer Assistentenantwort wird bei Fehler eingefügt.
- Konto/Projekt-Zugriff und Quellen-Existenz, Projekt/Konto-Assoziation und Übersetzungs-Autorisierung werden vor und nach Inferenz geprüft. Widerrufen Zugriff oder unzureichende Queue-Scope versagen die Runde mit `not_authorized`; gelöschte oder verschobene Quelle versagen mit `source_unavailable`. Kein Assistentenantwort wird bei beiden Fehlern persistiert.
- Ein Wiederherstellungs-Aufgabe läuft jede Minute und markiert laufende Arbeit älter als zwei Minuten, oder waitende Arbeit älter als fünfzehn Minuten, als `failed` mit `inference_interrupted`. Dies legt überfällige, terminierte und verwaiset Aufgaben ohne Inferenz-Wiederholung. Eine verzögerte Aufgabe kann eine abgelaufene Nachricht nicht beanspruchen oder eine neuere Ausführung überschreiben. Ein Nutzer kann bewusst nach einem Fehler einen **neuen** Nachrichten-UUID senden.

## Fehler

`401` bedeutet, dass Authentifizierung fehlgeschlagen ist. `403` bedeutet, dass der Scope oder die Ressourcenrichtlinien Zugriff verweigert haben; fehlende Scope enthalten eine `WWW-Authenticate`-Herausforderung. Unbekannte Projekte und fremde/private Konversations-UUIDs kehren `404` zurück. Validierung verwendet `422`, Paginierung verwendet `400`, UUID/besetzt-Konflikte verwenden `409`, und Kontingent-Abung verwendet `429`.
