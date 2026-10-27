%{
  title: "Linguistische Überprüfungen",
  summary:
    "An die Quellen gebundene menschliche Entscheidungen, Übersetzungsfortsetzungen und geprüfte Repository-Hinweise.",
  category: "Referenz",
  section: "translation",
  order: 31
}
---

## Escalation

Repository translation runs with a configured decision model can request linguistic input for missing source meaning or domain context, conflicting guidance, or consequential cultural adaptation. Low confidence alone does not trigger a question. Errors correctable from existing context use the ordinary correction budget; quality failures remaining after that budget can also request input. Without a decision model, automatic linguistic escalation is disabled.

Nur die betroffene Datei/Lokalstellung wird angehalten. Ihr ungeprüfter Kandidat wird nicht veröffentlicht. Unabhängige Dateien werden abgeschlossen und können normal veröffentlicht werden. Nach Abschluss der Veröffentlichung wird die Sitzung `awaiting_input` und gibt ihren Runner frei. Es verbraucht keinen Worker, während ein Mensch antwortet.

Jede Eskalation öffnet ein **geteiltes Toki-Gespräch mit einem definierten linguistischen Ziel**, das mit der Übersetzungssitzung verknüpft ist. Teilnehmer diskutieren die Bedeutung, stellen Nachfragen und verfeinern einen vorgeschlagenen Beschluss. Die Diskussion allein genehmigt niemals eine Übersetzung oder schreibt Repository-Kontext. Normale Toki-Gespräche bleiben dem Eigentümer vorbehalten, einschließlich gegenüber Administratoren.

Alle aktuell autorisierten Teammitglieder, dessen erklärte bequeme Sprachen mit der Ziel-Lokalisierung übereinstimmen, werden zum selben Gespräch eingeladen. Sprachbeherrschung ist getrennt von der Anzeigesprache und gewährt keinen Projektzugriff oder Genehmigungszugewinn zur Genehmigung von Beschlüssen. Eine breite Sprache wie `es` stimmt mit regionalen Varianten wie `es-MX` überein; inkompatible explizite Skripte stimmen nicht überein. Regionale Deklarationen wie `zh-TW` verwenden ihr übliches CLDR-Skript, während breites `zh` unbegrenzt von Skript bleibt.

Berechtigte Teilnehmer erhalten generische mobile Push-Benachrichtigungen nur, wenn sie sich angemeldet haben; die Lieferung überprüft erneut die aktuelle Sprachbeherrschung, Mitgliedschaft, Projektzugriff und das offene Ziel. Benachrichtigungen öffnen das gemeinsame Gespräch. Gespräche und Genehmigungen sind sowohl aus den nativen Apps als auch aus dem Web-Dashboard verfügbar. Siehe [Native push notifications](/docs/reference/native-push-notifications) für Konfiguration des Anbieters und Lieferpolitik.

## Profil der flüssigen Sprache

`GET /api/me` beinhaltet `user.fluent_languages`. `PUT /api/me/fluent-languages` erfordert `user:write` und akzeptiert nur `{"fluent_languages": ["es", "ar", "zh-Hant"]}`. Es ersetzt die Liste des authentifizierten Benutzers und gibt das Profil-Etikett zurück. Unterstützte CLDR BCP47-Tags behalten explizite Regionen/Skript-Spezifität bei und verwenden kanonische Groß-/Kleinschreibung; Duplikate kollabieren. Ein leeres Array reinigt die Sprachbeherrschung. ungültige Tags, unführige Felder oder mehr als 50 eingereichte Einträge geben 422 zurück. Dies ändert die Benutzeroberflächen-Lokalisierung jemals nicht.

## Review API

`GET /api/:handle/projects/:project/translations/:id/reviews` erfordert `translation:read` und Projektzugriff. Es gibt `{"reviews": [...]}` zurück, wobei offene Fragen zuerst und dann älteste zuerst, begrenzt auf 500 Einträge. Aktualisieren Sie nach dem Beantworten, um verbleibende Fragen aufdecken; beantwortete Historie verbirgt niemals eine offene Frage hinter der Begrenzung.

Jeder Durchgang enthält `id`, `translation_session_id`, `conversation_id`, `participants` (`id` und optionales `name`), `status`, `source_path`, `output_path`, `locale`, `question`, begrenzte `source_excerpt` und `translation_excerpt`, `answer`, `guidance`, `context_path`, `resolution_message_id`, `resumed_session_id`, und `inserted_at`. Status ist `open`, `answered` oder `stale`.

`answered_by` identifiziert den Menschen, der den Beschluss als `{"id": "<user UUID>", "name": "<current display name>"}` genehmigte; `name` kann null sein. Das Feld ist null vor Genehmigung oder wenn der Genehmiger nicht verfügbar ist. Es enthält keine E-Mail oder andere private Profil-Felder, und das Nacherzählen einer Genehmigung ändert den Genehmiger nicht. Dasselbe Feld ist im verschachtelten `linguistic_review` auf gemeinsamen Toki-Gesprächen enthalten. Kein Genehmigungs-Zeitstempel ist offengelegt; `inserted_at` ist die Erstellungsdauer der Überprüfung, nicht ihre Genehmigungsedierung.

