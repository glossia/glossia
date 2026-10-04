%{
  title: "Glossar",
  summary:
    "Wie Glossia genehmigte Übersetzungen über jede Sprache und jede Datei hinweg konsistent hält.",
  category: "Erklärung",
  section: "translation",
  order: 5
}
---
Ein Glossar ist eine kuratierte Sammlung von Begriffen, die Ihre Übersetzungen jedes Mal auf die gleiche Weise darstellen müssen. \\"Commit\\" im Sinne der Versionskontrolle bleibt unverändert. `commit` im Spanischen, wird es `提交` im vereinfachten Chinesischen, und `コミット` im Japanischen. Eine Entscheidung pro Sprache, überall durchgesetzt.

## Zwei Orte, an denen ein Glossar existieren kann

Glossia durchsucht an zwei Stellen nach Glossareinträgen und verschmilzt sie bei der Übersetzung:

- **Ihr Repository**, in den Dateien, die Sie bereits für Übersetzungseinstellungen verwenden. `L10N.md` legt die Begriffe fest, und jede Sprache `L10N/<locale>.md` festigt ihre Übersetzungen. Dies ist das entwickler-autorisierte Glossar: Änderungen gelangen durch Pull-Requests, Reviewer jeder Sprache besitzen ihre eigene Datei, und verschachtelte Dateien können es für einen Teil des Repositoriums verfeinern.
- **Ihr Glossia-Konto**, wird über das gehostete Dashboard verwaltet. Dies ist das linguist-autoritäre Glossar: Reviewer und Lokalisierungsbeiträge fügen oder verfeinern Einträge ohne Codekontakt hinzu, über das Dashboard, das [REST API](/docs/reference/apis), oder das [MCP-Server](/docs/reference/mcp). Es gilt für jedes Repository, das vom Konto übersetzt wird.

Beide Orte sind nützlich, und keiner ersetzt den anderen.

## Wann welches verwendet wird

Einen Begriff definieren in **deinem Glossia-Konto** wenn:

- **Es gilt für mehr als ein Repositorium.** Produktnamen, Markenbegriffe und Firmenvokabular werden einmal definiert und überall verwendet.
- **Die Personen, die dies entscheiden, arbeiten nicht im Repositorium.** Linguisten, Rezensenten und externe Mitwirkende können das Glossar verfeinern, auch wenn das Repository im geschlossenen Quellcode-Modus liegt oder kein Schreibzugriff vorhanden ist.
- **Sie möchten einen Begriff korrigieren, ohne den Code zu ändern.** Eine korrigierte Übersetzung greift beim nächsten Lauf, ohne einen Pull Request an die Codebasis zu erstellen.
- **Änderungen erfordern Überprüfung und Versionshistorie.** Jede Änderung erstellt eine neue Version mit einer Änderungsnotiz, Mitwirkende können Änderungen als Vorschläge zur Genehmigung vorschlagen, und frühere Versionen bleiben verfügbar.
- **Andere Tools benötigen es.** Agenten und Integrationen können das Glossar über die REST-API und den MCP-Server lesen, beispielsweise um neuen Inhalt zu schreiben, der bereits die genehmigten Begriffe verwendet.

Einen Begriff definieren in **Ihr Repository** wann:

- **Es gehört zu dieser Codebasis.** Ein Begriff, dessen Bedeutung für ein Projekt spezifisch ist, wie zum Beispiel "commit" als Versionskontroll-Aktion, befindet sich neben dem Code, der ihn verwendet.
- **Es sollte sich zusammen mit dem Quelltext ändern.** Der Begriff und der Text, der ihn einführt, landen in derselben Pull Request und werden gemeinsam geprüft.
- **Nur ein Teil des Repositories benötigt es.** Ein verschachtelter `L10N.md` oder `L10N/<locale>.md` können Einträge für ein Verzeichnis hinzufügen oder überschreiben, z. B. Marketing-Seiten.
- **Es muss das Konto-Wörterbuch überschreiben.** Ein Repository-Eintrag hat gegenüber einem Konto-Eintrag für denselben Begriff Vorrang für die Sprachen, in die übersetzt wird.

## Wie sie kombiniert werden

Für jedes File und Zielsprache löst Glossia die beiden Wörterbücher in eine effektive Menge um:

1. Beginnen Sie mit den Konto-Wörterbuch-Einträgen für die Zielsprache.
2. Legen Sie die Repository-Einträge für diese Sprache darüber: die Begriffe aus der Datei `L10N.md` Kette, die eine Übersetzung in ihrer `L10N/<locale>.md` Kette. Wenn ein Repository-Eintrag den gleichen Quellterm wie ein Konto-Eintrag hat, gewinnt der Repository-Eintrag.
3. Wenn ein Repository-Begriff für eine Sprache keine Übersetzung hat, gilt der Konto-Eintrag für diese Sprache weiterhin. Das Repository blockt niemals eine Sprache, die es nicht übersetzt.

Die Zusammenführung findet **pro Zielsprache**, nicht pro Eintrag. Eine spanische Übersetzung von "commit" in `L10N/es.md` ersetzt den spanischen Eintrag des Konto-Eintrags für "commit", berührt aber nicht den japanischen Eintrag des Konto-Eintrags für denselben Begriff. Prüfer können sehen, welche Konto-Einträge ersetzt wurden: Die Übersetzungssitzungs-Zusammenfassung zeigt an, wie viele überschrieben wurden, und jede Datei-Sperrdatei listet sie unter `glossary.shadowed`.

## Wenn das Glossar sich ändert, werden Dateien neu übersetzt

Wenn Sie einen Eintrag im Glossar bearbeiten, übersetzt Glossia nur die Dateien, deren *effektives Glossar geändert*. Wenn der Quelltext einer Datei keine Übereinstimmungen für den bearbeiteten Begriff enthält, bleiben deren Übersetzungen unberührt. Wenn die Datei den Begriff verwendet, umfasst der nächste Übersetzungsvorgang die aktualisierte Anweisung.

Das gleiche Prinzip gilt umgekehrt: Das Hinzufügen eines Begriffs, der nur von einer Teilmenge der Dateien verwendet wird, erzwingt keinen vollständigen Neustart.

## Was ein Glossar nicht ist

- Nicht ein Wörterbuch für maschinelle Übersetzung. Das Glossia-Modell liest den umgebenden Kontext und kann einen Begriff anders darstellen, wenn der Satz dies verlangt. Das Glossar ist eine Richtlinie, keine Ersetzung.
- Nicht das gesamte Stilhandbuch. Stimme, Tonfall, Formalität und Zielgruppe befinden sich in der Stimmenkonfiguration Ihres Kontos und `L10N.md`. Das Glossar ist nur für einzelne Begriffe und deren genehmigte Übersetzungen.
- Nicht stumm. Jeder angewendete Begriff wird in der Lockdatei der Datei protokolliert, sodass ein Prüfer genau nachvollziehen kann, welche Glossareinträge das Modell erreicht haben.

## Verwandt

- Fügen Sie Ihre ersten Begriffe hinzu: [Ein Glossar definieren](/docs/how-to/define-a-glossary).
- Jedes Eintragsfeld: [Glossarverweis](/docs/reference/glossary).
- Das andere `L10N.md` Felder: [L10N.md Referenz](/docs/reference/l10n-md).