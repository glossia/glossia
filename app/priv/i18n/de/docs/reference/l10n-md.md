%{
  title: "L10N.md",
  summary: "Referenz für Repository-Übersetzungseinstellungen und Kontext.",
  category: "Referenz",
  section: "translation",
  order: 1
}
---

`L10N.md` teilt Glossia mit, welche Dateien übersetzt werden sollen, wohin die übersetzten Dateien gehören, welche Sprachen angemerkt werden sollen und welcher Kontext das Ergebnis leiten sollte. Ein Repository kann eine Root-Datei und zusätzliche Dateien mit eingescopierter Breite in Unterordner besitzen.

## Struktur

Jede Datei besteht aus zwei Teilen:

1. [YAML ist keine Markup-Sprache](https://yaml.org/) Frontmatter zwischen `---`-Markierungen.
2. Markdown unterhalb der Frontmatter mit Produkt-, Publikum, Stimme oder Domain-Kontext.

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

Die Anbieter-Berechtigungen gehören in die Kontoeinstellungen, niemals in `L10N.md`. Der optionale `model`-Wert ist ein Kontomodell-Handle.

## Frontmatter-Felder

| Feld | Typ | Erforderlich | Beschreibung |
|---|---|---|---|
| `source_language` | string | Ja | Quellsprache für diesen Bereich. Standard ist `en`. |
| `model` | string | Ja | Kontomodell-Handle. Glossia verwendet das Kontostandardmodell, wenn es weggelassen wird, und meldet einen Fehler, wenn ein eindeutiger Handle nicht existiert. |
| `sources` | Map oder Liste | für eine obere Regel | Muster für Quelldateien. Map-Werte können Ausgabe-Vorlagen definieren. |
| `targets` | Map oder Liste | wenn Quellen konfiguriert sind | Zielsprach-Codes. Eine Map kann einen Locale-Code mit einem Sprachnamen verknüpfen. |
| `output` | string | wenn keine Quellenverbindung oder `target_path` ein Ziel liefert | Ausgabe-Datei-Vorlage. |
| `target_path` | string | wenn keine Quellenverbindung oder `output` ein Ziel liefert | Basisverzeichnis-Vorlage für übersetzte Dateien. |
| `translate` | Liste | Nein | Mehrere Übersetzungsregeln, jede mit eigenen Quellen und optionalen Overrides. |
| `exclude` | Liste | Nein | Dateimuster, die übersprungen werden. |
| `preserve` | Liste | Nein | Inhaltsarten, die unverändert bleiben müssen, wie Platzhalter oder uniforme Ressourcen-Adressen. |
| `frontmatter` | string | Nein | `preserve` standardmäßig, oder `translate`. |
| `prompt` | string | Nein | Zusätzliche Hinweise für diesen Bereich oder Regel. |
| `validation` | Liste | für Dateierweiterungen, die keinen eingebauten Adapter haben | Ein Validierungsbefehl gefolgt von seinen Argumenten. Der Befehl empfängt den Kandidaten an seinem echten Zielpfad und muss bei einer ungültigen Datei einen nicht-null-Status zurückgeben. |
| `check_cmd` | string | Nein | Ein Prüfungsbefehl, der im Übersetzungsablauf verfügbar ist. |
| `check_cmds` | Map | Nein | Benannte Prüfungsbefehle, die im Übersetzungsablauf verfügbar sind. |
| `retries` | integer | Nein | Anzahl der Wiederversuche nach einem fehlgeschlagenen Check. Standard ist `2`. |
| `locale` | string | Nein | An eine kontextspezifische Datei angehängte Sprache. |
| `glossary` | Liste oder Map | Nein | In `L10N.md` eine Liste von Glossarbegriffen. In `L10N/<locale>.md` eine Map von jedem Begriff zu seiner Übersetzung in dieser Sprache. Geschachtelte Dateien fügen hinzu und überschreiben geerbte Einträge. Sehen Sie [Glossar-Referenz](/docs/reference/glossary). |

Unbekannte Frontmatter-Felder werden ignoriert.

## Dateiformate

Glossia bietet eingebaute Verarbeitungsmodalitäten für Markdown, JavaScript Object Notation, YAML Ain't Markup Language, portable Objekte und Textdateien. Andere Dateierweiterungen führen zu Planungsfehlern, es sei denn, das einschlägige `L10N.md` deklariert einen `validation`-Befehl. Dies vermeidet es einer proprietären strukturierten Formatierung stillschweigend als unbeschränkter Text zu behandeln.

In Markdown wird nur Prosa übersetzt: Absätze, Überschriften, Listenelemente, Tabellenzellen, `title`-, `details`-, `alt`-, `label`-, `description`-, `summary`-, `placeholder`-, `aria-label`- und `caption`-Attribute von Komponenten und HTML sowie der Text eines HTML `<summary>`s. Jeder andere Byte, einschließlich Code, Link-Ziele, Komponenten, Warnungen und explizite Überschriften-Verkettungen, wird exakt wie in der Quelle gespeichert. Siehe [Übersetzungswiederherstellung](/docs/explanation/translation-recovery) für die Funktionsweise.

Der Validierungsbefehl läuft nach dem temporären Schreiben des Kandidaten an seinen realen Zielpfad. Er kann den nativen Parser, Compiler oder Build-Befehl des Repositorys aufrufen. Glossia stellt nach jedem Validierungsversuch das vorherige Ziel wieder her und schreibt den akzeptierten Kandidaten nur danach.

## Quellzuweisungen

Die klarste Zuordnung abbildet jedes Quellmuster auf ein Ausgabe-Vorlage:

```yaml
sources:
  "docs/**/*.md": "docs/i18n/{locale}/{relpath}"
  "content/*.json": "content/{locale}/{basename}.{ext}"
```

Eine Quell-Liste ist ebenfalls gültig, aber sie benötigt `output` oder `target_path` zu definieren das Ziel:

```yaml
sources:
  - "docs/**/*.md"
target_path: "docs/i18n/{locale}"
```

## Zielsprachen

Eine Liste verwendet jeden Locale-Code als Sprach-Identifizierer:

```yaml
targets:
  - es
  - ja
```

Eine Map kann einen lesbaren Sprachnamen hinzufügen:

```yaml
targets:
  es: Spanish
  ja: Japanese
```

## Ausgabewerte

| Variable | Wert |
|---|---|
| `{locale}` oder `{lang}` | Zielsprach-Code. |
| `{relpath}` | Quellpfad relativ zum übereinstimmenden Muster. |
| `{basename}` | Quelldateiname ohne Erweiterung. |
| `{ext}` | Dateiendung ohne das führende Punkt. |

## Mehrere Regeln

Verwenden Sie `translate`, wenn verschiedene Inhaltsgruppen unterschiedliche Ziele oder Prüfungen erfordern:

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

Regelwerte überschreiben Werte, die von der umgebenden Datei geerbt werden.

## Kontext mit Gültigkeitsbereich

Glossia liest `L10N.md` Dateien vom Repository-Wurzelverzeichnis hin zur Quelldatei:

- Elterneinstellungen liefern Standardwerte.
- Eine tiefer gelegene Datei überschreibt Felder für ihr Verzeichnis.
- Der Markdown-Kontext wird vom Elternteil zum Kind angesammelt.
- Sprachspezifische Anleitung und ein sprachspezifisches Modell-Handle können in `L10N/<locale>.md` liegen.

Dies ermöglicht einem Repository, eine breite Stimmanweisung am Wurzelverzeichnis zu behalten, während es produktbereich- oder sprachspezifische Anleitung nah am von ihm betroffenen Inhalt platziert.
