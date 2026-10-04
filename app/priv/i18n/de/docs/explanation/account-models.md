%{
  title: "Account-Modelle",
  summary:
    "Warum Modellanbieter einmal pro Account konfiguriert und per Handle referenziert werden.",
  category: "Erklärung",
  section: "platform",
  order: 2
}
---
Glossia trennt Repository-Anweisungen von Modellanbieter-Zugangsdaten. Repositories beschreiben, was übersetzt werden soll, während Konten entscheiden, welches [großes Sprachmodell](https://en.wikipedia.org/wiki/Large_language_model) die Arbeit ausführt.

## Warum Modelle Accounts zugeordnet sind

Ein Team übersetzt oft mehrere Repositories mit demselben Anbieterverhältnis. Konto-spezifische Modelle erlauben es Administratoren, einen Anbieter-Schlüssel zu rotieren oder das zugrundeliegende Modell einmal zu wechseln, ohne jedes Repository zu bearbeiten.

Diese Grenze hält Zugangsdaten ebenfalls aus der Versionskontrolle fern. Ein Repository enthält einen lesbaren Bezeichner wie `translation-default`nicht den Anbieter-Schlüssel.

## Bezeichner bewahren stabile Intentionen.

Das `model` Feld in `L10N.md` bezieht sich auf einen Kontomodell-Handle:

```yaml
model: translation-default
```

Der Handle drückt die Intention des Repositoriums aus. Ein Administrator kann später aktualisieren, welches Provider-Modell dieser Handle auswählt, während die Konfiguration des Repositoriums stabil bleibt.

## Wie mehrere Modelle verwendet werden

Glossia verwendet ein konfiguriertes **generatives** Modell für jede Dokumentübersetzung. Das Hinzufügen mehrerer Modelle erzeugt kein Ensemble, keine Fallback-Kette oder keine automatische Qualitätsebene. Der Repositorium-Autor wählt seinen Zweck durch stabile Handles wie `translation-default`, `long-form`, oder `japanese-specialist`.

Die Auswahl folgt der Kontexthierarchie für das Dokument und die Zielsprache:

1. Die nächste `L10N/<locale>.md` Datei, die `model` gewinnt für diese Zielsprache.
2. Sonst die nächste `L10N.md` die Datei, die erklärt `model` gewinnt Vorrang für sein Verzeichnis.
3. Elternteil `L10N.md` Einstellungen werden vererbt, wenn eine näherliegende Datei kein Modell erklärt.
4. Wenn keine anwendbare Kontextdatei einen Handle erklärt, verwendet Glossia das standardmäßige generative Modell des Kontos.

Ein explizit konfigurierter Handle muss vorhanden sein. Glossia meldet einen Fehler für einen unbekannten Handle anstatt stumm auf die Standardeinstellung des Kontos umzuschalten.

## Standardauswahl

Das Projektsetup benötigt ein Modell, bevor das Repository ein eigenes besitzt. `L10N.md`. Glossia wählt daher das Konto-Standard aus. Das zuerst in jeder Kategorie hinzugefügte Modell wird zum Standard dieser Kategorie, und ein Administrator kann ein anderes Modell als Standard auf seiner Einstellungsseite festlegen.

Sobald ein Repository hat `L10N.md`Verwenden eines expliziten Handles macht die Wahl für die Prüfer eindeutig. Das Weglassen `model` behält das Repository beim Konto-Standard.

## Generativ und Entscheidungsmodelle

Modellkonfigurationen haben zwei Kategorien:

- **Generativ** Modelle erstellen Übersetzungen und ermöglichen Projekt-Einrichtung. Repositorymodel-Handles und Lokalisierungs-Routing-Regeln wählen ausschließlich diese Kategorie aus.
- **Entscheidung** Modelle bewerten Übersetzungen anhand eines festgelegten Qualitätsrahmens. Wenn ein Konto ein Entscheidungsmodell hat, prüft sein Standard-Entscheidungsmodell automatisch jedes übersetzte Repository-Dokument nach der strukturellen Validierung und vollständigen, einzelnen Dokument-Übersetzungen vom Content-Endpunkt. Fragmentanfragen sind Generierungsprimitive; Repositoryläufe bewerten ihre zusammengesetzte Ausgabe.

Die Kategorien haben unabhängige Standards. Das Hinzufügen von Jev verändert das Modell, das Ihre Übersetzungen erstellt, nie. Das erste Entscheidungsmodell ermöglicht die Evaluierung für nachfolgende Übersetzungsläufe; das Löschen des letzten deaktiviert die Evaluierung. Konten ohne Entscheidungsmodelle behalten ihr bestehendes Verhalten.

Glossia unterstützt derzeit [TypeSafe Jev](https://docs.typesafe.ai/introduction) als Entscheidungsanbieter. Jev gibt voreingestellte Optionen und Bewertungen statt Text zurück. Glossia wandelt Schwäche-Optionen in Korrekturhinweise um, ohne sie als lokalisierte oder unabhängig verifizierte Fehler darzustellen.

## Qualitätsprüfungen und Überarbeitungen

Der Prüfer erhält die Quelle, die Übersetzung, die Zielsprache, das Inhaltsformat, die Projektanweisungen und den gelösten Organisationskontext. Er bewertet Bedeutungserhaltung, Vollständigkeit, Terminologie, Fließfähigkeit, Dokumentkohärenz, Zweck- und Zielgruppenanpassung sowie Lokalisierungsangemessenheit. Stimme und Register werden bewertet, wenn Stimme-, Projekt- oder Dokumentenführung verfügbar sind.

Jede Dimension muss das konfigurierte Mindestergebnis erreichen, das auf 7 von 10 standardmäßig eingestellt ist. Ein schwerer oder kritischer Fehler fordert immer Korrektur, unabhängig vom Score. Der Vertrauenskoeffizient ist in Live-Bewertungsevents enthalten und ändert die Annahme nicht. Diese Ereignisse werden derzeit nicht gespeichert oder im Dashboard angezeigt. Ein Schwellenwert von 10 erfordert einen perfekten gewichteten Score und ist in der Regel zu streng.

Fehlende Dimensionen übermitteln ihre vordefinierten Korrekturvorschläge an den nächsten Übersetzungsversuch. Die im Repository bestehende `retries`-Einstellung begrenzt diese Revisionen; der Content-Endpoint erlaubt drei Korrekturwiederholungen, konfigurierbar von null bis drei mit dem `retries`-Feld. Das vollständig überarbeitete Dokument besticht erneut bei strukturellen Prüfungen und der Qualitätsbewertung, bevor es akzeptiert wird.

Temporäre Anbieterausfälle werden mit exponentiellen Backoff bis zu dreimal wiederholt; ungültige Anmeldedaten und falsch formatierte Antworten versagen sofort. Erschöpfte Anbieterausfälle stoppen die Dateiübersetzung, und nicht geprüfte Ausgaben werden niemals akzeptiert. Bewertungen nutzen vollständige Dokumente, und zu große Bewertungsdaten werden abgelehnt statt verkürzt. Serialisierte Eingaben werden konservativ auf maximal 30.000 Byte für Zustand plus die längste Frage und maximal 60.000 Byte über die gesamte Anfrage begrenzt, um innerhalb der [Jev’s context limits](https://docs.typesafe.ai/models) zu bleiben. Automatisierte Scores sind Modellermittlungen und benötigen dennoch Kalibrierung gegenüber zweisprachiger menschlicher Prüfung.

Die Evaluatoren-Konfiguration und die Rubrik-Version wirken in Übersetzungs-Sperrdateien mit. Das Aktivieren der Bewertung, das Ändern von Modellen oder Schwellenwerten oder das Entfernen der Bewertung macht vorherige Übersetzungen für den nächsten Durchlauf veraltet. Anbieter-Schlüssel sind von Sperrdateien ausgeschlossen.

## Die menschliche Prüfgrenze

Modellergebnisse sind vorgeschlagene Arbeit, keine automatische Verschmelzung. Einrichtung und Übersetzungsaktivitäten bleiben in Glossia sichtbar, während Repositorien-Änderungen über einen Pull-Request zur Prüfung durch das Team veröffentlicht werden. Dies erhält die gleiche Qualitäts- und Zuständigkeitsgrenze, die Teams bereits für Code nutzen.