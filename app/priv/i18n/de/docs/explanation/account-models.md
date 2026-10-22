%{
  title: "Konto-Modelle",
  summary:
    "Warum Modellanbieter einmal pro Konto konfiguriert sind und über handle referenziert werden.",
  category: "Erklärung",
  section: "platform",
  order: 2
}
---

Glossia trennt Repository-Instruktionen von Modell-Anbieter-Credentials. Repositories beschreiben, was übersetzt werden soll, während Konten festlegen, welches [großes Sprachmodell](https://en.wikipedia.org/wiki/Large_language_model) die Arbeit ausführt.

## ## Warum Modelle Accounts gehören

Ein Team übersetzt oft mehrere Repositories mit derselben Anbieterbeziehung. Accountspezifische Modelle ermöglichen es Administratoren, einen Anbieter-Schlüssel zu rotieren oder das zugrundeliegende Modell einmal zu wechseln, ohne jedes Repository zu bearbeiten.

Diese Grenze hält Zugangsdaten auch aus dem Source Control fern. Ein Repository enthält eine lesbare Bezeichnung, wie `translation-default`, nicht den Anbieter-Schlüssel.

## Handles bieten stabile Absicht

Das `model`-Feld in `L10N.md` bezieht sich auf ein Account-Modell-Handle:

```yaml
model: translation-default
```

Das Handle spricht die Absicht des Repositorys aus. Ein Administrator kann später aktualisieren, welches Provider-Modell dieses Handle auswählt, während die Repository-Konfiguration stabil bleibt.

## Wie mehrere Modelle verwendet werden

Glossia verwendet ein konfiguriertes **generatives** Modell für jede Dokumentübersetzung. Das Hinzufügen mehrerer Modelle erzeugt kein Ensemble, eine Fallback-Kette oder einen automatischen Qualitätstras. Der Repository-Autor wählt seinen Zweck durch stabile Handles wie `translation-default`, `long-form`, oder `japanese-specialist`.

Die Auswahl folgt der Kontexthierarchie für das Dokument und das Ziel-Locale:

1. Das naheliegendste `L10N/<locale>.md`-Datei, die `model` deklariert, gewinnt für dieses Locale.
2. Sonst gewinnt die naheliegendste `L10N.md`-Datei, die `model` deklariert, für sein Verzeichnis.
3. Parent `L10N.md`-Einstellungen (übersetzungsebene L10N.md) sind vererbbar, wenn eine näherliegende Datei kein Modell deklariert.
4. Wenn keine anwendbare Kontextdatei ein Handle deklariert, verwendet Glossia das Konto-Standard generative Modell.

Ein explizit konfiguriertes Handle muss existieren. Glossia meldet einen Fehler für ein unbekanntes Handle statt stillschweigend auf das Konto-Standard umzuschalten.

## Standardauswahl

Die Projekteinrichtung benötigt ein Modell, bevor ein Repository über seine eigene `L10N.md`. Glossia wählt daher das Konto-Standard.

Sobald ein Repository `L10N.md` hat, macht die Verwendung eines expliziten Handle seine Wahl für Reviewer klar. Weglassen von `model` lässt das Repository beim Konto-Standard.

## Generativ und Entscheidungs-Modelle

Modell-Konfigurationen haben zwei Kategorien:

- **Generativ**-Modelle schreiben Übersetzungen und versorgen die Projekteinrichtung. Repository-Modell-Handles und Locale-Routing-Regeln wählen nur diese Kategorie aus.
- **Entscheidung**-Modelle bewerten Übersetzungen gegen einen festen Qualitäts-Rubrik. Wenn ein Konto ein Entscheidungsmodell hat, prüft sein Standard-Entscheidungs-Modell automatisch jedes übersetzte Repository-Dokument after struktureller Validierung und vollständigen, Single-Document-Übersetzungen vom Content-Endpoint. Fragment-Requests sind Generierungsprimitive; Repository-Läufe bewerten ihre zugebaute Ausgabe.

Die Kategorien haben unabhängige Standards. Das Hinzufügen von Jev ändert nie das Modell, das Ihre Übersetzungen schreibt. Das erste Entscheidungsmodell ermöglicht Evaluation für nachfolgende Übersetzungs-Läufe; das Löschen des letzten deaktiviert Evaluation. Konten ohne Entscheidungsmodelle behalten ihr bestehendes Verhalten.

Glossia unterstützt derzeit [TypeSafe Jev](https://docs.typesafe.ai/introduction) als Entscheidungsanbieter. Jev liefert vordefinierte Entscheidungen und Punktzahlen statt Prosa. Glossia wandelt Schwächewahl in Korrekturhinweise um, ohne sie als lokalisierte oder unabhängig verifizierte Fehler darzustellen.

## Qualitätsprüfungen und Revisionen

Der Evaluator empfängt Quelle, Übersetzung, Ziel-Locale, Inhalt-Format, Projektrichtlinien und aufgelösten Organisationskontext. Er bewertet Bedeutungserhaltung, Vollständigkeit, Terminologie, Flüssigkeit, Dokumentkohärenz, Zweck- und Zielgruppenpassung sowie Lokalitätsgeschicklichkeit. Ton und Register werden bewertet, wenn Ton-, Projekt- oder Dokument-Anweisungen verfügbar sind.

Jede Dimension muss das konfigurierte Minimalscore erreichen, was Standardmäßig 7 von 10 ist. Ein major oder kritischer Fehler fordert die Korrektur ein, unabhängig vom Score. Vertrauen ist in Live-Prüfungs-Events enthalten und ändert die Annahme nicht. Diese Events werden derzeit nicht im Dashboard gespeichert oder angezeigt. Ein Schwellenwert von 10 erfordert einen perfekten gewichteten Score und ist meist zu streng.

Fehlende Dimensionen leiten ihre vordefinierten Korrekturhinweise in den nächsten Übersetzungsversuch. Die bestehende `retries`-Einstellung des Repository begrenzt diese Revisionen; der Content-Endpoint erlaubt drei Korrektur-Neustarts, konfigurierbar von null bis drei mit seinem `retries`-Feld. Das vollständige revidierte Dokument besticht durch strukturelle Prüfungen und Qualitätsevaluation, bevor es akzeptiert wird.

Vorübergehende Provider-Fehler werden mit exponentiellem Backoff bis zu dreimal neu versucht; ungültige Credentials und falsche Antworten scheitern sofort. Erschöpfte Provider-Fehler stoppen die Datei-Übersetzung; ungeprüfte Ausgabe wird nie akzeptiert. Evaluierungen verwenden vollständige Dokumente, und überdimensionale Evaluierungseingabe wird abgelehnt statt gekürzt. Serialisierte Eingabe wird vorsichtig auf 30.000 Bytes für Zustand plus die längste Frage und 60.000 Bytes über den gesamten Request begrenzt, um innerhalb von [Jevs Kontextgrenzen](https://docs.typesafe.ai/models) zu bleiben. Automatisierte Scores sind Modellurteile und erfordern immer noch Kalibrierung gegenüber zweisprachiger menschlicher Prüfung.

Die Evaluierungs-Konfiguration und Rubrik-Version nehmen an Übersetzungs-Lockfiles teil. Aktivierung von Evaluation, Änderung von Modellen oder Schwellenwerten oder Entfernen der Evaluation macht frühere Übersetzungen veraltet für den nächsten Lauf. Provider-Schlüssel sind von Lockfiles ausgeschlossen.

## Die menschliche Überprüfungs-Grenze

Modell-Ausgabe ist vorgeschlagene Arbeit, keine automatische Zusammenführung. Einrichtung und Übersetzungsaktivität bleibt in Glossia sichtbar, während Repository-Änderungen über einen Pull Request für das Team veröffentlicht werden. Dies bewahrt die gleiche Qualitäts- und Eigentums-Grenze, die Teams bereits für Code verwenden.
