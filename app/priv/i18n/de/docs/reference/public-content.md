%{
  title: "Öffentlicher Inhalt und Crawler-Schnittstellen",
  summary: "HTML, Markdown, Discovery, Caching und Crawler-Grenzen für die öffentliche Website.",
  category: "Referenz",
  section: "platform",
  order: 10
}
---

Glossia zeigt veröffentlichten Website-Inhalt getrennt von Konto- und Projektanwendungsoberflächen an.

## Darstellungen

| Schnittstelle | Verhalten |
|---|---|
| Eine veröffentlichte HTML-URL | Die Browserdarstellung, mit kanonischen Metadaten und einem Markdown-Alternative `Link` Response-Header. |
| `Accept: text/markdown` an dieser URL | Eine Markdown-Darstellung, wenn der explizite Medientyp positive Qualität hat und nicht weniger bevorzugt ist als `text/html`. |
| Die Seiten-URL mit `.md` angehängt | Eine explizite Markdown-Darstellung, unabhängig von der Browsereinstellung. |
| `/index.md` | Die Markdown-Übersicht der Startseite. |
| `/docs.md`, `/blog.md`, `/features.md` | Markdown-Indizes für veröffentlichten Inhalt. |
| `/changelog.md` | Veröffentlichte Changelog-Einträge in einem Markdown-Dokument. |
| `/terms.md`, `/privacy.md`, `/cookies.md` | Die aktuellsten veröffentlichten Rechtsdokumente. Datierter gesetzlicher URLs unterstützen ebenfalls `.md`. |

`*/*` allein reicht nicht für Markdown. HTML- und Markdown-Antworten teilen `Vary: Accept` gemeinsam, sodass Caches die Darstellungen nicht vermischen.

Einzelne Dokumentationen, Blog, Features und rechtliche Inhalte verwenden verfasste Markdown anstelle einer Umwandlung des gerenderten HTML. Indexseiten werden aus dem veröffentlichten Inventar generiert; die Startseite verfügt über eine kuratierte Markdown-Übersicht. Die interaktive REST-Referenz verweist Leser auf die OpenAPI-Spezifikation, anstatt nur ein browserbasierter API-Widget einzubetten.

## Regionen

Englisch ist ohne Präfix. Übersetzte Marketing-URLs verwenden wörtliche Präfixe: `/de`, `/es`, `/fr`, `/ja`, `/ko`, `/pt-br` und `/zh-hans`. Zum Beispiel dient `/es/docs/tutorials/getting-started.md` der spanischen Version, wenn sie veröffentlicht ist.

Die URL wählt die Sprache des Markdown-Inhalts. `Accept-Language` leitet keine Markdown-Anfrage um. Fehlende Inhaltsübersetzungen fallen zurück auf ihren englischen Ursprung. Die Startseite-Übersicht wird derzeit auf Englisch verfasst.

## Entdeckung

- `/robots.txt` standardmäßig verbietet das Crawling und nutzt die begrenzten veröffentlichten HTML- und Markdown-Inventare, lokalisierte Feeds, Render-Assets unter `/assets/`, `/fonts/` und `/images/`, das Favicon und öffentliche Marketing-Vorschauen unter `/og/marketing/`. Account-Vorschau-Bilder unter `/og/app/` bleiben ausgeschlossen. Es dient als Anleitung für kooperative Crawler, nicht als Autorisierungsmechanismus.
- `/sitemap.xml` listet kanonische öffentliche HTML-Inhalte mit regionalen Alternativen auf. Changelog-Bruchstücke sind keine separaten URLs.
- `/llms.txt` stellt Glossia vor und verlinkt auf öffentliche Dokumentation, Feature-Leitfäden und aktuelle Texte, einschließlich expliziter Markdown-Verweise.
- `/llms-full.txt` exportiert die Startseite-Übersicht und das vollständige Dokumentareninventar in einem einzigen Textdokument, das Markdown enthält.

Authentifizierung, Konto-Dashboards, APIs und weitere Anwendungsantworten sind als `noindex, nofollow` markiert. Veröffentlichter, erfolgreicher Inhalt ist mit `index, follow` markiert; Fehler bleiben nicht indizierbar. Entdeckungs-Textdateien (`/robots.txt`, `/llms.txt` und `/llms-full.txt`) verwenden `noindex, follow`: Leser können diese abrufen und die Links verfolgen, doch Suchmaschinen sollten die kanonischen Seiten indizieren statt eines duplicierten Dokumentenauswurfs.

## Caching und Ressourcenverbrauch

Markdown- und Text-Entdeckungsantworten umfassen:

| Header | Wert oder Bedeutung |
|---|---|
| `Content-Type` | `text/markdown; charset=utf-8` oder `text/plain; charset=utf-8` für Discovery-Texte. |
| `Cache-Control` | `public, max-age=300, stale-while-revalidate=60`. |
| `ETag` | Ein zitiertes SHA-256-Hash der Darstellung. |
| `X-Markdown-Tokens` | Eine grobe Schätzung in Zeichen, geteilt durch vier, gerundet; kein modellspezifischer Tokenzähler. |

`If-None-Match` unterstützt das Abgleichen starker oder schwacher Validatoren, mehrerer Validatoren und `*`. Ein Treffer gibt `304` ohne Körper zurück. `HEAD` gibt Darstellungsköpfe ohne Körper zurück.

Das veröffentlichte Markdown-Inventar wird in die Freigabe kompiliert. Anfragen führen keine Inhaltübersetzungen durch, lesen Quelltexte, laden ein authentifiziertes Konto oder rendern eine LiveView. Für den Zugriff auf diese öffentlichen Darstellungen wird keine User-Agent-Identitatisbildung benötigt.

## Operative Grenzen

Markdown-Negotiation verschafft keinen Zugriff auf Konto- oder Projektdashboards. Bestehende Ratenbeschränkungen für Kontenbrowsing und Turnstile-Prüfungen bleiben getrennte Schutzmechanismen.

Produktionskanten-Ratenbeschränkungen gelten für `GET` und `HEAD`. Verifizierte Crawler sind weiterhin limitiert. Übermäßige Anfragen erhalten eine Rate-Limit-Antwort statt einer Browser-Safe Challenge; Leser sollten den Durchsatz verringern und später erneut versuchen. Geteiltes Caching und bedingte Anfragen befreien Clients nicht von Ratenbeschränkungen.

Änderungen der Crawler-Richtlinien im Repository treten nur in Kraft, nachdem die Anwendung und die relevante Infrastrukturausstattung bereitgestellt wurden.
