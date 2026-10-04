%{
  title: "Glossar",
  summary:
    "Referenz für das Glossar-Feld in L10N.md und in jeder sprachspezifischen Überschreibdatei.",
  category: "Referenz",
  section: "translation",
  order: 2
}
---
Ein Repositories-Glossar teilt sich über zwei Dateien. Glossia vereinigt es mit dem Glossar des Kontos für jede übersetzte Datei. [Glossar](/docs/explanation/glossary) für die Zusammenführung beide.

| Datei | `glossary` enthält | Beispiel |
|---|---|---|
| `L10N.md` | Eine Liste von **Termen**, die für alle Sprachen identisch. | `- source: commit` |
| `L10N/<locale>.md` | Eine Zuordnung von Begriff zu dessen **Übersetzung** in dieser Sprache. | `commit: commit` |

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
| `source` | Zeichenkette | ja | Der Begriff, wie er in der Quelltext erscheint. |
| `definition` | Zeichenkette | nein | Kurze Hinweise, die das Modell liest, um zu entscheiden, ob ein Treffer wirklich diesen Begriff bedeutet. |
| `case_sensitive` | Boolean | nein | Wenn `true`, stimmt der Begriff nur in der exakten Schreibweise überein. Standardeinstellung ist `false`. Benutz es für Namen und Akronyme wie `API` oder `SDK`. |
| `id` | Zeichenkette | nein | Stabiler Identifier. Wenn nicht angegeben, leitet sich von `source` ab (`Version Control` wird zu `version-control`, `C++` wird zu `cplusplus`). Wenn du es auf Schlüsselnübersetzungen mittels id setzen möchtest, um `source` zu umbenennen, ohne die Identität des Begriffs zu verlieren, oder um einen Begriff aus einem übergeordneten `L10N.md` zu überschreiben. |

Бegriffe tragen keine Übersetzungen. Ein Begriff mit einem `targets`-Feld wird abgelehnt: Übersetzungen gehören in die Sprachdateien.

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

Jeder Schlüssel ist ein `id` eines Begriffs oder dessen `source`, und jeder Wert ist die genehmigte Übersetzung für diese Sprache.

- Ein Schlüssel, der keinen Begriff in `L10N.md`matcht, deklariert einen Begriff für diese Sprache nur.
- Ein Begriff ohne Übersetzung in einer Sprache greift auf das Glossar des Kontos für diese Sprache zurück.
- Um einen Namen unverändert zu lassen, ordne ihn sich selbst zu, zum Beispiel `Glossia: Glossia`.

## Verschachtelte Dateien

Jede Datei wird mit dem Glossar ihres Verzeichnis-Kette übersetzt:

- Eine verschachtelte `L10N.md` fügt Begriffe hinzu, die sie vererbt. Ein Begriff mit demselben `id`, oder demselben `source`, wenn kein `id` gesetzt ist, ersetzt den vererbten für dies Unterbaum.
- Eine verschachtelte `L10N/<locale>.md` fügt Übersetzungen hinzu, die sie vererbt, und seine Übersetzung gewinnt für einen Begriff, die beide deklarieren.

## Validierung

Wenn ein Glossar ungültig ist, übersetzt Glossia die betroffenen Dateien nur mit dem Konto-Glossar, damit ein Tippfehler nie die Übersetzungen blockiert. Häufige Ursachen:

- **Fehgende `source`.** Jeder Begriff benötigt eine nicht-leere.
- **Duplizierter `id`.** Jeder Begriff muss zu einem eindeutigen Identifier führen, egal ob explizit gesetzt oder aus `source` abgeleitet.
- **Übersetzungen in L10N.md.** Ein Begriff mit `targets`. Verschiebe die Übersetzungen in `L10N/<locale>.md`.
- **Leere Übersetzung.** Ein Begriff, der einem leeren String zugeordnet ist. Lass es heraus statt.
- **Falsche Formen oder Typen.** `glossary` muss eine Liste in `L10N.md` und ein Karten in `L10N/<locale>.md` sein. Übersetzungen, `id`, und `definition` müssen Zeichenketten sein; `case_sensitive` muss `true` oder `false` sein.

## Was Glossia aufzeichnet

Lockfile jeder übersetzten Datei verzeichnet die Glossar-Einträge, die sie geformt:

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

- `applied` listet die Einträge auf, die der Datei berechtigten. Repositories-Einträge erscheinen als `repo:<id>`, Konto-Einträge als `account:<id>`.
- `shadowed` listet Konto-Einträge auf, die ein Repositories-Eintrag für diese Datei ersetzt hat.

Bearbeitung eines Begriffs oder einer Übersetzung übersetzt nur die Dateien neu, die ihn verwenden.

## Siehe auch

- [Glossar definieren](/docs/how-to/define-a-glossary): Schritt-für-Schritt-Anleitung.
- [Glossar](/docs/explanation/glossary): wie die Repositories- und Konto-Glossarien sich zusammenführen.
- [L10N.md Referenz](/docs/reference/l10n-md): die anderen Frontmatter-Felder.