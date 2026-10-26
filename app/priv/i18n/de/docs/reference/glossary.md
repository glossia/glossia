%{
  title: "Glossar",
  summary:
    "Referenz für das Glossar-Feld in L10N.md und in der Übersetzungs-Override-Datei jeder Sprache.",
  category: "Referenz",
  section: "translation",
  order: 2
}
---

Ein Repository-Glossar ist in zwei Dateien aufgeteilt. Glossia verschmilzt es mit dem Glossar des Kontos für jede Datei, die es übersetzt. Siehe [Glossar](/docs/explanation/glossary) für die Kombination beider.

| Datei | `glossary` enthält | Beispiel |
|---|---|---|
| `L10N.md` | Eine Liste von **Termen**, die für jede Sprache gleich sind. | `- source: commit` |
| `L10N/<locale>.md` | Eine Zuordnung vom Begriff zu seiner **Übersetzung** in dieser Sprache. | `commit: commit` |

## Begriffe in L10N.md

```yaml
---
glossary:
  - source: commit
    definition: The version-control action of recording changes.
  - source: API
    case_sensitive: true
  - id: vcs-branch
    source: branch
    definition: A line of development in version control.
---
```

| Feld | Typ | Erforderlich | Beschreibung |
|---|---|---|---|
| `source` | string | Ja | Der Begriff wie er im Quelltext erscheint. |
| `definition` | string | Nein | Kurzanweisungen, die das Modell liest, um zu entscheiden, ob ein Treffer wirklich dieses Konzept ist. |
| `case_sensitive` | boolean | Nein | Wenn `true` ist der Begriff nur im genau geschriebenen Fall gültig. Der Standardwert ist `false`. Nutzen Sie ihn für Namen und Akronyme wie `API` oder `SDK`. |
| `id` | string | Nein | Stabiler Identifier. Abgeleitet aus `source` wenn weggelassen (`Version Control` wird zu `version-control`, `C++` wird zu `cplusplus`). Setzen Sie es, um Übersetzungen nach id anzuschließen, um `source` zu umbenennen, ohne die Identität des Begriffs zu verlieren, oder um einen Begriff von einem übergeordneten `L10N.md` zu überschreiben. |

Begriffe tragen keine Übersetzungen. Ein Begriff mit einem `targets`-Feld wird abgelehnt: Übersetzungen gehören in die Sprachdateien.

## Übersetzungen in L10N/<locale>.md

```yaml
# L10N/es.md
---
locale: es
glossary:
  commit: commit
  API: API
  vcs-branch: rama
  pull request: pull request
---
```

Jeder Schlüssel ist ein Begriff `id` oder seine `source` und jeder Wert ist die genehmigte Übersetzung für diese Sprache.

- Ein Schlüssel, der keinem Begriff in `L10N.md` entspricht, deklariert einen Begriff, der nur für diese Sprache gilt.
- Ein Begriff ohne Übersetzung in einer Sprache stützt sich auf das Glossar des Kontos für diese Sprache.
- Um einen Namen in Klänge zu übersetzen, kartieren Sie sich auf sich selbst, beispielsweise `Glossia: Glossia`.

## Verschachtelte Dateien

Jede Datei wird mit dem Glossar ihrer Verzeichnisstruktur übersetzt:

- Eine verschachtelte `L10N.md` fügt Begriffe zu denen hinzu, die sie vererbt. Ein Begriff mit demselben `id` oder demselben `source` wenn kein `id` gesetzt ist, ersetzt den vererbten für diesen Unterbaum.
- Eine verschachtelte `L10N/<locale>.md` fügt Übersetzungen zu denen hinzu, die sie vererbt, und ihre Übersetzung gewinnt für einen Begriff, beide deklariert.

## Validierung

Wenn ein Glossar ungültig ist, übersetzt Glossia die betroffenen Dateien nur mit dem Glossar des Kontos, sodass ein Tippfehler niemals Übersetzungen blockiert. Häufige Ursachen:

- **Fehlende `source`.** Jeder Begriff braucht eine nicht leere.
- **Duplizierte `id`.** Jeder Begriff muss zu einem eindeutigen Identifier auflösen, sei es explizit gesetzt oder aus `source` abgeleitet.
- **Übersetzungen in L10N.md.** Ein Begriff mit `targets`. Verschieben Sie die Übersetzungen nach `L10N/<locale>.md`.
- **Leere Übersetzung.** Ein Begriff, der einem leeren String zugeordnet ist. Lassen Sie ihn stattdessen weg.
- **Falsche Formen oder Typen.** `glossary` muss eine Liste in `L10N.md` und eine Zuordnung in `L10N/<locale>.md` sein. Übersetzungen, `id` und `definition` müssen Strings sein; `case_sensitive` muss `true` oder `false` sein.

## Was Glossia aufzeichnet

Die Sperrdatei jeder übersetzten Datei protokolliert die Glossar-Einträge, die sie geprägt haben:

```json
{
  "server_context": {
    "glossary": {
      "applied": ["repo:commit", "account:repository"],
      "shadowed": ["account:commit"]
    }
  }
}
```

- `applied` listet die Einträge auf, die der Datei zugeordnet wurden. Repository-Einträge erscheinen als `repo:<id>`, Konto-Einträge als `account:<id>`.
- `shadowed` listet Konto-Einträge auf, die ein Repository-Eintrag für diese Datei ersetzt hat.

Die Änderung eines Begriffs oder einer Übersetzung führt nur dazu, dass Dateien neu übersetzt werden, die ihn verwenden.

## Siehe auch

- [Glossar definieren](/docs/how-to/define-a-glossary): eine Schritt-für-Schritt-Anleitung.
- [Glossar](/docs/explanation/glossary): wie das Repository- und Kontoglossar kombiniert werden.
- [L10N.md-Referenz](/docs/reference/l10n-md): die anderen frontmatter-Felder.
