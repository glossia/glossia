%{
  title: "Analytik zur Lokalisierung",
  summary:
    "Sehen Sie, welche Sprachen und Länder Ihre Besucher tatsächlich wollen, und wo Lücken in der Lokalisierung bestehen, bevor Sie in eine neue Lokalisierung investieren.",
  order: 6,
  icon: "Welt",
  hero_cta_text: "Loslegen",
  hero_cta_url: "/signup",
  highlights: [
    %{
      title: "Opportunität, nicht Eitelkeit",
      description:
        "Die Dashboards orientieren sich an der Lokalisierungslücke: der Anteil des Traffics, der eine Sprache wünscht, die Sie noch nicht unterstützen.",
      icon: "Welt"
    },
    %{
      title: "Ohne Cookies durch Design",
      description:
        "Keine Cookies, kein Fingerprinting, keine Einwilligungs-Banner. Einzigartige Besucher stammen aus einem täglich rotierten Hash, der nicht über Tage hinweg verknüpft werden kann.",
      icon: "Blitz"
    },
    %{
      title: "Eine Zeile zum Installieren",
      description:
        "Fügen Sie ein einzelnes Script-Tag in Ihre Website ein und Glossia misst sich selbst. Veröffentlichen Sie via npm oder CDN.",
      icon: "Code"
    }
  ]
}
---
## Bestimmen Sie Ihr nächstes Zielgebiet mit Daten

Die meisten Teams wählen Zielsprachen aus Bauchgefühl. Lokalisierungsanalysen ersetzen dies durch Signale. Hinzufügen Sie das Web-SDK und Glossia zeigt Ihnen die Sprachen, die die Browser Ihrer Besucher anfordern, die Länder, aus denen sie stammen, und, entscheidend, die Überschneidung mit den Sprachen, die Sie bereits unterstützen.

Der wichtigste Kennwert ist die **Lokalisierungslücke**: der Prozentsatz Ihrer Besucher, deren bevorzugte Sprache keine unterstützte Übersetzung hat. Untersuchen Sie dies nach Land, nach Referrer und nach Seite, um genau zu erkennen, wo unterversorgte Nachfrage konzentriert ist und welches neue Zielgebiet einen Unterschied macht.

## Datenschutz ohne Kompromisse

Glossia-Analytik sammelt keine Daten, die sie nicht benötigen, und speichert keine identifizierbaren Informationen. Der Browser sendet die URL der Seite, den Referrer, die bevorzugten Sprachen, die Zeitzone und die Bildschirmgröße. Der Server ermittelt den eindeutigen Besucher aus einem täglich rotierten Hash der IP und User-Agent und verwirft ihn anschließend. Es werden keine Cookies gesetzt, nichts wird abgezeichnet, und kein Besucher kann über Tage hinweg oder über verschiedene Websites hinweg verfolgt werden.

Das Ergebnis ist Analytik, die Sie ohne Einwilligungsbanner bereitstellen können und die den Datenschutz-Erwartungen Ihrer internationalen Besucher entspricht.

## Installation in Sekunden

Fügen Sie eine Zeile zu Ihrer Website hinzu, und Glossia beginnt zu messen:

```html
<script defer data-domain="example.com" src="https://cdn.glossia.ai/web.js"></script>
```

Eher npm? Installieren `@glossia/web` und führen Sie aus `init({ domain })`. Unabhängig davon, fließen Seitenaufrufe, clientseitige Navigation und benutzerdefinierte Ereignisse in dasselbe Dashboard, das Ihre Lokalisierungsmöglichkeiten priorisiert.