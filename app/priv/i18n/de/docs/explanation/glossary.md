%{
  title: "Glossar",
  summary:
    "Wie Glossia genehmigte Übersetzungen über jede Sprache und jede Datei hinweg konsistent hält.",
  category: "Erklärung",
  section: "translation",
  order: 5
}
---

Ein Glossar ist eine kuratierte Menge von Begriffen, die deine Übersetzungen jeweils auf dieselbe Weise darstellen müssen. "Commit" im Sinne der Versionskontrolle bleibt `commit` im Spanischen, wird `提交` im vereinfachten Chinesischen und `コミット` im Japanischen. Eine Entscheidung pro Sprache, überall durchgesetzt.

## Zwei Orte, an denen ein Glossar existieren kann

Glossia sucht an zwei Orten nach Glossareinträgen und fasst sie zur Übersetzungszeit zusammen:

- **Dein Repository**, in den Dateien, die du bereits für Übersetzungseinstellungen nutzt. `L10N.md` erklärt die Begriffe, und die `L10N/<locale>.md` der einzelnen Sprachen erklären deren Übersetzungen. Dies ist das entwickler-autoritäre Glossar: Änderungen werden über Pull Requests übergeben, die Reviewers jeder Sprache besitzen ihre eigene Datei, und verschachtelte Dateien können es für einen Teil des Repositories verfeinern.
- **Dein Glossia-Account**, verwaltet über das gehostete Dashboard. Dies ist das linguist-autoritäre Glossar: Reviewers und Lokalisierungsbeiträge fügen oder verfeinern Einträge, ohne den Code zu berühren, über das Dashboard, den [REST API](/docs/reference/apis) oder den [MCP Server](/docs/reference/mcp). Dies gilt für jedes Repository, das der Account übersetzt.

Beide Orte sind nützlich, und keiner ersetzt den anderen.

## Wann man welche verwendet

Definiere einen Begriff in **deinem Glossia-Account**, wenn:

- **Es gilt für mehr als ein Repository.** Produktnamen, Markenbegriffe und Unternehmensvokabular werden einmal definiert und überall verwendet.
- **D die Personen, die es entscheiden, arbeiten nicht im Repository.** Linguisten, Reviewers und externe Beiträge können das Glossar verfeinern, auch wenn das Repository Closed Source ist oder ihnen keine Schreibrechte darin gewährt sind.
- **Du möchtest einen Begriff beheben, ohne eine Codeänderung.** Eine korrigierte Übersetzung kommt im nächsten Durchlauf zur Anwendung, ohne einen Pull Request gegen die Codebasis festzulegen.
- **Änderungen benötigen Prüfung und Historie.** Jede Bearbeitung erstellt eine neue Version mit einem Änderungsnotiz, Beiträge können Änderungen als Vorschläge für jemanden zur Genehmigung vorlegen, und frühere Versionen bleiben verfügbar.
- **Andere Tools benötigen es.** Dienste und Integrationen können das Glossar über die REST API und den MCP Server lesen, z. B., um neuen Content zu schreiben, der bereits die genehmigten Begriffe verwendet.

Definiere einen Begriff in **dem Repository**, wenn:

- **Es gehört zu dieser Codebasis.** Ein Begriff, dessen Bedeutung spezifisch für ein Projekt ist, wie "commit" für die Versionskontrollhandlung, steht neben dem Code, der ihn verwendet.
- **Es sollte gemeinsam mit dem Quelltext geändert werden.** Der Begriff und der Copy, der ihn eingeführt hat, landen im selben Pull Request und werden gemeinsam rezensiert.
- **Nur ein Teil des Repositories benötigt es.** Ein verschachtelter `L10N.md` oder `L10N/<locale>.md` kann Einträge für ein Verzeichnis hinzufügen oder überschreiben, wie z. B. für Marketingseiten.
- **Es muss den Account-Glossar überlagern.** Ein Repository-Eintrag gewinnt gegenüber einem Account-Eintrag für denselben Begriff für die Sprachen, die er übersetzt.

## Wie sie kombiniert werden

Für jede Datei und Zielsprache fasst Glossia die beiden Glossare in eine effektive Menge zusammen:

1. Beginne mit den Glossar-Einträgen des Accounts für die Zielsprache.
2. Überlagere die Repository-Einträge für diese Sprache: Die Begriffe aus dem `L10N.md`-Chain der Datei, die eine Übersetzung in ihrer `L10N/<locale>.md`-Chain haben. Wenn ein Repository-Eintrag denselben Quellbegriff wie ein Account-Eintrag hat, gewinnt der Repository-Eintrag.
3. Wenn ein Repository-Begriff keine Übersetzung für eine Sprache hat, gilt der Account-Eintrag für diese Sprache dennoch. Das Repository blockiert niemals eine Sprache, die es nicht übersetzt.

Die Zusammenführung erfolgt **pro Zielsprache**, nicht pro Eintrag. Eine spanische Übersetzung von "commit" in `L10N/es.md` ersetzt den Account's spanischen Eintrag für "commit", berührt aber denAccount's japanischen Eintrag für denselben Begriff nicht. Reviewers können sehen, welche Account-Einträge ersetzt wurden: Die Übersetzungssitzungsübersicht zeigt an, wie viele überschrieben wurden, und die Lock-Datei jeder Datei listet sie unter `glossary.shadowed` auf.

## Wenn das Glossar geändert wird, werden Dateien erneut übersetzt

Wenn du einen Glossar-Eintrag bearbeitest, übersetzt Glossia nur die Dateien, deren *effektives Glossar geändert wurde*. Wenn der Quelltext einer Datei keine Übereinstimmungen für den geänderten Begriff enthält, bleiben ihre Übersetzungen unberührt. Wenn eine Datei den Begriff verwendet, umfasst der nächste Übersetzungsdurchgang den aktualisierten Anweisungen.

Das gleiche Prinzip gilt umgekehrt: Das Hinzufügen eines Begriffs, der nur von einer Teilmenge der Dateien verwendet wird, erzwingt keine vollständige Wiederherstellung.

## Was ein Glossar nicht ist

- Nicht ein Wörterbuch für maschinelle Übersetzung. Das Glossia-Modell erzwingt den umgebenden Kontext und kann einen Begriff anders darstellen, falls der Satz es verlangt. Das Glossar ist eine Richtlinie, keine Substitution.
- Nicht der gesamte Style Guide. Stimme, Ton, Formalität und Zielgruppe leben in deiner Voice-Konfiguration und in `L10N.md`. Das Glossar gilt nur für einzelne Begriffe und deren genehmigte Übersetzungen.
- Nicht stumm. Jeder angewendete Begriff wird in der Lock-Datei der Datei festgehalten, sodass ein Revisor genau nachvollziehen kann, welche Glossar-Einträge das Modell erreicht haben.

## Verwandt

- Füge deine ersten Begriffe hinzu: [Einen Glossar definieren](/docs/how-to/define-a-glossary).
- Jedes Eintragsfeld: [Glossar-Referenz](/docs/reference/glossary).
- Die anderen `L10N.md` Felder: [L10N.md Referenz](/docs/reference/l10n-md).
