%{
  title: "Lokalisierungs-Analysen",
  summary:
    "Sehen Sie, welche Sprachen und Länder Ihre Besucher tatsächlich benötigen und wo Sie eine Lokalisierungslücke haben, bevor Sie in eine neue Lokalisierung investieren.",
  order: 6,
  icon: "globe",
  hero_cta_text: "Loslegen",
  hero_cta_url: "/signup",
  highlights: [
    %{
      title: "Chance, nicht Eitelkeit",
      description:
        "Die Dashboards konzentrieren sich auf die Lokalisierungslücke: den Anteil des Traffics, der eine Sprache wünscht, die Sie noch nicht bereitstellen.",
      icon: "globe"
    },
    %{
      title: "Cookie-frei konzipiert",
      description:
        "Keine Cookies, kein Fingerprinting, keine Einwilligungs-Banner. Eindeutige Besucher kommen aus einem täglich rotierenden Hash, der über Tage hinweg nicht verknüpft werden kann.",
      icon: "zap"
    },
    %{
      title: "Eine Zeile zum Installieren",
      description:
        "Fügen Sie ein Script-Tag an Ihrer Website ein und Glossia misst sich selbst. Veröffentlichen Sie über npm oder CDN.",
      icon: "code"
    }
  ]
}
---
## Entscheiden Sie sich für Ihre nächste Zielsprache mit Daten

Die meisten Teams wählen Zielsprachen nach Bauchgefühl. Lokalisierungsanalytik ersetzt dies durch Signale. Fügen Sie das Web-SDK hinzu, und Glossia zeigt Ihnen die Sprachen, die die Browser Ihrer Besucher anfordern, die Länder, aus denen sie stammen, und, was entscheidend ist, die Überschneidung mit den Sprachen, die Sie bereits unterstützen.

Die wichtigste Kennzahl ist die **Lokalisierungslücke**: der Prozentsatz Ihrer Besucher, dessen bevorzugte Sprache keine unterstützte Übersetzung hat. Analysieren Sie sie nach Land, nach Referrer und nach Seite, um genau zu sehen, wo die unterversorgte Nachfrage konzentriert ist und welche neue Zielsprache den Unterschied macht.

## Datenschutz ohne Kompromisse

Glossia-Analytik sammelt nichts, was sie nicht benötigt, und speichert nichts Identifizierbares. Der Browser sendet die Seiten-URL, den Referrer, die bevorzugten Sprachen, die Zeitzone und die Bildschirmgröße. Der Server leitet den eindeutigen Besucher aus einem täglich rotierenden Hash von IP und User-Agent ab und löscht ihn dann. Es werden keine Cookies gesetzt, nichts wird identifiziert, und kein Besucher kann über Tage oder über Websites hinweg verfolgt werden.

Das Ergebnis sind Analysen, die Sie ohne Einwilligungsbanner bereitstellen können, abgestimmt auf die Datenschutzerwartungen, die Ihre internationalen Besucher ohnehin haben.

## Installation in Sekunden

Fügen Sie eine Zeile zu Ihrer Website hinzu und Glossia beginnt mit der Messung:

```html
<script defer data-domain="example.com" src="https://cdn.glossia.ai/web.js"></script>
```

Bevorzugen Sie npm? Installieren Sie `@glossia/web` und rufen Sie `init({ domain })` auf. Auf jeden Fall fließen Seitenaufrufe, client-seitige Navigation und benutzerdefinierte Ereignisse in dasselbe Dashboard, das Ihre Lokalisierungsbedarfe priorisiert.