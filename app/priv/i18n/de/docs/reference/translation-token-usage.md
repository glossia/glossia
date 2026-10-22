%{
  title: "Nutzung von Übersetzungs-Token",
  summary:
    "Verstehen Sie die Token-Abrechnung und die Aufschlüsselung nach Projekt, Sprache und Quelldatei.",
  category: "Referenz",
  section: "translation",
  order: 12
}
---

## Dashboard

Öffnen **Einstellungen → Modelle → Token-Nutzung** um die vom Anbieter berichtete Nutzung für generative Übersetzungen zu sehen. Der Zugriff erfordert die Berechtigung zum Lesen von Modellsinstellungen.

Das Dashboard unterstützt die letzten 7, 30 oder 90 Kalendertage, einschließlich des aktuellen Tages, in UTC. Modelle-, Projekt- und Sprachfilter gelten für Gesamte, Tagesdiagramm und Aufschlüsselung. Die Suche gilt nur für Aufschlüsselungszeilen. Der ausgewählte Zeitraum, die Dimension, Filter, Suche, Sortierung und die Seite werden in der URL gespeichert.

## Metriken

| Metrik | Bedeutung |
| --- | --- |
| Eingabetokens | Eingabe, die vom Anbieter verarbeitet wird, einschließlich berichteter Cache-Lese- und Cache-Schreibvorgänge. |
| Ausgabetokens | Vom Anbieter berichtete Ausgaben, einschließlich Reasoning, wenn der Anbieter dies in seine Ausgabezahl einbezieht. |
| Cache-Eingabetokens | Cache-Lesevorgänge. Eine Teilmenge der Eingabetokens, keine zusätzliche Gebühr im Gesamtergebnis. |
| Gesamttokens | Eingabetokens plus Ausgabetokens. |
| Antworten | Antworten mit Eingabe- und Ausgabezählungen sowie einem positiven Token-Gesamtwert. Nullisierte fehlende-Nutzung-Fallbacks werden ignoriert. |

Tokenanzahlen sind keine monetären Kosten. Anbieter können unterschiedliche Preise für Eingabe, Ausgabe, Cache-Eingabe und Cache-Schreibvorgänge berechnen.

Jede gemeldete Antwort wird gezählt, einschließlich Validierungsneuversuche, Qualitätskorrekturneuversuche und Antworten, die wegen Erreichung des Ausgabe-Limits abgelehnt wurden. Übersprungene Dateien und Checkpoint-Treffer, die kein Modell aufrufen, verursachen keine Nutzung. Fehlgeschlagene Anfragen ohne Nutzung können nicht gezählt werden.

## Dimensionen

- **Projekte** gruppiert die Nutzung nach Projekt. Verwenden Sie den Projektfilter, um alle Metriken auf ein einzelnes Projekt zu beschränken.
- **Sprachen** gruppiert nach Ziel-Locale, wie `es` oder `ja`, über Projekte im aktuellen Geltungsbereich.
- **Dateien** gruppiert nach Quelldatei-Wege und Projekt. Die gleiche Quelldatei, die in mehrere Sprachen übersetzt wurde, erscheint einmal; gleichnamige Dateien in verschiedenen Projekten bleiben getrennt.

**Nicht zugeordnet** hält Anfragen ohne Projekt- oder Quelldatei-Metadaten sichtbar. Repositories-Übersetzungen stellen beides automatisch bereit. Einzelcontent-API-Anfragen können `project_id` und `source_path` für Zuordnung bereitstellen; eine Projekt-ID außerhalb des authentifizierten Kontos wird als nicht zugeordnet behandelt. Ungültige oder zeilweise optionale Metadaten werden ohne Verwerfen der Tokenanzahlen als nicht zugeordnet behandelt.

## Abdeckung

Die Nutzung wird von ReqLLM API-key und OAuth-Antworten, Together Completion und abgeschlossenen lokalen Codex-Durchläufen gesammelt. Nur vom Anbieter berichtete Zählungen werden gespeichert. Lokale Pi-Sitzungen und Entscheidungsmodellanalysen sind nicht enthalten. Historische Übersetzungen werden nicht nachfüllend oder geschätzt. Summen beschreiben daher die aufgezeichnete Nutzung, keine vollständige Anbieterrechnung.

Das Ledger speichert Konten, Projekte, Modellidentifikatoren und Handles, Ziel-Locale, Quelldatei-Wege, Zählungen und Zeitstempel. Es speichert keine Prompts, übersetzten Inhalt, Credentials oder rohe Anbieterantworten. Fehlgeschlagene Nutzungsaufzeichnungen werden protokolliert, ohne die Übersetzung zu unterbrechen.
