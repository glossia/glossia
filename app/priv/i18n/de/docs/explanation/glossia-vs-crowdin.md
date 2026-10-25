%{
  title: "Glossia gegen Crowdin",
  summary:
    "Wählen Sie Glossia aus, um die Lokalisierung in Git zu behalten, eigene Model-Tokens mitzubringen und mit den Prüfungen Ihres Repositorys zu validieren.",
  category: "Erklärung",
  markdown_only: true,
  section: "translation",
  order: 20
}
---

**Wählen Sie Glossia, wenn die Lokalisierung mit der Geschwindigkeit Ihrer Softwareauslieferung erfolgen muss.** Ihr Repository definiert bereits, wie Änderungen geprüft, validiert und ausgeliefert werden. Glossia bringt die Spracharbeit in diesen Prozess statt einen separaten Übersetzungsarbeitsbereich zum Mittelpunkt Ihres Vorgangs zu machen.

[Crowdin](https://crowdin.com/) bietet kollaboratives Übersetzungsmanagement, Prüfungsabläufe, Übersetzungsspeichersysteme und Repository-Integrationen. Der Vorteil von Glossia für ein Softwareteam ist die Kombination aus Repository-geführten Inhalten, überprüfbarem Quellcode, eigenen Modellberechtigungen und einer Validierung, die das tatsächliche Projekt versteht.

## Warum Glossia wählen

| Ihre Priorität | Vorteil von Glossia |
|---|---|
| Kontinuierlich ausliefern | Übersetzungsabläufe folgen Quellcodeänderungen und liefern überprüfbare Repository-Updates zurück. Inhalte benötigen keinen eigenen, unabhängigen Release-Prozess. |
| Behalten Sie die Kontrolle über die Implementierung | Die öffentliche Reaktion, die CLI und das Bereitstellungscode können unter den Lizenzbedingungen geprüft, bearbeitet und selbst gehostet werden. |
| Bringen Sie Ihre eigenen Tokens mit | Konfigurieren Sie unterstützte Modelle mit Ihren eigenen Anbieter-API-Tokens. Repository-Dateien verweisen auf stabile Modell-Handles, nicht auf Geheimnisse. |
| Nutzen Sie die Prüfungen, denen Sie vertrauen | Führen Sie einen Repository-Validierungsbefehl gegen den Kandidaten auf dessen echtem Zielpfad aus, bevor Sie ihn akzeptieren. |
| Behalten Sie die Inhalte in Ihrem Besitz | Quelldateien, übersetzte Ausgaben, Konfigurationen und Pull-Request-Verlauf verbleiben in Ihrem Repository. |

## Lokalisierung, die mit Commits Schritt hält

Glossia arbeitet von verfassten `L10N.md`-Anweisungen aus und erkennt, welcher Inhalt aktualisiert werden muss. Ungeänderte Eingaben müssen nicht erneut übersetzt werden. Ein Projekt behält einen offenen Übersetzungs-Pull-Request bei und veröffentlicht Fortschritte in Chargen, wodurch unnötige Pull-Requests und wiederholte CI-Läufe reduziert werden, wie sich der Quellcode entwickelt.

Das Ergebnis ist ein Sprach-Ablauf, der um die gleichen kleinen, überprüfbaren Änderungen entwickelt wurde, die Ihr Team bereits ausliefert. Kontinuierlich bedeutet nicht ohne Prüfung: Prüfer entscheiden immer noch, was sicher gemerged werden kann.

Crowdin unterstützt ebenfalls Git-Integrationen und Automatisierung. Der Grund für die Wahl von Glossia ist nicht, dass sich Crowdin nicht mit einem Repository verbinden kann; vielmehr ist die Repositoryauslieferung die Grundlage des Glossia-Ablaufs, nicht nur eine Integrationsgrenze.

## Ihre Token, Ihre Modellauswahl

Sie müssen keine Repository-Konfiguration neu aufbauen müssen, um ein Provider-Token zu rotieren oder das Modell hinter einem Übersetzungsworkflow zu ändern. Glossia speichert Credentials in den Kontoeinstellungen und gibt stabile Handles an das Repository aus. Verschiedene Inhaltsbereiche oder Ziel-Lokalen können verschiedene konfigurierte Modelle auswählen.

Dies gibt Ihrem Team die Kontrolle über die unterstützten Anbieterbeziehungen und Modelauswahl, die es verwendet. Siehe [Ein Modellanbieter konfigurieren](/docs/how-to/configure-a-model-provider).

## Validieren Sie die Ausgabe als Teil Ihres Produkts

Eine Übersetzung kann gut lesbar sein und dennoch einen Dokumentationsbuild, -Komponenten, -Placeholder oder einen Applikationsparser beschädigen. Glossia ermöglicht es Ihnen, eine Repository-Prüfung zu wiederholen, anstatt sich bei der Einschätzung eines Texteditors einzuschließen.

Wenn Ihr Repository bereits ein Dokumentation-Validierungsskript bereitstellt, verweisen Sie direkt darauf:

```yaml
validation:
  - ./scripts/validate-docs.sh
  - --strict
```

Der Validator empfängt den Kandidaten auf dessen tatsächlichem Zielpfad, gibt einen Nicht-Null-Status bei Misserfolg zurück und läuft innerhalb des konfigurierten Wiederholungsbudgets ab. Seine Abhängigkeiten müssen im Validierungsumfeld verfügbar sein. Siehe [L10N.md](/docs/reference/l10n-md) für den Vertrag.

## Öffentlicher Quellcode, ohne das Repository zu opfern

Sie können prüfen, wie Glossia-Pläne funktionieren, Credentials verwalten, Markdown bewahren und Ergebnisse validieren. Bestehende übersetzte Dateien bleiben über Ihre Repository-Pipeline publizierbar, selbst wenn der Sprachdienst nicht verfügbar ist.

Glossia ist unter der [O'Saasy Lizenz](https://github.com/glossia/glossia/blob/main/LICENSE.md) verfügbar, was Eigenbetrieb erlaubt, aber konkurrierende gehostete Dienste einschränkt. Es ist keine uneingeschränkte Open-Source-Lizenz.

Crowdin kann für ein Programm angemessen sein, das sich auf die Koordination von Beiträgern und einen dedizierten Übersetzer-Editor konzentriert. Für ein Softwareteam, dessen Priorität **Git-eigenen Inhalten, bestehende Validierung und Lokalisierung, die der Auslieferung folgt** ist, ist Glossia für diese Aufgabe geschaffen.

Dieser Vergleich behauptet nicht, dass Crowdin an Automatisierung mangelt oder jede Form der Anbieterintegration, oder dass Glossia seine Speicher und Verläufe automatisch migriert. Konsultieren Sie [Crowdins Dokumentation](https://support.crowdin.com/) für aktuelle Fähigkeiten.
