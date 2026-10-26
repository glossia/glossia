%{
  title: "Glossia gegen Crowdin",
  summary:
    "Wählen Sie Glossia, um die Lokalisierung in Git zu behalten, Ihre eigenen Modelltokens zu verwenden und mit den Prüfungen Ihres Repositories zu validieren.",
  category: "Erklärung",
  markdown_only: true,
  section: "translation",
  order: 20
}
---

**Wählen Sie Glossia, wenn die Lokalisierung so schnell wie Ihre Softwarebereitstellung vorankommen muss.** Ihr Repository definiert bereits, wie Änderungen überprüft, validiert und ausgeliefert werden. Glossia bringt sprachliche Arbeit in diesen Prozesskreis ein, anstatt einen separaten Übersetzungsarbeitsbereich zum Mittelpunkt Ihres Prozesses zu machen.

[Crowdin](https://crowdin.com/) bietet kollaboratives Übersetzungsmanagement, Review-Workflows, Übersetzungsspeicher und Repository-Integrationen. Der Vorteil von Glossia für ein Software-Team ist die Kombination aus Repository-inhalt, überprüfbarer Quelle, Ihren eigenen Modell-Credentials und einer Validierung, die das tatsächliche Projekt versteht.

## Warum Glossia wählen

| Ihre Priorität | Vorteil von Glossia |
|---|---|
| Kontinuierlich ausliefern | Übersetzungsabläufe folgen Quellenänderungen und liefern überprüfbare Repository-Updates zurück. Inhalt benötigt keinen eigenen unabhängigen Veröffentlichungsprozess. |
| Kontrolle über die Implementierung behalten | Die öffentliche Anwendung, die CLI und der Bereitstellungscode können unter den Lizenzbedinungen geprüft, angepasst und selbst gehostet werden. |
| Bringen Sie Ihre eigenen Token mit | Konfigurieren Sie unterstützte Modelle mit Ihren eigenen Provider-API-Token. Repository-Dateien verweisen auf stabile Modell-Handles, nicht auf Geheimnisse. |
| Verwenden Sie die Prüfungen, denen Sie vertrauen | Führen Sie einen Repository-Validierungsbefehl gegen den Kandidaten an dessen echtem Zielpfad aus, bevor Sie diesen akzeptieren. |
| Behalten Sie den Inhalt in Ihrem Besitz | Quelldateien, übersetzte Ausgaben, Konfiguration und Pull-Request-Historie verbleiben in Ihrem Repository. |

## Lokalisierung, die mit Commits mithalten kann

Glossia funktioniert von versionierten `L10N.md` Anweisungen ausgehend und erkennt, welche Inhalte aktualisiert werden müssen. Unveränderte Eingaben müssen nicht erneut übersetzt werden. Ein Projekt verwaltet einen offenen Übersetzungs-Pull-Request und veröffentlicht Fortschritte in Batches, wodurch unnötige Pull-Requests und wiederholte CI-Läufe vermieden werden, je nach Entwicklung der Quelle.

Das Ergebnis ist ein Sprach-Workflow, der um dieselben kleinen, überprüfbaren Änderungen herum konzipiert ist, die Ihr Team bereits ausliefert. Kontinuierlich bedeutet nicht unüberprüft: Reviewer entscheiden weiterhin, was sicher isIn den Merge gezählt werden kann.

Crowdin unterstützt ebenfalls Git-Integrationen und Automatisierung. Der Grund, Glossia zu wählen, ist nicht, dass Crowdin sich nicht mit einem Repository verbinden kann; es ist, dass Repository-Bereitstellung die Grundlage des Glossia-Workflows ist und nicht nur eine Integrationsgrenze.

## Ihre Token, Ihre Modellwahl

Sie müssen die Repository-Konfiguration nicht neu erstellen, um einen Provider-Token zu wechseln oder das Modell hinter einem Übersetzungs-Workflow zu ändern. Glossia speichert Credentials in Account-Einstellungen und stellt stabile Handles dem Repository zur Verfügung. Unterschiedliche Inhaltsbereiche oder Ziel-L10Ns können verschiedene konfigurierte Modelle auswählen.

Dadurch erhält Ihr Team Kontrolle über die unterstützten Provider-Beziehungen und Modellwahl-Optionen, die es verwendet. Siehe [Ein Modellprovider konfigurieren](/docs/how-to/configure-a-model-provider).

## Validierung der Ausgabe als Bestandteil Ihres Produkts

Eine Übersetzung kann gut lesbar sein und dennoch einen Dokumentationsbuild, eine Komponente, einen Platzhalter oder einen Anwendungsparser beschädigen. Glossia ermöglicht Ihnen, eine Repository-Prüfung zu wiederverwenden, statt sich bei der Bewertung des Editors beim Text aufzuhalten.

Falls Ihr Repository bereits ein Dokumentationsvalidierungsskript bereitstellt, verweisen Sie direkt darauf:

```yaml
validation:
  - ./scripts/validate-docs.sh
  - --strict
```

Der Validator empfängt den Kandidaten am tatsächlichen Zielpfad, gibt bei einem Fehler einen nicht-null-Status zurück und läuft innerhalb des konfigurierten Retry-Budgets. Seine Abhängigkeiten müssen in der Validierungsumgebung verfügbar sein. Sie [L10N.md](/docs/reference/l10n-md) für den Vertrag.

## Öffentlicher Quellcode, ohne das Repository aufzugeben

Sie können überprüfen, wie Glossia-Pläne funktionieren, Credentials verarbeiten, Markdown bewahren und Ergebnisse validieren. Bestehende übersetzte Dateien können auch dann weiterhin über Ihre Repository-Pipeline veröffentlicht werden, wenn der Sprachdienst nicht verfügbar ist.

Glossia folgt einem Open-Core-Modell. Der Kern steht unter [Apache-2.0](https://github.com/glossia/glossia/blob/main/LICENSE-APACHE), die kommerzielle Nutzung, Änderungen, Weitergabe, Self-Hosting und konkurrierende gehostete Dienste gemäß ihren Bedingungen erlaubt. Der Code unter `ee/` ist einsehbar, aber nicht Open Source. Er unterliegt einer separaten [Enterprise-Lizenz](https://github.com/glossia/glossia/blob/main/ee/LICENSE.md); der Produktionseinsatz erfordert eine schriftliche kommerzielle Vereinbarung.

Crowdin kann auch weiterhin geeignet sein für ein Programm, das sich auf Mitwirkenden-Koordination und einen dedizierten Übersetzungsredakteur konzentriert. Für ein Software-Team, dessen Priorität **Inhalt im Git-Eigentum, bestehende Validierung und Lokalisierung sind, die der Lieferung folgen**, ist Glossia für diese Aufgabe konzipiert.

Dieser Vergleich behauptet nicht, dass Crowdin Automation oder jede Form von Provider-Integration fehlt, oder dass Glossia seine Speicher und Historie automatisch migriert. Konsultieren Sie [Crowdin-Dokumentation](https://support.crowdin.com/) für aktuelle Fähigkeiten.
