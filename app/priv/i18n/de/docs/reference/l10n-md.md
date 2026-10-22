%{
  title: "L10N.md",
  summary: "Referenz für Repository-Übersetzungseinstellungen und Kontext.",
  category: "Referenz",
  section: "translation",
  order: 1
}
---

`L10N.md`Sagt, welche Dateien Glossia zu übersetzen sind, wohin die übersetzten Dateien gehören, welche Sprachen gesichtet werden und welche Kontexte das Ergebnis leiten sollten. Eine Repository kann eine Stammdatei und zusätzliche scoped-Dateien in Unter-Verzeichnissen enthalten.

## Struktur

Jede Datei hat zwei Teile:

1. [YAML Ain't Markup Language](https://yaml.org/) Frontmatter zwischen `---`-Markern.
2. Markdown-Text unter dem Frontmatter mit Produkt-, Publikum-, Stimme- oder Domänen-Kontext.

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

Provider-Credentials gehören in die Account-Einstellungen, niemals in `L10N.md`. Der optionale `model`-Wert ist ein Account-Modell-Handle.

## Frontmatter-Felder

| Feld | Typ | Erforderlich | Beschreibung |
|---|---|---|---|
| `source_language` | string | nicht | Quell-locale für diesen Bereich. Standardmäßig `en`. |
| `model` | string | nicht | Account-Modell-Handle. Glossia verwendet das Account-Standardmodell wenn eingespart und meldet einen Fehler wenn ein expliziter Handle existiert. |
| `sources` | Map oder Liste | für eine top-level Regel | Quelldatei-Muster. Map-Werte können Ausgabe-Templates definieren. |
| `targets` | Map oder Liste | wenn Quellen konfiguriert sind | Ziel-locale-Code. Eine Map kann einen locale-Code mit einem Sprachnamen assoziieren. |
| `output` | string | wenn keine Quellmappung oder `target_path` versorgt ein Ziel | Ausgabedatei-Schablone. |
| `target_path` | string | wenn keine Quellmappung oder `output` versorgt ein Ziel | Basisverzeichnisschablone für übersetzte Dateien. |
| `translate` | Liste | nicht | Mehrere Übersetzungsregeln, jede mit eigenen Quellen und optionalen Overrides. |
| `exclude` | Liste | nicht | Dateimuster zu überspringen. |
| `preserve` | Liste | nicht | Inhaltstypen, die unverändert bleiben müssen, wie Platzhalter oder uniforme Ressourcenscanner. |
| `frontmatter` | string | nicht | `preserve` Standardmäßig, oder `translate`. |
| `prompt` | string | nicht | Zusätzliche Hinweise für diesen Bereich oder diese Regel. |
| `validation` | Liste | für Dateierweiterungen ohne eingebaute Adapter | Ein Validierungsbefehl gefolgt von seinen Argumenten. Der Befehl empfängt den Kandidaten an seinem realen Zielpfad und muss einen nicht-null-Status zurückgeben, wenn die Datei ungültig ist. |
| `check_cmd` | string | nicht | Ein Prüfungsbefehl, der im Übersetzungsablauf verfügbar ist. |
| `check_cmds` | map | nicht | Benannte Prüfungsbefehle, die im Übersetzungsablauf verfügbar sind. |
| `retries` | integer | nicht | Anzahl der Wiederholungsversuche nach einem fehlgeschlagenen Check. Standardmäßig `2`. |
| `locale` | string | nicht | Locale, die an eine lokal-spezifische Kontextdatei angehängt ist. |
| `glossary` | Liste oder Map | nicht | In `L10N.md` eine Liste von Glossar-Termini. In `L10N/<locale>.md` eine Map von jedem Term zu seiner Übersetzung in dieser Sprache. Eingebettete Dateien fügen sich hinzu und überschreiben die vererbten Einträge. Siehe die [Glossar-Referenz](/docs/reference/glossary). |

Unbekannte Frontmatter-Felder werden ignoriert.

## Dateiformate

Glossia verfügt über eingebaute Verarbeitung für Markdown, JavaScript Object Notation, YAML Ain't Markup Language, portables Objekt und reine Textdateien. Andere Dateierweiterungen scheitern bei der Planung, es sei denn, die anwendbare `L10N.md` deklariert einen `validation`-Befehl. Dies vermeidet das stillschweigende Behandeln eines proprietären strukturierten Formats als unbeschränkten Text.

In Markdown wird nur Prosa übersetzt: Absätze, Überschriften, Listenpunkte, Tabellenzellen, die `title`, `details`, `alt`, `label`, `description`, `summary`, `placeholder`, `aria-label`, und `caption`-Attribute von Komponenten und HTML, sowie der Text einer HTML `<summary>`. Jeder andere Byte, einschließlich Code, Link-Ziele, Komponenten, Warnungen und explizite Überschriftenanker, bleibt exakt wie im Quelltext. [translation recovery](/docs/explanation/translation-recovery) zeigt, wie dies funktioniert.

Der Validierungsbefehl läuft nach, nachdem der Kandidat vorübergehend an seinen realen Zielpfad geschrieben wurde. Er kann den nativen Parser, Compiler oder Build-Befehl des Repositoriums aufrufen. Glossia stellt das vorherige Ziel nach jedem Validierungsversuch wieder her und schreibt nur den akzeptierten Kandidaten danach.

## Quell-Mappungen

Die klarste Form bildet jedes Quellmuster auf eine Ausgabe-Schablone ab:

```yaml
sources:
  "docs/**/*.md": "docs/i18n/{locale}/{relpath}"
  "content/*.json": "content/{locale}/{basename}.{ext}"
```

Eine Quellliste ist ebenfalls gültig, benötigt aber `output` oder `target_path` um das Ziel zu definieren:

```yaml
sources:
  - "docs/**/*.md"
target_path: "docs/i18n/{locale}"
```

## Zielsprachen

Eine Liste verwendet jeden Locale-Code als Sprach-Identifikator:

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

## Output-Variablen

| Variable | Wert |
|---|---|
| `{locale}` oder `{lang}` | Ziel-Local-Code. |
| `{relpath}` | Quellpfad relativ zum übereinstimmenden Muster. |
| `{basename}` | Quell-Dateiname ohne Erweiterung. |
| `{ext}` | Quell-Dateierweiterung ohne das führende Punkt. |

## Mehrere Regeln

Verwenden Sie `translate` wenn verschiedene Inhaltgruppen unterschiedliche Zielorte oder Prüfungen benötigen:

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

Regelwerte überschreiben Werte, die aus der umgebenden Datei vererbt werden.

## Bereicherter Kontext

Glossia liest `L10N.md`-Dateien vom Repository-Wurzel bis zur Quelldatei:

- Elterneinstellungen bieten Standardwerte.
- Eine tiefere Datei überschreibt Felder für ihr Verzeichnis.
- Markdown-Kontext wird von Eltern zu Kind akkumuliert.
- Lokalspezifische Anleitung und ein lokalspezifischer Modell-Handle können in `L10N/<locale>.md` liegen.

Dies erlaubt einem Repository, breite Sprachanweisung am Wurzel zu behalten, während produktbereich- oder sprachspezifische Anleitung nahe dem Inhalt liegt, den sie beeinflusst.
