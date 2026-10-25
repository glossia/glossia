%{
  title: "Mobile- und Begleit-API",
  summary:
    "Native-Design, Profil, Übersetzungsaktivität, Analysen und private Toki-Konversationen.",
  category: "Referenz",
  subcategory: "APIs",
  order: 4
}
---

Alle Endpunkte außer dem öffentlichen nativen Aussehen-Katalog erfordern einen Bearer-Token. Die [OpenAPI-Spezifikation](/api/openapi.json) beschreibt die vollständigen Schemata. Erhalten Sie Tokens über den bestehenden [OAuth PKCE-Fluss](/docs/reference/apis/authentication). Verwenden Sie niemals einen Inferenz-Provider-Schlüssel in einem Client.

## Autorisierung

| Endpoint | Token-Bereich |
|---|---|
| `GET /api/native/themes` | Keine (öffentliche Erscheinungsbild-Metadaten) |
| `GET /api/me` | `user:read` |
| `GET /api/:handle/projects/:project/translations` | `translation:read` |
| `GET /api/:handle/projects/:project/translations/:id` | `translation:read` |
| `GET /api/:handle/projects/:project/analytics` | `analytics:read` |
| `GET /api/:handle/projects/:project/toki/conversations` | `toki:read` |
| `POST /api/:handle/projects/:project/toki/conversations` | `toki:write` |
| `GET /api/:handle/projects/:project/toki/conversations/:id` | `toki:read` |
| `POST /api/:handle/projects/:project/toki/conversations/:id/messages` | `toki:write` |

Token-Bereiche sind ein Deckel, keine Gewährung. Jedes Projekten-Endpunkt prüft ebenfalls die project-read-Zugelassenheit des Benutzers. Eine zweite `project:read` **Token** Bereich ist nicht erforderlich, sondern eine Organisationsmitgliedschaft mit expliziten Berechtigungen muss sowohl Projektlektüre als auch die angeforderte Fähigkeit zulassen. Neue Mitgliedschaften umfassen diese Mobilfähigkeiten; bestehende explizite Mitgliedschaften werden nicht automatisch erweitert.

Persönliche Projekte folgen den bestehenden Regeln für persönliche Organisationsmitglieder. Kontosichtbarkeit steuert die öffentlichen Projektlektüren; eine authentisierte Außenstehende mit dem erforderlichen Bereich kann die Übersetzungsaktivität und Analysen eines öffentlichen Projekts lesen. Toki-Schreiben erfordern eine Kontozugehörigkeit, sodass alleinige öffentliche Sichtbarkeit keine Inferenzguthaben eines Kontos ausgibt. Toki-Gespräche bleiben innerhalb des Projekts für deren erstellenden Benutzer privat, selbst bei öffentlichen Konten. Organisations- und Plattformadministratoren können kein Gespräch eines anderen Benutzers lesen. Das Wissen über eine Gesprächs-UUID gewährt keinen Zugriff.

## Natives Erscheinungsbild

`GET /api/native/themes` gibt landschaftsquale Erscheinungsbild-Metadaten aus dem ausgewählten Glossia-Server zurück, ohne Authentifizierung oder Benutzer-/Projektdaten. Die Antworten enthalten `Cache-Control: public, max-age=300`. Dies ändert die Autorisierung für jedes Projekt-Endpoint nicht.

Die Antwort hat vier erforderliche Felder:

| Feld | Wert |
|---|---|
| `schema_version` | Integer `1` |
| `revision` | Nicht-leere Inhaltsrevision, maximal 128 Zeichen |
| `default_theme_id` | `"glossia"` |
| `themes` | Array, das das Standard-Glossia-Thema enthält |

Das Standardthema verfügt über `id: "glossia"`, `name: "Glossia"`, eine nicht-leere `description`, `typography: "standard"`, `button_radius: 8`, `card_radius: 12` und `light` und `dark`-Paletten. Radien sind numerische logische Pixel. Jede Palette enthält alle neun unten所列 Felder, ausgedrückt als undurchsichtige `#RRGGBB` Farben:

| Paletten-Feld | Hell | Dunkel |
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

Der Katalog wird aus den kanonischen `:root`-Farb- und Radius-Token in `app/priv/static/assets/styles.css` kompiliert. Das Neuaufbauen nach einem Token-Änderung aktualisiert den Katalog und seine deterministische Revision. Die Revision deckt Kataloginhalt ab, nicht unzusammenhängende Stylesheet-Änderungen. Es sind keine benutzerspezifischen Vorlieben oder Laufzeit-Theme-Konfigurationen enthalten.

