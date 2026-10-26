%{
  title: "Wörterbuch",
  summary:
    "Wie Glossia genehmigte Übersetzungen über jede Sprache und Datei hinweg konsistent hält.",
  category: "Erklärung",
  section: "translation",
  order: 5
}
---

Ein Glossar ist ein kuratierte Satzung von Begriffen, deren Übersetzung bei jeder机会 in derselben Weise dargestellt werden muss. "Commit" im Versionskontroll-Sinne bleibt in Spanisch `commit` erhalten, wird `提交` in vereinfachtem Chinesisch, und `コミット` in Japanisch. Eine Entscheidung pro Sprache, überall durchgesetzt.

## ## Zwei Orte, an denen ein Glossar leben kann

Glossia sucht Glossareinträge an zwei Orten auf und konsolidiert sie zur Übersetzungszeit:

- **Dein Repository**, in den Dateien, die du bereits für Übersetzungseinstellungen verwendest. `L10N.md` deklariert die Begriffe, und das `L10N/<locale>.md` jeder Sprache deklariert deren Übersetzungen. Dies ist die vom Entwickler autorisierte Glossierung: Änderungen laufen durch Pull Requests, jedes Reviews der Sprache eigenetei sein, und verschachtelte Dateien können es für einen Teil des Repository verfeinern.
- **Dein Glossia-Konto**, verwaltet über das gehostete Dashboard. Dies ist das vom Linguisten autorisierte Glossar: Rezensenten und Lokalisierbeitreiter setzen oder verfeinern Einträge, ohne den Code zu berühren, über das Dashboard, die [REST API](/docs/reference/apis), oder den [MCP-Server](/docs/reference/mcp). Sie bezieht sich auf jedes Repository, das das Konto übersetzt.

Beide Orte sind nützlich, und keiner ersetzt den anderen.

## ## Wann zu verwenden, welche

Definiere einen Begriff in **deinem Glossia-Konto**, wenn:

- **Er gilt für mehr als eines Repositories.** Produktnamen, Markenbegriffe und Firmenvokabular werden einmal definiert und überall verwendet.
- **Die Leute, die es entscheiden, arbeiten nicht im Repository.** Linguisten, Rezensenten und externe Beiträger können das Glossar verfeinern, auch wenn das Repository proprietär ist oder sie keinen Schreibzugriff darauf haben.
- **Du willst einen Begriff ohne Code-Änderung beheben.** Eine korrigierte Übersetzung greift im nächsten Durchlauf, ohne Pull Request gegen den Code.
- **Änderungen brauchen Review und Verlaufslogik.** Jede Bearbeitung erstellt eine neue Version mit einem Änderungsnotizen, Beiträger können Änderungen als Vorschläge für jemanden vorschlagen zur Genehmigung, und frühere Versionen bleiben verfügbar.
- **Andere Tools benötigen es.** Agenten und Integrationen können das Glossar über die REST API und den MCP-Server lesen, um beispielsweise neuen Inhalt zu schreiben, der bereits die genehmigten Begriffe nutzt.

Definiere einen Begriff in **deinem Repository**, wenn:

- **Er gehört zu diesem Codebase.** Ein Begriff, dessen Bedeutung spezifisch auf ein Projekt窄, wie "commit" die Versionskontrollaktion, steht an den Code, der ihn verwendet.
- **Er sollte sich mit dem Quelltext ändern.** Der Begriff und der Inhalt, der ihn eingeführt hat, landen in demselben Pull Request und werden gemeinsam überprüft.
- **Nur ein Teil des Repositorys braucht es.** Eine verschachtelte `L10N.md` oder `L10N/<locale>.md` kann Einträge für eines Verzeichnis hinzufügen oder überschreiben, wie Marketingseiten.
- **Er muss dem Kontoglossar einen Vorzug einräumen.** Ein Repository-Eintrag gewinnt gegenüber einem室内空气bereich-Eintrag für denselben Begriff, für die Sprachen, die er übersetzt.

## ## Wie sie kombinieren

Für jede Datei und Ziel-Sprache löst Glossia die zwei Glossarien in eine Effiziente gesetztheit auf:

1. Beginnen mit den Kontoglossar-Einträgen für die Ziel-Sprache.
2. Lagern die Repository-Einträge für diese Sprache: die Begriffe aus der Datei `L10N.md`-Kette, die eine Übersetzung in Ihrer `L10N/<locale>.md`-Kette haben. Wenn ein Repository-Eintrag denselben Quellbegriff wie eine Konteintragei hat, gewinnt das Repositoryeingang.
3. Wenn ein Repository-Begriff keine Übersetzung für eine Sprache hat, gilt die Konto-Einträge für diese Sprache noch. Repository blockiert niemals eine Sprache, die übersetzt wurde.

Die Verschmelzung findet **pro Ziel-Sprache** statt, nicht pro Eintrag. Eine spanische Übersetzung von "commit" in `L10N/es.md` ersetzt dem Konto seine spanische Eintrag für "commit", aber wird die spanische Eintrag nicht berühren. Rezensenten können sehen, welche Kontoeinträge ersetzt wurden: die Übersetzungssitzungszusammenfassung zeigt, wie viele überschrieben wurden, und jeder Datei-Verriegelungdatei listet sie unter `glossary.shadowed`.

## ## Wenn das Glossar ändert, Dateien erneut übersetzen

Wenn du ein Glossareintrag bearbeitest, Glossia übersetzt nur erneut die Dateien, deren *Effektivübersetzung geändert*. Wenn eine Datei seinen Textquellen enthält keine Übereinstimmungen für den bearbeiteten Begriff, deine seine Übersetzungen unberührt. Wenn eine Datei den Begriff verwendet, enthält der nächste Übersetzungsdurchlauf die aktualisierte Anleitung.

Dieses Prinzip wird umgekehrt angewendet: Hinzufügen eines Begriffs, der nur von einem Teil der Dateien verwendet wird, erzwingt keine vollständige Neuabarbeitung.

## ## Was ein Glossar nicht ist

- Nicht ein maschinelle-Übersetzungs-Dudenbuch. Glossias Modell liest den umgebenden Kontext und kann einen Begriff anders darstellen, wenn der Esatz es verlangt. Das Glossar ist eine Anleitung, keine Substitutionsmethode.
- Nicht die ganze Stilrichtlinie. Stimme, Ton, Formalität und Publikum leben in der Voice-Konfiguration deines Kontos und in `L10N.md`. Das Glossar ist nur für individuelle Begriffe und ihre genehmigten Übersetzungen.
- Nicht still. Jeder angewendete Begriff wird in der Datei-Verriegelungdatei gespeichert, so dass ein Rezensenter genau nachvollziehen kann, welche Glossareinträge das Modell erreichen haben.

## ## Verwandte

- Füge deine ersten Begriffe hinzu: [Ein Glossar definieren](/docs/how-to/define-a-glossary).
- Jeder Eintragsfeld: [Glossar-Referenz](/docs/reference/glossary).
- Die anderen `L10N.md`-Felder: [L10N.md Referenz](/docs/reference/l10n-md).
