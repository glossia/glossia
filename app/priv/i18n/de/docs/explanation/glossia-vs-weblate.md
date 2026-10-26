%{
  title: "Glossia gegenüber Weblate",
  summary:
    "Wählen Sie Glossia für modellbasierte Spracharbeit, die der Repository-Bereitstellung folgt und Ihre bestehende Validierung wiederverwendet.",
  category: "Erklärung",
  markdown_only: true,
  section: "translation",
  order: 23
}
---

**Wählen Sie Glossia, wenn Sie möchten, dass Sprachautomatisierung wie der Rest Ihrer Softwareauslieferung funktioniert:** quellkontrollierte Anweisungen, eigene Modell-Token, repository-orientierte Prüfungen und Pull Requests zur Überprüfung.

[Weblate](https://weblate.org/) ist ein Open-Source-Lokalisierungssystem mit einer webbasierten Übersetzungschnittstelle, Versionskontroll-Integration und Selbsthosting-Optionen. Öffentlicher Code und Git-Integration sind nicht exklusiv für Glossia. Der Grund, Glossia zu wählen, ist die Kombination aus repository-zentrierter Abgabe, modellgesteuerten Transformationen und wiederverwendbarem Sprachkontext für sowohl Menschen als auch Agenten.

## Warum Glossia wählen

| Ihre Priorität | Vorteil von Glossia |
|---|---|
| Beibehalten der Überprüfung im Produkt-Workflow | Überprüfen Sie den tatsächlichen versionsgesteuerten Output über Repository-Änderungen und Pull-Requests. |
| Anpassung an ein schnellgelegtes Quell-Repository | Die Änderungserkennung und der gepackte Publikumsbetrieb unterstützen einen laufenden Lokalisierungslauf, ohne dass ungewandelte Eingaben wiederholt übersetzt werden. |
| Bringen Sie Ihre eigenen Modell-Tokens mit | Richten Sie unterstützte Modelle mit an Konten gebundenen Provider-Anmeldeinformationen ein und wählen Sie sie mit repository-eigenen Handles aus. |
| Wiederverwendung der nativen Validierung | Führen Sie den eigenen Validierungsbefehl des Repositorys am Kandidaten bei seinem realen Zielpfad aus. |
| Wiederverwendung von Kontext über die Übersetzung hinaus | Geteilte Stimme und Terminologie können neuen Inhalt und Agenten-Integrationen durch MCP- und REST-Schnittstellen führen. |

## Halten Sie das Repository als Überprüfungsoberfläche bei

Glossia ist für ein Team konzipiert, das Git bereits nutzt, um zu entscheiden, was versandbereit ist. Seine Lokalisierungs-Konfiguration lebt neben dem Inhalt, und seine vorgeschlagenen Ausgaben können über denselben Prozess wie die Produktänderung überprüft werden.

Weblate integriert sich ebenfalls mit Versionskontrolle. Seine browserbasierte Übersetzungs-Oberfläche ist möglicherweise genau das, was eine Beitragsgemeinschaft benötigt. Glossias Fokussierung liegt anders: Bewahren Sie die Repository-Überprüfungsgrenze bei, und bringen Sie Sprachautomatisierung dazu, statt einen anderen Bearbeitungsbereich in den Mittelpunkt der Teamarbeit zu stellen.

## Bringen Sie eigene Tokens mit und machen Sie Modellentscheidungen explizit

Glossia nutzt unterstützte Modelle, die mit Ihren Provider-API-Tokens konfiguriert sind. Repository-Konfiguration bezieht sich auf stabile Modellhandles; Geheimnisse bleiben in den Konteneinstellungen. Sie können verschiedene konfigurierte Modelle nach Inhaltsumfang oder Ziellokalität auswählen und Anmeldeinformationen drehen, ohne jedes Repository zu ändern.

Damit hat Ihr Team einen expliziten Ort, um die Modelle auszuwählen, die deren Inhalt erstellen. Es wird nicht zugesichert, dass jedes Token oder Modell unterstützt ist, oder dass die Generierung den Bedarf an menschlicher Überprüfung beseitigt. Siehe [Modellanbieter konfigurieren](/docs/how-to/configure-a-model-provider).

## Wiederverwendung der Checks, die eine lieferbare Änderung definieren

Die eingebaute strukturelle Checks von Glossia sind nur ein Teil der Qualitätsgrenze. Durch `L10N.md` kann ein Repositorys nativen Validierungsskript, Parser, Compiler oder Dokumentations-Check am Kandidaten an seinem realen Zielpfad ausführen.

Das ist nützlich, wenn übersetzter Inhalt mehr als nur einfache Strings enthält: anwendungsspezifische Formate, Markdown-Komponenten, strukturierte Metadaten und Einschränkungen, die das Projekt bereits weiß, wie es zu verifizieren ist. Validierung und Wiederherstellung bleiben mit den tatsächlichen Dateien verbunden, die Ihre Pipeline veröffentlichen wird.

Die Ausführungsumgebung benötigt weiterhin die Abhängigkeiten des Validators, und die strukturelle Validierung etabliert keine linguistische Genauigkeit. Siehe [L10N.md](/docs/reference/l10n-md) und [Übersetzungswiederherstellung](./translation-recovery).

## Öffentlicher Quellesscode ist eine Grundlinie, nicht die gesamte Vergleich.

Der Kern von Glossia ist öffentlich und kann unter [Apache-2.0](https://github.com/glossia/glossia/blob/main/LICENSE-APACHE) inspiziert, geändert, verteilt und selbst gehostet werden, was konkurrierende gehostete Dienste erlaubt. Unternehmenscode unter `ee/` hat eine separate [Lizenz](https://github.com/glossia/glossia/blob/main/ee/LICENSE.md), die für den Produktionsbetrieb eine schriftliche Geschäftsvereinbarung erfordert. Dieses Open-Core-Modell unterscheidet sich von der GPL-basierten Lizenzierung von Weblate.

Wenn GPL-basierte Lizenzierung und ein etabliertes Web-Übersetzungsinterface Ihre primären Kriterien sind, verdient Weblate Berücksichtigung. Wenn das Ziel **Ihre eigenen Modellzugangsdaten, bestehende Repository-Prüfungen und Spracharbeit, die der Softwareauslieferung folgt** ist, bringt Glossia diese Optionen in einem Sprach-OS zusammen.

Dieser Vergleich behauptet nicht, dass Weblate an Automatisierung, Validierungsmerkmalen oder Provider-Integrationen leidet, und verspricht keine automatische Migration oder Feature-Parität. Siehe [Weblates Dokumentation](https://docs.weblate.org/) für die aktuellen Fähigkeiten.
