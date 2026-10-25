%{
  title: "Glossia gegen Phrase",
  summary:
    "Wählen Sie einen repository-nativen Sprachworkflow mit öffentlichen Quellen, Ihren eigenen Modell-Tokens und wiederverwendbaren Bereitstellungsprüfungen.",
  category: "Erklärung",
  markdown_only: true,
  section: "translation",
  order: 22
}
---

**Glossia wählen, wenn Sie möchten, dass die sprachbezogene Arbeit dem Lieferungssystem Ihres Produkts folgt, anstatt einen parallelen Übersetzungsmanagement-Prozess darum herum aufzubauen.** Behalten Sie den Inhalt in Git, wählen Sie unterstützte Modelle mit Ihren eigenen Zugangsdaten aus und validieren Sie die Ergebnisse mit den Checks, denen Ihr Repository bereits vertraut.

[Phrase](https://phrase.com/) bietet eine Lokalisierungslösung, einschließlich Phrase Strings und Phrase TMS für unterschiedliche Software-Lokalisierungs- und gemanagte-Übersetzungsbedürfnisse. Glossia verfolgt einen fokussierten Ansatz: Geben Sie Software-Teams ein Language OS an, das zu ihrem bestehenden Prüfung- und Lieferzyklus passt.

## Warum Glossia wählen

| Ihre Priorität | Vorteil von Glossia |
|---|---|
| Sprachänderungen mit Software liefern | Repository-Änderungen steuern die Lokalisierung, und Ausgaben kehren als überprüfbare Änderungen zurück. |
| Überprüfen und Kontrolle der Verarbeitung | Öffentlicher Quellcode zeigt die Anwendung und die Bereitstellungs-Implementierung an, wobei Änderungen und das Self-Hosting unter den Lizenzbedingungen gestattet sind. |
| Bringen Sie Ihre eigenen Tokens mit | Konfigurieren Sie Ihre eigenen Zugangsdaten für unterstützte Modell-Anbieter; wählen Sie Modelle über Account-Handles in der Repository-Konfiguration aus. |
| Wiederverwendung von Validierungspipelines | Führen Sie Repository-eigene Checks an Übersetzungskandidaten aus, anstatt die sprachliche Freigabe als Beweis dafür zu betrachten, dass eine Datei erstellt wird. |
| Sichern Sie die dauerhafte Eigentümerschaft | Veröffentlichte Dateien, Konfiguration und Pull-Request-Geschichte verbleiben beim Repository. |

## Machen Sie Lokalisierung Teil der Continuous Delivery

Die Änderungs-Erkennung von Glossia verhindert die Wiederholung von Übersetzungsarbeit für unveränderte Eingaben. Der Repository-Workflow von Glossia hält pro Projekt einen offenen Übersetzungs-Pull-Request aufrecht und veröffentlicht den Fortschritt in Chargen, sodass ein sich schnell änderndes Quell-Repository keinen neuen Übersetzungsprozess für jede kleine Änderung benötigt.

Ziel ist kein unveröffentlichter Wettlauf in die Produktion. Es geht darum, sprachbezogene Arbeit kontinuierlich überprüfbar und auslieferbar zu machen, durch die Pipeline, die Ihr Team bereits verwendet.

Phrase bietet auch APIs, Integrationen und Automatisierung. Der Vorteil, den Glossia betont, ist die architektonische Ausrichtung: Das Repository bleibt der Instandhalter des Inhalts und die Liefergrenze, anstatt nur ein Ort zu sein, um die Ergebnisse eines anderen Workspaces zu synchronisieren.

## Halten Sie Modellwahl und Zugangsdaten unter Ihrer Kontrolle

Glossia akzeptiert Ihre eigenen Provider-API-Token für unterstützte Modelle. Zugangsdaten verbleiben in den Kontoeinstellungen; Repositories wählen stabile Handles aus. Ein Team kann einen Token rotieren oder das Modell hinter einem Handle ändern, ohne die Repository-Anweisungen neu zu schreiben.

Unterschiedliche Inhaltsschweife und Zielsprachen können verschiedene konfigurierte Modelle nutzen. Optionaler Entscheidungsmuster können vollständige Übersetzungen bewerten und Korrektur anfordern, während Menschen weiterhin für sprachliches Urteil verantwortlich sind. Siehe [Account models](./account-models) für das aktuelle Verhalten und Limits.

## Ihr Repository weiß bereits, was gültiger Inhalt bedeutet

Die Sicht eines Übersetzungsmanagement-Systems auf einen String muss nicht notwendig die Anwendungsvorschau auf eine Datei sein. Ein Repository kann seinen eigenen Parser, Compiler, Komponentenvorschriften, Dokumentationsbuild und Platzhalter-Checks haben.

Glossia kann diese Checks über `L10N.md` Validierungsanweisungen wiederverwenden. Es schreibt den Kandidaten vorübergehend in seinen echten Ziel-Pfad für Validierung und akzeptiert ihn erst nach dem Bestehen der erforderlichen Checks. Der Befehl und seine Abhängigkeiten müssen in der Ausführungsumgebung verfügbar sein.

Dies ermöglicht es dem Team, seine bestehende Qualitätsgrenze zu erweitern, anstatt eine separate Definition von "valid" ausschließlich innerhalb eines Übersetzungsworkspaces zu pflegen. Siehe [L10N.md](/docs/reference/l10n-md).

## Öffentliche Implementierung, keine Black-Box

Anwendung, CLI, SDK und Bereitstellungsquellen von Glossia sind öffentlich. Sie können überprüfen, wie Inhalt behandelt wird, und die Implementierung unter der [O'Saasy-Lizenz](https://github.com/glossia/glossia/blob/main/LICENSE.md) ändern oder selbst hosten. Die Lizenz beschränkt konkurrierende gehostete Dienste und ist keine uneingeschränkte Open-Source-Lizenz.

Eine erweiterte Übersetzungs-Lösung kann für spezialisierte Übersetzungsoperationen und komplexe Koordination sinnvoll sein. Wenn Ihre Priorität **die Abgleichung der Software-Liefer-Geschwindigkeit mit Ihren eigenen Tokens und Repository-Checks** ist, ist Glossia konzipiert, diesen Workflow direkt zu halten.

Das Verlegen eines etablierten Übersetzungsprogramms erfordert immer noch einen Plan für seine Kontexte, Terminologie und Historie. Diese Seite verspricht keinen automatischen Phrase-Importer oder suite-Vollständigkeit oder behauptet nicht, dass Phrase äquivalente Integrationen vermisst. Konsultieren Sie [Phrase-Dokumentation](https://support.phrase.com/) für die aktuellen Fähigkeiten des spezifischen Produkts.