## Profil

`GET /api/me` gibt nur das Profil des authentisierten Benutzers zurück:

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

`name` kann `null` sein." Das Handle gehört zur persönlichen Konto des Benutzers, nicht zur ausgewählten Organisation. `server_version` ist die Version der laufenden Anwendung.

## Paginierung

Übersetzungs- und Gesprächslisten akzeptieren `page` (Standardwert `1`, Reichweite `1–10000`) und `page_size` (Standardwert `20`, Reichweite `1–50`). Ungültige Werte geben `400` statt leisem Nachnutzen wider.

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

Listen spiegeln den aktuellen Zustand, keinen eingefrorenen Momentabbild wider. Gesprächsreihenfolge wird zuerst nach dem jüngsten Aktualisiert sortiert, wobei die UUID als deterministischer Entscheid.

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

Statusse sind `pending`, `running`, `completed`, `failed` oder `cancelled`. Commit-Nachricht, Quell-Sprache und Zusammenfassung können `null` sein, während Arbeit ausstehend ist oder nicht verfügbar ist. Ergebnisse sind neuester zuerst und auf das angesprochene Projekt beschränkt.

`GET /api/:handle/projects/:project/translations/:id` gibt `{session: {...}, progress: {...}}` zurück. Das `session` hat genau die Listen-Sitzungsfelder plus optional `commit_sha`, unverändert. `progress` wird aus langlebigen Ereignissen neu erstellt, unter Verwendung des gleichen Elixir-Fortschritt-Reduktors wie das Web-Dashboard. Dies ist eine direkte, exakte UUID-Suche innerhalb des angesprochenen Projekts und Kontos, unabhängig von Paginierung oder dem Alter der Sitzung. Fehlformatierte, fehlende und fremd-Projekt-IDs geben `404` mit `error: "not_found"` zurück; Authentifizierung und Projektautorisierung laufen zuerst ab (`401`/`403`). Das Öffnen dieser Ressource erstellt niemals ein Gespräch, sendet keine Nachricht oder startet eine Inferenz. Es bietet **Provenienz auf Sitzungsebene** und pro-Datei-Fortschritt, nicht übersetzter Segmente-Text oder eine Überprüfung von übersetzter Ausgabe.

### Echtes Live-Fortschritt

Öffnen Sie einen persistenten Phoenix WebSocket bei `/native/socket/websocket?vsn=2.0.0` (`wss` auf HTTPS-Servern). Longpoll ist deaktiviert. Senden Sie das Zugangs-Token nur durch den WebSocket-Subprotokoll-Header, niemals über Abfrageparameter:

```text
Sec-WebSocket-Protocol: phoenix,base64url.bearer.phx.<base64url-no-padding-of-access-token>
```

Der Server verhandelt `phoenix`. Verbinden Sie das Topic `translation:<session UUID>` mit `{"organization":"account-handle","project":"project-handle"}`. Der Organisationswert entspricht demselben Kontohandle, der vom HTTP-API verwendet wird, einschließlich persönlicher Konten. Die Join-Antwort und jedes `snapshot`-Event enthalten die gleiche vollständige Projektion wie das HTTP-Detail:

```json
{
  "session": {
    "id": "e4183cef-2b43-42a8-a60f-78b4fbb02bbf",
    "status": "running",
    "commit_message": "Update installation guide",
    "commit_sha": "abc123",
    "source_language": "en",
    "target_languages": ["es"],
    "translated_content_count": 0,
    "inserted_at": "2026-10-25T10:00:00Z",
    "summary": null
  },
  "progress": {
    "seq": 3,
    "summary": {
      "total": 2, "checked": 2, "needs_translation": 2, "assessed?": true,
      "skipped": 0, "done": 0, "failed": 0, "cancelled": 0, "running": 1, "queued": 1,
      "glossary": {"applied_ids": [], "shadowed_ids": [], "files_with_applied": 0, "files_with_shadowed": 0}
    },
    "items": [
      {"index": 0, "output_path": "es/guide.md", "locale": "es", "status": "running", "turns": 1, "file_ref": null},
      {"index": 1, "output_path": "es/faq.md", "locale": "es", "status": "queued", "turns": 0, "file_ref": null}
    ],
    "omitted_items": 0
  }
}
```

