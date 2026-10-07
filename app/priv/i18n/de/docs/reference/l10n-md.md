%{
  title: "L10N.md",
  summary: "Referenz für Repository-Übersetzungseinstellungen und Kontext.",
  category: "Referenz",
  section: "translation",
  order: 1
}
---
`L10N.md` legt fest, welche Dateien Glossia übersetzt, wohin übersetzte Dateien gehören, welche Sprachen als Ziel dienen und welcher Kontext das Ergebnis leiten soll. Ein Repository kann eine Wurzeldatei und zusätzliche Dateien im Geltungsbereich in Unterordnern enthalten.

## Struktur

Jede Datei besteht aus zwei Teilen:

1. [YAML Ain't Markup Language](https://yaml.org/) Frontmatter zwischen `---` Marker.
2. Markdown nach dem Frontmatter mit Produktzielgruppe, Stimme oder Domänenkontext.

<!-- end list -->

```yaml
---
source_language: en
model: translation-default
sources:
  "docs/**/*.md": "docs/i18n/{locale}/{relpath}"
targets:
  - es
  - ja
validation:
  - ./scripts/validate-docs.sh
  - --strict
frontmatter: preserve
preserve:
  - placeholders
  - urls
---

Write for software developers. Keep product names and code samples unchanged.
```

Anbieter-Credentials gehören in die Kontoeinstellungen, nie in `L10N.md`. Das optionale `model` ist ein Benutzermodell-Handle.

## Frontmatter-Felder

| Feld | Typ | Erforderlich | Beschreibung |
|---|---|---|---|
| `source_language` | string | nein | Standardwert ist `en`. |
| `model` | string | nein | Benutzermodell-Handle. Glossia verwendet das Standardeinstellung des Kontos, wenn es fehlt, und meldet einen Fehler, wenn ein expliziter Handle nicht existiert. |
| `sources` | map oder Liste | für eine oberstehende Regel | Quelldatei-Muster. Map-Werte können Ausgabe-Vorlagen definieren. |
| `targets` | map oder Liste | wenn Quellen konfiguriert sind | Zielregionscodes. Eine Map kann einen Regionscode mit einem Sprachnamen verknüpfen. |
| `output` | string | wenn keine Quellzuordnung oder `target_path` einen Zielort liefert | Ausgabe-Datei-Vorlage. |
| `target_path` | string | wenn keine Quellzuordnung oder `output` einen Zielort liefert | Stammordnungs-Vorlage für übersetzte Dateien. |
| `translate` | Liste | nein | Mehrere Übersetzungsregeln, jede mit eigenen Quellen und optionalem Override. |
| `exclude` | Liste | nein | Dateimuster zu überspringen. |
| `preserve` | Liste | nein | Inhaltsarten, die unverändert bleiben müssen, wie z. B. Platzhalter oder URIs. |
| `frontmatter` | string | nein | `preserve` standardmäßig, oder `translate`. |
| `prompt` | string | nein | Zusätzliche Anleitung für diesen Geltungsbereich oder diese Regel. |
| `validation` | Liste | für Dateierweiterungen ohne eingebaute Adapter | Ein Validierungsbefehl gefolgt von seinen Argumenten. Der Befehl erhält den Kandidaten an seinem echten Zielort und muss einen nicht-null-Status zurückgeben, wenn die Datei ungültig ist. |
| `check_cmd` | string | nein | Ein Prüf-Befehl für den Übersetzungsablauf. |
| `check_cmds` | Map | nein | Benannte Prüf-Befehle für den Übersetzungsablauf. |
| `retries` | Integer | nein | Anzahl der Wiederholungsversuche nach fehlerhafter Prüfung. Standardwert ist `2`. |
| `locale` | string | nein | Region, die an einen regionspezifischen Kontext-Datei angehängt ist. |
| `glossary` | Liste oder Map | nein | In `L10N.md` eine Liste von Glossarbegriffen. In `L10N/<locale>.md` eine Map von jedem Begriff zu seiner Übersetzung in dieser Sprache. Verschachtelte Dateien fügen hinzu und überschreiben vererbte Einträge. Siehe [Glossar-Referenz](/docs/reference/glossary). |

Unbekannte Frontmatter-Felder werden ignoriert.

## Dateiformate

Glossia verfügt über integrierte Handhabung für Markdown, JavaScript Object Notation, YAML Ain't Markup Language, portable object und Textdateien. Andere Dateierweiterungen außer Plan ist es, wenn die entsprechende `L10N.md` eine `validation`-Anweisung deklariert. Dies verhindert, dass ein proprietäres strukturiertes Format nicht als ungebremster Text behandelt wird.

In Markdown werden nur Prosentexte übersetzt: Abschnitte, Überschriften, Listenpunkte, Tabellenzellen, ©`title`, `details`, `alt`, `label`, `description`, `summary`, `placeholder`, `aria-label`, und `caption`-Attributen von Komponenten und HTML und der Text von einem HTML `<summary>`. Jeder andere Byte, inklusive Code, Link-Ziele, Komponenten, Warnungen und explizite Überschriften-Anker, bleibt genau so wie im Original. Siehe [Übersetzungsrecovery](/docs/explanation/translation-recovery) für die Funktionsweise.

Der Validierungs-Befehl wird ausgeführt, nachdem der Kandidat vorübergehend an den echten Ziel-Pfad geschrieben wurde. Er kann das native Parser-, Compiler- oder Build-Befehl des Repositoriums aufrufen. Glossia stellt nach jedem Validierungsversuch das vorherige Ziel wieder her und schreibt den akzeptierten Kandidaten nur danach.

## Quellzuordnungen

Die klarste Form weist jedes Quellmuster einem Ausgabemuster zu:

```yaml
sources:
  "docs/**/*.md": "docs/i18n/{locale}/{relpath}"
  "content/*.json": "content/{locale}/{basename}.{ext}"
```

Eine Quellliste ist ebenfalls gültig, benötigt jedoch `output` oder `target_path`, um das Ziel zu definieren:

```yaml
sources:
  - "docs/**/*.md"
target_path: "docs/i18n/{locale}"
```

## Zielsprachen

Eine Liste verwendet jeden Locale-Code zur Sprachidentifizierung:

```yaml
targets:
  - es
  - ja
```

Eine Abbildung kann einen lesbaren Sprachnamen hinzufügen:

```yaml
targets:
  es: Spanish
  ja: Japanese
```

## Ausgabevariablen

| Variable | Wert |
|---|---|
| `{locale}` oder `{lang}` | Zielelokale-Code. |
| `{relpath}` | Quellpfad relativ zum übereinstimmenden Muster. |
| `{basename}` | Quelldateiname ohne Erweiterung. |
| `{ext}` | Quelldatei-Erweiterung ohne führenden Punkt. |

## Mehrere Regeln

Verwenden Sie `translate`, wenn unterschiedliche Inhaltsteile verschiedene Ziele oder Prüfungen benötigen:

```yaml
---
source_language: en
targets:
  - es
translate:
  - sources:
      - "docs/**/*.md"
    output: "docs/i18n/{locale}/{relpath}"
  - source: "messages/*.json"
    output: "messages/{locale}/{basename}.{ext}"
---
```

Regelwerte überschreiben Werte, die aus der umgebenden Datei geerbt werden.

## Begrenzter Kontext

Glossia liest `L10N.md`-Dateien vom Repository-Root bis hin zur Quelldatei:

- Elterneinstellungen bieten Standards.
- Eine tieferliegende Datei überschreibt Felder für ihr Verzeichnis.
- Markdown-Context wird von Eltern zu Kindern akkumuliert.
- Locale-spezifische Leitlinien und ein locale-spezifisches Modell-Handle können sich in `L10N/<locale>.md` befinden.

Dies ermöglicht es einem Repository, eine allgemeine Sprachanweisung am Root zu behalten, während produktbereichs- oder sprachspezifische Anweisungen nah am von ihnen betroffenen Inhalt platziert werden.