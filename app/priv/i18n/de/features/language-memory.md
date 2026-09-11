%{
  title: "Sprachgedächtnis",
  summary:
    "Eine versionierte Kontextschicht, die Stimme, Terminologie und Stil Ihrer Organisation erfasst. Sprachgedächtnis leitet jeden Agenten-Workflow und erweitert sich durch die API und MCP auf Ihre eigenen Tools.",
  order: 5,
  icon: "brain",
  hero_cta_text: "Loslegen",
  hero_cta_url: "/signup",
  highlights: [
    %{
      title: "Versioniert und überprüfbar",
      description:
        "Jede Änderung Ihrer Stimme oder Terminologie erstellt eine neue unveränderliche Version. Sie können die Historie überprüfen, Iterationen vergleichen und zurückrollen, wenn sich etwas abweicht.",
      icon: "git-branch"
    },
    %{
      title: "Über Lokalisierung hinaus",
      description:
        "Sprachgedächtnis dient nicht nur der Lokalisierung. Verwenden Sie es zum Erstellen von Marketinginhalten, Entwurf von Dokumentation, Überprüfung von Pull-Requests oder Verfassung von Social-Media-Beiträgen, alles in der Stimme Ihrer Organisation.",
      icon: "megaphone"
    },
    %{
      title: "Offen und erweiterbar",
      description:
        "Greifen Sie über die REST-API oder den MCP-Server auf Sprachgedächtnis zu. Integrieren Sie es in Ihre eigenen CI-Pipelines, Content-Tools oder benutzerdefinierte Agenten, um die Konsistenz bei jedem Text, den Sie verfassen, zu gewährleisten.",
      icon: "puzzle"
    }
  ]
}
---
## Was ist Sprachspeicher?

Sprachspeicher ist der angesammelte Kontext, der den Glossia-Agenten darüber informiert, wie Ihre Organisation kommuniziert. Er besteht aus zwei Grundbausteinen, die Sie im Laufe der Zeit erstellen und verfeinern:

**Stimme** definiert, wie Inhalte klingen sollten. Ton, Formalität, Zielgruppe und freie Richtlinien leben hier. Sie können eine Basisstimme für Ihr Konto festlegen und dann bestimmte Felder für einzelne Lokale überschreiben, sodass Ihre japanischen Inhalte formeller sein können, während Ihr Englisch weiterhin gesprächig bleibt.

**Terminologie** definiert, was Begriffe bedeuten und wie sie lokalisiert werden sollten. Jeder Eintrag trägt eine Definition und Übersetzungen pro Lokale. Wenn ein Agent "workspace" in Ihrem Quellinhalt findet, bestimmt die Terminologie, ob er lokalisiert, translitteriert oder unverändert lassen soll, und genau welches Wort er in jeder Zielsprache verwenden muss.

Zusammen bilden Stimme und Terminologie eine Kontextschicht, die die Agenten bei jedem Durchlauf konsultieren. Je mehr Sie in diese Schicht investieren, desto weniger Überprüfung benötigt Ihre Ausgabe.

## Unveränderliche Versionierung

Der Sprachspeicher ist append-only. Wenn Sie Ihre Stimme oder Terminologie aktualisieren, erstellt Glossia eine neue Version statt der alten zu überschreiben. Jede Version erfasst, wer sie erstellt hat, wann und eine optionale Änderungsnotiz, die erläutert, welche Änderungen entstanden.

Das bedeutet, Sie verfügen immer über einen vollständigen Audit-Trail. Sie können Version 3 gegen Version 7 vergleichen, um zu verstehen, wie Ihr Tonfall über ein Quartal verschoben hat. Wenn eine kürzliche Änderung Inkonsistenzen eingeführt hat, rollen Sie auf eine frühere Version zurück und setzen Sie den Vorgang fort.

Die Versionierung macht die Zusammenarbeit ebenfalls sicherer. Mehrere Teammitglieder können Änderungen an der Stimme vorschlagen, ohne sich über Konflikte zu sorgen, da jede Änderung eine getrennte, verfolgbare Aktion ist.

## Lokalisierungsbewusste Auflösung

Wenn ein Agent einen Workflow für eine spezifische Spracheinstellung ausführt, bestimmt Glossia den Sprachspeicher für diesen Kontext. Es beginnt mit Ihren Basis-Stimmeinstellungen und wendet dann jede lokalspezifische Überschreibung darüber an. Bei der Terminologie ist es dasselbe: Nur Einträge, die einen lokalisierten Begriff für die Zielsprache haben, werden berücksichtigt.

Dieser Auflösungs Schritt bedeutet, dass Agenten immer mit dem relevantesten Kontext arbeiten. Sie müssen keine separaten Konfigurationen pro Sprache pflegen. Definieren Sie Ihre Standardwerte einmal, überschreiben Sie dort, wo es notwendig ist, und lassen Sie das Auflösungssystem den Rest übernehmen.

## Nutzen Sie es überall

Der Sprachspeicher wurde für die Lokalisierung konzipiert, ist aber nützlich überall, wo Sie Text produzieren. Da der Kontext über die zugänglich ist. [REST API](/features/rest-api) und den [MCP-Server](/features/mcp-server), können Sie es in Workflows jenseits der Lokalisierung einbinden:

**Marketing- und Social Content** -- Binden Sie die Stimme Ihrer Organisation in einen Content-Agenten ein, der Social-Media-Posts, E-Mail-Kampagnen oder Landingpage-Texte erstellt. Terminologie sichert konsistente Markenbegriffe, und die Stimmeinstellungen stellen sicher, dass der Ton Ihrer Marke entspricht.

**Dokumentation** -- Füttern Sie das Sprachgedächtnis in eine Dokumentationspipeline ein, sodass technisches Schreiben denselben Stilregeln folgt wie der Rest Ihres Inhalts. Terminologie-Einträge verhindern Abweichungen bei Dokumenten, Hilfeartikeln und in-Produkt-Text.

**Code-Überprüfung** -- Erstellen Sie einen Agenten, der Pull-Request-Texte (Fehlermeldungen, UI-Labels, Onboarding-Texte) mit Ihrer Stimme und Terminologie abgleicht. Kennzeichnen Sie Inkonsistenzen, noch bevor sie veröffentlicht werden.

**Benutzerdefinierte Agenten** -- Jeder MCP-kompatible Client kann den Sprachspeicher lesen und schreiben. Bitten Sie Ihren Coding-Assistenten, "Aktualisieren Sie die Terminologie mit dem neuen Produktnamen" oder "Stellen Sie den Sprachton auf professionell für das deutsche Sprachumfeld" und es übersetzt Ihre Absicht in den richtigen API-Aufruf.

## Progressive Verfeinerung

Der Sprachspeicher verbessert sich durch Nutzung. Jedes Mal, wenn ein Prüfer die Ausgabe eines Agenten korrigiert, wird diese Korrektur in die nächste Version Ihrer Stimme oder Terminologie übernommen. Mit der Zeit verringert sich die Lücke zwischen dem ersten Entwurf und der endgültigen Ausgabe, und der Überprüfungsschritt wird schneller.

Dies ist die Feedback-Schleife im Kern von Glossia: Generieren, überprüfen, Kontext verfeinern, erneut generieren. Die Agenten befolgen Anweisungen nicht einfach nur. Sie arbeiten mit Kontext, der mit jedem Zyklus besser wird.