`seq` ist die persistente Fortschrittssequenz, **nicht** eine eindeutige Snapshot-Version. Sitzungsstatus- und Veröffentlichungs-Änderungen und Live-Modell-Aufrufzählungen können einen neuen Snapshot mit derselben Sequenz erzeugen; ersetzen Sie die vorherige Projektion, auch wenn `seq` unverändert bleibt. Status pro Datei sind `queued`, `running`, `done`, `failed` und `cancelled`. Pfade, Lokale und Datei-Referenzen können `null` sein, bevor sie bekannt sind. Eine unberührte Sitzung hat eine Sequenz von 0, leere Elemente und 0-Zählwerte. Die Zusammenfassung deckt **alle** Dateien ab, auch wenn Elemente ausgelassen werden. Die Glossar-Identifikatoren/Zählwerte der Zusammenfassung sind das Aggregat des Web-Reducers, nicht die Provider-Metadaten.

Maximal 500 Artikel in der geplanten-Index-Reihenfolge werden berücksichtigt, mit einem kombinierten Encode-Artikel-Budget von 512.000 Bytes. Ein Artikel, der nicht passt, wird ausgelassen, und `omitted_items` zählt jede Zeile, die durch entweder Grenzwert ausgeschlossen ist. Roh-übersetzter Ausgabe, Stream-Text, Denken, private Provider-Payloads und rohe Fehlerdetails werden niemals enthalten. Live öffentliche Modell-Anruf-Zahlen können sich nach Neukonnektion oder Abgleich zurücksetzen; Beständige End-Zahlen und Datei-Zustände werden rekonstruiert. Volle nativ Snapshots sind auf 1.000.000 encodierte JSON-Bytes begrenzt. Wenn unveränderte Sitzungsmetadaten oder die vollständige Zusammenfassung allein das Limit überschreiten, die Verbindung versagt mit `{"reason":"payload_too_large"}`; ein bestehender Kanal erhält `error` mit diesem Grund und schließt sich anstelle den Senden eines übermäßigen Rahmens oder das Leise Abschneiden von Provenienz.

Der Server abonniert den bestehenden cross-node Session PubSub **bevor** das persistente Vorangsefix liest, faltet den Live-Schwanz mit Sequenz-Entdublizierung und konsolidiert Fortschritts- /Status- /Veröffentlichung-Benachrichtigungen in vollständige Snapshots bei etwa 100 ms. Kein pro-Kunden-HTTP-Rating oder runner-lokalen Zustand ist erforderlich. Alle fünf Sekunden erneuert es die Autorisierung und baut den persistenten Status neu auf, um verpasste Benachrichtigungen zu reparieren. Neuverbinden und neu beitreten nach Vordergrund oder Transportunterbrechung; die Join-Projektion ist ausreichend, ohne Deltas wiederzugeben. Folgen Sie dem normalen Phoenix-Puls-Lebenszyklus während der Verbindung und verlassen Sie das Thema, wenn Sie es nicht mehr anzeigen.

Der gegenwärtige persistente Token-Bereiterung, Gültigkeit/Aufhebung, Benutzer, `translation:read` Token-Bereich, Richtlinienberechtigungen, Projekt-Sichtbarkeit und exakte Konten-/Projekt-/Sitzung-Zuordnung werden bei Join und vor jedem Snapshot geprüft. Fehlenden Bereich oder Richtlinienberechtigung gibt zurück `{"reason":"forbidden"}`; fehlender Ressource gibt zurück `{"reason":"not_found"}`; absichtlich oder aufgekündigte Authentifizierung gibt zurück `{"reason":"sign_in_required"}`. Nach erfolgreichem Join emittiert Abweisung `access_revoked` mit diesem Grund und schließt den Kanal sofort ohne anderen Snapshot. Erneuerung erkennt auch Aufhebung auf inaktiven Kanälen. Bei `sign_in_required`, aktualisieren /Re-Authentifizieren und erstelle eine neue Verbindung; bei anderen Abweisungen, stoppen Sie das Anzeigen des geschützten Details. WebSockets sind ein Vordergrund Live-Update-Mechanismus, keine Garantie der Lieferung während die mobile App pausiert ist.

## Analytik

`GET /api/:handle/projects/:project/analytics?days=30` gibt summarische Metriken zurück, bis zu zehn Top-Seiten und die Traffic-Logistik-Time-Serie. Ein leeres Projekt gibt zurück:

