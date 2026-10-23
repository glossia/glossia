# Glossia: ein Sprach-Betriebssystem für Teams

Glossia vereinigt Sprache, Terminologie, Übersetzung, Revisionsverlauf und Lokalisierungsanalysen in einem System. Es hilft Entwicklern, Linguisten und Produktteams, konsistent über Sprachen hinweg zu kommunizieren, ohne ihren Content aus Git zu entfernen.

## Das Problem

Auszuglisten auf Englisch bedeuten nicht nur den Austausch von Wörtern. Teams müssen Gebrauch von Bedeutung richtig, Terminologie verwenden, Ton an das Publikum anpassen und Übersetzungen auf dem Laufenden halten, während sich das Produkt ändert. Kontext, der über Tabellen, Prompts und Übersetzungswerkzeuge verstreut ist, führt zu inkonsistentem Schreiben und wiederholter manueller Arbeit.

Ein LLM kann eine Übersetzung skizzieren, aber ein Entwurf allein stellt Versionsverlauf, Validierung, selektive Updates oder einen Feedback-Loop für die nächste Änderung nicht bereit.

## Die Rolle von Glossia

- **Sprach-Gedächtnis:** gemeinsam genutzte Sprachführungen und Glossar-Einträge helfen Menschen und Agenten, konsistente Sprache zu verwenden.
- **Repository-Lokalisierung:** Repository verbinden, Quelldateien und Ziel-Lokalen in der Konfiguration beschreiben und Änderungen über Pull-Requests überprüfen.
- **Schrittweise Verfeinerung:** Content-Hashes helfen dabei, unveränderte Inhalte zu übersetzen zu vermeiden. Validierung und Wiederherstellung machen Fehler sichtbar und handhabbar.
- **Inhaltrevisionierung:** bewahren Sie die Geschichte von Sprachentscheidungen und Änderungen auf, anstatt jede Generierung als isolierten Prompt zu behandeln.
- **Lokalisierungsanalysen:** datenschutzbewusste Web-Analysen helfen Teams, ihr Publikum zu verstehen und wo sich Lokalisierung auszahlt.
- **Agent-Integration:** ein OAuth-authentifizierter MCP-Server und REST-Schnittstellen machen Sprach-Kontext für bestehende Workflows verfügbar.

Glossia ersetzt nicht das Redakteururteil. Es liefert den Kontext, die Automatisierung und den Überprüfungs-Arbeitsgang, der Teams erlaubt, dieses Urteil wiederholt anzuwenden.

## Entdecken

- [Erste Schritte](/docs/tutorials/getting-started.md): Repository verbinden und Ihre erste Lokalisierungsarbeitsgang ausführen.
- [Warum Glossia](/docs/explanation/why-glossia.md): die Probleme, die das Sprach-Betriebssystem lösen soll.
- [Features](/features.md): Produkteigenschaften und Anwendungsfälle.
- [Dokumentation](/docs.md): Tutorials, Anleitungen, Referenzen und Erklärungen.
- [Blog](/blog.md): Schreiben über Lokalisierung und Sprachsysten.
- [Änderungsprotokoll](/changelog.md): Produktänderungen.
- [Quellcode](https://github.com/glossia/glossia): die Umsetzung inspizieren und beitragen.

## Vergleiche

- [Glossia vs Crowdin](/docs/explanation/glossia-vs-crowdin.md)
- [Glossia vs Lokalise](/docs/explanation/glossia-vs-lokalise.md)
- [Glossia vs Phrase](/docs/explanation/glossia-vs-phrase.md)
- [Glossia vs Weblate](/docs/explanation/glossia-vs-weblate.md)

## Für Crawler und Agenten

Veröffentlichte Seiten sind als Markdown verfügbar, indem Sie `.md` an ihren HTML-Url anhängen, oder indem Sie `Accept: text/markdown` an der HTML-Url anfordern. Die Markdown-Url der Startseite ist `/index.md`. Übersetzter Content verwendet die gleichen Lokalen-Vorfixe wie HTML und fällt zurück auf Englisch, wenn keine Übersetzung veröffentlicht ist.

Verwenden Sie [/llms.txt](/llms.txt) für Entdeckung, [/llms-full.txt](/llms-full.txt) für einen konsolidierten Dokumentations-Export und [/sitemap.xml](/sitemap.xml) für kanonische HTML-URLs. Kontodashboards sind Anwendungsoberflächen, nicht Dokumentation; durchsuchen Sie sie nicht, um über Glossia zu lernen.
