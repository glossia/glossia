%{
  title: "Lokalisierungsanalysen",
  summary: "Erfahren Sie, welche Sprachen und Länder Ihre Besucher tatsächlich bevorzugen und wo eine Lokalisierungslücke besteht, bevor Sie in eine neue Lokalisierung investieren.",
  order: 6,
  icon: "globe",
  hero_cta_text: "Jetzt starten",
  hero_cta_url: "/signup",
  highlights: [
    %{title: "Chancen statt Eitelkeit", description: "Die Dashboards konzentrieren sich auf die Lokalisierungslücke: den Anteil des Traffics, der eine Sprache bevorzugt, die Sie noch nicht anbieten.", icon: "globe"},
    %{title: "Von Grund auf cookiefrei", description: "Keine Cookies, kein Fingerprinting, keine Cookie-Banner. Eindeutige Besucher werden über einen täglich rotierenden Hash erfasst, der sich nicht über mehrere Tage hinweg verknüpfen lässt.", icon: "zap"},
    %{title: "In einer Zeile installiert", description: "Fügen Sie einfach ein einziges Script-Tag in Ihre Website ein, und Glossia misst selbst. Bereitstellung über npm oder CDN.", icon: "code"}
  ]
}
---
## Entscheiden Sie datenbasiert über Ihr nächstes Locale

Die meisten Teams wählen Zielsprachen nach Bauchgefühl aus. Lokalisierungsanalysen ersetzen dieses Vorgehen durch belastbare Signale. Integrieren Sie das Web-SDK, und Glossia zeigt Ihnen die von den Browsern Ihrer Besucher angeforderten Sprachen, deren Herkunftsländer sowie, was besonders wichtig ist, die Überschneidung mit den bereits von Ihnen unterstützten Sprachen.

Die wichtigste Kennzahl ist die **Lokalisierungslücke**: der Prozentsatz Ihrer Besucher, deren bevorzugte Sprache über keine unterstützte Übersetzung verfügt. Analysieren Sie diese Kennzahl nach Land, Referrer und Seite, um genau zu sehen, wo sich ungedeckte Nachfrage konzentriert und welches neue Locale die größte Wirkung erzielen würde.

## Datenschutz ohne Kompromisse

Glossia Analytics erfasst nur Daten, die absolut notwendig sind, und speichert keine identifizierbaren Informationen. Der Browser übermittelt die Seiten-URL, den Referrer, die bevorzugten Sprachen, die Zeitzone und die Bildschirmgröße. Der Server ermittelt den eindeutigen Besucher aus einem täglich rotierenden Hashwert aus IP-Adresse und User-Agent und verwirft diese Daten anschließend. Es werden keine Cookies gesetzt, es wird kein Fingerprinting durchgeführt und Besucher können weder über mehrere Tage noch über verschiedene Websites hinweg verfolgt werden.

Das Ergebnis ist eine Analyselösung, die Sie ohne Consent-Banner bereitstellen können, perfekt abgestimmt auf die Datenschutzanforderungen, die Ihre internationalen Besucher ohnehin erwarten.

## In Sekundenschnelle installiert

Fügen Sie Ihrer Website eine einzige Zeile hinzu, und Glossia beginnt mit der Messung:

```html
<script defer data-domain="example.com" src="https://cdn.glossia.ai/web.js"></script>
```


Bevorzugen Sie npm? Installieren Sie `@glossia/web` und rufen Sie `init({ domain })` auf. Unabhängig von der Methode fließen Seitenaufrufe, clientseitige Navigation und benutzerdefinierte Ereignisse in dasselbe Dashboard ein, das Ihre Lokalisierungspotenziale bewertet.