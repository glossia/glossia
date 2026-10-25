%{
  title: "Mobile- und Begleit-API",
  summary:
    "Natives Erscheinungsbild, Profil, Übersetzungsaktivitäten, Analytik und private Toki-Gespräche.",
  category: "Referenz",
  subcategory: "APIs",
  order: 4
}
---

Alle Endpunkte außer dem öffentlichen nativen Erscheinungsbild-Katalog erfordern einen Bearer-Token. Die [OpenAPI-Spezifikation](/api/openapi.json) beschreibt die vollständigen Schemas. Besorgen Sie sich Tokens über das bestehende [OAuth PKCE-Verfahren](/docs/reference/apis/authentication). Verwenden Sie niemals einen Inferenzanbieterschlüssel in einem Client.

## Autorisierung

| Endpunkt | Token scope |
|---|---|
| `GET /api/native/themes` | Keine (öffentliches Erscheinungsbild-Metadaten) |
| `GET /api/me` | `user:read` |
| `GET /api/:handle/projects/:project/translations` | `translation:read` |
| `GET /api/:handle/projects/:project/translations/:id` | `translation:read` |
| `GET /api/:handle/projects/:project/analytics` | `analytics:read` |
| `GET /api/:handle/projects/:project/toki/conversations` | `toki:read` |
| `POST /api/:handle/projects/:project/toki/conversations` | `toki:write` |
| `GET /api/:handle/projects/:project/toki/conversations/:id` | `toki:read` |
| `POST /api/:handle/projects/:project/toki/conversations/:id/messages` | `toki:write` |

Token-Berechtigungen stellen eine Obergrenze, keine Gewährung. Jedes Projektenomdunkt prüft zudem die Projekt-Leseberechtigung des Benutzers. Ein zweiter `project:read` **Token**-Bereich ist nicht erforderlich, aber eine Organisationsmitgliedschaft mit expliziten Berechtigungen muss sowohl das Lesen des Projekts als auch die angeforderte Fähigkeit erlauben. Neue Mitgliedschaften umfassen diese mobilen Fähigkeiten; bestehende explizite Mitgliedschaften werden nicht automatisch ausgeweitet.

Private Projekte folgen den bestehenden Regeln für die persönliche Organisationsmitgliedschaft. Kontosichtbarkeit steuert das öffentliche Projektlesen; ein authentifizierter Externer mit dem erforderlichen Berechtigungsbereich kann die Übersetzungsaktivität und Analyse eines öffentlichen Projekts lesen. Toki-Schreibvorgänge erfordern Kontozugehörigkeit, sodass alleinige öffentliche Sichtbarkeit die Inferenzgutschriften eines Kontos nicht aufwendet. Toki-Gespräche bleiben innerhalb des Projekts für den Erstellbenutzenden privat, selbst bei öffentlichen Konten. Organisations- und Plattformadministratoren können nicht auf ein Gespräch eines anderen Benutzers zugreifen. Die Kenntnis einer Gesprächs-UUID gewährt keinen Zugriff.

## Natives Erscheinungsbild

`GET /api/native/themes` liefert instanzweit Erscheinungsbild-Metadaten vom ausgewählten Glossia-Server, ohne Authentifizierung oder Benutzer- oder Projektdaten. Antworten beinhalten `Cache-Control: public, max-age=300`. Dies ändert die Autorisierung für keine Projektenomdunkte.

Die Antwort hat vier erforderliche Felder:

| Feld | Wert |
|---|---|
| `schema_version` | Ganzzahl `1` |
| `revision` | Nicht-leerer Inhaltsüberarbeitung, höchstens 128 Zeichen |
| `default_theme_id` | `"glossia"` |
| `themes` | Array mit dem Standard-Glossia-Theme |

Das Standardthema hat `id: "glossia"`, `name: "Glossia"`, einen nicht-leeren `description`, `typography: "standard"`, `button_radius: 8`, `card_radius: 12`, sowie `light`- und `dark`-Paletten. Radien sind numerische logische Pixel. Jede Palette enthält alle neun untenstehenden Felder, ausgedrückt als undurchsichtige `#RRGGBB`-Farben:

| Palettenfeld | Helle | Dunkel |
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

Der Katalog wird aus den kanonischen `:root`-Farb- und -Radius-Token in `app/priv/static/assets/styles.css` kompiliert. Das dunkle Farbschema verwendet nur native semantische Token und ändert die Web-Darstellung nicht. Ein erneutes Aufbauen nach einer Token-Änderung aktualisiert den Katalog und seine deterministische Revision. Die Revision umfasst den Kataloginhalt, nicht unbezogene Stylesheet-Änderungen. Es werden keine Benutzerpräferenzen oder Laufzeit-Theme-Konfigurationen enthalten.

## Profil

`GET /api/me` gibt nur das Profil des authentifizierten Benutzers zurück:

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

`name` kann `null` sein. Das Handle gehört dem persönlichen Konto des Benutzers an, nicht der ausgewählten Organisation. `server_version` ist die Versionsnummer des laufenden Anwendungsprogramms.

## Paginierung

Übersetzungsver- und Gesprächslisten akzeptieren `page` (Standardwert `1`, Bereich `1–10000`) und `page_size` (Standardwert `20`, Bereich `1–50`). Ungültige Werte melden `400` statt es stumm auf einen Grenzwert festzulegen. Metadaten verwenden die gleiche Struktur wie andere Glossia-API-Listen:

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

Listen spiegeln den aktuellen Zustand wider, nicht ein eingefrorenes Snapshot. Die Gesprächsreihenfolge ist nach der kürzlichsten Aktualisierung zuerst mit UUID als deterministischem Displizantin.

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

Status sind `pending`, `running`, `completed`, `failed` oder `cancelled`. Commit-Nachricht, Quellsprache und Zusammenfassung können `null` sein, solange die Arbeit aussteht oder wenn unavailable. Ergebnisse sind neu zuerst und auf das angesprochene Projekt beschränkt.

`GET /api/:handle/projects/:project/translations/:id` gibt `{session: {...}, progress: {...}}` zurück. Das `session` hat genau die benannten Sitzungs Felder plus nullbar `commit_sha`, unverändert. `progress` wird aus dauerhaften Ereignissen unter Verwendung desselben Elixir Fortschrittsreduktors wie das Web-Dashboard neu aufgebaut. Dies ist eine direkte, exakte UUID-Auffassung innerhalb des angesprochenen Projekts und des Kontos, unabhängig von Paginierung oder dem Alter der Sitzung. Fehlerhafte, fehlende und fremdprojekten IDs melden `404` mit `error: "not_found"`; Authentifizierung und Projekt-Autorisierung laufen trotzdem zuerst (`401`/`403`). Das Öffnen dieses Ressourcen erstellt niemals ein Gespräch, sendet keine Nachricht oder startet Inferenz. Es liefert **Session-Zusammenfassung-Niveau-Provenienz** und pro-Datei Fortschritt, nicht übersetzter Segmenttext oder eine Prüfung des Übersetzungsoutputs.

### Natives Live-Fortschrittsmanagement

Öffnen Sie ein persistentes Phoenix WebSocket bei `/native/socket/websocket?vsn=2.0.0` (`wss` auf HTTPS-Servern). Longpoll ist deaktiviert. Senden Sie den Zugriffstoken nur durch den WebSocket Subprotokoll-Header, niemals durch Abfrageparameter:

```text
Sec-WebSocket-Protocol: phoenix,base64url.bearer.phx.<base64url-no-padding-of-access-token>
```

Der Server verhandelt `phoenix`. Verbinden Sie sich zum Thema `translation:<session UUID>` mit `{"organization":"account-handle","project":"project-handle"}`. Der Organisationswert ist das gleiche Konto-Handle, das vom HTTP-API verwendet wird, einschließlich persönlicher Konten. Die Verbindungsantwort und jedes `snapshot`-Ereignis tragen die gleiche vollständige Projektion wie HTTP-Details:

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