```json
{
  "summary": {
    "pageviews": 0,
    "unique_visitors": 0,
    "locale_gap_visits": 0,
    "top_country": "",
    "top_browser_language": ""
  },
  "top_pages": [],
  "traffic": {"granularity": "day", "points": []},
  "days": 30
}
```

`days` standardmäßig `30` und muss eine Ganzzahl von `1` bis `365` sein. Das gleitende UTC-Berichtsfenster endet zur Anfragezeit. Diese sind die gleichen projektbezogenen ClickHouse-Aggregate wie das Dashboard, einschließlich seiner alltagsrotierenden Besucher-Identifikatoren. Speicherfehler geben zurück `503` mit `error: "analytics_unavailable"`

`traffic.granularity` ist `"hour"` für Fenster bis zwei Tage, `"day"` für Fenster bis 90 Tage, und `"month"` ansonsten. `traffic.points` ist chronologisch. Jeder Punkt enthält ein UTC-Bucket-Start-Zeitstempel und nichtnegative Anzahl-Zahlen:

```json
{"bucket": "2026-10-25T00:00:00Z", "pageviews": 420, "unique_visitors": 280}
```

Anzahlen umfassen nur Ereignisse in dem angeforderten Berichtsfenster, sodass die ersten und letzten Buckels unvollständig sein können. Wenn Ereignisse bestehen, werden Stille-Buckets in diesem Fenster mit Null-Anzahlen gewählt. Wenn keine Ereignisse bestehen, ist `points` leer statt eines synthetischen Flach-Trend. `unique_visitors` zählt eindeutige Identifikatoren **innerhalb jeden Buckles**; summieren dieses Vulkan-Werte ist nicht die Periode einzigartigen Besucher-Anzahl. Benutzen Sie `summary.unique_visitors` für diese Alumium. Klient sollten die zurückgegebenen Buckels unverändert darstellen statt von summarischen Metriken einen Trend rekonstruieren.

## Toki-Konversationen

### Erstellen und Listen

`POST /api/:handle/projects/:project/toki/conversations` akzeptiert ein client-generiertes UUID:

```json
{"id": "52a3b55c-c2db-4b3f-a83f-d7d3542ae46b"}
```

Es gibt `201` mit `{conversation, messages: []}` zurück. Leere Konversationen haben Titel `New conversation` und Status `completed` (inaktiv, nicht generierend). Das Abspielen desselben UUID für denselben Akteur, Projekt und Ursprung gibt das vorhandene Detail zurück ohne eine weitere Konversation erstellen. Wiederverwenden für einen anderen Akteur, Projekt oder Ursprung gibt `409` mit `error: "id_conflict"` zurück.

`GET /api/:handle/projects/:project/toki/conversations` zurück `{conversations: [...], meta: {...}}`. Eine Konversation enthält `id`, `title`, `status`, `updated_at`, Nullable `error`, und Nullable `translation_session_id`. Titel wird aus dem ersten Benutzer-Nachricht abgeleitet, nicht aus einer zweiten Modell-Aufruf.

### Übersetzungsursprung

Erstellung akzeptiert optional eine Übersetzungssitzung UUID vom gleichen Projekt:

```json
{
  "id": "52a3b55c-c2db-4b3f-a83f-d7d3542ae46b",
  "translation_session_id": "e4183cef-2b43-42a8-a60f-78b4fbb02bbf"
}
```

Der Ursprung ist unendlich; Auslassung und `null` bedeuten beide keinen Ursprung. Ein Retry muss denselben Ursprung beliefern, einschließlich nach dem Senden von Nachrichten. Sie können keinen Ursprung später anfügen oder mit einem Retry entfernen. Ein ungeschickter Ursprung gibt zurück `422`; eine fehlende oder ausländische Projekt-Ursprung gibt zurück `404`. Source-verknüpft Erstellung benötigt zusätzlich `translation:read` Token-Bereich und aktuelle Richtlinien-Berechtigung, zusammen mit `toki:write` und Projekt-Lese-Berechtigung. Client-bereitgestellte Ursprung-Zusammenfassungen, Metadaten, Rollen und Besitz werden ignoriert. Nur das UUID wird berechnet; der Server löst seinen autorisierten Kontext zur Antwort-Zeit.

