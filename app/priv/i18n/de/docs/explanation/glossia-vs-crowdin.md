%{
  title: "Glossia gegen Crowdin",
  summary:
    "Wählen Sie Glossia, um die Lokalisierung in Git zu beibehalten, eigene Modell-Tokens zu nutzen und mit den Prüfungen Ihres Repositories zu validieren.",
  category: "Erklärung",
  markdown_only: true,
  section: "translation",
  order: 20
}
---

**Wählen Sie Glossia, wenn Lokalisierung mit der Geschwindigkeit Ihrer Softwareauslieferung gehen muss.** Ihr Repository definiert bereits, wie Änderungen überprüft, validiert und bereitgestellt werden. Glossia bringt Spracharbeit in diesen Prozesskreis ein, statt einen separaten Übersetzungsworkspace zum Schwerpunkt Ihres Prozesses zu machen.

[Crowdin](https://crowdin.com/) bietet kollaboratives Übersetzungsmanagement, Review-Workflows, Translation Memories und Repository-Integrationen. Der Vorteil von Glossia für ein Softwareteam ist die Kombination aus Repository-eigenem Inhalt, überprüfbarem Quellcode, Ihren eigenen Modell-Anmeldeinformationen und Validierung, die das tatsächliche Projekt versteht.

## Warum Glossia wählen

| Ihre Priorität | Vorteil von Glossia |
|---|---|
| Kontinuierlich liefern | Übersetzungsläufe folgen Quellcode-Änderungen und liefern überprüfbare Repository-Updates zurück. Inhalte benötigen keinen eigenen, unabhängigen Vertriebsprozess. |
| Kontrolle über die Implementierung behalten | Öffentliche Anwendung, CLI und Bereitstellungscode können unter den Lizenzbedingungen inspiziert, geändert und selbst gehostet werden. |
| Bringen Sie Ihre eigenen Tokens | Konfigurieren Sie unterstützte Modelle mit Ihren eigenen Provider-API-Tokens. Repository-Dateien verweisen auf stabile Modell-Handles, nicht auf Geheimnisse. |
| Wiederverwenden der Prüfungen, denen Sie vertrauen | Führen Sie einen Repository-Validierungsbefehl gegen den Kandidaten an seinem tatsächlichen Zielpfad aus, bevor Sie ihn akzeptieren. |
| Behalten Sie den Inhalt als Ihren | Quelldateien, übersetzte Ausgaben, Konfigurationen und Pull-Request-Geschichte bleiben in Ihrem Repository. |

## Lokalisierung, die mit Commits Schritt hält

Glossia arbeitet von versionierten `L10N.md` Anweisungen aus und erkennt, welche Inhalte aktualisiert werden müssen. Unveränderte Eingaben müssen nicht erneut übersetzt werden. Ein Projekt hält einen offenen Übersetzungs-Pull-Request und veröffentlicht Fortschritte in Chargen, was unnötige Pull-Requests und wiederholte CI-Läufe reduziert, während sich der Quellcode entwickelt.

Das Ergebnis ist ein Sprach-Workflow, der um die gleichen kleinen, überprüfbaren Änderungen herum gestaltet ist, die Ihr Team bereits einsendet. Kontinuierlich bedeutet nicht unüberprüft: Reviewer entscheiden weiterhin, was sicher zu mergen ist.

Crowdin unterstützt ebenfalls Git-Integrationen und Automatisierung. Der Grund, Glossia zu wählen, ist nicht, dass Crowdin nicht mit einem Repository verbinden kann; es ist, dass Repository-Auslieferung das Fundament des Glossia-Workflows ist, nicht nur eine Integrationsgrenze.

## Ihre Tokens, Ihre Modellentscheidungen

Sie sollten nicht darauf angewiesen sein, die Repository-Konfiguration neu aufzubauen, um ein Provider-Token zu rotieren oder das Modell hinter einem Übersetzungs-Workflow zu ändern. Glossia speichert Anmeldeinformationen in Kontoeinstellungen und gibt stabile Handles an das Repository aus. Unterschiedliche Inhaltsbereiche oder Ziel-Lokale können verschiedene konfigurierte Modelle auswählen.

Dies gibt Ihrem Team Kontrolle über die unterstützten Provider-Beziehungen und die von ihm verwendeten Modellentscheidungen. Siehe [Ein Modell-Provider konfigurieren](/docs/how-to/configure-a-model-provider).

## Output als Teil Ihres Produkts validieren

Eine Übersetzung kann gut lesbar sein und dennoch einen Dokumentenaufbau, Komponente, Platzhalter oder Anwendungsparser brechen. Glossia ermöglicht es Ihnen, eine Repository-Prüfung zu wiederverwenden, statt bei der Bewertung eines Editors am Text aufzuhören.

Wenn Ihr Repository bereits ein Dokumentenvalidierungsskript bereitstellt, beziehen Sie sich direkt darauf:

```yaml
validation:
  - ./scripts/validate-docs.sh
  - --strict
```

Der Validierer empfängt den Kandidaten an seinem tatsächlichen Zielpfad, gibt bei Fehlern einen nicht-null-Status zurück und läuft innerhalb des konfigurierten Wiederholbudgets. Seine Abhängigkeiten müssen in der Validierungsumgebung verfügbar sein. Siehe [L10N.md](/docs/reference/l10n-md) für den Vertrag.

## Öffentlicher Quellcode, ohne das Repository zu preiszugeben

Sie können prüfen, wie Glossia-Pläne funktionieren, wie Anmeldeinformationen gehandhabt werden, wie Markdown erhalten bleibt und Ergebnisse validiert werden. Existierende übersetzte Dateien bleiben über die Pipeline Ihres Repository öffentlich machbar, selbst wenn der Sprachdienst nicht verfügbar ist.

Glossia ist Open Core: [Apache-2.0](https://github.com/glossia/glossia/blob/main/LICENSE-APACHE) deckt das Kernpaket ab und erlaubt Self-Hosting sowie konkurrierende gehostete Dienste. Quellverfügbares Enterprise-Code unter `ee/` hat einen separaten [Lizenzvertrag](https://github.com/glossia/glossia/blob/main/ee/LICENSE.md), der für den produktiven Einsatz einen schriftlichen kommerziellen Vertrag erfordert.

Crowdin kann weiterhin angebracht sein für ein Programm, das auf Koordinierung von Mitwirkenden und einem dedizierten Übersetzer basiert. Für ein Software-Team, dessen Priorität **Git-eigener Inhalt, bestehende Validierung und Lokalisierung, die der Lieferung folgt**, ist Glossia für diese Aufgabe gemacht.

Dieser Vergleich beansprucht nicht, dass Crowdin an Automatisierung oder jeder Form von Provider-Integration mangelt, oder dass Glossia seine Erinnerungen und Geschichte automatisch migriert. Sehen Sie [Dokumentation von Crowdin](https://support.crowdin.com/) für aktuelle Funktionen.
