%{
  title: "Nutzung von Übersetzungstoken",
  summary:
    "Verstehen Sie die Token-Buchhaltung und die Aufschlüsselung nach Projekt, Sprache und Quelldateien.",
  category: "Referenz",
  section: "translation",
  order: 12
}
---
## Dashboard

Öffnen **Einstellungen → Modelle → Token-Nutzung** um den vom Provider gemeldeten Verbrauch für generative Übersetzungen anzuzeigen. Der Zugriff erfordert Berechtigung zum Lesen der Modelleinstellungen.

Das Dashboard unterstützt die letzten 7, 30 oder 90 Kalendertage, einschließlich des heutigen Tages, in UTC. Modell-, Projekt- und Sprachfilter gelten für die Gesamtsummen, das Tagesdiagramm und die Aufschlüsselung. Die Suche gilt nur für Aufschlüsselungszeilen. Der ausgewählte Zeitraum, die Dimension, Filter, Suche, Sortierung und die Seite werden in der URL gespeichert.

## Metriken

| Metrik | Bedeutung |
| --- | --- |
| Eingabe-Tokens | Vom Anbieter verarbeitete Eingabe, einschließlich gemeldeter Cache-Lese- und Cache-Schreibvorgänge. |
| Ausgabe-Tokens | Vom Anbieter gemeldeter Output, einschließlich Schlussfolgerungen, wenn der Anbieter es in seiner Ausgabeanzahl einschließt. |
| Gecachte Eingabe-Tokens | Cache-Lesevorgänge. Ein Teilbereich der Eingabe-Tokens, keine zusätzliche Gebühr in der Gesamtsumme. |
| Gesamt-Token | Eingabe-Tokens plus Ausgabe-Tokens. |
| Antworten | Antworten mit Eingabe- und Ausgabe-Anzahlen sowie einem positiven Token-Betrag. Nullwerte für fehlende Nutzungsnachweise werden ignoriert. |

Token-Anzahlen sind keine monetären Kosten. Anbieter können unterschiedliche Preise für Eingabe, Ausgabe, Gecachte Eingabe und Cache-Schreibvorgänge berechnen.

Jede gemeldete Antwort wird gezählt, einschließlich Validierungswiederholungen, Qualitätskorrekturwiederholungen und Antworten, die abgewiesen wurden, weil sie ihre Ausgabe-Grenze erreicht hatten. Übersprungene Dateien und Checkpoint-Treffer, die kein Modell aufrufen, verursachen keine Nutzung. Fehlgeschlagene Anfragen ohne Nutzung können nicht gezählt werden.

## Dimensionen

- **Projekte** gruppiert die Nutzung nach Projekt. Verwenden Sie den Projektfilter, um alle Metriken auf ein einzelnes Projekt einzuschränken.
- **Sprachen** gruppiert nach Zielsprache, z. B. `es` oder `ja`, über Projekte im aktuellen Geltungsbereich.
- **Dateien** gruppiert nach Quellpfad und Projekt. Die gleiche Quelldatei, die in mehrere Sprachen übersetzt wird, erscheint einmal; identisch benannte Dateien in verschiedenen Projekten bleiben getrennt.

**Nicht zugeordnet** hält Anfragen ohne Projekt- oder Quellpfad-Metadaten sichtbar. Repository-Übersetzungen liefern beide automatisch. Einzelinhalt-API-Anfragen können bereitstellen `project_id` und `source_path` zur Zuschreibung; eine Projekt-ID außerhalb des authentifizierten Kontos wird als Nicht zugeordnet behandelt. Ungültige oder zu große optionale Metadaten werden ohne Verwerfen der Token-Anzahlen als Nicht zugeordnet behandelt.

## Abdeckung

Die Nutzung wird aus ReqLLM API-Schlüssel- und OAuth-Antworten, Together-Completions und abgeschlossenen lokalen Codex-Durchläufen gesammelt. Nur vom Dienstanbieter gemeldete Werte werden gespeichert. Lokale Pi-Sitzungen und Entscheidungsmodell-Bewertungen sind nicht enthalten. Historische Übersetzungen werden nicht nachgeladen oder geschätzt. Summen beschreiben daher aufgezeichnete Nutzung, keine vollständige Anbieter-Rechnung.

Das Ledger speichert Konto, Projekt, Modellbezeichner und Handle, Ziel-Lokalisierung, Quellpfad, Anzahl und Zeitstempel. Es speichert keine Prompts, übersetzten Inhalt, Zugangsdaten oder rohe Anbieterantworten. Fehlgeschlagene Protokollierungen der Nutzung werden protokolliert, ohne die Übersetzung zu unterbrechen.