**Source-verknüpft Konversationen versagen geschlossen**, statt bloß den UUID zu redigieren: ohne aktuellen `translation:read` Bereich oder Richtlinie-Berechtigung, Detail, matching-origin create replay, Nachricht senden, und Nachricht replay gibt zurück `403`. Ein mismatched Ursprung gibt immer noch `409` zurück, ohne Geschichte oder Ursprung-Metadaten schreibt zurück. Listen lassen die ganze source-verknüpfte Konversation aus, einschließlich seines Titels und bei Paginierungs-Anzahl-Beitrag. Dies schützt frühere Assistenten-Nachrichten, die den Ursprung erwähnen könnten. Fehlende Bereiche schließen die normale `WWW-Authenticate`-Herausforderung ein. Unverknüpfte Konversationen behalten ihr bestehendes Toki-only Autorisierungsverhalten.

Gelöscht oder versetzte Ursprünge auch versagen geschlossen: source-verknüpfe Detail, Sends, und matching create retries geben `404` zurück, und Listen lassen die Konversation aus. Der unendliche UUID bleibt nach Ursprung-Löschung gespeichert, sodass ein Retry nicht stillschweigend unverknüpft werden kann. Der Referenz hat keine kaskadierende fremde Schlüssel; jede Benutzung prüft aktuelle Ursprung-Existenz und seine genaue Projekt/Konto. Keine Ursprung-Referenz erteilt Zugang oder ändert eine Stimme, Glossar, oder gemeinsamer Kontext.

Erstellen oder Öffnen einer source-verknüpften Konversation sendet **nicht** eine Nachricht oder schloss Inferenz an. Native Navigation sollte die Übersetzungsdetail zuerst holen; nur eine explizite Benutzer-Aktion sollte die Konversation erstellen, und eine getrennte explizite Nachricht-Übermittlung startet eine Wende. Keine Vorschlag-Veröffentlichung, gemeinsame Diskussionsprüfung oder Agent Schreib-Tools werden bereitgestellt.

### Senden und abfragen

`POST /api/:handle/projects/:project/toki/conversations/:id/messages` akzeptiert einen separaten client-generierten **Nachricht** UUID:

```json
{"id": "17c3b189-80f0-4382-b7bb-1305b1db70ad", "content": "Which translations have completed?"}
```

Die Anfrage persistert die Benutzer-Nachricht und eine Oban-Arbeit in einer Datenbank-Transaktion. Es ruft kein Modell an. Es gibt `202` mit Konversationsstatus `queued` und den aktuellen Nachrichten zurück. Poll `GET /api/:handle/projects/:project/toki/conversations/:id` während Status ist `queued` oder `running`; stoppen auf `completed` oder `failed`.

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

Nachrichten haben Rolle `user` oder `assistant` und sind chronologisch. Eine Konversation hält maximal 100 Nachrichten, sodass das Detail-Endpoint seine gesamte beschränkte Geschichte zurückgibt ohne eine zusätzliche Seitenanfrage.

Ein Wiederspielen einer Nachrichten-UUID mit identischem Inhalt plant niemals eine weitere Inferenz, einschließlich nach Abschluss oder Fehlschlag. Eine abgeschlossene Wiedergabe gibt `200` zurück; eine ausstehende Wiedergabe gibt `202` zurück. Die Wiederverwendung einer UUID mit anderem Inhalt oder in einer anderen Konversation gibt `409` zurück. Eine andere während einer aktiven Wende eingereichte Nachricht gibt `409` mit `error: "conversation_busy"` zurück.

### Modell-Verhalten und Grenzen