`seq` ist die dauerhafte Fortschrittssequenz, **nicht** eine einzigartige Snapshot-Version. Sitzungsstatus/Veröffentlichungsänderungen und Live-Modell-Nummerierung können eine neue Snapshot mit derselben Sequenz erzeugen; ersetzen Sie die vorherige Projektion, auch wenn `seq` unverändert ist. Status pro Datei sind `queued`, `running`, `done`, `failed` und `cancelled`. Pfade, Lokale, und Dateireferenzen können `null` sein, bevor sie bekannt sind. Ein unberührter Sitzungssatz hat Sequenz Null, leere Elemente und Null-Zählungen. Das Fazit deckt **alle** Dateien ab, auch wenn Elemente weggelassen werden. Die Id- / Zählungen des Fazit- Worters sind das Web-Aggregat des Reduktoren, nicht Anbieter-Metadaten.

Höchstens 500 Elemente in geplanter Indexreihenfolge werden mit einem kombinierten nachdotsitem-Budget von 512.000 Bytes enthalten. Ein Objekt, das nicht passt, wird weggelassen, und `omitted_items` zahlt alle Zeilen, die durch jede Begrenzung ausgeschlossen werden. Rohe Übersetzungsdaten, strömender Text, Denkprozesse, private Anbieter-Aktivlasten und rohe Fehlerdetails werden niemals enthalten. Livezahlen der öffentlich sichtbaren Modell-Nummerierung können nach Wiederanbinden oder Vereinigung zurücksetzen; dauerhafte Endanstreifungen und Dateizustände werden wiederhergestellt. Volle natives Snapshots sind auf 1.000.000 codierte JSON-Bytes begrenzt. Wenn unveränderte Sitzungsmetadaten oder das komplette Fazit allein diese Grenzeüber, versagt Beitritt mit `{"reason":"payload_too_large"}` oder ein bestehender Kanal empfangt `error` mit diesem Grund und schließt, anstatt einen überdimensionierten Rahmen zu senden oder die Provenienz schweigsam zu kürzen.

Der Server abonniert das existierende cross-node Session PubSub **bevor** das dauerhafte Präfix liest, faltet den live-Tail mit Sequenz-Deduplizierung und fusioniert Benachrichtigungen für Fortschritt/Status/Veröffentlichung in vollständige Snapshots bei ungefähr 100 ms. Per-Klient-HTTP-Abfragen oder runner-lokaler Zustand werden nicht benötigt. Alle fünf Sekunden erneuert es die Autorisierung und stellt den dauerhaften Zustand wieder her, um fehlgeschlagene Benachrichtigungen zu korrigieren. Nach Fokussierung oder einer Transportunterbrechung verbinden Sie sich neu und verbinden neuen Kanal; die Join-Projektion ist ausreichend ohne Deltas nachzuspielen. Folgen Sie dem normalen Phoenix Heartbeat-Lebenszyklus, solange verbunden, und verlassen Sie das Thema, wenn es nicht mehr angezeigt.

Der aktuelle persistente Token-Zugriff, Ablauf/Erhebungsverbot, Benutzer, `translation:read` Token-Bereich, Richtlinien-Berechtigungen, Projekt-Sichtbarkeit und genaue Konto/Projekt/Sitzungs-Assoziation werden beim Beitreten und vor jedem Snapshot geprüft. Fehlender Bereich oder Richtlinieberechtigung返回 `{"reason":"forbidden"}`; fehlende Ressource return `{"reason":"not_found"}`; abgelaufene/erhöhte Authentifizierung zurück `{"reason":"sign_in_required"}`. Nach erfolgreichem Beitritt sendet die Verweigerung anderen `access_revoked` mit diesem Grund und schließt den Kanal ohne weiteren Snapshot. Erneuerung erkennt auch Erwährung bei unbefrorenen Kanälen. Bei `sign_in_required` wiederherstellen/wiederauthentifizieren und neu verbinden; bei anderen Verweigerungen festhalten, das geschützte Detail anzeigen.

## Analytics

`GET /api/:handle/projects/:project/analytics?days=30` wiedergibt zusammengefasste Metriken, bis zu zehn Top-Seiten und die Verkehrszeitreihen. Ein leeres Projekt werte zurück:

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

