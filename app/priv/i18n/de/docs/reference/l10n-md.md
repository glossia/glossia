%{
  title: "L10N.md",
  summary: "Referenz für Repository-Übersetzungseinstellungen und Kontext.",
  category: "Referenz",
  order: 1
}
---
`L10N.md` erklärt Glossia, welche Dateien übersetzt werden sollen, wohin die übersetzten Dateien gehören, welche Sprachen als Ziel dienten und welcher Kontext den Output leiten sollte. Ein Repository kann eine Quelldatei und zusätzlich bereichsspezifische Dateien in Unterverzeichnissen haben.

## Struktur

Jede Datei hat zwei Teile:

1. [YAML Ain't Markup Language](https://yaml.org/) Kopfen zwischen `---` Markierungen.
2. Markdown unter dem Kopfen mit Produkt-, Zielgruppen-, Stimme- oder Domänendetails.

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

Anmeldezugänge gehören in das Konto-Konfigurationsmenü, niemals in `L10N.md`. Der optionalen `model` Wert ist ein Accounts-Modelldurchführungsname.

## Kopfen-Felder

| Feld | Typ | Erforderlich | Beschreibung |
|---|---|---|---|
| `source_language` | String | nein | Quelldiel für diesen Bereich. Standardwert ist `en`. |
| `model` | String | nein | Accounts-Modelldurchführungsname. Glossia benutzt die Accounts-Sonderausführung, wenn nichts angegeben ist und meldet einen Fehler, wenn der angegebene Durchführungsname nicht existiert. |
| `sources` | Map oder Liste | für eine oberste Regel | Quelldatei-Muster. Map-Werte können Output-Vorlagen definieren. |
| `targets` | Map oder Liste | wenn Quellen konfiguriert sind | Zielsprachencodes. Eine Map kann einen Sprachencode mit einem Sprachnamen verknüpfen. |
| `output` | String | wenn keine Quellzuordnung oder `target_path` ein Ziel bereitstellt | Output-Datei-Vorlage. |
| `target_path` | String | wenn keine Quellzuordnung oder `output` ein Ziel bereitstellt | Basisverzeichnis-Vorlage für übersetzte Dateien. |
| `translate` | Liste | nein | Mehrere Übersetzungsregeln, jede hat eigene Quellen und optionale Überschreibungen. |
| `exclude` | Liste | nein | Dateimuster, die übersprungen werden. |
| `preserve` | Liste | nein | Inhaltsarten, die unverändert bleiben müssen, etwa Platzhalter oder gleichförmige Ressourcen Lokatoren. |
| `frontmatter` | String | nein | `preserve` durch Standard oder `translate`. |
| `prompt` | String | nein | Zusätzliche Richtungen für diesen Bereich oder Regel. |
| `validation` | Liste | für Dateiendungen ohne eingebauten Adapter | Ein Validierungs Befehl gefolgt von seinen Daten. Der Befehl bekommt den Kandidaten an seinem Real-Zieldurchgang und muss einen NEUMER-Konstatus zurückgeben, wenn die Datei ungültig ist. |
| `check_cmd` | String | nein | Ein Check-Befehl, der für den Übersetzerweg verfügbar ist. |
| `check_cmds` | Map | nein | Benannte Check-Befehle, die für den Übersetzerweg verfügbar sind. |
| `retries` | Integer | nein | Anzahl der Wiederholungs-Versuche nach einem fehlgeschlagenen Check. Standardwert `2`. |
| `locale` | String | nein | Lokalität, die an ein lokal-spezifisches Kontextdatei angehängt ist. |

Unbekannte Kopfen-Felder werden ignoriert.

## Dateiformate

Glossia unterstützt Markdown, JavaScript Object Notation, YAML Ain't Markup Language, portables Objekt und reine Textdateien. Andere Dateiendarten versagen die Planung, es sei denn, die passende `L10N.md` erklärt einen `validation` Befehl. Dies vermeidet zu stumm ein eigenes strukturiertes Format als unbeschränkten Text zu behandeln.

Der Validierungs-Befehl läuft, nachdem der Kandidat vorübergehend an seinem Zielhafen geschrieben wurde. Er kann den Repository's inst Sally Parser, Compiler oder Bau-Befehl aufrufen. Glossia stellt den vorherigen Hafen nach jedem Validierungs-Versuch wieder her und schreibt den akzeptierten Kandidaten danach nur.

## Quellzuordnungen

Die klarste Form weist jedes Quellmuster einer Output-Vorlage zu:

```yaml
sources:
  "docs/**/*.md": "docs/i18n/{locale}/{relpath}"
  "content/*.json": "content/{locale}/{basename}.{ext}"
```

Eine Quell-Liste ist auch gültig, aber sie braucht `output` oder `target_path` um das Ziel zu definieren:

```yaml
sources:
  - "docs/**/*.md"
target_path: "docs/i18n/{locale}"
```

## Zielsprachen

Eine Liste verwendet jeden Locale-Code als Sprachkennung:

```yaml
targets:
  - es
  - ja
```

Eine Karte kann einen lesbaren Sprachnamen hinzufügen:

```yaml
targets:
  es: Spanish
  ja: Japanese
```

## Ausgabevariablen

| Variable | Wert |
|---|---|
| `{locale}` oder `{lang}` | Code der Zielsprache. |
| `{relpath}` | Quellpfad relativ zum Mustermuster. |
| `{basename}` | Quelldateiname ohne Erweiterung. |
| `{ext}` | Dateinamerweiterung der Quelldatei ohne den führenden Punkt. |

## Mehrere Regeln

Verwenden Sie `translate`, wenn unterschiedliche Inhaltstypen unterschiedliche Bestimmungsorte oder Prüfungen benötigen:

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

## Kontextbereich

Glossia liest `L10N.md` -Dateien vom Repository-Wurzelverzeichnis bis zur Quelldatei:

- Eine Einstufung der Eltern bietet Standardwerte.
- Eine tiefere Datei überschreibt Felder für ihr Verzeichnis.
- Markdown-Kontext wird von Eltern zu den Kindern akkumuliert.
- Locale-spezifische Hinweise und ein Locale-spezifischer Modell-Handler können in `L10N/<locale>.md` wave.

Dies ermöglicht es einem Repository, weit gefasste Stimmbestimmungen am Wurzelverzeichnis zu belassen, während produktbereichs- oder sprachespezifische Hinweise nah am Inhalt platziert werden, den sie betreffen.