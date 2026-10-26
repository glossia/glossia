%{
  title: "Kontomodelle",
  summary:
    "Warum Modellanbieter einmal pro Konto konfiguriert und über Handle referenziert werden.",
  category: "Erklärung",
  section: "platform",
  order: 2
}
---

Glossia trennt Repository-Anweisungen von Anmeldeinformationen für Modelle. Repositorien beschreiben, was übersetzt werden soll, während Konten entscheiden, welches [großes Sprachmodell](https://en.wikipedia.org/wiki/Large_language_model) die Arbeit ausführt.

## Warum Modelle zu Konten gehören

Ein Team übersetzt oft mehrere Repositorien mit derselben Anbieterbeziehung. Kontenbezogene Modelle ermöglichen es Administratoren, einen Anbieter-Schlüssel zu rotieren oder das zugrundeliegende Modell einmal zu wechseln, ohne jedes Repository zu bearbeiten.

Diese Grenze hält Anmeldeinformationen ebenfalls außerhalb der Versionskontrolle. Ein Repository enthält eine lesbare Kennung wie `translation-default`, nicht den Anbieter-Schlüssel.

## Handles bieten stabile Absichten

Das `model`-Feld in `L10N.md` bezieht sich auf einen Kontomodell-Handle:

```yaml
model: translation-default
```

Die Kennung drückt die Absicht des Repositoriums aus. Ein Administrator kann später aktualisieren, welches Anbietermodell diese Kennung auswählt, während die Repository-Konfiguration stabil bleibt.

## Wie mehrere Modelle verwendet werden

Glossia nutzt für jede Dokumentübersetzung ein konfiguriertes **generativ** Modell. Das Hinzufügen mehrerer Modelle erstellt kein Ensemble, eine Failover-Kette oder eine automatische Qualitätsstufe. Der Repository-Autor wählt seinen Zweck durch stabile Kennungen aus wie `translation-default`, `long-form` oder `japanese-specialist`.

Die Auswahl folgt der Kontexthierarchie für das Dokument und das Zielsprachgebiet:

1. Die nächste `L10N/<locale>.md`-Datei, die `model` deklariert, gewinnt für dieses Sprachgebiet.
2. Sonst gewinnt die nächste `L10N.md`-Datei, die `model` deklariert, für ihr Verzeichnis.
3. Eltern-`L10N.md`-Einstellungen werden vererbt, wenn eine nähere Datei kein Modell deklariert.
4. Wenn keine anwendbare Kontextdatei eine Kennung deklariert, nutzt Glossia das Standard-generative Modell des Kontos.

Eine explizit konfigurierte Kennung muss existieren. Glossia meldet einen Fehler für eine unbekannte Kennung statt sie schweigend mit dem Standard des Kontos zu ersetzen.

## Standardauswahl

Die Projekteinrichtung benötigt ein Modell, bevor ein Repository sein eigenes `L10N.md` hat. Glossia wählt daher das Standardmodell des Kontos aus. Das erste in jeder Kategorie hinzugefügte Modell wird zum Standard dieser Kategorie, und ein Administrator kann ein anderes Modell von seiner Einstellungsseite zum Standard machen.

Sobald ein Repository `L10N.md` besitzt, macht die Verwendung einer expliziten Kennung die Entscheidung für Rezensenten klar. Das Weglassen von `model` belässt das Repository beim Standardmodell des Kontos.

## Generative und Entscheidungsmodelle

Modell-Konfigurationen haben zwei Kategorien:

- **Generativ** Modelle schreiben Übersetzungen und ermöglichen die Projekteinrichtung. Repository-Modell-Kennungen und lokalizationsroutingsregeln ausweichen nur diese Kategorie.
- **Entscheidungs** Modelle bewerten Übersetzungen anhand eines festen Qualitätsrahmens. Wenn ein Konto ein Entscheidungsmodell hat, überprüft sein Standard-Entscheidungsmodell automatisch jedes übersetzte Repository-Dokument nach strukturvalidierung und vollständigen, einzigen Dokumentübersetzungen vom Content-Endpoint. Fragmentanfragen sind Generierungsprimitive; Repository-Läufe bewerten ihre zusammengefügten Ausgaben.

Die Kategorien haben unabhängige Standards. Das Hinzufügen von Jev ändert das Modell, das deine Übersetzungen schreibt, nie. Das erste Entscheidungsmodell ermöglicht die Bewertung für nachfolgende Übersetzungsläufe; das Löschen des letzten deaktiviert die Bewertung. Konten ohne Entscheidungsmodelle behalten ihr bestehendes Verhalten.

Glossia unterstützt derzeit [TypeSafe Jev](https://docs.typesafe.ai/introduction) als Entscheidunganbieter. Jev gibt vordefinierte Auswahlmöglichkeiten und Punktzahlen statt Text zurück. Glossia wandelt Schwächenwahl in Korrekturvorschläge um, ohne sie als örtlich oder unabhängig verifizierte Fehler zu präsentieren.

## Qualitätsüberprüfungen und Revisionen

Der Bewerter erhält die Quelle, die Übersetzung, die Zielsprache, das Inhaltsformat, Projektanweisungen und den aufgelösten Organisationskontext. Er bewertet Bedeutungserhaltung, Vollständigkeit, Terminologie, Flüssigkeit, Dokumentkohärenz, Zweck- und Publikumsgerechtigkeit sowie Sprachbundsangemessenheit. Stimme und Register werden bewertet, wenn Sprach-, Projekt- oder Dokument-Hinweise verfügbar sind.

Jede Dimension muss das konfigurierte Mindest-Score erreichen, der standardmäßig 7 von 10 beträgt. Ein schwerer oder kritischer Fehler verlangt immer eine Korrektur, unabhängig von Punktzahl. Das Vertrauen ist in Live-Bewertungsereignisse enthalten und ändert die Akzeptanz nicht. Diese Ereignisse werden derzeit nicht gespeichert oder im Dashboard angezeigt. Ein Schwellenwert von 10 erfordert einen perfekten gewichteten Score und ist normalerweise zu streng.

Gescheiterte Dimensionen speisen ihre vordefinierten Korrekturvorschläge in den nächsten Übersetzungsversuch ein. Die `retries`-Einstellung des Repositoriums begrenzt diese Revisionen; der Content-Endpoint erlaubt drei Korrekturwiederholungen, konfigurierbar von null bis drei mit seinem `retries`-Feld. Das vollständige überarbeitete Dokument besteht erneut strukturelle Prüfungen und Qualitätsbewertung, bevor es akzeptiert wird.

Transiente Anbieterfehler werden bis zu drei Mal mit exponentiellem Backoff versucht; ungültige Anmeldeinformationen und falschformatierte Antworten versagen sofort. Erschöpfte Anbieterfehler stoppen die Dateiausführung; ungeprüfte Ausgabe wird nie akzeptiert. Bewertungen verwenden vollständige Dokumente, und überdimensionierten Bewertungseingaben werden statt abgeschnitten abgelehnt. Die Serialisierte Eingabe wird konservativ auf 30.000 Bytes für Zustand plus die längste Frage und 60.000 Bytes über die volle Anfrage beschränkt, um innerhalb [Jevs Kontextgrenzen](https://docs.typesafe.ai/models) zu bleiben. Automatisierte Scores sind Modellurteile und benötigen dennoch Kalibrierung gegenüber zweisprachiger menschlicher Prüfung.

Die Bewertungskonfiguration und Richtlinienversion nehmen an Übersetzungs-Sperrdateien teil. Das Aktivieren von Bewertungen, Verändern von Modellen oder Schwellenwerten oder Entfernen der Bewertung macht vorherige Übersetzungen für den nächsten Durchlauf veraltet. Anbieter-Schlüssel sind von Sperrdateien ausgeschlossen.

## Die menschliche Überprüfungsgrenze

Modelloutput ist vorgeschlagene Arbeit, kein automatisches Zusammenführen. Projekteinrichtung und Übersetzungsaktivität bleibt in Glossia sichtbar, während Repository-Änderungen über einen Pull Request für das Team veröffentlicht werden, um zu prüfen. Dies bewahrt die gleiche Qualitäts- und Besitzgrenze, die Teams bereits für Code verwenden.
