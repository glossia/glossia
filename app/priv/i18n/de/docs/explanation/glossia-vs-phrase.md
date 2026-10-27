%{
  title: "Glossia gegenüber Phrase",
  summary:
    "Wählen Sie einen repository-integrierten Sprach-Arbeitsablauf mit öffentlicher Quelle, Ihren eigenen Modelltokens und wiederverwendbaren Auslieferungsprüfungen.",
  category: "Erklärung",
  markdown_only: true,
  section: "translation",
  order: 22
}
---

**Wählen Sie Glossia, wenn Sie möchten, dass die Spracharbeit Ihrem Lieferungssystem folgt, anstatt einen parallelen Übersetzungsmanagement-Prozess darum herum aufzubauen.** Bewahren Sie den Inhalt in Git auf, wählen Sie unterstützte Modelle mit Ihren eigenen Zugangsdaten aus und validieren Sie die Ergebnisse mit den Prüfungen, denen Ihr Repository bereits vertraut.

[Phrase](https://phrase.com/) bietet eine Lokalisierungslösung an, einschließlich Phrase Strings und Phrase TMS für verschiedene Software-Lokalisierungs- und verwaltete Übersetzungsbedürfnisse. Glossia verfolgt einen fokussierten Ansatz: Bieten Sie Software-Teams ein Language OS an, das in ihre bestehende Prüf- und Lieferungsschleife passt.

## Warum Glossia wählen

| Ihre Priorität | Der Vorteil von Glossia |
|---|---|
| Sprachänderungen mit Software bereitstellen | Repository-Änderungen treiben die Lokalisierung voran, und Ergebnisse werden als überprüfbare Änderungen zurückgegeben. |
| Überprüfen und übernehmen Sie die Verarbeitung | Der öffentliche Quellcode macht die Anwendung und die Implementierung der Bereitstellung zugänglich, wobei Änderungen und Selbst-Hosting unter den Lizenzbedingungen erlaubt sind. |
| Bringen Sie Ihre eigenen Token mit | Konfigurieren Sie Ihre eigenen Zugangsdaten für unterstützte Modell-Anbieter; wählen Sie Modelle über Konto-Handles in der Repository-Konfiguration aus. |
| Wiederverwenden von Validierungspipelines | Führen Sie Repository-eigene Prüfungen für Übersetzungsvorschläge durch, anstatt die linguistische Genehmigung als Beweis dafür zu behandeln, dass eine Datei kompiliert wird. |
| Behalten Sie dauerhafte Eigentümerschaft | Veröffentlichte Dateien, Konfigurationen und Pull-Request-Historie verbleiben im Repository. |

## Lokalisierung zum Bestandteil der Continuous Delivery machen

Glossias Änderungserkennung vermeidet die Wiederaufnahme von Übersetzungsarbeit für unveränderte Eingaben. Der Repository-Arbeitsablauf hält eine offene Übersetzungs-Pull-Request pro Projekt aufrecht und veröffentlicht Fortschritte in Stapeln, sodass sich schnell verändernde Quell-Repositorys keinen neuen Übersetzungsprozess für jede kleine Änderung benötigen.

Das Ziel ist kein unüberprüftes Rennen zur Produktion. Stattdessen geht es darum, Spracharbeit kontinuierlich überprüfbar und über die Pipeline bereitstellbar zu machen, die Ihr Team bereits nutzt.

Phrase bietet auch APIs, Integrationen und Automatisierung. Der Vorteil, den Glossia betont, ist die architektonische Ausrichtung: Das Repository bleibt die Inhalt-Autorität und die Abgrenzung der Lieferung, anstatt nur ein Ort zu sein, um Ergebnisse eines anderen Arbeitsbereichs zu synchronisieren.

## Halten Sie Modellwahl und Zugangsdaten unter Ihrer Kontrolle

Glossia akzeptiert Ihre eigenen Anbieter-API-Token für unterstützte Modelle. Zugangsdaten bleiben in Kontoeinstellungen; Repositories wählen stabile Handles. Ein Team kann ein Token rotieren oder das Modell hinter einem Handle ändern, ohne seine Repository-Anweisungen neu zu schreiben.

Verschiedene Inhalt-Scope und Zielsprachen können unterschiedlich konfigurierte Modelle nutzen. Optionale Entscheidungsmodelle können vollständige Übersetzungen bewerten und Korrektur anfordern, während Menschen für linguistisches Urteil verantwortlich bleiben. Siehe [Kontomodell](./account-models) für das aktuelle Verhalten und die Grenzen.

## Ihr Repository weiß bereits, was gültiger Inhalt bedeutet

Die Ansicht eines Übersetzungsmanagementsystems auf eine Zeichenkette ist nicht unbedingt die Ansicht einer Anwendung auf eine Datei. Ein Repository kann einen eigenen Parser, Compiler, Komponentenregeln, Dokumentations-Build und Platzhalterprüfungen haben.

Glossia kann diese Prüfungen durch `L10N.md` Validierungs-Befehle wiederverwenden. Es schreibt den Kandidaten vorübergehend auf seinen eigentlichen Zielpfad für Validierung und akzeptiert ihn nur, nachdem die erforderlichen Prüfungen bestanden sind. Der Befehl und seine Abhängigkeiten müssen in der Ausführungsumgebung verfügbar sein.

Dies ermöglicht es dem Team, seine bestehende Qualitätsbegrenzung zu erweitern, anstatt eine separate Definition von "gültig" ausschließlich innerhalb eines Übersetzungsarbeitsbereichs beizubehalten. Siehe [L10N.md](/docs/reference/l10n-md).

## Öffentliche Implementierung, keine Blackbox

Die Glossia-Anwendung, CLI, SDK und Bereitstellungsquellen sind öffentlich. Der Kern ist quelloffen unter [Apache-2.0](https://github.com/glossia/glossia/blob/main/LICENSE-APACHE), was Änderungen, Verteilung, Selbst-Hosting und konkurrierende gehostete Dienste erlaubt. Enterprise-Code unter `ee/` hat eine separate [Lizenz](https://github.com/glossia/glossia/blob/main/ee/LICENSE.md), die für den Produktionsbetrieb eine schriftliche kommerzielle Vereinbarung erfordert.

Eine umfassendere Lokalisierungslösung kann für spezialisierte Übersetzungsoperationen und komplexe Koordination Sinn ergeben. Wenn Ihre Priorität darin besteht, **die Software-Lieferungsgeschwindigkeit an Ihre eigenen Token und Repository-Prüfungen anzupassen**, ist Glossia darauf ausgelegt, diesen Arbeitsablauf direkt zu halten.

Die Umstellung eines etablierten Übersetzungsprogramms erfordert weiterhin einen Plan für seine Translation Memories, Terminologie und Historie. Diese Seite verspricht keinen automatischen Phrase-Importer oder vollständige Suite-Gleichwertigkeit oder behauptet nicht, dass Phrase alle äquivalenten Integrationen mangelt. Konsultieren Sie [Phrases Dokumentation](https://support.phrase.com/) für die aktuellen Fähigkeiten des spezifischen Produkts.
