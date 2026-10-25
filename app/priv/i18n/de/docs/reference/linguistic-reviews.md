%{
  title: "Linguistische Überprüfungen",
  summary:
    "Quellenbezogene menschliche Entscheidungen, Übersetzungsfortsetzungen und geprüfte Repository-Leitlinien.",
  category: "Referenz",
  section: "translation",
  order: 31
}
---

## Eskalation

Repository-Übersetzungsprozesse mit einem konfigurierten Entscheidungsmodell können linguistische Inputs für fehlende Quellbedeutung oder Fachbereichskontext, widersprüchliche Anleitungen oder umfassende kulturelle Anpassung anfordern. Nur niedrige Konfidenz löst keine Frage aus. Fehler, die aus dem bestehenden Kontext korrigiert werden können, verbrauchen das übliche Korrekturbudget; Qualitätsfehlern, die nach diesem Budget übrig bleiben, können ebenfalls Input anfordern. Ohne Entscheidungsmodell ist der automatische linguistische Eskalationsmodus deaktiviert.

Nur die betroffene Datei/die Zielsprache wird angehalten. Ihr ungeprüfter Kandidat wird nicht veröffentlicht. Unabhängige Dateien werden abgeschlossen und können normal veröffentlicht werden. Nach Abschluss der Veröffentlichung wird die Sitzung `awaiting_input` und beendet ihren Runner. Es wird kein Worker verbraucht, solange eine Person antwortet.

Jede Eskalation eröffnet eine **gemeinsame Toki-Konversation mit einem definierten linguistischen Ziel**, die mit der Übersetzungsitzung verknüpft ist. Die Teilnehmer diskutieren die Bedeutung, stellen Nachfragen und verfeinern eine vorgeschlagene Entscheidung. Eine Diskussion allein kann eine Übersetzung niemals genehmigen oder Repository-Kontext schreiben. Gewöhnliche Toki-Konversationen bleiben für ihren Besitzer privat, selbst gegenüber Administratoren.

Alle derzeit autorisierten Teammitglieder, deren angegebene fluent Sprachen der Zielsprache entsprechen, werden zur selben Konversation eingeladen. Flüssigkeit ist von der Darstellungssprache getrennt und gewährt keinen Projektzugriff oder die Berechtigung zur Genehmigung von Entscheidungen. Eine allgemeine Sprache, wie `es` stimmt mit regionalen Varianten wie `es-MX` überein; inkompatible explizite Schriften stimmen nicht überein. Regionale Deklarationen wie `zh-TW` verwenden ihre gewohnten CLDR-Schriften, während `zh` durch Schriftart nicht eingeschränkt bleibt.

Berechtigte Teilnehmer erhalten generische Mobile-Push-Benachrichtigungen nur, wenn sie zugestimmt haben; die Lieferung überprüft erneut die aktuelle Flüssigkeit, Mitgliedschaft, Projektzugriff und das offene Ziel. Benachrichtigungen öffnen die gemeinsame Konversation. Konversationen und Genehmigungen sind sowohl in Native-Apps als auch im Web-Dashboard verfügbar. Siehe [Native push notifications](/docs/reference/native-push-notifications) zur Anbieterkonfiguration und Zustellungspolitik.

## Profil der fluenten Sprachen

`GET /api/me` enthält `user.fluent_languages`. `PUT /api/me/fluent-languages` erfordert `user:write` und akzeptiert nur `{"fluent_languages": ["es", "ar", "zh-Hant"]}`. Sie ersetzt die Liste des authentifizierten Benutzers und gibt das Profill-envelope zurück. Unterstützte CLDR BCP47-Tags behalten die explizite Region-/Schriftart-Spezifikität bei und verwenden die kanonische Großschreibung; Duplikatte werden zusammengelegt. Ein leeres Array löscht die Flüssigkeit. Ungültige Tags, nicht verwandte Felder oder mehr als 50 eingereichte Einträge senden 422. Dies ändert niemals die UI-Lokalität.

## Review API

`GET /api/:handle/projects/:project/translations/:id/reviews` erfordert `translation:read` und Projektzugang. Es gibt `{"reviews": [...]}` zurück, zuerst offene Fragen, dann älteste zuerst, limitiert auf 500 Einträge. Aktualisieren Sie nach Antworten, um verbleibende Fragen aufzudecken; die Antworthistorie versteckt niemals eine offene Frage hinter dem Limit.

Jeder Review beinhaltet `id`, `translation_session_id`, `conversation_id`, `participants` (`id` und optional `name`), `status`, `source_path`, `output_path`, `locale`, `question`, begrenzten `source_excerpt` und `translation_excerpt`, `answer`, `guidance`, `context_path`, `resolution_message_id`, `resumed_session_id`, und `inserted_at`. Der Status ist `open`, `answered` oder `stale`.

