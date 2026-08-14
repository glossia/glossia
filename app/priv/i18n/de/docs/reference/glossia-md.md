%{
  title: "GLOSSIA.md",
  summary: "Referenz für Übersetzungseinstellungen und Kontext des Repositorys.",
  category: "Referenz",
  order: 1
}
---
`GLOSSIA.md` teilt Glossia mit, welche Dateien übersetzt werden sollen, wohin übersetzte Dateien gehören, welche Sprachen das Ziel sind und welcher Kontext das Ergebnis leiten soll. Ein Repository kann eine Root-Datei und zusätzliche bereichsbezogene Dateien in Unterverzeichnissen enthalten.

## Struktur

Jede Datei besteht aus zwei Teilen:

1. [YAML Ain't Markup Language](https://yaml.org/)-Frontmatter zwischen `---`-Markierungen.
2. Markdown unterhalb des Frontmatter mit Kontext zu Produkt, Zielgruppe, Stimme oder Domäne.

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

Provider-Anmeldedaten gehören in die Kontoeinstellungen, niemals in `GLOSSIA.md`. Der optionale Wert für `model` ist ein Kontomodell-Handle.

## Frontmatter-Felder

| Feld | Typ | Erforderlich | Beschreibung |
|---|---|---|---|
| `source_language` | String | Nein | Quell-Locale für diesen Bereich. Standardwert ist `en`. |
| `model` | String | Nein | Kontomodell-Handle. Glossia verwendet den Konto-Standardwert, wenn dieser Parameter ausgelassen wird, und meldet einen Fehler, wenn ein explizites Handle nicht existiert. |
| `sources` | Map oder Liste | Für eine Regel auf oberster Ebene | Quelldatei-Muster. Map-Werte können Ausgabe-Templates definieren. |
| `targets` | Map oder Liste | Wenn Quellen konfiguriert sind | Ziel-Locale-Codes. Eine Map kann einen Locale-Code mit einem Sprachnamen verknüpfen. |
| `output` | String | Wenn kein Quell-Mapping oder `target_path` ein Ziel bereitstellt | Ausgabe-Datei-Template. |
| `target_path` | String | Wenn kein Quell-Mapping oder `output` ein Ziel bereitstellt | Basisverzeichnis-Template für übersetzte Dateien. |
| `translate` | Liste | Nein | Mehrere Übersetzungsregeln, jeweils mit eigenen Quellen und optionalen Überschreibungen. |
| `exclude` | Liste | Nein | Zu überspringende Dateimuster. |
| `preserve` | Liste | Nein | Inhaltsarten, die unverändert bleiben müssen, wie Platzhalter oder Uniform Resource Locators. |
| `frontmatter` | String | Nein | Standardmäßig `preserve` oder `translate`. |
| `prompt` | String | Nein | Zusätzliche Anweisungen für diesen Bereich oder diese Regel. |
| `validation` | Liste | Für Dateiendungen ohne integrierten Adapter | Ein Validierungsbefehl gefolgt von seinen Argumenten. Der Befehl erhält den Kandidaten an seinem tatsächlichen Zielpfad und muss einen Status ungleich Null zurückgeben, wenn die Datei ungültig ist. |
| `check_cmd` | String | Nein | Ein Prüfbefehl, der für den Übersetzungsworkflow verfügbar ist. |
| `check_cmds` | Map | Nein | Benannte Prüfbefehle, die für den Übersetzungsworkflow verfügbar sind. |
| `retries` | Integer | Nein | Anzahl der Wiederholungsversuche nach einer fehlgeschlagenen Prüfung. Standardwert ist `2`. |
| `locale` | String | Nein | Locale, die einer localespezifischen Kontextdatei zugeordnet ist. |

Unbekannte Frontmatter-Felder werden ignoriert.

## Dateiformate

Glossia verfügt über eine integrierte Verarbeitung von Markdown-, JavaScript Object Notation-, YAML Ain't Markup Language-, Portable-Object- und Reintextdateien. Bei anderen Dateiendungen schlägt die Planung fehl, es sei denn, die entsprechende `GLOSSIA.md` deklariert einen `validation`-Befehl. Dies verhindert, dass ein proprietäres strukturiertes Format stillschweigend als unbeschränkter Text behandelt wird.

Der Validierungsbefehl wird ausgeführt, nachdem die temporäre Version des Kandidaten in seinen tatsächlichen Zielpfad geschrieben wurde. Er kann den nativen Parser, Compiler oder Build-Befehl des Repositorys aufrufen. Glossia stellt das vorherige Ziel nach jedem Validierungsversuch wieder her und schreibt erst danach den akzeptierten Kandidaten.

## Quell-Mappings

Die klarste Form ordnet jedes Quellmuster einem Ausgabe-Template zu:

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

Eine Liste verwendet jeden Locale-Code als Kennung für die Sprache:

```yaml
targets:
  - es
  - ja
```

Ein Map-Objekt kann einen lesbaren Sprachnamen hinzufügen:

```yaml
targets:
  es: Spanish
  ja: Japanese
```

## Ausgabevariablen

| Variable | Wert |
|---|---|
| `{locale}` oder `{lang}` | Ziel-Locale-Code. |
| `{relpath}` | Quellpfad relativ zum übereinstimmenden Muster. |
| `{basename}` | Quelldateiname ohne Erweiterung. |
| `{ext}` | Quelldateierweiterung ohne führenden Punkt. |

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

Regelwerte überschreiben Werte, die aus der übergeordneten Datei geerbt wurden.

## Gültigkeitsbereich des Kontexts

Glossia liest `GLOSSIA.md`-Dateien vom Repository-Stammverzeichnis in Richtung der Quelldatei:

- Übergeordnete Einstellungen liefern Standardwerte.
- Eine tiefer liegende Datei überschreibt Felder für ihr Verzeichnis.
- Markdown-Kontext wird von der übergeordneten zur untergeordneten Ebene akkumuliert.
- Locale-spezifische Richtlinien und ein locale-spezifischer Model-Handle können in `GLOSSIA/<locale>.md` hinterlegt werden.

Dies ermöglicht es einem Repository, allgemeine Richtlinien zur Stimme im Stammverzeichnis zu verwalten, während produktbereichs- oder sprachspezifische Richtlinien nah am betroffenen Inhalt platziert werden.