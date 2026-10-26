%{
  title: "Glossia gegenüber Phrase",
  summary:
    "Wählen Sie einen repository-nativen Sprachworkflow mit öffentlicher Quelle, Ihren eigenen Modell-Token und wieder verwendbaren Lieferprüfungen.",
  category: "Erklärung",
  markdown_only: true,
  section: "translation",
  order: 22
}
---

**Wählen Sie Glossia, wenn Sie möchten, dass die sprachliche Arbeit Ihrem Produktdistributionsystem folgt, anstatt einen parallelen Übersetzungsmanagementprozess darum herum zu erstellen.** Behalten Sie den Inhalt in Git, wählen Sie unterstützte Modelle mit Ihren eigenen Anmeldedaten aus und validieren Sie die Ergebnisse mit den Prüfungen, denen Ihr Repository bereits vertraut.

[Phrase](https://phrase.com/) bietet eine Lokalisierungssuite an, inklusive Phrase Strings und Phrase TMS für unterschiedliche Bedürfnisse der Softwarelokalisierung und verwalteten Übersetzungen. Glossia verfolgt einen fokussierten Ansatz: Bieten Sie Softwareteams ein Sprach-Betriebssystem, das in ihren bestehenden Review- und Delivery-Schleife passt.

## Warum Glossia wählen

| Ihre Priorität | Vorteil von Glossia |
|---|---|
| Sprachänderungen mit Software bereitstellen | Repository-Änderungen steuern die Lokalisierung, und die Ergebnisse werden als überprüfbare Änderungen zurückgegeben. |
| Prüfen und kontrollieren Sie die Verarbeitung | Der Quellencode ist öffentlich und enthüllt die Implementierung der Anwendung und des Deployments; Änderungen und Selbstbetrieb sind gemäß den Lizenzbedingungen erlaubt. |
| Verwenden Sie Ihre eigenen Token | Konfigurieren Sie Ihre eigenen Anmeldedaten für unterstützte Modellanbieter; wählen Sie Modelle über Kontohandles in der Repository-Konfiguration aus. |
| Wiederverwendung von Validierungspipelines | Führen Sie Repository-native Überprüfungen auf Übersetzungskandidaten aus, anstatt die linguische Genehmigung als Beweis dafür zu betrachten, dass eine Datei erfolgreich erstellt wird. |
| Behalten Sie das dauerhafte Eigentum bei | Veröffentlichte Dateien, Konfigurationen und Pull-Request-Historie verbleiben im Repository. |

## Lokalisierung Teil von Continuous Delivery machen

Die Änderungserkennung von Glossia vermeidet die Wiederholung von Übersetzungsarbeit bei unveränderten Eingaben. Der Repository-Workflow behält einen offenen Übersetzungs-Pull-Request pro Projekt und veröffentlicht den Fortschritt in Batches, sodass ein schnellwandelndes Quellrepository keinen neuen Übersetzungsprozess für jede einzelne Änderung benötigt.

Das Ziel ist nicht ein nicht überprüfter Wettlauf in die Produktion. Es geht darum, die sprachliche Arbeit kontinuierlich überprüfbar und über die Pipeline lieferbar zu machen, die Ihr Team bereits nutzt.

Phrase bietet auch APIs, Integrationen und Automatisierung. Der von Glossia hervorgehobene Vorteil ist die architektonische Ausrichtung: Das Repository bleibt die Inhaltseinstanz und die Liefergrenze, anstatt nur ein Ort zu sein, um die Ergebnisse eines anderen Workspaces zu synchronisieren.

## Behalten Sie die Kontrolle über Modellwahl und Anmeldedaten

Glossia akzeptiert Ihre eigenen Provider-API-Token für unterstützte Modelle. Anmeldedaten bleiben in den Kontoeinstellungen; Repositories wählen stabile Handles aus. Ein Team kann einen Token rotieren oder das Modell hinter einem Handle wechseln, ohne seine Repository-Anweisungen neu zu schreiben.

Verschiedene Inhaltsschirme und Zielstone können verschiedene konfigurierte Modelle verwenden. Fakultative Entscheidungsmodelle können vollständige Übersetzungen bewerten und Korrektur anfordern, während Menschen weiterhin für linguistische Urteile verantwortlich sind. [Konto-Modelle](./account-models) für das aktuelle Verhalten und Grenzen.

## Ihr Repository weiß bereits, was gültiger Inhalt bedeutet

Die Ansicht eines Übersetzungsmanagement-Systems für einen String ist nicht unbedingt die Ansicht der Anwendung für eine Datei. Ein Repository kann seinen eigenen Parser, Compiler, Komponentenregeln, Dokumentationsaufbau und Platzhalterprüfungen haben.

Glossia kann diese Überprüfungen durch `L10N.md` Validierungsbefehle wiederverwenden. Es schreibt den Kandidaten vorübergehend in den echten Zielpfad für die Prüfung und akzeptiert ihn erst, nachdem die erforderlichen Überprüfungen bestanden sind. Der Befehl und seine Abhängigkeiten müssen in der Ausführungsumgebung verfügbar sein.

Dadurch kann das Team seine bestehende Qualitätsgrenze erweitern, anstatt eine separate Definition für gültig ausschließlich innerhalb eines Übersetzungsarbeitsbereichs aufrechtzuerhalten. Siehe [L10N.md](/docs/reference/l10n-md).

## Öffentliche Implementierung, keine Blackbox

Die Anwendung, CLI, SDK und Deploymentsources von Glossia sind öffentlich. Sie können prüfen, wie der Inhalt verarbeitet wird, und die Implementierung ändern oder selbst hosten, gemäß der [O'Saasy license](https://github.com/glossia/glossia/blob/main/LICENSE.md). Die Lizenz beschränkt konkurrierende gehostete Dienste und ist keine uneingeschränkte Open-Source-Lizenz.

Eine umfassende Lokalisierungssuite kann Sinn für spezialisierte Übersetzungsoperationen und komplexe Koordination ergeben. Wenn Ihre Priorität **das Angleichen der Software-Liefergeschwindigkeit an eigene Token und Repository-Prüfungen** ist, ist Glossia so konzipiert, dass dieser Workflow direkt ist.

Die Verlagerung eines etablierten Übersetzungsprogramms erfordert immer noch einen Plan für seine Erinnerungen, Terminologien und Verlauf. Diese Seite verspricht keinen automatischen Phrase-Importeur oder vollständige Suite-Parität, noch stellt sie fest, dass Phrase alle gleichwertigen Integrationen fehlt. Konsultieren Sie [Phrase-Dokumentation](https://support.phrase.com/) für die aktuellen Möglichkeiten des spezifischen Produkts.
