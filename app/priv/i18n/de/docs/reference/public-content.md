%{
  title: "Öffentliche Inhalte und Crawler-Schnittstellen",
  summary: "HTML, Markdown, Entdeckung, Caching und Crawler-Grenzen für die öffentliche Website.",
  category: "Referenz",
  section: "platform",
  order: 10
}
---

Glossia stellt veröffentlichte Website-Inhalte getrennt von Konto- und Projektanwendungsoberflächen zur Verfügung.

## Darstellungen

| Schnittstelle | Verhalten |
|---|---|
| Eine veröffentlichte HTML-URL | Die browserseitige Darstellung, mit kanonischen Metadaten und einem Markdown-`Link`-Antwort-Header. |
| `Accept: text/markdown` an dieser URL | Eine Markdown-Darstellung, wenn der explizite Medientyp positive Qualität aufweist und nicht weniger bevorzugt ist als `text/html`. |
| Die Seiten-URL mit angehängtem `.md` | Eine explizite Markdown-Darstellung, unabhängig von der Browser-Spracheinstellung. |
| `/index.md` | Die Markdown-Übersicht der Startseite. |
| `/docs.md`, `/blog.md`, `/features.md` | Markdown-Indizes von veröffentlichtem Inhalt. |
| `/changelog.md` | Veröffentlichte Changelog-Einträge in einem einzigen Markdown-Dokument. |
| `/terms.md`, `/privacy.md`, `/cookies.md` | Die aktuellsten veröffentlichten Rechtsdokumente. Datumsbezogene rechtliche URLs unterstützen ebenfalls `.md`. |

Allein `*/*` führt nicht zu Markdown. HTML- und Markdown-Antworten teilen `Vary: Accept` auf, sodass Caches die Darstellungen nicht vermischen.

Einzelne Dokumentationen, Blog-, Feature- und Rechtsinhalte verwenden verfasste Markdown-Formate statt einer Konvertierung des gerenderten HTMLs. Indexseiten werden aus dem veröffentlichten Inventar generiert; die Startseite bietet eine kuratierte Markdown-Übersicht. Die interaktiven REST-Referenzen verweisen Leser auf die OpenAPI-Spezifikation anstatt ein browser-only API-Widget einzubetten.

## Lokale

Englisch ist nicht vorangestellt. Übersetzte Marketing-URLs verwenden wörtliche Präfixe: `/de`, `/es`, `/fr`, `/ja`, `/ko`, `/pt-br`, und `/zh-hans`. Zum Beispiel dient `/es/docs/tutorials/getting-started.md` der spanischen Version, wenn diese veröffentlicht ist.

Die URL wählt die Sprache des Markdown-Inhalts. `Accept-Language` leitet keine Markdown-Anfrage um. Eine fehlende Inhalts-Übersetzung greift auf die englische Quelle zurück. Die Startseite-Übersicht wurde bisher auf Englisch verfasst.

## Entdeckung

- `/robots.txt` verbietet Crawling standardmäßig und ermöglicht die endliche veröffentlichte HTML- und Markdown-Inventare, lokalisierte Feeds, Rendering-Assets unter `/assets/`, `/fonts/`, und `/images/`, das Favicon, und öffentliche Marketing-Previews unter `/og/marketing/`. Account-Preview-Bilder unter `/og/app/` bleiben verboten. Es dient als Leitfaden für kooperative Crawler, nicht als Autorisierungsmaschine.
- `/sitemap.xml` listet kanonische öffentlichen Inhalt mit Lokale-Alternativen auf, einschließlich Markdown-URLs für Markdown-nur-Seiten. Changelog-Fragmente sind keine separaten URLs.
- `/llms.txt` stellt Glossia vor und verlinkt auf öffentliche Dokumentation, Feature-Leitfäden und jüngste Texte, einschließlich expliziter Markdown-Links.
- `/llms-full.txt` exportiert die Startseite-Übersicht, Dokumentation und Markdown-nur-Vergleichsinhalt in einem einzigen Textdokument, das Markdown enthält.

Vergleichsinhalt wird als Markdown nur veröffentlicht. Er bleibt außerhalb der HTML-Dokumentation, -navigation, -suche, und Dokumentations-Indizes, aber Agenten können ihn entdecken durch `/llms.txt` und die Sitemap. Seine kanonische URL endet in `.md`; die frühere HTML-URL reagiert auch auf `Accept: text/markdown`, fantastme aber keine Browserseite mehr.

Authentifizierung, Konto-Dashboards, APIs und andere Anwendungsanworten sind mit `noindex, nofollow` markiert. Veröffentlichter erfolgreicher Inhalt ist mit `index, follow` markiert; Fehler bleiben nichtindizierbar. Entdeckungstexte (`/robots.txt`, `/llms.txt`, und `/llms-full.txt`) verwenden `noindex, follow`: Leser können sie abrufen und ihre Links befolgen, aber Suchmaschinen sollten die kanonischen Seiten auflisten anstatt einer doppelten Dokumentation.

## Cache-Nutzung und Ressourcenverbrauch

Markdown- und Entdeckungstext-Antworten umfassen:

| Header | Wert oder Bedeutung |
|---|---|
| `Content-Type` | `text/markdown; charset=utf-8`, oder `text/plain; charset=utf-8` für Entdeckungstexte. |
| `Cache-Control` | `public, max-age=300, stale-while-revalidate=60`. |
| `ETag` | Ein zitiertes SHA-256-Digest der Darstellung. |
| `X-Markdown-Tokens` | Eine ungefähre Schätzung von Zeichen, geteilt durch vier, gerundet auf; keine modellabhängige Tokenizer-Zählung. |

`If-None-Match` unterstützt das Abgleichen starker oder schwacher Validatoren, mehrere Validatoren und `*`. Eine Übereinstimmung sendet `304` ohne Körper. `HEAD` gibt Header der Darstellung ohne Körper zurück.

Das veröffentlichte Markdown-Inventar wird in die Veröffentlichung kompiliert. Anfragen führen keine Inhaltübersetzung, das Lesen von Quelldateien, Laden eines authentifizierten Kontos oder das Erzeugen eines LiveViews aus. Keine User-Agent-Umnormung ist notwendig, um diese öffentlichen Darstellungen zu erreichen.

## Operative Grenzen

Markdown-Negotiation gewährt keinen Zugang zu Konto- oder Projektdashboards. Bestehende Konten-Browsing-Ratenbegrenzungen und Turnstile-Überprüfungen bleiben separate Schutzmaßnahmen.

Produktions-Edge-Ratenbegrenzungen gelten für sowohl `GET` und `HEAD`. Verifizierte Crawler werden weiter rate-limitiert. Übermäßige Anfragen erhalten eine Ratenbegrenzung-Antwort statt einer Browser-Herausforderung; Leser sollten langsamer werden und später erneut versuchen. Gemeinsame Caching- und Konditional-Anfragen entbinden Clients nicht von Ratenlimits.

Crawler-Politik-Änderungen in dem Repository treten nur nach der Bereitstellung der Anwendung und der relevanten Infrastruktur-Konfiguration in Kraft.