`days` defaultiert auf `30` und muss eine Gesamt angle von `1` bis `365` sein. Die wachsend UTC-Berichtsfenster enden in Abfragerate. Das sind dieselben projekt-scope ClickHouse-Verallgemeinerungen wie das Dashboard, einschließlich des täglichen-rotierten Besucheridentifikatoren. Speicherfehler return `503` mit `error: "analytics_unavailable"`, niemals erfundene null-Metriken.

`traffic.granularity` ist `"hour"` für Fenster bis zu zwei Tage, `"day"` für Fenster bis zu neunzig Tagen und `"month"` sonst. `traffic.points` ist chronologisch. Jeder Punkt enthält ein UTC-Box-start-Timestamp und nicht-negative Ganzzahlzählungen:

```json
{"bucket": "2026-10-25T00:00:00Z", "pageviews": 420, "unique_visitors": 280}
```

Zählungen umfassen nur Ereignisse im angeforderten Berichtszeitfenster, sodass der erste und letzte Bucket partiell sein können. Wenn Ereignisse existieren, werden ruhige Buckets in diesem Fenster mit 0-Zählungen aufgenommen. Wenn keine Ereignisse existieren, ist `points` leer statt einer synthetischen, flachen Tendenz. `unique_visitors` zählt eindeutige Identifikatoren **innerhalb jedes Buckets**; die Summierung dieser Werte ergibt nicht die Anzahl der eindeutigen Besucher des Zeitraums. Verwenden Sie `summary.unique_visitors` für diese Summe. Clients sollten die zurückgegebenen Buckets unverändert abbilden, statt einen Trend aus Zusammenfassungs-Metriken zu rekonstruieren.

## Toki-Konversationen

### Erstellen und listen

`POST /api/:handle/projects/:project/toki/conversations` akzeptiert eine client-generierte UUID:

```json
{"id": "52a3b55c-c2db-4b3f-a83f-d7d3542ae46b"}
```

Es return `201` mit `{conversation, messages: []}`. Leere Konversationen haben Titel `New conversation` und Status `completed` (unaktiv, nicht generierend). Wiederholen derselben UUID für denselben Akteur, Projekt und Ursprung return existierende Details ohne weitere Konversation zu erstellen. Neuverwenden für anderen Akteur, Projekt oder Ursprung return `409` mit `error: "id_conflict"`.

`GET /api/:handle/projects/:project/toki/conversations` return `{conversations: [...], meta: {...}}`. Eine Konversation enthält `id`, `title`, `status`, `updated_at`, nullable `error` und nullable `translation_session_id`. Titel werden aus der ersten Benutzer-Mission abgeleitet, nicht aus einer zweiten Modell-Aufrufen.

### Übersetzungsursprung

Erstellung akzeptiert optional eine Übersetzungssitzung UUID vom selben Projekt:

```json
{
  "id": "52a3b55c-c2db-4b3f-a83f-d7d3542ae46b",
  "translation_session_id": "e4183cef-2b43-42a8-a60f-78b4fbb02bbf"
}
```

Der Ursprung ist unveränderlich; Weglassen und `null` beide mean kein Ursprung. Ein Retry muss denselben Ursprung liefern, einschließlich nach Senden von Nachrichten. Sie können zum Später keinen Ursprung anhängen oder mit einem Retry entfernen. Eine fehlerhafte Ursprung return `422`; ein fehlende oder fremd-projekt Quelle return `404`. Source-linked Erstellung erfordert zusätzlich `translation:read` Token-Bereich und aktuelle Richtlinie-Berechtigung, nebst `toki:write` und Projekt-Lesen-Berechtigung. Client-gelieferte Quellensummen, metadaten, Rollen und Eigentum sind ignoriert. Nur die UUID ist persistiert; der Dienst löst seinen autorisierten Kontext bei Antwortzeit.

