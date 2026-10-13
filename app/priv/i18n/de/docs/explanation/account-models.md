%{
  title: "Account-Modelle",
  summary:
    "Warum Modellanbieter einmal pro Account konfiguriert und über den Handle referenziert werden.",
  category: "Erklärung",
  section: "platform",
  order: 2
}
---

Glossia trennt Repository-Anweisungen von Credentials. Repositories beschreiben, was übersetzt werden soll, während Accounts entscheiden, welches [großes Sprachmodell](https://en.wikipedia.org/wiki/Large_language_model) die Arbeit ausführt.

## Warum Modelle Accounts zugeordnet sind

Ein Team übersetzt oft mehrere Repositories mit der selben Provider-Beziehung. Account-spezifische Modelle ermöglichen Administratoren, einen Provider-Schlüssel zu rotieren oder das zugrundeliegende Modell einmal ohne Änderung aller Repositories zu wechseln.

Diese Grenze hält Credentials auch aus der Versionskontrolle. Ein Repository enthält eine lesbare Handle wie `translation-default`

## Handles bieten stabile Intention

Das `model`-Feld in `L10N.md` verweist auf ein Account-Modell-Handle:

```yaml
model: translation-default
```

Das Handle drückt die Absicht des Repositories aus. Ein Administrator kann später aktualisieren, welches Provider-Modell durch dieses Handle ausgewählt wird, während die Repository-Konfiguration stabil bleibt.

## Wie mehrere Modelle verwendet werden

Glossia verwendet für jede Dokument-Übersetzung ein konfiguriertes **generatives** Modell. Das Hinzufügen mehrerer Modelle bildet kein Ensemble, eine Fallback-Kette oder eine automatische Qualitätsebene. Der Repository-Autor wählt seinen Zweck über stabile Handles wie `translation-default`, `long-form` oder `japanese-specialist` aus.

Die Auswahl folgt der Kontexthierarchie für das Dokument und das Ziel-Locale:

1. Die nächste `L10N/<locale>.md`-Datei, die `model` deklariert, gewinnt für dieses Locale.
2. Sonst gewinnt die nächste `L10N.md`-Datei, die `model` deklariert, für ihr Verzeichnis.
3. Eltern-`L10N.md`-Einstellungen werden vererbt, wenn eine nähere Datei kein Modell deklariert.
4. Wenn keine anwendbare Kontext-Datei ein Handle deklariert, verwendet Glossia das Account-Schnittstelle-default-generatives Modell.

Ein explizit konfiguriertes Handle muss existieren. Glossia meldet einen Fehler für ein unbekanntes Handle statt stillschweigend auf das Account-Default umzuschalten.

## Standardauswahl

Projekt-Setup benötigt ein Modell, bevor ein Repository sein eigenes `L10N.md` hat. Glossia wählt daher das Account-Default aus. Das erste Modell in jeder Kategorie wird Standard für diese Kategorie, und ein Administrator kann ein anderes Modell über dessen Einstellungsseite zum Standard machen.

Sobald ein Repository `L10N.md` hat, macht das Verwenden eines expliziten Handles seine Wahl für Rezensenten klar. Wenn `model` weggelassen wird, bleibt das Repository beim Account-Default.

## Generative und Entscheidungs-Modelle

Modell-Konfigurationen haben zwei Kategorien:

- **Generative**-Modelle schreiben Übersetzungen und betreiben Projekt-Setup. Repository-Modell-Handles und Locale-Routing-Regeln wählen nur diese Kategorie aus.
- **Entscheidungs**-Modelle bewerten Übersetzungen gegen eine feste Qualitätsrubrik. Wenn ein Account ein Entscheidungs-Modell hat, überprüft sein Standard-Entscheidungs-Modell jedes übersetzte Repository-Dokument automatisch nach struktureller Validierung und vollständigen, Single-Document-Übersetzungen vom Content-Endpoint. Fragment-Anfragen sind Generierungs-Primitiven; Repository-Läufe bewerten ihre assemblierte Ausgabe.

Die Kategorien haben unabhängige Standards. Das Hinzufügen von Jev ändert das Modell nie, das Ihre Übersetzungen schreibt. Das erste Entscheidungs-Modell ermöglicht Bewertung für nachfolgende Übersetzungs-Läufe; das Löschen des letzten deaktiviert die Bewertung. Contos ohne Entscheidungs-Modelle behalten ihr bestehendes Verhalten.

Glossia unterstützt derzeit [TypeSafe Jev](https://docs.typesafe.ai/introduction) als Entscheidungsanbieter. Jev gibt vordefinierte Entscheidungen und Scores statt Prose zurück. Glossia wandelt Schwäche-Entscheidungen in Korrektur-Hinweise um, ohne sie als lokalisiert oder unabhängig verifizierte Fehler darzustellen.

## Qualitätsprüfungen und Korrekturen

Der Evaluator empfängt Source, Übersetzung, Ziel-Locale, Content-Format, Projektanweisungen und aufgelösten Organisationskontext. Er bewertet Bedeutungserhalt, Vollständigkeit, Terminologie, Flüssigkeit, Dokumentenkohärenz, Ziel- und Nutzergruppen-Passendigkeit und Locale-Tauglichkeit. Stimme und Register werden bewertet, wenn Stimme-, Projekt- oder Dokument-Führung verfügbar ist.

Jede Dimension muss das konfigurierte Mindest-Punktzahl erreichen, was Standard ist 7 von 10. Ein schwerer oder kritischer Fehler fordert Korrektur immer, unbeschadet der Punktzahl. Vertrauen ist in Live-Bewertungs-Events enthalten und ändert keine Annahme. Diese Events werden derzeit nicht gespeichert oder im Dashboard angezeigt. Eine Schwelle von 10 erfordert eine perfekte Gewichtung-Punktzahl und ist meist zu streng.

Fehlgeschlagene Dimensionen füttern ihre vordefinierten Korrektur-Hinweise in den nächsten Übersetzungs-Versuch. Die bestehende `retries`-Einstellung des Repositories begrenzt diese Revisionen; der Content-Endpoint erlaubt drei Korrektur-Restarts, konfigurierbar von Null auf drei mit seinem `retries`-Feld. Das komplette revidierte Dokument bestreitet strukturelle Prüfungen und Qualitätsbewertung erneut vor der Annahme.

Flüchtige Provider-Fehler wiederholen sich mit exponentiellem Backoff bis zu dreimal; ungültige Credentials und fehlerhaft formatierte Antworten scheitern sofort. Erschöpfte Provider-Fehler stoppen die Datein'-Übertragung; ungeprüfte Ausgabe wird nie akzeptiert. Bewertungen nutzen vollständige Dokumente, und übergroße Bewertungs-Eingabe werden abgelehnt statt abgeschnitten. Serialisierte Eingaben sind bescheiden auf 30.000 Bytes für Zustand plus längste Frage und 60.000 Bytes im gesamten Antrag begrenzt, um innerhalb [Jevs Kontextgrenzen](https://docs.typesafe.ai/models) zu bleiben. Automatisierte Scores sind Modellsprüche und erfordern immer noch Kalibrierung gegenüber zweisprachiger menschlicher Prüfung.

Evaluator-Konfiguration und Rubrik-Version gehen in Übersetzungs-Lockfiles. Evaluation aktivieren, Modelle oder Schwellen ändern oder Evaluation entfernen macht vorherige Übersetzungen für den nächsten Lauf veraltet. Provider-Keys werden aus Lockfiles ausgeschlossen.

## Die menschliche Prüffragegrenze

Modelloutput sind vorgeschlagene Arbeit, keine automatische Merge. Setup und Übersetzungsaktivität bleibt in Glossia sichtbar, während Repository-Änderungen über einen Pull-Request für das Team veröffentlicht werden. Das bewahrt die gleiche Qualitäts- und Besitzgrenze, die Teams bereits für Code nutzen.
