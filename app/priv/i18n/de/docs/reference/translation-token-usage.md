%{
  title: "Nutzung von Übersetzungstoken",
  summary:
    "Verstehen Sie die Tokenaufstellung und die Aufschlüsselung nach Projekt, Sprache und Quelldatei.",
  category: "Referenz",
  section: "translation",
  order: 12
}
---

## Dashboard

Öffnen Sie **Einstellungen → Modelle → Tokenverbrauch**, um die von Anbietern berichtete Nutzung für generative Übersetzungen anzuzeigen. Zugriff erfordert die Berechtigung, Modelleinstellungen zu lesen.

Das Dashboard unterstützt die letzten 7, 30 oder 90 Kalendertage, einschließlich des heutigen Tages, in UTC. Modell-, Projekt- und Sprachfilter gelten für die Gesamtwerte, das tagesbedingte Diagramm und die Aufschlüsselung. Die Suche gilt nur für Zeilen der Aufschlüsselung. Der ausgewählte Zeitraum, die Dimension, die Filter, die Suche, die Sortierung und die Seite werden in der URL beibehalten.

## Metriken

| Metrik | Bedeutung |
| --- | --- |
| Eingabetokens | Vom Anbieter verarbeitete Eingabe, einschließlich berichteter Cache-Lese- und Cache-Schreibvorgänge. |
| Ausgabetokens | Anbieterberichtete Ausgabe, einschließlich Überlegungen, wenn der Anbieter dies in seiner Ausgabenzahl einschließt. |
| Gecachte Eingabetokens | Cache-Lesevorgänge. Ein Teilmenge der Eingabetokens, keine zusätzliche Gebühr in der Summe. |
| Gesamttokens | Eingabetokens plus Ausgabetokens. |
| Antworten | Antworten mit sowohl Eingabe- als auch Ausgabenzählungen und einer positiven Token-Summe. Nullwerte für fehlende Nutzungsfallbacks werden ignoriert. |

Token-Zählungen sind keine finanziellen Kosten. Anbieter können unterschiedliche Tarife für Eingabe, Ausgabe, gecachte Eingabe und Cache-Schreiben berechnen.

Jede gemeldete Antwort wird gezählt, einschließlich Validierungswiederholungen, Wiederholungen zur Qualitätskorrektur und Antworten, die abgelehnt wurden, weil sie ihre Ausgabegrenze erreicht hatten. Übersprungte Dateien und Checkpoint-Treffer, die kein Modell aufrufen, fügen keine Nutzung hinzu. Fehlgeschlagene Anfragen ohne Nutzung können nicht gezählt werden.

## Dimensionen

- **Projekte** gruppiert die Nutzung nach Projekt. Verwenden Sie den Projektfilter, um alle Metriken auf ein einzelnes Projekt zu fesseln.
- **Sprachen** gruppiert nach Zielsprache, wie `es` oder `ja`, über Projekte im aktuellen Bereich.
- **Dateien** gruppiert nach Quellpfad und Projekt. Dieselbe Quelldatei, die in mehrere Sprachen übersetzt wurde, erscheint einmal; identisch benannte Dateien in verschiedenen Projekten bleiben getrennt.

**Unzugeordnet** hält Anfragen ohne Projekt- oder Quellpfad-Metadaten sichtbar. Repository-Übersetzungen liefern beide automatisch. Einzelinhalt-API-Anfragen können `project_id` und `source_path` für Zuordnung bereitstellen; eine Projekt-ID außerhalb des authentifizierten Kontos wird als unzugewiesen behandelt. Ungültige oder übergroße optionale Metadaten werden ohne Verwerfen der Token-Zählungen unzugewiesen.

## Abdeckung

Die Nutzung wird aus ReqLLM API-Schlüssen und OAuth-Antworten, Together-Endergebnissen und abgeschlossenen lokalen Codex-Runden gesammelt. Nur anbieterberichtete Zählungen werden gespeichert. Lokale Pi-Sitzungen und Entscheidungsmodell-Bewertungen sind nicht enthalten. Historische Übersetzungen werden nicht nachträglich aufgefüllt oder geschätzt. Summen beschreiben daher aufgezeichnete Nutzung, keine vollständige Anbieterrechnung.

Das Hauptbuch speichert Konto, Projekt, Modell-Bezeichner und Handle, Zielsprache, Quellpfad, Zählungen und Zeitstempel. Es werden keine Prompts, übersetzten Inhalte, Zugangsdaten oder rohen Anbieter-Antworten gespeichert. Nutzungsprotokollierungsfehler werden protokolliert, ohne die Übersetzung zu unterbrechen.
