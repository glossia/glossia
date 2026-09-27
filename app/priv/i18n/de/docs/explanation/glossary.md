%{
  title: "Glossar",
  summary:
    "Wie Glossia genehmigte Übersetzungen konsistent über jede Sprache und Datei hinweg sichert.",
  category: "Erklärung",
  section: "Übersetzung",
  order: 5
}
---
Ein Glossar ist eine sorgfältig zusammengestellte Begriffsliste, die Ihre Übersetzungen stets identisch darstellen müssen. "Commit" im Sinne der Versionskontrolle bleibt `commit` in Spanisch lautet es `提交` in Vereinfachtem Chinesisch und `コミット` in Japanisch. Eine Entscheidung pro Sprache, überall durchgesetzt.

## Zwei Speicherorte, an denen ein Glossar liegen kann

Glossia sucht an zwei Stellen nach Glossareinträgen und verknüpft sie während der Übersetzung:

- **Ihr Repository**, in den Dateien, die Sie bereits für Übersetzungseinstellungen verwenden. `L10N.md` definiert die Begriffe, und jede Sprache `L10N/<locale>.md` definiert ihre Übersetzungen. Dies ist das entwickler-autorisierte Glossar: Änderungen reisen durch Pull-Requests, Reviewer jeder Sprache besitzen ihre eigene Datei, und verschachtelte Dateien können es für einen Teil des Repositorys verfeinern.
- **Der Server**, bei Ihrem Konto gespeichert. Dies ist das Übersetzer-autorisierte Glossar: Reviewer und Lokalisierungs-Beiträger fügen oder verfeinern Einträge, ohne den Code zu berühren, über das Dashboard, die [REST-API](/docs/reference/apis), oder den [MCP-Server](/docs/reference/mcp). Es gilt für jedes Repository, das das Konto übersetzt.

Beide Orte sind nützlich, und keiner ersetzt den anderen.

## Wann welches verwendet wird

Definieren Sie einen Begriff auf **dem Server** wenn:

- **Es gilt für mehr als ein Repository.** Produktnamen, Markenterme und Unternehmenswortschatz werden einmal definiert und überall verwendet.
- **Die Personen, die dies entscheiden, arbeiten nicht im Repository.** Linguisten, Rezensenten und externe Mitwirkende können das Glossar verfeinern, selbst wenn das Repository in geschlossener Quelle liegt oder sie keinen Schreibzugriff darauf haben.
- **Sie möchten einen Begriff korrigieren, ohne den Code zu ändern.** Eine korrigierte Übersetzung gilt beim nächsten Durchlauf, ohne Pull Request gegen den Code zu erstellen.
- **Änderungen benötigen Überprüfung und Historie.** Jede Änderung erstellt eine neue Version mit einer Änderungsnote; Mitwirkende können Änderungen als Vorschläge für die Genehmigung einreichen, und frühere Versionen bleiben verfügbar.
- **Andere Tools benötigen dies.** Agenten und Integrationen können das Glossar über die REST API und den MCP Server lesen, beispielsweise um neuen Inhalt zu erstellen, der bereits die genehmigten Begriffe verwendet.

Einen Begriff definieren in **dein Repository** bei:

- **Es gehört zu dieser Codebasis.** Ein Begriff, dessen Bedeutung für ein Projekt spezifisch ist, wie etwa "commit" für die Versionskontrolle, befindet sich neben dem Code, der ihn verwendet.
- **Es sollte sich gemeinsam mit dem Quelltext ändern.** Der Begriff und der ihn einführende Text landen im selben Pull Request und werden gemeinsam geprüft.
- **Nur ein Teil des Repositories benötigt es.** Ein verschachtelter `L10N.md` oder `L10N/<locale>.md` kann Einträge für ein Verzeichnis hinzufügen oder überschreiben, z. B. Marketing-Seiten.
- **Es muss den Server überschreiben.** Ein Repositoriumseintrag geht einem Servereintrag für denselben Begriff vor, für die Sprachen, die er übersetzt.

## Wie sie kombiniert werden

Für jede Datei und Zielsprache verbindet Glossia die beiden Glossare zu einer effektiven Menge:

1. Beginnen Sie mit den Server-Glossar-Einträgen für die Zielsprache.
2. Überlagern Sie die Repositorium-Einträge für diese Sprache: die Begriffe aus der Datei `L10N.md` Kette\[n\], die eine Übersetzung in ihrer `L10N/<locale>.md` Kette. Wenn ein Repository-Eintrag denselben Quellterm wie ein Server-Eintrag hat, gewinnt der Repository-Eintrag.
3. Wenn ein Repository-Term für eine Sprache keine Übersetzung hat, gilt der Server-Eintrag für diese Sprache weiterhin. Ein Repository blockiert niemals eine Sprache, die es nicht übersetzt.

Die Zusammenführung findet **pro Zielsprache**, nicht pro Eintrag. Eine spanische Übersetzung von \\"commit\\" in `L10N/es.md` ersetzt den Server-Eintrag für \\"commit\\" auf Spanisch, berührt aber nicht den japanischen Server-Eintrag für denselben Term. Prüfer können sehen, welche Server-Einträge überschrieben wurden: Die Übersetzungssitzungszusammenfassung zeigt, wie viele überschrieben wurden, und das Lockfile jeder Datei listet sie unter `glossary.shadowed`.

## Wenn sich der Glossar ändert, werden die Dateien neu übersetzt

Wenn Sie einen Glossar-Eintrag bearbeiten, übersetzt Glossia nur die Dateien, deren *effektives Glossar geändert*. Wenn der Quelltext der Datei den bearbeiteten Begriff nicht enthält, bleiben die Übersetzungen unverändert. Wenn die Datei den Begriff verwendet, beinhaltet die nächste Übersetzungsprüfung die aktualisierte Anweisung.

Das gleiche Prinzip gilt in umgekehrter Richtung: Das Hinzufügen eines Begriffs, der nur von einer Teilmenge der Dateien verwendet wird, erhält keinen vollständigen Neustart.

## Was ein Glossar nicht ist

- Nicht ein Wörterbuch für maschinelle Übersetzung. Das Modell von Glossia liest den umgebenden Kontext und kann einen Begriff anders übersetzen, wenn der Satz dies verlangt. Das Glossar ist Orientierung, keine Ersetzung.
- Nicht die gesamte Stilrichtlinie. Stimme, Ton, Formalität und Zielgruppe befinden sich in Ihrer Stimmenkonfiguration und in `L10N.md`.
- Nicht stumm. Jeder angewendete Begriff wird in der Lockdatei der Datei aufgezeichnet, sodass ein Rezensent genau nachverfolgen kann, welche Glossareinträge das Modell erreicht haben.

## Verwandt

- Fügen Sie Ihre ersten Begriffe hinzu: [Glossar definieren](/docs/how-to/define-a-glossary).
- Jedes Eintragsfeld: [Glossarverweis](/docs/reference/glossary).
- Die anderen `L10N.md` Felder: [L10N.md Referenz](/docs/reference/l10n-md).