%{
  title: "L10N.md",
  summary: "Referenz für Repository-Übersetzungseinstellungen und Kontext.",
  category: "Referenz",
  section: "translation",
  order: 1
}
---
`L10N.md` sagt Glossia, welche Dateien zu übersetzen sind, wohin die übersetzten Dateien gehören, welche Sprachen das Ziel sind und welchen Kontext das Ergebnis leiten soll. Ein Repository kann eine Wurzeldatei und zusätzliche Dateien in Bereichen in Unterordnern haben.

## Struktur

Jede Datei hat zwei Teile:

1. [YAML Ain't Markup Language](https://yaml.org/) Frontmatter zwischen `---` Markiernern.
2. Markdown unter dem Frontmatter mit Produkt-, Zielgruppen-, Stimme- oder Bereichskontext.

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

Anbieterzugangsdaten gehören in den Kontoeinstellungen, niemals in `L10N.md`. Der optionalen `model`-Wert ist ein Kontomodell-Handle.

## Frontmatter-Felder

| Feld | Typ | Erforderlich | Beschreibung |
|---|---|---|---|
| `source_language` | string | no | Quelldialekt für diesen Bereich. Standardmäßig `en`. |
| `model` | string | no | Kontomodell-Handle. Glossia nutzt den Kontodefekt, wenn weggelassen, und meldet einen Fehler, wenn eine explizite Handle nicht existiert. |
| `sources` | map or list | für eine Top-Level-Regel | Quelldateimuster. Map-Werte können Ausgabe-Vorlagen definieren. |
| `targets` | map or list | wenn Quellen konfiguriert sind | Ziel-Locale-Codes. Eine Map kann einen Locale-Code mit einem Sprachnamen verknüpfen. |
| `output` | string | wenn keine Quellenabbildung oder `target_path` ein Ziel versorgt | Ausgabe-Datei-Vorlage. |
| `target_path` | string | wenn keine Quellenabbildung oder `output` ein Ziel versorgt | Basis-Verzeichnis-Vorlage für übersetzte Dateien. |
| `translate` | list | no | Mehrere Übersetzungsregeln, jede mit eigenen Quellen und möglichen Überschreibungen. |
| `exclude` | list | no | Dateimuster, die übersprungen werden. |
| `preserve` | list | no | Inhaltarten, die unverändert bleiben müssen, wie Platzhalter oder gleichförmige Ressourcenlokatoren. |
| `frontmatter` | string | no | Standardmäßig `preserve` oder `translate`. |
| `prompt` | string | no | Zusätzliche Hinweise für diesen Bereich oder Regel. |
| `validation` | list | für Dateierweiterungen ohne eingebauten Adapter | Ein Validierungs-Befehl gefolgt von seinen Argumenten. Das Kommando empfängt den Kandidaten an seinem echten Zielpfad und muss bei ungültiger Datei einen nicht-null-Status zurückgeben. |
| `check_cmd` | string | no | Ein Abfrag-Kommando, das dem Übersetzungsablauf zur Verfügung steht. |
| `check_cmds` | map | no | Benannte Abfrag-Kommandos, die dem Übersetzungsablauf zur Verfügung stehen. |
| `retries` | integer | no | Anzahl der Wiederholungsversuche nach einem fehlgeschlagenen Abgleich. Standardmäßig `2`. |
| `locale` | string | no | Locale, das an eine locale-spezifische Kontext-Datei angehängt ist. |
| `glossary` | list or map | no | In `L10N.md`, eine Liste von Glossar-Terminen. In `L10N/<locale>.md`, eine Map von jedem Begriff zu seiner Übersetzung in dieser Sprache. Verschachtelte Dateien fügen hinzu und überschreiben vererbte Einträge. Siehe die [glossary-Referenz](/docs/reference/glossary). |

Unbekannte Frontmatter-Felder werden ignoriert.

## Dateiformate

Glossia hat eingebaute Behandlungen für Markdown, JavaScript Object Notation, YAML Ain't Markup Language, portable Object und Textdateien. Andere Dateierweiterungen scheitern wegen der Planung, es sei denn, das entsprechende `L10N.md` skriptiert einen `validation`-Befehl. Dies verhindert das unsichere Behandeln eines proprietären strukturierten Formats als uneingeschränkter Text.

Der Validierungsbefehl läuft, nachdem der Kandidat vorübergehend an seinen echten Zielpfad geschrieben wurde. Er kann den nativen Parser, Compiler oder Build-Befehl des Repositories aufrufen. Glossia stellt nach jedem Validierungsversuch den vorherigen Ziel wieder her und schreibt den angenommenen Kandidaten danach erst.

## Quellzuordnungen

Die klarste Form abbildegngt das Quellmuster auf eine Ausgabe-Vorlage:

```yaml
sources:
  "docs/**/*.md": "docs/i18n/{locale}/{relpath}"
  "content/*.json": "content/{locale}/{basename}.{ext}"
```

Eine Quellenliste ist ebenfalls gültig, benötigt aber `output` oder `target_path`, um das Ziel zu definieren:

```yaml
sources:
  - "docs/**/*.md"
target_path: "docs/i18n/{locale}"
```

## Zielsprachen

Eine Liste verwendet jeden Locale-Code als Sprachkennzeichen:

```yaml
targets:
  - es
  - ja
```

Eine Zuordnung kann einen lesbaren Sprachnamen hinzufügen:

```yaml
targets:
  es: Spanish
  ja: Japanese
```

## Ausgabevariablen

| Variable | Wert |
|---|---|
| `{locale}` oder `{lang}` | Code des Ziellocales. |
| `{relpath}` | Quellpfad relativ zum erfassten Muster. |
| `{basename}` | Quelldateiname ohne Erweiter. |
| `{ext}` | Dateinamenerweiterung ohne führenden Punkt. |

## Mehrere Regeln

Verwenden Sie `translate`, wenn unterschiedliche Inhaltgruppen unterschiedliche Ziele oder Prüfungen benötigen:

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

Regelwerte überschreiben Werte, die von der umgebenden Datei vererbt wurden.

## Eingeschränkter Kontext

Glossia liest `L10N.md`-Dateien vom Repository-Wurzelverzeichnis bis zur Quelldatei:

- Einstellungen der übergeordneten Dateien liefern Standardwerte.
- Eine tiefere Datei überschreibt Felder für ihr Verzeichnis.
- Der Markdown-Kontext wird vom übergeordneten leider zum untergeordneten Element gesammelt.
- Lokalspezifische Leitlinien und deren Handhabungsmodelle können in `L10N/<locale>.md` gespeichert werden.

Dies ermöglicht es einem Repository, breite Stimmenrichtlinien an der Wurzel beizubehalten, während produkt- oder sprachspezifische Leitlinien dort platziert werden, wo sie den Inhalt betreffen.