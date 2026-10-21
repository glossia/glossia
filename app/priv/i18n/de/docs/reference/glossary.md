%{
  title: "Glossar",
  summary:
    "Referenz für das Glossar-Feld in L10N.md und in der Überschreibungsdatei jeder Sprache.",
  category: "Referenz",
  section: "translation",
  order: 2
}
---

Ein Repository-Glossar ist über zwei Dateien verteilt. Glossia verschmilzt es mit dem Account-Glossar des Kontos für jede Datei, die es übersetzt. Siehe [Glossar](/docs/explanation/glossary) für Details zur Kombination beider.

| Datei | `glossary` enthält | Beispiel |
|---|---|---|
| `L10N.md` | Eine Liste von **Begriffen**, die für jede Sprache gleich sind. | `- source: commit` |
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
| `source` | string | yes | Der Begriff, wie er in der Quelltexte erscheint. |
| `definition` | string | no | Kurze Orientierung, die das Modell liest, um zu entscheiden, ob ein Treffer wirklich dieses Konzept ist. |
| `case_sensitive` | boolean | no | Wenn `true`, stimmt der Begriff nur im exakten Schreibstil überein. Standardmäßig auf `false`. Verwenden Sie es für Namen und Akronyme wie `API` oder `SDK`. |
| `id` | string | no | Stabiler Identifier. Abgeleitet aus `source`, wenn weggelassen (`Version Control` wird zu `version-control`, `C++` wird zu `cplusplus`). Legen Sie es fest, um Übersetzungen nach ID zu steuern, um `source` neu zu benennen, ohne die Identität des Begriffs zu verlieren, oder einen Begriff aus einem übergeordneten `L10N.md` zu überschreiben. |

Begriffe tragen keine Übersetzungen. Ein Begriff mit einem `targets`-Feld wird verworfen: Übersetzungen gehören in die Sprachendateien.

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

Jede Schlüsseloze ist eine Begriff-ID oder sein `id` sowie sein `source`, und jeder Wert ist die genehmigte Übersetzung für diese Sprache.

- Ein Schlüssel, der keinen Begriff in `L10N.md` trifft, erklärt einen Begriff nur für diese Sprache.
- Ein Begriff ohne Übersetzung in einer Sprache greift auf das Account-Glossar für diese Sprache zurück.
- Um einen Namen unübersetzt zu belassen, ordnen Sie ihn sich selbst zu, z. B. `Glossia: Glossia`.

## Eingeschachtelte Dateien

Jede Datei wird mit dem Glossar der Verzeichnis-Kette ihrer Übersetzung:

- Ein `L10N.md` fügt Begriffe hinzu, die es vererbt. Ein Begriff mit dem gleichen `id`, oder dem gleichen `source`, falls kein `id` gesetzt ist, ersetzt das vererbte für diesen Unterbaum.
- Ein `L10N/<locale>.md` fügt Übersetzungen hinzu, die es vererbt, und seine Übersetzung gewinnt für einen Begriff, den beide erklären.

## Validierung

Wenn ein Glossar ungültig ist, übersetzt Glossia die betroffenen Dateien nur mit dem Account-Glossar, sodass ein Tippfehler die Übersetzungen nie blockiert. Häufige Ursachen:

- **Fehlende `source`.** Jeder Begriff benötigt eine nicht-leere.
- **Duplizierte `id`.** Jeder Begriff muss zu einem eindeutigen Identifier auflösen, ob explizit gesetzt oder aus `source` abgeleitet.
- **Übersetzungen in L10N.md.** Ein Begriff mit `targets`. Legen Sie die Übersetzungen nach `L10N/<locale>.md` um.
- **Leere Übersetzung.** Ein Begriff mit einem leeren String abgebinigt. Lassen Sie ihn einfach weg.
- **Falsche Formen oder Typen.** `glossary` muss eine Liste in `L10N.md` und eine Map in `L10N/<locale>.md` sein. Übersetzungen, `id` und `definition` müssen Strings sein; `case_sensitive` muss `true` oder `false` sein.

## Was Glossia protokolliert

Das lockfile jeder übersetzten Datei protokolliert die Glossar-Einträge, die sie geprägt haben:

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

- `applied` listet die Einträge auf, die mit der Datei übereinstimmen. Repository-Einträge erscheinen als `repo:<id>`, Account-Einträge als `account:<id>`.
- `shadowed` listet Account-Einträge auf, die von einem Repository-Eintrag für diese Datei ersetzt wurden.

Das Bearbeiten eines Begriffs oder einer Übersetzung führt nur zur Neuübersetzung der Dateien, die ihn verwenden.

## Siehe auch

- [Ein Glossar definieren](/docs/how-to/define-a-glossary): Schritt-für-Schritt-Anleitung.
- [Glossar](/docs/explanation/glossary): wie das Repository- und Account-Glossar zusammenwirken.
- [L10N.md Referenz](/docs/reference/l10n-md): die anderen Frontmatter-Felder.
