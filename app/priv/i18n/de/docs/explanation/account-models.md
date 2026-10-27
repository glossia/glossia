%{
  title: "Account-Modelle",
  summary:
    "Warum Modellanbieter einmal pro Account konfiguriert und über handle referenziert werden.",
  category: "Erklärung",
  section: "platform",
  order: 2
}
---

Glossia trennt Repository-Anweisungen von Modell-Anbieter-Zugangsdaten. Repositorien beschreiben, was übersetzt werden soll, während Konten entscheiden, welches [große Sprachmodell](https://en.wikipedia.org/wiki/Large_language_model) die Arbeit erledigt.

## Warum Modelle zu Konten gehören

Ein Team übersetzt oft mehrere Repositorien mit der gleichen Anbieter-Beziehung. Konten-spezifische Modelle es ermöglichen Administratoren, einen Anbieter-Schlüssel zu rotieren oder das zugrundeliegende Modell einmal zu wechseln, ohne jedes Repository zu bearbeiten.

Diese Trennfläche hält Zugangsdaten auch aus der Versionskontrolle aus. Ein Repository enthält einen lesbaren Handle, wie `translation-default`, nicht den Anbieter-Schlüssel.

## Handles bieten stabile Absichten

Das `model`-Feld in `L10N.md` bezieht sich auf einen Konten-Modell-Handle:

```yaml
model: translation-default
```

Der Handle drückt die Absicht des Repositories aus. Ein Administrator kann später aktualisieren, welchen Anbieter-Modell-Handle dieser Handle auswählt, während die Repository-Konfiguration stabil bleibt.

## Wie mehrere Modelle verwendet werden

Glossia verwendet für jede Dokumentübersetzung ein konfiguriertes **generativ** Modell. Das Hinzufügen mehrerer Modelle erzeugt kein Ensemble, keine Fallback-Kette oder eine automatische Qualitätsebene. Der Autor des Repositories wählt seinen Zweck durch stabile Handles wie `translation-default`, `long-form` oder `japanese-specialist` aus.

Die Auswahl folgt der Kontexthierarchie für das Dokument und das Ziel-Locale:

1. Die nächstgelegene `L10N/<locale>.md`-Datei, die `model` deklariert, gewinnt für dieses Locale.
2. Ansonsten gewinnt die nächstgelegene `L10N.md`-Datei, die `model` deklariert, für ihr Verzeichnis.
3. Eltern- `L10N.md` -Einstellungen werden vererbt, wenn eine näherliegende Datei kein Modell deklariert.
4. Wenn keine anwendbare Kontextdatei einen Handle deklariert, verwendet Glossia das Standard-generative Modell des Kontos.

Ein explizit konfigurierter Handle muss existieren. Glossia meldet einen Fehler bei einem unbekannten Handle statt schweigsam auf die Konto-Standardumstellung zu wechseln.

## Standardauswahl

Die Projekteinrichtung benötigt ein Modell, bevor ein Repository sein eigenes `L10N.md` hat. Glossia wählt daher das Konto-Standardmodell aus. Das erste hinzugefügte Modell jeder Kategorie wird zu deren Standardmodell, und ein Administrator kann aus seiner Einstellungsseite ein anderes Modell zum Standard machen.

Sobald ein Repository `L10N.md` hat, macht die Verwendung eines expliziten Handles seine Wahl für Prüfer deutlich. Das Auslassen von `model` hält das Repository am Konto-Standard.

## Generative und Entscheidungsmodelle

Modellkonfigurationen haben zwei Kategorien:

- **Generativ** Modelle schreiben Übersetzungen und betreiben die Projekteinrichtung. Repository-Modelle-Handles und Lokale-Verkehrsregeln wählen nur diese Kategorie aus.
- **Entscheidungs** Modelle bewerten Übersetzungen gegen ein festes Qualitätsraster. Wenn ein Konto ein Entscheidungsmodell hat, prüft sein Standard-Entscheidungsmodell automatisch jedes übersetzte Repository-Dokument nach struktureller Validierung und vollständigen, einzelndokumentären Übersetzungen vom Inhalt-Endpunkt. Fragment-Anfragen sind Erstellungsprimitive; Repositoryläufe bewerten ihre zusammengesetzten Ausgabe.

Die Kategorien haben unabhängige Standards. Das Hinzufügen von Jev ändert niemals das Modell, das deine Übersetzungen schreibt. Das erste Entscheidungsmodell ermöglicht die Bewertung für nachfolgende Übersetzungsläufe; das Löschen des letzten deaktiviert die Bewertung. Konten ohne Entscheidungsmodelle behalten ihr bestehendes Verhalten.

Glossia unterstützt derzeit [TypeSafe Jev](https://docs.typesafe.ai/introduction) als Entscheidungsanbieter. Jev gibt vordefinierte Entscheidungen und Scores zurück statt Text. Glossia wandelt Schwäch-Entscheidungen in Korrekturvorschläge um, ohne sie als üblicherweise verortete oder unabhängig verifizierte Fehler vorzustellen.

## Qualitätsprüfungen und Revisionen

Der Evaluator erhält die Quelle, die Übersetzung, das Ziel-Locale, das Inhaltsformat, die Projektanweisungen und den aufgelösten Organisationskontext. Er bewertet Bedeutungserhaltung, Vollständigkeit, Terminologie, Flüssigkeit, Dokumentkohärenz, Zweck und Publikumsanziehung sowieLocale-Eignung. Stimme und Register werden bewertet, wenn Stimme, Projekt- oder Dokumenten-Anleitung verfügbar ist.

Jede Dimension muss das konfigurierte Mindestscore erreichen, der standardmäßig von 10 als 7 default ist. Ein großer oder kritischer Fehler fordert immer Korrektur, unabhängig vom Score. Vertrauen ist in Live-Bewertungs-Ereignisse enthalten und ändert keine Annahme. Diese Ereignisse werden derzeit nicht gespeichert oder im Dashboard angezeigt. Eine Schwelle von 10 erfordert einen perfekten gewichteten Score und ist in der Regel zu streng.

Fehlgeschlagene Dimensionen füttern ihre vordefinierten Korrekturvorschläge zur nächsten Übersetzungsversuch. Das bestehende `retries`-Setting des Repositories begrenzt diese Revisionen; der Inhalt-Endpunkt erlaubt drei Korrektur-Rückversuche, konfigurierbar von null bis drei mit seinem `retries`-Feld. Das vollständige überarbeitete Dokument passiert strukturellen Checks und Qualitätsbewertung erneut, bevor es akzeptiert wird.

Vorübergehende Anbieterfehler wiederholen mit exponentiellem Backoff bis zu drei Mal; ungültige Zugangsdaten und fehlerhafte Antworten versagen sofort. Erschöpfte Anbieterfehler stoppen die Datei-Übersetzung; ungeprüfte Ausgabe wird niemals akzeptiert. Bewertungen verwenden vollständige Dokumente, und übergröße Bewertungs-Eingabe wird verworfen statt zerkleinert. Serialisierte Eingaben werden konservativ auf 30.000 Bytes für Status plus die längste Frage begrenzt, und 60.000 Bytes über die vollständige Anfrage, um innerhalb von [Jevs Kontextgrenzen](https://docs.typesafe.ai/models) zu bleiben. Automatisierte Scores sind Modellurteile und erfordern weiterhin Kalibrierung gegenüber zweisprachiger menschlicher Überprüfung.

Die Evaluator-Konfiguration und die Rubrik-Version nehmen an Übersetzungs-Lockdateien teil. Aktivierung der Bewertung, Änderung von Modellen oder Schwellenwerten oder Entfernen der Bewertung macht frühere Übersetzungen für den nächsten Lauf veraltet. Anbieter-Schlüssel sind von Lockdateien ausgenommen.

## Die menschliche Überprüfungsantige

Modell-Ausgabe ist vorgeschlagene Arbeit, kein automatisches Zusammenführen. Setup- und Übersetzungsaktivität bleibt in Glossia sichtbar, während Repository-Änderungen über eine Pull-Anfrage veröffentlicht werden, damit das Team sie überprüfen kann. Dies bewahrt die gleiche Qualitäts- und Besitzgrenze, die Teams bereits für Code verwenden.
