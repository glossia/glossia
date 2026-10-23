%{
  title: "Glossia gegenüber Crowdin",
  summary:
    "Wählen Sie Glossia, um die Lokalisierung in Git zu behalten, Ihre eigenen Modell-Token zu nutzen und mit den Prüfungen Ihres Repositories zu validieren.",
  category: "Erklärung",
  markdown_only: true,
  section: "translation",
  order: 20
}
---

**Wählen Sie Glossia, wenn die Lokalisierung mit der Geschwindigkeit Ihrer Softwareauslieferung Schritt halten muss.** Ihr Repository definiert bereits, wie Änderungen geprüft, validiert und versendet werden. Glossia integriert Spracharbeiten in diesen Prozess, anstatt einen separaten Übersetzungsarbeitsbereich zum Zentrum Ihres Prozesses zu machen.

[Crowdin](https://crowdin.com/) bietet kollaboratives Übersetzungsmanagement, Prüfarbeitsabläufe, Übersetzungsspeicher und Repository-Integrationen. Der Vorteil von Glossia für ein Software-Team ist die Kombination aus Repository-verwalteten Inhalten, einsehbarem Quellcode, Ihren eigenen Modellzugangsdaten und einer Validierung, die das tatsächliche Projekt versteht.

## Warum Glossia

| Ihre Priorität | Vorteil von Glossia |
|---|---|
| Kontinuierlich versenden | Übersetzungsabläufe folgen den Änderungen am Quellcode und liefern überprüfbare Repository-Updates. Inhalte brauchen keinen eigenen, unabhängigen Release-Prozess. |
| Behalten Sie die Kontrolle über die Implementierung | Die öffentliche Anwendung, CLI und Bereitstellungscode können unter den Lizenzbedingungen geprüft, geändert und selbst gehostet werden. |
| Bringen Sie Ihre eigenen Tokens mit | Richten Sie unterstützte Modelle mit Ihren eigenen Anbieter-API-Tokens ein. Repository-Dateien verweisen auf stabile Modellhandles, nicht auf Geheimnisse. |
| Nutzen Sie die Prüfungen, denen Sie vertrauen | Führen Sie einen Repository-Validierungsaufruf gegen den Kandidaten an seinem tatsächlichen Zielpfad aus, bevor Sie ihn akzeptieren. |
| Behalten Sie Ihre Inhalte | Quellcodes, übersetzte Ausgaben, Konfigurationen und Pull-Request-Geschichte bleiben in Ihrem Repository. |

## Lokalisierung, die mit Commits Schritt hält

Glossia arbeitet mit versionierten `L10N.md`Anweisungen und erkennt, welche Inhalte aktualisiert werden müssen. Unveränderte Eingaben müssen nicht erneut übersetzt werden. Ein Projekt pflegt eine offene Übersetzungs-Pull-Request und veröffentlicht Fortschritte in Batches, was unnötige Pull-Requests und wiederholte CI-Abläufe reduziert, während sich der Quellcode weiterentwickelt.

Das Ergebnis ist ein Sprachworkflow, der um dieselben kleinen, überprüfbaren Änderungen herum gestaltet ist, die Ihr Team bereits versendet. Kontinuierlich bedeutet nicht unüberpruft: Prüfer entscheiden weiterhin, was sicher gemergt werden darf.

Crowdin unterstützt ebenfalls Git-Integrationen und Automatisierung. Der Grund, Glossia zu wählen, liegt nicht darin, dass Crowdin nicht zu einem Repository verbinden kann; es liegt vielmehr darin, dass die Repository-Auslieferung die Grundlage des Glossia-Workflows ist, nicht nur eine Integrationsgrenze.

## Ihre Tokens, Ihre Modellauswahl

Sie müssen die Repository-Konfiguration nicht für die Rotation eines Anbietertokens oder die Änderung eines Modells hinter einem Übersetzungsworkflow neu erstellen. Glossia speichert Zugangsdaten in den Kontoeinstellungen und stellt stabile Handles für das Repository bereit. Unterschiedliche Inhaltsbereiche oder Ziel-Locales können unterschiedlich konfigurierte auswählen.

Dies gibt Ihrem Team die Kontrolle über die unterstützten Anbieterbeziehungen und Modellauswahlen, die es verwendet. Siehe [Ein Modellanbieter konfigurieren](/docs/how-to/configure-a-model-provider).

## Validieren Sie die Ausgabe als Teil Ihres Produkts

Eine Übersetzung kann gut lesbar sein und dennoch einen Dokumentationsbuild, eine Komponente, einen Platzhalter oder einen Anwendungsparser beschädigen. Glossia ermöglicht es Ihnen, eine Repository-Prüfung weiterzuverwenden, anstatt bei der Bewertung durch einen Editor beim Text stehen zu bleiben.

Wenn Ihr Repository bereits ein Dokumentationsvalidierungsskript bereitstellt, verweisen Sie direkt darauf:

```yaml
validation:
  - ./scripts/validate-docs.sh
  - --strict
```

Der Validierer empfängt den Kandidaten an seinem tatsächlichen Zielpfad, gibt bei Fehlern einen Wert nicht null zurück und führt innerhalb des konfigurierten Retry-Budgets aus. Seine Abhängigkeiten müssen in der Validierungsumgebung verfügbar sein. Sehen Sie [L10N.md](/docs/reference/l10n-md) für den Vertrag.

## Offener Quellcode, ohne das Repository abzugeben

Sie können prüfen, wie Glossia Pläne erstellt, Zugangsdaten verwaltet, Markdown erhält und ein Ergebnis validiert. Bestehende übersetzte Dateien bleiben über die Pipeline Ihres Repositories veröffentlicht, auch wenn der Sprachdienst nicht verfügbar ist.

Glossia ist unter der [O'Saasy-Lizenz](https://github.com/glossia/glossia/blob/main/LICENSE.md) als Quellcode-Verfügbarkeit gültig, was Selbst-Hosting gestattet, aber konkurrierende gehostete Dienste einschränkt. Es ist keine unbeschränkte Open-Source-Lizenz.

Crowdin kann weiterhin geeignet sein für ein Programm, das auf die Koordinierung von Beiträgen und einem dedizierten Übersetzungsbearbeiter ausgerichtet ist. Für ein Software-Team, dessen Priorität **Inhalte im Git-Besitz, existierende Validierung und Lokalisierung, die der Auslieferung folgt** ist, ist Glossia für diese Aufgabe konzipiert.

Dieser Vergleich behauptet nicht, dass Crowdin Automatisierung oder jede Form der Anbieterintegration vermisst, oder dass Glossia seine Speicher und Geschichte automatisch migriert. Konsultieren Sie [Crowdins Dokumentation](https://support.crowdin.com/) für aktuelle Fähigkeiten.