- Jede Benutzer-Nachricht ist nicht-leerer Text, maximal 8.000 Zeichen und 32.000 UTF-8-Byte. Ungültige UUIDs, Typen oder Inhalte geben `422` zurück.
- Jeder Benutzer kann maximal 100 Gespräche pro Projekt und fünf in Warteschlange/labende Gespräche über alle Projekte hinweg halten. Mehr als fünf ausstehende Wendungen gibt `429` zurück; Gesprächs/Geschichte-Grenzen geben `422` zurück.
- Neue Nachrichten sind auf 30 pro Stunde pro Benutzer pro Server begrenzt, zusätzlich zu normalen API-Ratenbeschränkungen. Wiedergaben verbrauchen kein Inferenz-Quotum.
- Die dedizierte Oban-Warteschlange führt pro Server zwei Jobs parallel aus. Jede Wendung stellt maximal eine Anbieter-HTTP-Anfrage: ReqLLM bereitet die Anbieter-Anfrage vor, dann führt der Oban-Worker sie synchron aus mit HTTP-Wiederholungen und Umlenkungen deaktiviert nach Anbieter-Anbindung. Keine Condukt-Sitzung, getrennte Inferenz-Aufgabe, Werkzeuge, Sub-Agenten oder Dateisystem-Instruktionslading ist beteiligt. Der Anbieter erhält ein 2.048-Ausgabeton-Dach; Assistent-Antworten sind ebenfalls auf 8.000 Zeichen und 32.000 Byte begrenzt.
- HTTP-Verbindungs- und Pool-Wartezeiten sind auf fünf Sekunden und Sockets-Empfangswartezeiten auf 60 Sekunden begrenzt. Der Oban-Worker hat eine harte 90-Sekunden-Wanduhr-Frist, einschließlich tropfender Antworten. Arbeitsautertermination beendet auch seine lokale Inferenz-Umsetzung. Trennung kann keine Stornierung von Berechnungen gewährleisten, die bereits von einem remoter Provider akzeptiert wurden, sodass mehrdeutige Fehler niemals automatisch wiederholt werden.
- Das Modell erhält begrenztes Projekt-Metadaten und maximal drei kürzeste Übersetzungszusammenfassungen, wenn sowohl Token als auch aktuelle Mitgliedschaft `translation:read` erlauben. Die letzten zehn Gesprächs-Auszüge sind unabhängig vom Speicher begrenzt. Es hat keine Schreib-Fähigkeiten oder allgemeinen Repositorium-Zugriff, und keine Analysen werden dem Modell zur Verfügung gestellt.
- Bei einer Ursprungs-verknüpften Konversation erhält das Modell zusätzlich die genaue persistente Quelle, selbst wenn sie nicht aktuell ist: UUID, Status, Commit-Metadaten, Sprachen, Zählung und maximal 1.000 Zusammenfassungs-Charaktere. Kontext ist `provenance: "session_summary"` markiert, und die Aufforderung erfordert das Melden dieser Zusammenfassungsebene-Beschränkung. Kein Segment-Text, Repositorium-Dateien oder bei-Anbieter-Quelle-Kontext wird geladen.
- Anmeldeinformationen werden über das existierende generative Modell und die Server-Inferenz-Konfiguration des Kontos gelöst. Interaktive CLI/OAuth-Sitzungen werden für Toki nicht verwendet. Fehlende oder nicht unterstützte Anmeldeinformationen produzieren Status `failed` mit `error: "provider_unavailable"`.
- Provider-Fehler produzieren `inference_failed`; leerer oder übergroßer Output erzeugt `invalid_provider_response`. Roh-Provider-Fehler und Geheimnisse werden nicht zurückgegeben. Keine synthetische Assistentenantwort wird bei Fehlschlag eingefügt.
- Konto/Projekt-Zugang und Ursprungs-Existenz, Projekt/Konto-Verbindung und Übersetzungs-autorisierung werden vor und nach Inferenz erneut geprüft. Entzogener Zugang oder unzureichende gewartete Bereiche füllt die Wendung mit `not_authorized`; eine gelöschte oder verschobene Quelle versagt mit `source_unavailable`. Keine Assistentenantwort wird bei beiden Fehlschlägen persistent gespeichert.
- Ein Wiederherstellungs-Job läuft jede Minute und markiert laufende Arbeit älter als zwei Minuten oder gewartete Arbeit älter als 15 Minuten als `failed` mit `inference_interrupted`. Dies führt über Fällung, obsolut und verwaiste Jobs ohne Inferenzwiederholung ab. Ein verzögerter Job kann eine abgelaufene Nachricht nicht beanspruchen oder eine neuere Wendung überschreiben. Ein Benutzer kann absichtlich eine **neue** Nachrichten-UUID nach einem Fehlschlag senden.

## Fehler

`401` bedeutet Authentifizierung fehlgeschlagen. `403` bedeutet der Geltungsbereich oder Ressourcenpolitik verweigerten Zugang; fehlende Bereiche enthalten eine `WWW-Authenticate` Herausforderung. Unbekannte Projekte und fremd/private Gespräch-UUIDs geben `404` zurück. Validierung verwendet `422`, Paginierung verwendet `400`, UUID/Bes affairs Konfliktzuteilungen verwenden `409`, und Kontingent-Erschöpfung verwendet `429`.
