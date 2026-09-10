%{
  title: "L10N.md",
  summary: "Referenz für Repository-Übersetzungseinstellungen und Kontext.",
  category: "Referenz",
  order: 1
}
---
`L10N.md` sagt Glossia, welche Dateien zu übersetzen sind, wohin übersetzte Dateien gehören, welche Sprachen das Ziel sind und welchem Kontext das Ergebnis folgen soll. Ein Repository kann eine Root-Datei und zusätzliche Dateien in Unterordnern haben.

## Struktur

Jede Datei besteht aus zwei Teilen:

1. [YAML Ain't Markup Language](https://yaml.org/) Frontmatter zwischen `---` Markern.
2. Markdown unterhalb des Frontmatters mit Kontext zu Produkt, Publikum, Stimme oder Domäne.

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

Anbieter-Anmeldeinformationen gehören in die Kontoeinstellungen, niemals in `L10N.md`. Der optionale `model`-Wert ist ein Kontomodell-Handle.

## Frontmatter-Felder

| Feld | Typ | Erforderlich | Beschreibung |
|---|---|---|---|
| `source_language` | string | nein | Quelldialekt für diesen Bereich. Standardmäßig `en`. |
| `model` | string | nein | Kontomodell-Handle. Wenn weggelassen, verwendet Glossia die Standardschaltfläche des Kontos und meldet einen Fehler, wenn ein expliziter Handle nicht existiert. |
| `sources` | map oder list | für eine übergeordnete Regel | Quell-Dateimuster. Map-Werte können Ausgabe-Vorlagen definieren. |
| `targets` | map oder list | wenn Quellen konfiguriert sind | Zielsprachen-Codes. Eine Map kann einen Code mit einem Ländernamen verknüpfen. |
| `output` | string | wenn keine Quellabspiegelung oder `target_path` das Ziel zur Verfügung stellt | Ausgabe-Dateivorlage. |
| `target_path` | string | wenn keine Quellabspiegelung oder `output` das Ziel zur Verfügung stellt | Basis-Verzeichnis-Vorlage für übersetzte Dateien. |
| `translate` | list | nein | Mehrere Übersetzungsregeln, jede mit eigenen Quellen und optionalen Overrides. |
| `exclude` | list | nein | Datei-Muster zum Überspringen. |
| `preserve` | list | nein | Inhaltstypen, die unverändert bleiben müssen, wie z. B. Platzhalter oder URIs. |
| `frontmatter` | string | nein | `preserve` standardmäßig oder `translate`. |
| `prompt` | string | nein | Zusätzliche Anweisungen für diesen Bereich oder diese Regel. |
| `validation` | list | für Dateierweiterungen ohne integrierten Adapter | Ein Validierungsbefehl gefolgt von seinen Argumenten. Der Befehl erhält den Kandidaten an seinem echten Zielpfad und muss eine nicht-null-Rückmeldung zurückgeben, wenn die Datei ungültig ist. |
| `check_cmd` | string | nein | Ein Prüf-befehl, der für den Übersetzungsworkflow verfügbar ist. |
| `check_cmds` | map | nein | Benannte Prüf-befehle, die für den Übersetzungsworkflow verfügbar sind. |
| `retries` | integer | nein | Anzahl der Wiederholungsversuche nach einem fehlgeschlagenen Check. Standardmäßig `2`. |
| `locale` | string | nein | Anbindung an eine lokalitätsbestimmte Kontextdatei. |

Unbekannte Frontmatter-Felder werden ignoriert.

## Dateiformate

Glossia verfügt über eingebaute Handhabung für Markdown, JavaScript Object Notation, YAML Ain't Markup Language, Portable Objects und Textdateien. Andere Dateierweiterungen versagen bei der Planung, es sei denn, das entsprechende `L10N.md` deklariert einen `validation`-Befehl. Dies verhindert eine stillschweigende Behandlung eines proprietären strukturierten Formats als unbegrenzten Text.

Der Validierungsbefehl wird ausgeführt, nachdem der Kandidat vorübergehend an seinen echten Zielpfad geschrieben wurde. Er kann den nativen Parser, Compiler oder Build-Befehl des Repositories aufrufen. Glossia stellt nach jedem Validierungsversuch das vorherige Ziel wieder her und schreibt den angenommenen Kandidaten erst danach.

## Quellzuordnungen

Die klarste Form ist das Zuordnen jedes Quellmusters an eine Ausgabetemplate:

```yaml
sources:
  "docs/**/*.md": "docs/i18n/{locale}/{relpath}"
  "content/*.json": "content/{locale}/{basename}.{ext}"
```

Eine Quell-Liste ist ebenfalls gültig, benötigt aber `output` oder `target_path`, um das Ziel zu definieren:

```yaml
sources:
  - "docs/**/*.md"
target_path: "docs/i18n/{locale}"
```

## Zielsprachen

Eine Liste verwendet jeden Locale-Code als Sprachkennzeichner:

```yaml
targets:
  - es
  - ja
```

Ein Mapping kann einen lesbaren Sprachnamen hinzufügen:

```yaml
targets:
  es: Spanish
  ja: Japanese
```

## Ausgabewerte

| Variable | Wert |
|---|---|
| `{locale}` oder `{lang}` | Locale-Code des Zielspraches. |
| `{relpath}` | Quellpfad relativ zum zutreffenden Muster. |
| `{basename}` | Quelldateiname ohne seine Erweiterung. |
| `{ext}` | Datei-Extenion der Quelle ohne den führenden Punkt. |

## Mehrere Regeln

Verwenden Sie `translate`, wenn verschiedene Inhaltgruppen unterschiedliche Zielorte oder Prüfungen benötigen:

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

Regelwerte überschreiben Werte, die aus der umgebenden Datei geerbt wurden.

## Bereichsbezogener Kontext

Glossia liest `L10N.md`-Dateien vom Repository-Wurzelordner bis zur Quelldatei:

- Elterneinstellungen liefern Standardwerte.
- Eine tiefere Datei überschreibt Felder für ihr Verzeichnis.
- Der Markdown-Kontext wird vom Eltern- zum Kindobjekt gesammelt.
- Lokalspezifische Leitlinien und ein lokalspezifischer Modell-Handler können in `L10N/<locale>.md` angesiedelt sein.

Dadurch kann ein Repository breite Sprach-Leitlinien am Wurzelordner beibehalten und produktbereichs- oder sprachespezifische Anleitung nah am von ihnen betroffenen Inhalt platzieren.