Verwenden Sie die vorhandenen Projekt-Toki-Konversations- und Nachrichten-Endpunkte für Diskussionen. Gemeinsame Ziel-Konversationen erscheinen neben den privaten Konversationen des Akteurs in der Toki-Vorgeschichte. Gemeinsame Geschichtsdateien erfordern aktuelle Toki-Lese-/Schreib-Richtlinien-Berechtigung und Übersetzungs-Lesezugang; gewöhnliche Historien bleiben Besitzer-only. Menschliche Nachrichten enthalten ihre Autorenidentität, und Antworten beinhalten `status` und `reply_to_id`. Toki erhält beschränkte Quell-/Kandidaten-Auszüge und das Ziel, keinen Repository-Schreibzugang.

`POST /api/:handle/projects/:project/translations/:id/reviews/:review_id/answer` erfordert sowohl `translation:read` als auch `translation:write` sowie Projektzugang:

```json
{
  "resolution_message_id": "019a1c6d-4321-7000-8000-123456789abc",
  "answer": "Branch means a source-control release branch.",
  "guidance": "Use the source-control meaning of branch in release documentation.",
  "context_scope": "locale"
}
```

`resolution_message_id` muss die neueste abgeschlossene Assistant **Antwort** in der Ziel-Konversation identifizieren, nicht ihre Eröffnungsfrage. `answer` ist der menschlich genehmigte Beschluss und ist erforderlich und nicht leer. `guidance` und `context_scope` sind optional; der Bereich standardmäßig auf `locale` und kann auch `project` sein. Antwort und Anleitung erlauben jeweils bis zu 8.000 Zeichen und 32.000 UTF-8-Bytes. Anleitung darf keine reservierten Review-Marker-Kommentare von Glossia enthalten. Der Server wählt Repository-Pfade; ein von einem Client bereitgestellter Pfad wird niemals verwendet.

Eine erfolgreiche Antwort ist `{"review": {...}}`. Das Wiederspiel desselben Beschlusses, der Auflösungs-Nachricht, Anleitung und des Bereichs ist idempotent. Eine beschäftigte Konversation gibt `409 conversation_busy` zurück; eine neuere Meldung oder eine ungültige Auflösungsreferenz gibt `409 resolution_outdated` zurück. Laden Sie neu und prüfen Sie die aktuelle Diskussion erneut vor erneuter Genehmigung. Eine andere Entscheidung auf einem gelösten Ziel gibt `409 already_answered` zurück; die Genehmigung eines abgebrochenen oder überwundenen Ziels gibt `409 stale` zurück. Ungültiger Text oder unbezahlbarer Bereich gibt 422 zurück. Fehlende und fremdprojekt-IDs geben 404 zurück. Normale Authentifizierung und Projektauthorisierungen gelten für jede Anfrage, einschließlich Wiederholungen. Geschlossene Ziele verwerfen neue Diskussionsnachrichten mit `409 goal_closed`.

## Fortsetzungen und veralteter Kontext

Beschlüsse können genehmigt werden, während unabhängige Arbeit noch läuft. Sie starten niemals dann einen zweiten Runner. Sobald der Runner freigegeben und jedes Ziel in diesem Durchlauf gelöst ist, wertet Glossia atomar eine weitere Sitzung auf. `resumed_session_id` identifiziert sie; die ursprüngliche Sitzung bleibt der `awaiting_input`. Sowohl Dashboard als auch Native-Konversationen verlinken mit der Fortsetzung.

Die Fortsetzung hat eine frische Ausführungsidentität und behält den Übersetzungsveröffentlichungszweig und validierte Ausgaben bei. Jede Antwort gilt nur für die identische Quelle und den gelösten Übersetzungskontext-Fingerabdruck. Geänderte Quelle, Stimme, Glossar, Modell oder Repository-Anweisungen verhindern Antwortwiederverwendung. Ein neuerer Standardzweig-Commit stellt wartende Sitzungen ab und markiert offene Fragen veraltet. Stornierung markiert ebenfalls offene Fragen veraltet.

## Wiederverwendbare Repository-Anleitung

Wiederverwendbare Anleitung ist eine separate, explizite menschliche Bearbeitung. Eine Antwort allein wird nicht zum Repository-Kontext, und private Chat-Transkripte werden niemals automatisch kopiert.

`locale` zielt auf das anwendbare Lokalisierungsoverlay ab, wie `L10N/es.md`; `project` zielt auf das anwendbare `L10N.md`. Bestehende kontextbasierte Kontext-Dateien werden beachtet. Fehlende Lokalisierungsoverlays erhalten ihren Lokalisierungshopfenteren. Bestehenden Frontmatter und Prosa werden beibehalten, und jeder Beschluss wird mit seinem Revisor-UUID für Provenienz und Idempotenz angehängt.

Die Anleitung wird im normalen Übersetzungs-Pull-Request vorgeschlagen, nicht stillschweigend in den Standardzweig geschrieben. Das Repository muss weiterhin dem aufgezeichneten Kontext-Digest entsprechen; eine konfliktbehaftete Bearbeitung führt zum Scheitern der Veröffentlichung, statt diese zu überschreiben. Pfade müssen repository-relative Lokalisierungsdateien sein, ohne Traversierung oder Symbolische Links. Jedes Kontextdokument ist auf 1 MiB begrenzt. Das Zusammenführen des Pull-Requests macht die Anleitung zu einem normalen versionierten Lokalisierungskontext für spätere Durchläufe.
