%{
  title: "Glossar",
  summary:
    "Wie Glossia genehmigte Übersetzungen konsistent über jede Sprache und jede Datei hinweg hält.",
  category: "Erklärung",
  section: "translation",
  order: 5
}
---

Ein Glossar ist eine kuratierte Menge an Begriffen, die deine Übersetzungen jedes Mal auf die gleiche Weise wiedergeben müssen. "Commit" im Sinne der Versionskontrolle bleibt `commit` im Spanischen, wird `提交` im vereinfachten Chinesischen zu `コミット` und im Japanischen. Eine Entscheidung pro Sprache, die überall durchgesetzt wird.

## Zwei Orte, an denen ein Glossar leben kann

Glossia sucht an zwei Stellen nach Glossar-Einträgen und verschmelzt sie zum Zeitpunkt der Übersetzung:

- **Dein Repository**, in den Dateien, die du bereits für Übersetzungssettings verwendest. `L10N.md` erklärt die Begriffe, und jede Sprache’s `L10N/<locale>.md` erklärt ihre Übersetzungen. Dies ist das developer-authoritative Glossar: Änderungen reisen durch Pull Requests, jede Sprache’s Reviewer besitzt ihre eigene Datei, und verschachtelte Dateien können sie für einen Teil des Repository verfeinern.
- **Dein Glossia-Konto**, verwaltet über das gehostete Dashboard. Dies ist das linguist-authoritative Glossar: Reviewer und Lokalisierungskontribuenten fügen oder verfeinern Einträge hinzu, ohne den Code zu berühren, über das Dashboard, der [REST API](/docs/reference/apis) oder der [MCP-Server](/docs/reference/mcp). Es gilt für jedes Repository, das das Konto übersetzt.

Beide Orte sind nützlich und keiner ersetzt den anderen.

## Wann man welchen verwendet

Definieren Sie einen Begriff in **deinem Glossia-Konto**, wenn:

- **Es gilt für mehr als ein Repository.** Produktnamen, Markenbegriffe und Firmenwortschatz werden einmal definiert und überall verwendet.
- **Die Personen, die die Entscheidung treffen, arbeiten nicht im Repository.** Linguisten, Rezensenten und externe Mitwirkende können das Glossar verfeinern, selbst wenn das Repository proprietär ist oder sie keinen Schreibzugriff darauf haben.
- **Sie möchten einen Begriff ohne Codeänderung korrigieren.** Eine korrigierte Übersetzung gilt beim nächsten Durchlauf, ohne Pull Request in der Codebasis.
- **Änderungen benötigen Prüfung und Historie.** Jede Bearbeitung erstellt eine neue Version mit einer Änderungsnotiz, Mitwirkende können Änderungen als Vorschläge für jemanden zur Genehmigung vorschlagen, und frühere Versionen bleiben verfügbar.
- **Andere Tools benötigen es.** Agenten und Integrationen können das Glossar über die REST API und den MCP-Server lesen, um beispielsweise neuen Inhalt zu schreiben, der bereits die genehmigten Begriffe verwendet.

Definieren Sie einen Begriff in **deinem Repository**, wenn:

- **Es gehört zu diesem Codesatz.** Ein Begriff, dessen Bedeutung spezifisch für ein Projekt ist, wie "commit" im Sinne der Versionskontrollaktion, befindet sich neben dem Code, der ihn verwendet.
- **Es sollte gemeinsam mit dem Quelltext geändert werden.** Der Begriff und der Text, der ihn eingeführt hat, gelangen im selben Pull Request zusammen und werden gemeinsam geprüft.
- **Nur ein Teil des Repositorys benötigt es.** Ein verschachteltes `L10N.md` oder `L10N/<locale>.md` kann Einträge für ein Verzeichnis hinzufügen oder überschreiben, wie z. B. Marketingseiten.
- **Es muss das Account-Glossar überschreiben.** Ein Repository-Eintrag gewinnt gegenüber einem Account-Eintrag für denselben Begriff, für die Sprachen, die es übersetzt.

## Wie sie kombiniert werden

Für jede Datei und Zielsprache löst Glossia die beiden Glossare in einen effektiven Satz von Grunderfahrungen auf:

1. Beginnen Sie mit den Konto-Glossar-Einträgen für die Zielsprache.
2. Überlagern Sie die Repository-Einträge für diese Sprache: die Begriffe aus der Datei’s `L10N.md` -Kette, die eine Übersetzung in ihrer `L10N/<locale>.md` -Kette haben. Wenn ein Repository-Eintrag denselben Quellbegriff wie ein Konto-Eintrag hat, gewinnt der Repository-Eintrag.
3. Wenn ein Repository-Begriff keine Übersetzung für eine Sprache hat, gilt der Konto-Eintrag für diese Sprache immer noch. Das Repository blockiert niemals eine Sprache, die es nicht übersetzt hat.

Die Verschmelzung findet **pro Zielsprache** statt, nicht pro Eintrag. Eine spanische Übersetzung von "commit" in `L10N/es.md` ersetzt den Konto’s spanischen Eintrag für "commit", berührt aber nicht den Konto’s japanischen Eintrag für denselben Begriff. Reviewer können sehen, welche Konto-Einträge ersetzt wurden: die Übersetzungssitzungs-Zusammenfassung zeigt, wie viele überwältigt wurden, und jedes Datei’s lockfile listet sie unter `glossary.shadowed`.

## Wenn das Glossar sich ändert, Dateien re-translate

Wenn Sie einen Glossar-Eintrag bearbeiten, re-translate Glossia nur die Dateien, deren *effektives Glossar geändert* wurde. Wenn der Quelltext einer Datei keine Übereinstimmungen für den bearbeiteten Begriff enthält, bleiben seine Übersetzungen unberührt. Wenn eine Datei den Begriff verwendet, wird der nächste Übersetzungsvorgang die aktualisierte Anweisung enthalten.

Das gleiche Prinzip gilt in umgekehrter Richtung: das Hinzufügen eines Begriffs, der nur von einem Teil der Dateien verwendet wird, erzwingt keinen vollständigen Neustart.

## Was ein Glossar nicht ist

- Nicht ein maschineller Übersetzungsdienst. Glossia’s Modell liest den Kontext und kann einen Begriff anders rendern, wenn der Satz es erfordert. Das Glossar ist ein Hinweis, keine Substitution.
- Nicht die gesamte Stilrichtlinie. Stimme, Tonart, Formalität und Publikum leben in der Konfiguration Ihrer Kontostimme und in `L10N.md`.
- Nicht stillschweigend. Jeder angewendete Begriff wird im lockfile der Datei aufgezeichnet, damit ein Reviewer verfolgen kann, welche Glossar-Einträge das Modell erreicht haben.

## Verwandte

- Fügen Sie Ihre ersten Begriffe hinzu: [Ein Glossar definieren](/docs/how-to/define-a-glossary).
- Jeder Eintragsfeld: [Glossar-Referenz](/docs/reference/glossary).
- Die anderen `L10N.md` Felder: [L10N.md Referenz](/docs/reference/l10n-md).
