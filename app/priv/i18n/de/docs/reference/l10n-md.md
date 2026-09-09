%{
  title: "L10N.md",
  summary: "Referenz für Repository-Übersetzungseinstellungen und Kontext.",
  category: "reference",
  order: 1
}
---
`L10N.md` definiert, welche Dateien Glossia übersetzt, wohin die Übersetzungen gehören, welche Ziel-Sprachen تستهدف sich und welchen Kontext die Ergebnisse leiten sollen. Ein Repository kann eine Datei an der Wurzel und zusätzliche auf den Scope begrenzte Dateien in Subordnern enthalten.

## Struktur

Jede Datei verfügt über zwei Teile:

1. [YAML Ain't Markup Language](https://yaml.org/) der Frontmatter zwischen `---` Markern.
2. Markdown unterhalb der Frontmatter mit Produkt, Zielgruppe, Ton oder Domänenkontext.

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

Provider-Angeböte gehören in Kontoeinstellungen, niemals in `L10N.md`. Das optionale `model`Wert ist ein Konto-Modell-Handle.

## Frontmatter-Felder

| Feld | Typ | Erforderlich | Beschreibung |
|---|---|---|---|
| `source_language` | String | nein | Quell-Sprache für diesen Bereich. Standardwert ist `en`. |
| `model` | String | nein | Konto-Modell-Handle. Glossia nutzt die Konto-Standardvorgabe bei Weglassung und meldet einen Fehler, wenn ein expliziter Handhab nicht existiert. |
| `sources` | Karte oder Liste | für eine Root-Regel | Quell-Datei-Muster. Kamerawerte können Ausgabe-Vorlagen definieren. |
| `targets` | Karte oder Liste | wenn Quellen konfiguriert sind | Zielsprach-Code. Eine Karte kann einen Sprachcode mit einem Sprachnamen verknüpfen. |
| `output` | String | wenn keine Quelle Zuordnung oder `target_path` Vorhersage ein Ziel liefert | Ausgabe-Datei-Vorlage. |
| `target_path` | String | wenn keine Quelle Zuordnung oder `output` Vorhersage ein Ziel liefert | Basis-Verzeichnis-Vorlage für übersetzte Dateien. |
| `translate` | Liste | nein | Mehrere Übersetzungs-Regeln, jede mit eigenen Quellen und optionalen mitgetragenen Entscheidungen. |
| `exclude` | Liste | nein | Dateimuster zum überspringen. |
| `preserve` | Liste | nein | Inhalt-Art, die unverändert bleiben muss, wie Platzhalter oder einheitliche Ressourcen-Orte. |
| `frontmatter` | String | nein | `preserve` Standardmäßig, oder `translate`. |
| `prompt` | String | nein | Zusätzliche Anweisung für diesen Bereich oder Regel. |
| `validation` | Liste | für Datei-Attribute ohne eingebauten Adapter | Ein Validierungsbefehl gefolgt von seinen Argumenten. Der Befehl erhält das Kandidat an seinem echten Ziel-Weg und muss einen nicht-null Status zurückgeben, wenn die Datei ungültig ist. |
| `check_cmd` | String | nein | Ein Prüfbefehl zur Verfügung für den Übersetzungs-Arbeitsablauf. |
| `check_cmds` | Karte | nein | Benannte Prüfbefehle zur Verfügung für den Übersetzungs-Arbeitsablauf. |
| `retries` | Integer | nein | Anzahl der Versuche nach fehlgeschlagenen Prüfung nach einem Fehler. Standardwert `2`. |
| `locale` | String | nein | Sprache, die einem kontextspezifischen Kontext-Datei angehegt wurde. |

Unbekannte Frontmatter-Felder werden ignoriert.

## Dateiformate

Glossia hat integrierte Funktionen für Markdown, JavaScript Object Notation, YAML Ain't Markup Language, Portable Object und reine Textdateien. Andere Dateierweiterungen versagen im Planen, es sei denn, das zugewiesene `L10N.md` erklärt ein `validation`Befehl. Dies vermeidet das schweigende Behandeln eines proprietären strukturierten Formats als nicht-eingeschränkter Text.

Der Validierungsbefehl läuft nach dem Kandidat temporär in seinen realen Ziel-Weg geschrieben wurde. Er kann das Repositorys nativen Parser, Compiler, oder Build-Befehl aktivieren. Glossia stellt das vorherige Ziel nach jedem Validierungs-Versuch wieder her und schreibt nur den angenommenen Kandidaten danach.

## Quell-Zuordnungen

Die klarste Form mappert alle Quell-Muster zu einer Ausgabe-Vorlage:

```yaml
sources:
  "docs/**/*.md": "docs/i18n/{locale}/{relpath}"
  "content/*.json": "content/{locale}/{basename}.{ext}"
```

Eine Quell-Liste ist auch gültig, aber sie benötigt `output` oder `target_path` um das Ziel zu definieren:

```yaml
sources:
  - "docs/**/*.md"
target_path: "docs/i18n/{locale}"
```

## Zielsprachen

Eine Liste verwendet jeden Sprachcode als dessen Lokalisierungsidentifier:

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

## Ausgabewerte

| Variable | Wert |
|---|---|
 | `{locale}` oder `{lang}` | Zielsprachencode. |
| `{relpath}` | Quelldateipfad relativ zum übereinstimmenden Muster. |
| `{basename}` | Quelldateiname ohne Dateiendung. |
| `{ext}` | Dateiendung der Quelldatei ohne vorgesetztem Punkt. |

## Mehrere Regeln

VerwendenSie `translate` wenn unterschiedliche Inhaltsgruppen verschiedene Ziele oder Prüfungen benötigen:

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

## Eingeschränkter Kontext

Glossia liest`L10N.md`Dateien vom Repositoriumswurzelpfad hin zur Quelldatei:

- Übergreifende Einstellungen definieren Standardwerte.
- Eine tiefere Datei überschreibt Felder für ihr Verzeichnis.
- Markdown-Kontext wird von übergeordneten zu untergeordneten Verzeichnisstufen akkumuliert.
- Sprachspezifische Anleitung und ein sprachspezifischer Modellschlüssel können in`L10N/<locale>.md`.

Dies ermöglicht es einem Repositorium, breite Sprachausrichtungsanweisungen an der Wurzel zu behalten, während produktbereichs- oder sprachspezifische Anleitung nah am von ihr betroffenen Inhalt platziert wird.