Nutzen Sie die vorhandenen Projekt-Toki-Gespräch- und Nachrichten-Endpunkte für die Diskussion. Gemeinsame Ziel-Gespräche erscheinen neben den privaten Gesprächen des Akteurs in der Toki-Historie. Gemeinsame Historien erfordern aktuelle Toki-Lese-/Schreibpolitik-Zugriff und Übersetzung-Leseverfügbarkeit; herkömmliche Historien bleiben nur dem Eigentümer vorbehalten. Menschen-Nachrichten beinhalten ihre Autor-Identität, und Antworten beinhalten `status` und `reply_to_id`. Toki empfängt begrenzte Quell/Kandidat-Auszüge und das Ziel, nicht Repository-Schreibzugriff.

`POST /api/:handle/projects/:project/translations/:id/reviews/:review_id/answer` erfordert sowohl `translation:read` als auch `translation:write` sowie Projektzugriff:

```json
{
  "resolution_message_id": "019a1c6d-4321-7000-8000-123456789abc",
  "answer": "Branch means a source-control release branch.",
  "guidance": "Use the source-control meaning of branch in release documentation.",
  "context_scope": "locale"
}
```

`resolution_message_id` muss die neueste abgeschlossene Assistenten-Antwort **Antwort** im Ziel-Gespräch identifizieren, nicht seine Einleitungs-Frage. `answer` ist die vom Menschen genehmigte Entscheidung und ist erforderlich und nicht leer. `guidance` und `context_scope` sind optional; Reichweite ist standardmäßig `locale` und kann auch `project` sein. Antwort und Richtweisungen erlauben jeweils bis zu 8.000 Zeichen und 32.000 UTF-8 Bytes. Richtweisungen darf Glossia reservierte Überprüfungs-Markier-Kommentare nicht enthalten. Der Server wählt Repository-Pfade; ein vom Client gelieferter Pfad wird nie verwendet.

Ein erfolgreicher Rücklauf ist `{"review": {...}}`. Die Wiedergabe derselben Entscheidung, des Lösungs-Nachrichts, der Richtweisung und des Scopes ist idempotent. Ein beschäftigtes Gespräch gibt `409 conversation_busy` zurück; eine neuere Nachricht oder ungleiche Lösungs-Referenz gibt `409 resolution_outdated` zurück. Laden Sie die aktuelle Diskussion neu und überprüfen Sie vor erneuter Genehmigung. Eine andere Entscheidung auf einem gelösten Ziel gibt `409 already_answered` zurück; die Genehmigung eines abgebrochenen oder über unser Zielgeistes gibt `409 stale` zurück. Ungültiger Text oder unverseffte Reichweite gibt 422 zurück. Fehlende und fremd-Projekt-IDs geben 404 zurück. Normale Authentifizierung und Projekt-Autorisierung wenden sich auf jeder Anfrage, einschließlich Wiederholungen. Geschlossene Ziele lehnen neue Diskussion-Nachrichten mit `409 goal_closed` ab.

## Fortsetzungen und alter Kontext

Beschlüsse können genehmigt werden, während unabhängige Arbeit noch läuft. Sie starten niemals einen zweiten Runner dann. Sobald der Runner freigegeben ist und jedes Ziel in diesem Lauf解决 ist, bewertet Glossia atomarisch eine Fortsetzungssitzung auf. `resumed_session_id` identifiziert es; die ursprüngliche Sitzung bleibt historisch `awaiting_input`. Sowohl Dashboard als auch native Gespräche verknüpfen zur Fortsetzung.

Die Fortsetzung hat eine frische Ausführungsentität und behält den Übersetzungs publication-Zweig und validierte Ausgaben. Jede Antwort gilt nur für die identische Quelle und den vorgenommenen Übersetzungs-Kontext-Fingerabdruck. Geänderte Quelle, Stimme, Glossar, Modell oder Repository-Anweisungen verhindern Antwort-Wiederverwendung. Ein neuerer Default-Branch-Commit ersetzt wartende Sitzungen und markiert offene Fragen als veraltet. Stornierung markiert ebenfalls offene Fragen als veraltet.

## Wiederverwendbare Repository-Richtweisungen

Wiederverwendbare Richtweisungen sind eine eigenständige, explizite menschliche Bearbeitung. Eine Antwort allein wird nicht zum Repository-Kontext, und private Chat-Transkripte werden niemals automatisch kopiert.

`locale` gilt für das anwendbare Lokalisierungs-Overlay, beispielsweise `L10N/es.md`; `project` gilt für das anwendbare `L10N.md`. Bestehende kontextbezogene Kontextdateien werden beachtet. Fehlende Lokalisierungs-Overlays erhalten deren Lokalisierungs-Frontmatter. Bestehendes Frontmatter und Text sind erhalten, und jede Entscheidung wird mit ihrem Review-UUID für Provenienz und Idempotenz angehängt.

Die Richtweisung wird im normalen Übersetzungs-Pull-Request vorgeschlagen, nicht stillschweigend in den Standardzweig geschrieben. Das Repository muss weiterhin mit dem aufgezeichneten Kontext-Digest übereinstimmen; eine widersprüchliche Bearbeitung blockiert die Veröffentlichung anstatt sie zu überschreiben. Pfade müssen repository-relative Lokalisierungs-Dokumente ohne Traversal oder Symlinks sein. Jedes Kontext-Dokument ist auf 1 MiB beschränkt. Das Zusammenführen des Pull-Request macht die Richtweisung zu gewöhnlichem versioniertem Lokalisierungs-Kontext für spätere Durchläufe.
