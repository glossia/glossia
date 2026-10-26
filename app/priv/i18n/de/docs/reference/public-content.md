%{
  title: "Öffentliche Inhalte und Crawler-Schnittstellen",
  summary: "HTML, Markdown, Discovery, Caching und Crawler-Grenzen für die öffentliche Website.",
  category: "Referenz",
  section: "platform",
  order: 10
}
---

Glossia stellt veröffentlichten Website-Inhalt getrennt von Konto- und Projektanwendungsoberflächen bereit.

## Darstellungen

| Schnittstelle | Verhalten |
|---|---|
| Eine veröffentlichte HTML-URL | Die Browserdarstellung, mit kanonischem Metadaten und einem Markdown-Alternativ-`Link`-Response-Header. |
| `Accept: text/markdown` an dieser URL | Eine Markdown-Darstellung, wenn der explizite Medientyp positive Qualität aufweist und nicht weniger bevorzugt ist als `text/html`. |
| Die Seiten-URL mit angefügtem `.md` | Eine explizite Markdown-Darstellung, unabhängig von der Sprache-Präferenz des Browsers. |
| `/index.md` | Die Markdown-Zusammenfassung der Startseite. |
| `/docs.md`, `/blog.md`, `/features.md` | Markdown-Indizes des veröffentlichten Inhalts. |
| `/changelog.md` | Veröffentlichte Changelog-Einträge in einem einzigen Markdown-Dokument. |
| `/terms.md`, `/privacy.md`, `/cookies.md` | Die aktuellsten veröffentlichten Rechtsdokumente. Mit Datum versehene rechtliche URLs unterstützen ebenfalls `.md`. |

`*/*` allein ist kein Opt-in für Markdown. HTML- und Markdown-Antworten teilen `Vary: Accept` so, dass Caches die Darstellungen nicht mischen.

Individuelle Dokumentationen, Blog-, Feature- und Rechtsinhalte verwenden verfasste Markdown-Dokumente statt einer Konversion des gerenderten HTMLs. Index-Seiten werden aus dem veröffentlichten Inventar generiert; die Startseite hat eine zusammengestellte Markdown-Zusammenfassung. Die interaktive REST-Referenz verweist Leser auf die OpenAPI-Spezifikation statt einer browser-einigen API-Widget einishment.

## Sprachen

Englisch ist unprefixed. Übersetzte Marketing-URLs verwenden wörtliche Präfixe: `/de`, `/es`, `/fr`, `/ja`, `/ko`, `/pt-br`, und `/zh-hans`. Zum Beispiel dient `/es/docs/tutorials/getting-started.md` der spanischen Version, wenn diese veröffentlicht ist.

Die URL wählt die Sprache des Markdown-Inhalts aus. `Accept-Language` leitet keine Markdown-Anfrage um. Eine fehlende Inhaltsübersetzung greift auf ihre englische Quelle zurück. Die Startseite-Zusammenfassung wird derzeit auf Englisch verfasst.

## Entdeckung

- `/robots.txt` verbietet standardmäßig Crawling und umfasst das endliche veröffentlichte HTML- und Markdown-Inventar, lokalisierte Feeds, Rendering-Assets unter `/assets/`, `/fonts/`, und `/images/`, das Favicon und öffentliche Marketing-Vorschauen unter `/og/marketing/`. Konto-Vorschaubilder unter `/og/app/` bleiben verboten.
- `/sitemap.xml` verzeichnet kanonische öffentliche Inhalte mit Lokalisierungs-Alternativen, einschließlich Markdown-URLs für Markdown-nur-Seiten. Changelog-Fragmente sind keine separaten URLs.
- `/llms.txt` führt Glossia ein und verlinkt auf öffentliche Dokumentation, Feature-Leitfäden und kürzliche Veröffentlichungen, einschließlich expliziter Markdown-Links.
- `/llms-full.txt` exportiert die Startseite-Zusammenfassung, Dokumentation und Markdown-nur-Vergleichsinhalte in einem einzigen Textdokument, das Markdown enthält.

Vergleichsinhalte werden nur als Markdown veröffentlicht. Sie bleiben aus HTML-Dokumentation, Navigation, Suche und Dokumentationsindizes aus, aber Agenten können sie über `/llms.txt` und die Sitemap entdecken. Seine kanonische URL endet mit `.md`; die frühere HTML-URL antwortet ebenfalls auf `Accept: text/markdown`, rendert aber keine Browserseite mehr.

Authentifizierung, Kontodashboards, APIs und andere Anwendungsantworten sind mit `noindex, nofollow` markiert. Veröffentlichter erfolgreicher Inhalt ist mit `index, follow` markiert; Fehler bleiben nichtindizierbar. Discovery-Textdateien (`/robots.txt`, `/llms.txt`, und `/llms-full.txt`) verwenden `noindex, follow`: Leser können diese abrufen und ihre Links folgen, aber Suchmaschinen sollten die kanonischen Seiten indexieren statt einer doppelten Dokumententzung.

## Caching und Ressourcennutzung

Markdown- und Text-Entdeckungsantworten umfassen:

| Kopfzeile | Wert oder Bedeutung |
|---|---|
| `Content-Type` | `text/markdown; charset=utf-8` oder `text/plain; charset=utf-8` für Entdeckungstext. |
| `Cache-Control` | `public, max-age=300, stale-while-revalidate=60`. |
| `ETag` | Ein zitierter SHA-256-Digest der Darstellung. |
| `X-Markdown-Tokens` | Eine grobe Schätzung von Zeichen, geteilt durch vier, aufgerundet; keine modellspezifische Tokenizer-Anzahl. |

`If-None-Match` unterstützt das Matching starker oder schwacher Validatoren, mehrere Validatoren und `*`. Ein Match gibt `304` ohne Körper zurück. `HEAD` liefert Darstellungs-Köpfe ohne Körper.

Das veröffentlichte Markdown-Inventar wird zum Release kompiliert. Anfragen führen keine Inhaltübersetzungen, Quelldateien lesen, ein鉴entifiziertes Konto laden oder ein LiveView rendern.

## Operative Grenzen

Markdown-Inhaltsverhandlung bietet keinen Zugriff auf Konto- oder Projektdashboards. Bestehende Kontobrowsing-Rate-Limits und Turnstile-Prüfungen bleiben separate Schutzmaßnahmen.

Produktionskante-Rate-Limits gelten für beide `GET` und `HEAD`. Verifizierte Crawler sind immer noch Rate-Limit. Überschüssige Anfragen erhalten eine Rate-Limit-Antwort statt einer Browser-Challenge; Leser sollten sich verlangsamen und später erneut versuchen. Geteiltes Caching und bedingte Anfragen entbinden Clients nicht von Rate-Limits.

Crawler-Policy-Änderungen im Repository werden erst nach der Bereitstellung der Anwendung und der relevanten Infrastrukturkonfiguration wirksam.
