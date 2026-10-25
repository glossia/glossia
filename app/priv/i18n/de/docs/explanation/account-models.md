%{
  title: "Konto-Modelle",
  summary:
    "Warum Modell-Anbieter einmal pro Konto konfiguriert werden und per Handle referenziert werden.",
  category: "Erklärung",
  section: "platform",
  order: 2
}
---

Glossia trennt Repository-Anweisungen von Modell-Anbieter-Zugangsdaten. Repositories beschreiben, was übersetzt werden soll, während Accounts entscheiden, welches [großes Sprachmodell](https://en.wikipedia.org/wiki/Large_language_model) die Arbeit ausführt.

## Warum Modelle Accounts gehören

Ein Team übersetzt oft mehrere Repositories mit derselben Anbieter-Beziehung. Modelle, die einem Account zugeordnet sind, ermöglichen es Administratoren, einen Anbieter-Schlüssel zu rotieren oder das zugrundeliegende Modell einmal zu wechseln, ohne jedes Repository zu bearbeiten.

Diese Trennung hält Zugangsdaten zudem aus der Quellcodeverwaltung fern. Ein Repository enthält eine lesbare Bezeichnung wie `translation-default`, nicht den Anbieter-Schlüssel.

## Handles bieten stabile Intentionen

Das `model`-Feld in `L10N.md` bezieht sich auf einen Account-Modell-Handle:

```yaml
model: translation-default
```

Der Handle drückt die Absicht des Repositorys aus. Ein Administrator kann später aktualisieren, welches Anbieter-Modell dieser Handle auswählt, während die Repository-Konfiguration stabil bleibt.

## Wie mehrere Modelle verwendet werden

Glossia verwendet ein konfiguriertes **generatives** Modell für jede Dokumentübersetzung. Das Hinzufügen mehrerer Modelle führt kein Ensemble, keine Fallback-Kette oder eine automatische Qualitätsstufe herbei. Der Repository-Autor wählt seinen Zweck durch stabile Handles wie `translation-default`, `long-form` oder `japanese-specialist` aus.

Die Auswahl folgt der Kontexthierarchie für das Dokument und das Zielsprachgebiet:

1. Die nächstgelegene `L10N/<locale>.md`-Datei, die `model` deklariert, gewinnt für dieses Sprachgebiet.
2. Falls nicht, gewinnt die nächstgelegene `L10N.md`-Datei, die `model` dekariert, für sein Verzeichnis.
3. Eltern-`L10N.md`-Einstellungen werden vererbt, wenn eine näherliegende Datei kein Modell deklariert.
4. Wenn keine anwendbare Kontextdatei einen Handle deklariert, verwendet Glossia das Standard-Generativ-Modell des Accounts.

Ein explizit konfigurierter Handle muss existieren. Glossia meldet einen Fehler für einen unbekannten Handle, anstatt schweigend auf das Account-Standard zu wechseln.

## Standardauswahl

Die Projekt-Einrichtung benötigt ein Modell, bevor ein Repository sein eigenes `L10N.md` hat. Glossia wählt daher das Account-Standard aus. Das erste hinzugefügte Modell jeder Kategorie wird das Standardmodell dieser Kategorie, und ein Administrator kann ein anderes Modell von seiner Einstellungsseite zum Standard machen.

Sobald ein Repository `L10N.md` hat, macht das Verwenden eines expliziten Handles die Wahl für Rezensenten klar. Das Unterlassen von `model` hält das Repository beim Account-Standard.

## Generative und Entscheidende Modelle

Modell-Konfigurationen haben zwei Kategorien:

- **Generative** Modelle schreiben Übersetzungen und versorgen die Projekt-Einrichtung. Repository-Modell-Handles und Sprachgebietsrouting-Regeln wählen nur diese Kategorie aus.
- **Decision** Modelle bewerten Übersetzungen gegen eine feste Qualitätsrubrik. Wenn ein Account ein Entscheidmodells دارد, überprüft sein Standard-Entscheidungsmeld automatisches jedes übersetzte Repository-Dokument nach struktureller Validierung und vollständigen, einzelnen Dokument-Übersetzungen vom Content-Endpunkt. Fragmentbuchungen sind Generierungs-Primitiven; Repository-Läufe bewerten ihre zusammengelegten Ausgaben.

Kategorien haben unabhängige Standards. Das Hinzufügen von Jev ändert niemals das Modell, das Ihre Übersetzungen erstellt. Das erste Entscheidungsmodell ermöglicht die Bewertung für nachfolgende Übersetzungsläufe; das Löschen des letzten deaktiviert die Bewertung. Konten ohne Entscheidungsmodelle behalten ihr bestehendes Verhalten bei.

Glossia unterstützt derzeit [TypeSafe Jev](https://docs.typesafe.ai/introduction) als Entscheidungsanbieter. Jev liefert vorgegebene Optionen und Scores statt Fließtext. Glossia wandelt Schwächenoptionen in Korrekturhinweise um, ohne sie als lokalisierte oder eigenständig überprüfte Fehler darzustellen.

## Qualitätsüberprüfungen und Überarbeitungen

Der Evaluierer empfängt die Quelle, Übersetzung, Zielsprache, Inhaltsformat, Projektanweisungen und gelösten Organisationskontext. Er bewertet Bedeutungserhalt, Vollständigkeit, Terminologie, Sprachfluss, Dokumentenkohärenz, Zweck und Zielgruppenpassung sowie Sprachraumtauglichkeit. Stimme und Register werden bewertet, wenn Stimm-, Projekt- oder Dokumentführung verfügbar ist.

Jede Dimension muss das konfigurierte Mindestergebnis erreichen, das standardmäßig 7 von 10 ist. Ein wichtiger oder kritischer Fehler fordert jederzeit Korrektur an, unabhängig vom Ergebnis. Zuversicht ist in Live-Bewertungsevents enthalten und ändert die Annahme nicht. Diese Events werden derzeit nicht gespeichert oder im Armaturenbrett angezeigt. Eine Schwelle von 10 erfordert ein perfektes Gewichtetergebnis und ist meist zu streng.

Gescheiterte Dimensionen füttern ihre vorgegebenen Korrekturhinweise in den nächsten Übersetzungsversuch. Die bestehende `retries`-Einstellung des Repositorys begrenzt diese Überarbeitungen; der Content-Endpunkt erlaubt drei Korrektur-Retrys, konfigurierbar von null bis drei mit seinem `retries`-Feld. Das vollständige revidierte Dokument passiert Strukturprüfungen und Qualitätsbewertung erneut, bevor es akzeptiert wird.

Transientie Providerfehler undergon exponentialen Backoff bis zu drei Versuchen; ungültige Credentials und fehlerhafte Antworten scheitern sofort. Erschöpfte Providerfehler stoppen die Übersetzung des Dokuments; ungeprüfte Ausgabe wird niemals akzeptiert. Bewertungen verwenden vollständige Dokumente, und oversized Eingaben werden abgewiesen statt abgeschnitten. Serialisierte Eingaben werden vorsichtig auf 30.000 Bytes für Status plus die längste Frage und 60.000 Bytes über die gesamte Anfrage begrenzt, um innerhalb der [Jev-Context-Grenzen](https://docs.typesafe.ai/models) zu bleiben. Automatisierte Scores sind Modellurteile und erfordern weiterhin Kalibrierung gegenüber spracheigenen menschlichen Prüfungen.

Die Evaluierungs-Konfiguration und Rubrik-Version sind in Übersetzungs-Lockfiles enthalten. Das Aktivieren der Evaluation, das Ändern von Modellen oder Schwellenwerten oder das Entfernen der Evaluation macht vorherige Übersetzungen für den nächsten Lauf veraltet. Provider-Schlüssel werden von Lockfiles ausgeschlossen.

## Die menschliche Prüfgrenze

Modellausgabe ist vorgeschlagene Arbeit, kein automatischer Merge. Setup und Übersetzungsaktivität bleibt in Glossia sichtbar, während Repository-Änderungen über einen Pull Request veröffentlicht werden, damit das Team überprüfen kann. Dies bewahrt dieselbe Qualitäts- und Eigentums-Grenze, die Teams bereits für Code verwenden.
