%{
  title: "Glossar",
  summary:
    "Referenz für das Glossar-Feld in L10N.md und in jeder sprachspezifischen Überschreibdatei.",
  category: "Referenz",
  section: "translation",
  order: 2
}
---
Ein Repository-Wörterbuch ist über zwei Dateien verteilt. Glossia kombiniert es mit dem Kontowörterbuch für jede Datei, die es übersetzt. Siehe [Wörterbuch](/docs/explanation/glossary) wie die beiden kombiniert werden.

| Datei | `glossary` enthält | Beispiel |
|---|---|---|
| `L10N.md` | Eine Liste von **Begriffe**, dass das Gleiche für jede Sprache gilt. | `- source: commit` |
| `L10N/<locale>.md` | Eine Abbildung von einem Begriff zu seiner **Übersetzung** in dieser Sprache. | `commit: commit` |

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
| `definition` | string | nein | Kurze Anleitung, die das Modell liest, um zu entscheiden, ob eine Übereinstimmung wirklich dieses Konzept ist. |
| `case_sensitive` | boolean | no | Wenn `true`, der Begriff stimmt nur in der exakten Schreibweise überein. Standardwert ist `false`. Verwenden Sie es für Namen und Akronyme wie `API` oder `SDK`. |
| `id` . | string | no | Stabiler Identifikator. Abgeleitet aus `source` wenn nicht Angaben (`Version Control` wird `version-control`, `C++` wird `cplusplus`). Setze es als Schlüsselübersetzungen nach id, um zu umbenennen `source` ohne die Identität des Terms zu verlieren, oder einen Term von einem Elternteil zu überschreiben `L10N.md`. |

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

Jeder Schlüssel ist eines Begriffs `id` oder seines `source`, und jeder Wert ist die genehmigte Übersetzung für diese Sprache.

- Ein Schlüssel, der keinen Begriff in `L10N.md` definiert einen Begriff für diese Sprache nur.
- Ein Begriff ohne Übersetzung in einer Sprache greift auf das Konto-Glossar für diese Sprache zurück.
- Um einen Namen unübersetzt zu lassen, weisen Sie ihn auf sich selbst, zum Beispiel `Glossia: Glossia`.

## Verschachtelte Dateien

Jede Datei wird mit dem Glossar ihrer Verzeichnisstruktur übersetzt:

- Eine verschachtelte `L10N.md` fügt Begriffe hinzu, die es vererbt. Ein Begriff mit demselben `id`, oder der gleiche `source` wenn keine `id` ist gesetzt, ersetzt das vererbte für diesen Unterbaum.
- Ein verschachteltes `L10N/<locale>.md` fügt Übersetzungen hinzu, die es erbt, und seine Übersetzung hat Vorrang für einen Begriff, den beide deklarieren.

## Validierung

Wenn ein Glossar ungültig ist, übersetzt Glossia die betroffenen Dateien ausschließlich mit dem Kontoglossar, sodass ein Tippfehler die Übersetzungen nie blockiert. Häufige Ursachen:

- **Fehlend `source`.** Jeder Begriff benötigt einen nicht leeren Eintrag.
- **Duplikat `id`.** Jeder Begriff muss einen eindeutigen Identifikator aufweisen, sei er explizit festgelegt oder abgeleitet `source`.
- **Übersetzungen in L10N.md.** Ein Begriff mit `targets`. Verschieben Sie die Übersetzungen zu `L10N/<locale>.md`.
- **Leere Übersetzung.** Ein Begriff, der auf einen leeren String zugeordnet ist. Lassen Sie ihn stattdessen weg.
- **Falsche Struktur oder Typen.** `glossary` muss eine Liste sein in `L10N.md` und eine Map in `L10N/<locale>.md`. Übersetzungen, `id`, und `definition` müssen Strings sein; `case_sensitive` muss sein `true` oder `false`.

## Was Glossia protokolliert

Die Sperrdatei jeder übersetzten Datei protokolliert die Wörterbucheinträge, die sie geprägt haben:

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

- `applied` listet die Einträge auf, die mit der Datei übereinstimmten. Repository-Einträge erscheinen als `repo:<id>`, Konto-Einträge als `account:<id>`.
- `shadowed` Listet Konto-Einträge auf, die von einem Repository-Eintrag für diese Datei ersetzt wurden.

Das Bearbeiten eines Begriffs oder einer Übersetzung reübersetzt nur die Dateien, die ihn verwenden.

## Siehe auch

- [Glossar erstellen](/docs/how-to/define-a-glossary): Schritt-für-Schritt-Anleitung.
- [Glossar](/docs/explanation/glossary): wie Repository- und Konto-Glossare kombiniert werden.
- [L10N.md Referenz](/docs/reference/l10n-md): die anderen Frontmatter-Felder.