**Source-linked Konversationen fail closed**, statt nur Kaudel der UUID: ohne aktuellen `translation:read` Bereich oder Richtlinie-Berechtigung, Detail, matching-origin erstellen-Wiederholung, Nachrichtensenden und Nachrichtewiederholung return `403`. Eine mismatched Ursprung return immer `409` ohne Geschichte oder Quellen-Metadaten zurückzugeben. Listen omittieren die gesamte source-linked Konversation, einschließlich ihren Titel und Beitrag zu pagination-Zählungen. Das schützt vorfrühere Assistent-Nachrichten, die die Quelle erwähnt. Fehlende Bereiche enthalten die normale `WWW-Authenticate` Herausforderung. Unlinked Konversationen behalten ihre existierende Toki-only Autorisierung-Verhalten.

Gelöscht oder verschobene Quellen fällen auch geschlossen: source-linked Detail, Sends, und matching erstellen Retry return `404`, und Listen omittieren die Konversation. Der unveränderliche UUID bleibt nach Quellenlöschung gespeichert so that ein Retry nicht schweigend unlinked werden kann. Der Referenz hat keinen kaskadierenden Fremdschlüssel; jeden Gebrauch prüft aktuelle Quellen-Ekistenz und ihre genaue Projekt/Konto. Keine Quellen-Referenz verleiht Zugang oder ändert eine Stimme, glossar oder gemeinsamen Kontext.

Erstellen oder Öffnen einer source-linked Konversation sendet **keine** Nachricht oder queuete Inferenz. Native Navigation soll die Übersetzungsdetails zuerst abrufen; nur eine explizite Benutzer-Aktion soll die Konversation erstellen, und eine separierte explizite Nachrichteneinreichung start einen Turn. Keine Vorschlag-Veröffentlichung, gemeinsame Diskussion-Überprüfung oder agent Schreiben-Tools werden bereitgestellt.

### Senden und abfragen

`POST /api/:handle/projects/:project/toki/conversations/:id/messages` akzeptiert eine separate client-generierte **Message** UUID:

```json
{"id": "17c3b189-80f0-4382-b7bb-1305b1db70ad", "content": "Which translations have completed?"}
```

Die Anfrage persistiert die Benutzer-Nachricht und einen Oban-Job in einer Datenbank-Transaktion. Es ruft kein Modell. Es return `202` mit Konversations-Status `queued` und den aktuellen Nachrichten. Poll `GET /api/:handle/projects/:project/toki/conversations/:id` während Status `queued` oder `running`; stop bei `completed` oder `failed`.

Detail-Äntworten haben diese Form:

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

Nachrichten haben Rolle `user` oder `assistant` und sind chronologisch. Eine Konversation hält mindestens 100 Nachrichten, so dass das Detail-Endpunkt ihren gesamten begrenzten Geschichten zurückgeben ohne einen zusätzlichen Pagin-Anfrage.

Das Wiederholen einer Nachrichten-UUID mit identischem Inhalt queued niemals eine weitere Inferenz neu, einschließlich nach Abschluss oder Fehlschlag. Ein eingelöstes Replay return `200`; ein ausstehendes Replay return `202`. Die Wiederverwendung einer UUID mit verschiedenem Inhalt oder in einer anderen Konversation return `409`. Eine andere Nachricht eingereicht während ein Turn aktiv ist return `409` mit `error: "conversation_busy"`.

### Modellverhalten und -grenzen

