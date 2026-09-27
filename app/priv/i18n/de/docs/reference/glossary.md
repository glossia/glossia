%{
  title: "Glossar",
  summary:
    "Referenz für das Glossarfeld in L10N.md und in der Überschreibungsdatei jeder Sprache.",
  category: "Referenz",
  section: "Übersetzung",
  order: 2
}
---
Ein Repository-Glossar ist auf zwei Dateien verteilt. Glossia kombiniert es mit dem Server-Glossar des Kontos für jede Datei, die übersetzt wird. Siehe [Glossar](/docs/explanation/glossary) wie sich beide kombinieren.

| Datei | `glossary` enthält | Beispiel |
|---|---|---|
| `L10N.md` | Eine Liste von **Begriffe**, dasselbe gilt für jede Sprache. | `- source: commit` |
| `L10N/<locale>.md` | Eine Zuordnung vom Begriff zu dessen **Übersetzung** in dieser Sprache. | `commit: commit` |

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
| `source` | string | ja | Der Begriff, wie er im Quelltext erscheint. |
| `definition` | string | nein | Kurzer Hinweis, den das Modell liest, um zu entscheiden, ob eine Übereinstimmung tatsächlich diesem Konzept entspricht. |
| `case_sensitive` | boolean | no | Wann `true`, der Term stimmt nur in der exakt geschriebenen Schreibweise überein. Voreingestellt ist `false`, Verwende es für Namen und Akronyme wie `API` oder `SDK`. |
| `id` | String | Nein | Stabiler Identifier. Abgeleitet von `source` wenn weggelassen (`Version Control` wird `version-control`, `C++` wird `cplusplus`). Setzen Sie es auf Übersetzungsschlüssel nach ID, zum Umbenennen `source` ohne die Identität des Begriffs zu verlieren oder einen Begriff von einem Elternbegriff zu überschreiben `L10N.md`. |

Begriffe tragen keine Übersetzungen. Ein Begriff mit einem `targets` Feld wird abgelehnt: Übersetzungen gehören in die Sprachdateien.

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

Jeder Schlüssel ist eines Begriffs `id` oder sein `source`, und jeder Wert ist die genehmigte Übersetzung für diese Sprache.

- Ein Schlüssel, der keinen Begriff in `L10N.md` deklariert einen Begriff nur für diese Sprache.
- Ein Begriff ohne Übersetzung in einer Sprache greift auf das Serverglossar dieser Sprache zurück.
- Um einen Namen unverändert zu lassen, ordnen Sie ihn sich selbst zu, zum Beispiel `Glossia: Glossia`.

## Verschachtelte Dateien

Jede Datei wird mit dem Glossar ihrer Verzeichnis-Kette übersetzt:

- Ein verschachtelter `L10N.md` fügt Begriffe zu denen hinzu, die es erbt. Ein Begriff mit demselben `id`, oder derselbe `source` wenn keine `id` ist gesetzt, ersetzt das vererbte für diesen Verzeichnisbaum.
- Ein verschachteltes `L10N/<locale>.md` fügt Übersetzungen hinzu, die es erbt, und seine Übersetzung hat Vorrang für einen Begriff, den beide definieren.

## Validierung

Wenn ein Glossar ungültig ist, übersetzt Glossia die betroffenen Dateien nur mit dem Serverglossar, sodass ein Tippfehler die Übersetzungen nie blockiert. Häufige Ursachen:

- **Fehlend `source`.** Jeder Begriff benötigt eine nicht leere Definition.
- **Dupliziert `id`.** Jeder Begriff muss sich auf eine eindeutige Kennung auflösen, sei sie explizit gesetzt oder abgeleitet von `source`.
- **Übersetzungen in L10N.md.** Ein Begriff mit `targets`. Verschieben Sie die Übersetzungen nach `L10N/<locale>.md`.
- **Leere Übersetzung.** Ein Begriff, der auf eine leere Zeichenfolge abgebildet ist. Lassen Sie ihn stattdessen weg.
- **Falsche Strukturen oder Typen.** `glossary` muss eine Liste in `L10N.md` und eine Map in `L10N/<locale>.md`. Übersetzungen, `id`und `definition` müssen Zeichenfolgen sein; `case_sensitive` musses sein `true` oder `false`.

## Was Glossia protokolliert

Die Lockdatei jeder übersetzten Datei protokolliert die Glossareinträge, die sie geprägt haben:

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

- `applied` listet die Einträge auf, die der Datei entsprachen. Repository-Einträge erscheinen als `repo:<id>`, server-Einträge als `account:<id>`.
- `shadowed` listet Server-Einträge auf, die ein Repository-Eintrag für diese Datei ersetzt hat.

Das Bearbeiten eines Begriffs oder einer Übersetzung übersetzt nur die Dateien neu, die diesen verwenden.

## Siehe auch

- [Einen Glossar definieren](/docs/how-to/define-a-glossary): Schritt-für-Schritt-Anleitung.
- [Glossar](/docs/explanation/glossary): wie sich Repository- und Server-Glossare kombinieren.
- [Referenz zu L10N.md](/docs/reference/l10n-md): die anderen frontmatter-Felder.