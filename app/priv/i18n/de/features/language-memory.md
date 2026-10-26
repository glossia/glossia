%{
  title: "Sprachgedächtnis",
  summary:
    "Eine versionierte Kontextebene, die Stimme, Glossar und Stil Ihrer Organisation erfasst. Sprachgedächtnis leitet jeden Agenten-Workflow und verknüpft sich über die API und MCP mit Ihren eigenen Werkzeugen.",
  order: 5,
  icon: "brain",
  hero_cta_text: "Loslegen",
  hero_cta_url: "/signup",
  highlights: [
    %{
      title: "Versioniert und überprüfbar",
      description:
        "Jede Änderung Ihrer Stimme oder Ihres Glossars erstellt eine neue unveränderbare Version. Sie können die Historie prüfen, Iterationen vergleichen und im Fall einer Abweichung zurücksetzen.",
      icon: "git-branch"
    },
    %{
      title: "Jenseits der Lokalisierung",
      description:
        "Das Sprachgedächtnis dient nicht nur der Lokalisierung. Nutzen Sie es zur Erstellung von Marketingtexten, zum Entwurf von Dokumentation, zur Überprüfung von Pull Requests und zur Formulierung von Social Posts, alles in der Stimme Ihrer Organisation.",
      icon: "megaphone"
    },
    %{
      title: "Offen und erweiterbar",
      description:
        "Greifen Sie über die REST-API oder den MCP-Server auf das Sprachgedächtnis zu. Leiten Sie es in Ihre eigenen CI-Pipelines, Content-Tools oder benutzerdefinierte Agenten ein, um die Konsistenz überall beim Schreiben zu gewährleisten.",
      icon: "puzzle"
    }
  ]
}
---

## Was ist Sprachgedächtnis?

Sprachgedächtnis ist der angestaute Kontext, der den Agenten von Glossia mitteilt, wie sich Ihre Organisation kommuniziert. Es besteht aus zwei Kernkonzepten, die Sie über die Zeit erstellen und verfeinern:

**Stimme** gibt vor, wie Inhalte klingen sollten. Ton, Formalität, Zielgruppe und Leitlinien in freier Form vivem hier. Für Ihr Konto können Sie eine Grundstimme festlegen und dann spezifische Felder für einzelne Lokale überschreiben, sodass Ihr japanischer Text mehr Formalität haben kann, während Ihr englischer Text belebt bleibt.

**Glossar** definiert, was Begriffe bedeuten und wie sie lokalisiert werden sollen. Jeder Eintrag enthält eine Definition und Übersetzungen pro Lokal. Wenn ein Agent "workspace" in Ihrem Quelltext findet, gibt das Glossar ihm Anweisungen, ob es zu lokalisieren, mit Schrifttranskription zu erfassen, oder unverändert zu lassen ist, und genau welches Wort in jeder Zielsprache zu verwenden ist.

Zusammen bilden Stimme und Glossar eine Kontextschicht, die von Agenten bei jedem Durchlauf konsultiert wird. Je mehr Sie in dieser Schicht investieren, desto weniger Überprüfung benötigt Ihre Ausgabe.

## Unveränderliche Versionierung

Sprachgedächtnis ist nur appending. Wenn Sie Ihre Stimme oder das Glossar aktualisieren, erstellt Glossia eine neue Version anstatt die alte zu überschreiben. Jede Version dokumentiert, wer sie erstellt hat, wann, und eine optionale Änderungsnotiz, die erläutert, was sich entwickelt hat.

Das bedeutet, Sie haben immer einen vollständigen Nachweis. Sie können Version 3 mit Version 7 vergleichen, um zu verstehen, wie sich Ihr Ton über ein Quartal verschiebt hat. Wenn eine jüngstere Änderung Inkonsistenzen eingeführt hat, rollen Sie zu einer früheren Version zurück und fahren Sie weiter.

Versionierung macht auch Zusammenarbeit sicherer. Mehrere Teammitglieder können Stimmenänderungen vorschlagen, ohne sich über Konflikte Sorgen zu machen, da jede Änderung ein diskreter, nachvollziehbarer Ereignis ist.

## Lokalbewusster Auflösungsprozess

Wenn ein Agent einen Arbeitsablauf für ein spezielles Lokal durchführt, löst Glossia das Sprachgedächtnis für diesen Kontext auf. Es beginnt mit Ihren Grundstimmen-Einstellungen und wendet dann jegliche lokal-spezifische Überschreibungen darauf an. Das Gleiche geschieht mit Glossaren: Nur Einträge, die einen localisierten Begriff für das Ziellokal haben, werden eingeschlossen.

Diese Auflösungsstufe bedeutet, Agenten arbeiten immer mit dem relevanten Kontext. Sie müssen keine separaten Konfigurationen pro Sprache anhalten. Definieren Sie Ihre Standards einmal, überschreiben Sie, wo es zählt, und lassen Sie das Auflösungssystem den Rest handhaben.

## Verwenden Sie es überall

Sprachgedächtnis wurde für Lokalisierung entwickelt, aber es ist nützlich, wo immer Sie Text produzieren. Da der Kontext durch die [REST API](/features/rest-api) und den [MCP Server](/features/mcp-server) zugänglich ist, können Sie ihn in Arbeitsabläufe jenseits der Lokalisierung integrieren:

**Marketing und Sozialer Inhalt** -- Holen Sie die Stimme Ihrer Organisation in einen Inhalts-Agenten, der Social-Media-Beiträge, E-Mail-Kampagnen oder Landing-Page-Text erstellt. Glossare hält Markentermen konsistent und die Stimmen-Einstellungen stellen sicher, dass der Ton Ihrem Markenbild entspricht.

**Dokumentation** -- Füttern Sie Sprachgedächtnis in einen Dokumentations-Arbeitsablauf, damit technisches Schreiben dieselben Regel-Originanen wie der Rest Ihres Inhalts folgt. Glossar-Einträge verhindern Drift über Docs, Hilfestellungen und Produkt-Text.

**Code-Review** -- Erstellen Sie einen Agenten, der Pull-Request-Text (Fehlermeldungen, UI-Bezeichnungen, Onboarding-Text) gegen Ihre Stimme und das Glossare prüft. Markieren Sie Inkonsistenzen, bevor sie ausgeliefert werden.

**Benutzerdefinierte Agenten** -- Jeder MCP-kompatible Client kann Sprachgedächtnis lesen und schreiben. Bitten Sie Ihren Programmierungsassistenten, "glossar mit dem neuen Produktname aktualisieren" oder "die Stimmm-Stimmung auf professionell für das deutsche Lokal setzen", und sie übersetzt Ihre Absicht in die richtige API-Aufruf.

## Kontinuierliche Verfeinerung

Sprachgedächtnis verbessert sich mit Nutzung. Jedes Mal, wenn ein Prüfer die Ausgabe eines Agenten korrigiert, mündet diese Korrektur in die nächste Version Ihrer Stimme oder des Glossar zurück. Mit der Zeit verengt sich die Lücke zwischen Erstentwurf und finaler Ausgabe, und die Prüfungsstufe wird schneller.

Das ist der Feedbackkreis am Herzstück von Glossia: Generieren, überprüfen, Kontext verfeinern, erneut generieren. Die Agenten folgen nicht nur Anweisungen. Sie arbeiten mit Kontext, der in jedem Zyklus besser wird.
