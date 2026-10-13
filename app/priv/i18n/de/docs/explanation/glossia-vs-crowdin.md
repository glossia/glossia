%{
  title: "Glossia im Vergleich zu Crowdin",
  summary:
    "Wählen Sie Glossia, um die Lokalisierung in Git zu behalten, eigene Modell-Tokens zu nutzen und mit den Prüfungen Ihres Repositories zu validieren.",
  category: "Erklärung",
  section: "translation",
  order: 20
}
---

**Wählen Sie Glossia, wenn die Lokalisierung mit der Geschwindigkeit Ihrer Softwareauslieferung mithalten muss.** Ihr Repository definiert bereits, wie Änderungen überprüft, validiert und ausgeliefert werden. Glossia bringt die sprachliche Arbeit in diesen Kreislauf ein, anstatt einen separaten Übersetzungs-Workspace zum Zentrum Ihres Prozesses zu machen.

[Crowdin](https://crowdin.com/) bietet kollaboratives Übersetzungsmanagement, Review-Arbeitsabläufe, Übersetzungsspeicher und Repository-Integrationen. Der Vorteil von Glossia für ein Software-Team ist die Kombination aus Repository-eigenem Inhalt, überprüfbarem Quellcode, Ihren eigenen Modell-Credentials und einer Validierung, die das tatsächliche Projekt versteht.

## Warum Glossia wählen

| Ihre Priorität | Vorteil von Glossia |
|---|---|
| Kontinuierlich liefern | Übersetzungs-Läufe folgen Quelländerungen und geben überprüfbare Repository-Updates zurück. Inhalte benötigen keinen eigenen, unverbundenen Release-Prozess. |
| Die Kontrolle der Implementierung behalten | Öffentliche Anwendung, CLI und Bereitstellungscode können unter den Lizenzbedingungen inspiziert, geändert und eigenständig gehostet werden. |
| Bringen Sie Ihre eigenen Token mit | Konfigurieren Sie unterstützte Modelle mit Ihren eigenen Anbieter-API-Token. Repository-Dateien verweisen auf stabile Modell-Handles, keine Secrets. |
| Nutzen Sie die Prüfungen, denen Sie vertrauen | Führen Sie einen Repository-Validierungs-Befehl gegen den Kandidaten an seinem tatsächlichen Zielpfad aus, bevor Sie ihn akzeptieren. |
| Behalten Sie Ihre Inhalte | Quelldateien, übersetzte Ausgaben, Konfigurationen und Pull-Request-Historien bleiben in Ihrem Repository. |

## Lokalisierung, die mit Commits Schritt hält

Glossia arbeitet von versionierten `L10N.md` Anweisungen aus und erkennt, welche Inhalte aktualisiert werden müssen. Unveränderte Eingaben müssen nicht erneut übersetzt werden. Ein Projekt hält einen offenen Übersetzungs-Pull-Request aufrecht und veröffentlicht Fortschritte in Batches, wodurch unnötige Pull-Requests und wiederholte CI-Ausläufe vermieden werden, während sich die Quelle weiterentwickelt.

Das Ergebnis ist ein Sprach-Arbeitsablauf, der um die gleichen kleinen, überprüfbaren Änderungen herum konstruiert ist, die Ihr Team bereits liefert. Kontinuierlich bedeutet nicht unüberprüft: Prüfer entscheiden weiterhin, was sicher zusammengeführt werden darf.

Crowdin unterstützt ebenfalls Git-Integrationen und Automatisierung. Der Grund für die Wahl von Glossia liegt nicht darin, dass Crowdin nicht mit einem Repository verbunden werden kann; es ist, dass die Repository-Auslieferung die Grundlage des Glossia-Arbeitsablaufs ist und nicht nur eine Integrationsgrenze.

## Ihre Token, Ihre Modell-Wahlen

Sie sollten nicht beim Rotieren eines Anbieters-Tokens oder Ändern des Modells hinter einem Übersetzungs-Arbeitsablauf die Repository-Konfiguration neu aufbauen müssen. Glossia speichert Credentials in den Account-Einstellungen und macht stabile Handles für das Repository verfügbar. Unterschiedliche Inhaltsbereiche oder Ziel-Lokalisierungen können verschiedene konfigurierte Modelle auswählen.

Dies gibt Ihrem Team Kontrolle über die unterstützten Anbieter-Beziehungen und Modell-Wahlen, die es verwendet. Sehen Sie sich [Modell-Anbieter konfigurieren](/docs/how-to/configure-a-model-provider) an.

## Validieren Sie die Ausgabe als Teil Ihres Produkts

Eine Übersetzung kann gut lesbar sein und dennoch einen Dokumentations-Build, eine Komponente, einen Placeholder oder einen Parser für Anwendungen beeinträchtigen. Glossia ermöglicht es Ihnen, einen Repository-Check zu wieder verwenden, anstatt bei der Beurteilung des Textes durch einen Editor stehen zu bleiben.

Wenn Ihr Repository bereits ein Dokumentations-Validierungs-Skript bereitstellt, beziehen Sie es direkt:

```yaml
validation:
  - ./scripts/validate-docs.sh
  - --strict
```

Der Validator empfängt den Kandidaten an seinem tatsächlichen Zielpfad, gibt bei Fehlschlag einen nicht-null-Status zurück und läuft innerhalb des konfigurierten Retry-Budgets. Seine Abhängigkeiten müssen in der Validierungs-Umgebung verfügbar sein. Sehen Sie [L10N.md](/docs/reference/l10n-md) für den Vertrag.

## Öffentlicher Quellcode, ohne das Repository abzugeben

Sie können überprüfen, wie Glossia Arbeitspläne erstellt, Credentials verarbeitet, Markdown verwaltet und Ergebnisse validiert. Bestehende übersetzte Dateien können weiterhin über die Pipeline Ihres Repositories veröffentlicht werden, auch wenn der Sprachdienst nicht verfügbar ist.

Glossia ist unter der [O'Saasy license](https://github.com/glossia/glossia/blob/main/LICENSE.md) als Quelle verfügbar, was das Eigenhosting erlaubt, aber konkurrierende gehostete Dienste einschränkt. Es ist keine uneingeschränkte Open-Source-Lizenz.

Crowdin kann dennoch für ein Programm angemessen sein, das auf der Koordinierung von Beitragsleistern und einem dedizierten Übersetzungs-Editor zentriert ist. Für ein Software-Team, dessen Priorität **Git-eigentümliche Inhalte, bestehende Validierung und Lokalisierung, die der Lieferung folgt** ist, ist Glossia für diese Aufgabe konzipiert.

Diese Vergleichsaussage behauptet nicht, dass Crowdin keine Automatisierung oder jede Form der Anbieter-Integration bietet, oder dass Glossia seine Speicher und Historie automatisch migriert. Sehen Sie [Crowdin-Dokumentation](https://support.crowdin.com/) für aktuelle Fähigkeiten.