- Jede Benutzer-Nachricht ist nicht-leerer Text, maximal 8.000 Zeichen und 32.000 UTF-8 Bytes. Ungültige UUIDs, Typen oder Inhalte return `422`.
- Jeder Benutzer kann maximal 100 Konversationen pro Projekt und fünf queued/running Konversationen über Projekte halten. Mehr als fünf ausstehende Turns return `429`; Konversation/Geschichten-Grenzen return `422`.
- Neue Nachrichten sind auf 30 pro Stunde pro Benutzer pro Server begrenzt, zusätzlich zu normalen API-Rate-Limits. Replays verbrauchen keine Inferenz-Quote.
- Die dedizierte Oban-Warteschlange führt pro Server zwei Jobs gleichzeitig aus. Jeder Turn führt maximal eine Provider-HTTP-Anfrage aus: ReqLLM vorbereitet die Provider-Anfrage, dann führt der Oban-Worker sie synchron aus mit HTTP-Retrys und nach Provider-Anbindung deaktivierten Redirects. Keine Condukt-Sitzung,ionierte Inferenz-Aufgabe, Tools, Subagenten oder Dateisystem-Instruktionsladung ist beteiligt. Der Provider erhält oben ab 2.048-Ausgabe-Token-Himmel; Assistant-Antworten sind ebenfalls auf 8.000 Zeichen und 32.000 Bytes begrenzt.
- HTTP-Verbindung und Pool-Warten sind auf fünf Sekunden und Socket-Empfang-Warten auf 60 Sekunden beschränkt. Der Oban-Worker hat eine 90-Sekunden-Hartwallclock-Frist, einschließlich Einkommen-Verantwortungen. Worker-Terminierung terminiert auch seine lokale Inferenz-Ausführung. Trennen kann nicht Abbruch bereits akzeptierter Berechnung durch einen Remote-Provider garantieren, so dass mehrdeutige Fehlschläge nie automatisch neu versucht werden.
- Das Modell erhält begrenztes Projekt-Metadatum und maximal drei aktuelle Übersetzung-Zusammenfassungen, wenn sowohl Token als auch aktuelle Mitgliedschaft `translation:read` erlauben. Die letzten zehn Konversations-Auszüge sind unabhängig vom Speicher begrenzt. Es hat keine Schreibfähigkeiten oder allgemeine Repository-Zugang, und keine Analysen werden dem Modell bereitgestellt.
- Für eine source-linked Konversation erhält das Modell zusätzlich die exakte persistierte Quelle, sogar wenn sie nicht neu ist: UUID, Status, Commit-Metadatum, Sprachen, Zählung und maximal 1.000 Zusammenfassungs-Textzeichen. Kontext ist beschriftet `provenance: "session_summary"`, und der Prompt verlangt die Berichterstattung dieser Zusammenfassungs-Ebene-Beschränkung. Kein Segment-Text, Referenz-Dateien oder client-zulieferter Quellen-Kontext wird geladen.
- Bereitstellungen lösen sich über die Konto-Existing generativer Modell und Server-Inferenz-Konfiguration. Interaktive CLI/OAuth-Sitzungen werden nicht für Toki verwendet. Fehlende oder nicht-unterstützte Credentials erzeugen Status `failed` mit `error: "provider_unavailable"`.
- Provider-Fehler produzieren `inference_failed`; leerer oder überschüssiger Output produziert `invalid_provider_response`. Rohe Provider-Fehler und geheime werden nicht zurückgegeben. Keine synthetische Assistant-Antwort wird bei Fehlschlag eingefügt.
- Konto/Projekt-Zugang und Quell-Ekistenz, Projekt/Konto-Assoziation, und Übersetzungsberechtigung werden vor und nach Inferenz erneut geprüft. Revoke Zugang oder unzureichende queued-Scope führen Turn mit `not_authorized` ab; eine gelöschte oder verschobene Quelle facht mit `source_unavailable` ab. Keine Assistant-Antwort wird bei beiden Fehlschlägen persistiert.
- Eine Erholungsaufgabe läuft jede Minute und markiert laufende Arbeit älter als zweieinhalb Minuten, oder queued Arbeit älter als 15 Minuten, als `failed` mit `inference_interrupted`. Das regelt Timeout, terminierte und verwaiste Jobs ohne Inferenz-neu-Versuch. Eine verspätete Aufgabe kann ein abgelaufene Nachrichten nicht beanspruchen oder einen neueren Turn überschreiben. Ein Benutzer kann beabsichtigt eine **new** message UUID nach einem Fehlschlag senden.

## Fehler

`401` bedeutet Authentifizierung fehlgeschlagen. `403` bedeutet Scope oder Ressource-Politik verweigerte Zugang; fehlende Scopes umfassen eine `WWW-Authenticate` Herausforderung. Unbekannte Projekte und fremd/private Konversations-UUIDs return `404`. Validierung benutzt `422`, Paginierung nutzt `400`, UUID/busy Konflikte verwenden `409`, und Quota-Erschöpfung benutzt `429`.
