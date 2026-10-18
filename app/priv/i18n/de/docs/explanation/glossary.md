%{
  title: "Glossar",
  summary:
    "So stellt Glossia sicher, dass genehmigte Übersetzungen in jeder Sprache und jeder Datei konsistent sind.",
  category: "Erklärung",
  section: "translation",
  order: 5
}
---

Ein Glossar ist eine kuratierte Sammlung von Begriffen, die Ihre Übersetzungen jede Zeit auf dieselbe Weise darstellen müssen. "Commit" im Sinne der Versionskontrolle bleibt `commit` auf Spanisch, wird `提交` in vereinfachtes Chinesisch und `コミット` auf Japanisch. Eine Entscheidung pro Sprache, durchgängig durchgesetzt.

## ## Zwei Orte, an denen ein Glossar untergebracht sein kann

Glossia sucht Glossar-Einträge in zwei Orten und kombiniert sie zum Übersetzungszeitpunkt:

- **Ihr Repository**, in den Dateien, die Sie bereits zur Übersetzung verwenden. `L10N.md` erklärt die Begriffe, und die `L10N/<locale>.md` jeder Sprache erklärt ihre Übersetzungen. Dies ist das von Entwicklern autorisierte Glossar: Änderungen reisen durch Pull Requests, die Reviewer jeder Sprache verwalten ihre eigenen Dateien und verschachtelte Dateien können sie für einen Teil des Repositories verfeinern.
- **Ihr Glossia-Konto**, verwaltet durch das gehostete Dashboard. Dies ist das von Linguisten autorisierte Glossar: Reviewer und Lokalisations-Beiträge fügen oder verfeinern Einträge ohne den Code zu berühren, über das Dashboard, die [REST API](/docs/reference/apis) oder den [MCP server](/docs/reference/mcp). Es gilt für alle Repositories, die das Konto übersetzt.

Beide Orte sind nützlich, und keiner ersetzt den anderen.

## ## Wann Sie welche verwenden

Definieren Sie einen Begriff in **Ihr Glossia-Konto** wenn:

- **Er gilt für mehrere Repositorys.** Produktname, Markenbezeichnungen und Firmen-Vokabular werden einmal definiert und überall verwendet.
- **Die Personen, die entscheiden, arbeiten nicht im Repository.** Linguisten, Reviewer und externe Mitwirkende können das Glossar verfeinern, auch wenn das Repository Closed Source ist oder sie keinen Schreibzugriff darauf haben.
- **Sie möchten einen Begriff ohne Codeänderung korrigieren.** Eine korrigierte Übersetzung wirkt beim nächsten Durchlauf, ohne Pull Request gegen die Codebasis.
- **Änderungen benötigen Überprüfung und Historie.** Jede Änderung erstellt eine neue Version mit einem Änderungsnotiz, Mitwirkende können Änderungen als Vorschläge für jemanden vorbringen, diegenehmigt werden sollen, und frühere Versionen bleiben verfügbar.
- **Auch andere Tools benötigen es.** Agenten und Integrationen können das Glossar über die REST API und den MCP server lesen, zum Beispiel, um neuen Inhalt zu schreiben, der bereits die genehmigten Begriffe verwendet.

Definieren Sie einen Begriff in **Ihr Repository** wenn:

- **Er gehört zu dieser Codebasis.** Ein Begriff, dessen Bedeutung einzig für ein Projekt spezifisch ist, wie z. B. "commit" als Version-Control-Aktion, sitzt neben dem Code, der ihn nutzt.
- **Er sollte gemeinsam mit dem Quelltext geändert werden.** Der Begriff und der Text, der ihn eingeführt hat, landen im selben Pull Request und werden gemeinsam überprüft.
- **Nur ein Teil des Repositories braucht es.** In einem verschachtelten `L10N.md` oder `L10N/<locale>.md` können Einträge für ein Verzeichnis hinzugefügt oder überschrieben werden, wie etwa für Marketingseiten.
- **Es muss das Account-Glossar überschreiben.** Ein Repository-Eintrag hat Vorrang vor einem Account-Eintrag für denselben Begriff, für die Sprachen, die er übersetzt.

## ## Wie sie kombiniert werden

Für jede Datei und Zielsprache löst Glossia die beiden Glossare in eine effektive Menge auf:

1. Beginnen Sie mit den Glossar-Einträgen des Accounts für die Zielsprache.
2. Überlagern Sie die Repository-Einträge für diese Sprache: die Begriffe aus der Datei's `L10N.md` Kette, die eine Übersetzung in der `L10N/<locale>.md` Kette haben. Wenn ein Repository-Eintrag denselben Quellbegriff wie ein Account-Eintrag hat, gewinnt der Repository-Eintrag.
3. Wenn ein Repository-Begriff für eine Sprache keine Übersetzung hat, gilt der Account-Eintrag für diese Sprache weiterhin. Das Repository blockiert niemals eine Sprache, die es nicht übersetzt.

Die Zusammenführung findet **pro Zielsprache** statt, nicht pro Eintrag. Eine spanische Übersetzung von "commit" in `L10N/es.md` ersetzt den Spanisch-Eintrag des Accounts für "commit", berührt aber nicht den japanischen Eintrag des Accounts für denselben Begriff. Reviewer können sehen, welche Account-Einträge ersetzt wurden: Die Zusammenfassung der Übersetzungssitzung zeigt, wie viele überschrieben wurden, und die Lockfile jeder Datei listet sie unter `glossary.shadowed` auf.

## ## Bei Glossaränderungen: Dateien neu übersetzen

Wenn Sie einen Glossar-Eintrag bearbeiten, übersetzt Glossia nur die Dateien, deren *effektive Glossareinträge geändert wurden*. Wenn der Quelltext einer Datei keine Übereinstimmungen für den bearbeiteten Begriff enthält, bleiben ihre Übersetzungen unberührt. Wenn eine Datei den Begriff verwendet, enthält ihr nächster Übersetzungslauf die aktualisierte Anweisung.

Das gleiche Prinzip gilt rückwärts: Das Hinzufügen eines Begriffs, der nur in einem Teil der Dateien verwendet wird, erzwingt keinen kompletten Neustart.

## ## Was ein Glossar nicht ist

- Nicht ein Wörterbuch für maschinelle Übersetzung. Das Modell von Glossia liest den umgebenden Kontext und kann einen Begriff anders darstellen, wenn der Satz dies verlangt. Das Glossar ist eine Anleitung, keine Substitution.
- Nicht die gesamte Stilvorgabe. Stimme, Ton, Formalität und Zielgruppe leben in Ihrer Voice-Konfiguration und in `L10N.md`. Das Glossar ist nur für einzelne Begriffe und ihre genehmigten Übersetzungen.
- Nicht still. Jeder angewendete Begriff wird im Lockfile der Datei gespeichert, sodass ein Prüfer genau verfolgen kann, welche Glossareinträge das Modell erreicht haben.

## ## Verwandt

- Fügen Sie Ihre ersten Begriffe hinzu: [Ein Glossar definieren](/docs/how-to/define-a-glossary).
- Jedes Eintragfeld: [Glossarreferenz](/docs/reference/glossary).
- Die anderen `L10N.md` Felder: [L10N.md Referenz](/docs/reference/l10n-md).
