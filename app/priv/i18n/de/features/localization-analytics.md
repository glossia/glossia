%{
  title: "Lokalisierungsanalysen",
  summary:
    "Erfahren Sie, welche Sprachen und Länder Ihre Besucher tatsächlich wollen, und wo Sie eine Lokalisierungslücke haben, bevor Sie in eine neue Lokalisierung investieren.",
  order: 6,
  icon: "Globus",
  hero_cta_text: "Loslegen",
  hero_cta_url: "/signup",
  highlights: [
    %{
      title: "Chance, nicht Eitelkeit",
      description:
        "Dashboards orientieren sich an der Lokalisierungslücke: dem Anteil des Datenverkehrs, der eine Sprache wünscht, die Sie noch nicht anbieten.",
      icon: "Globus"
    },
    %{
      title: "Ohne Cookies konzipiert",
      description:
        "Keine Cookies, kein Fingerprinting, keine Einwilligungs-Banner. Einzigartige Besucher kommen aus einem täglich rotierten Hash, der nicht über die Tage hinweg verknüpft werden kann.",
      icon: "Blitz"
    },
    %{
      title: "Eine Zeile zum Installieren",
      description:
        "Fügen Sie einen einzigen Skript-Tag in Ihre Website ein und Glossia misst sich selbst. Veröffentlichen Sie über npm oder CDN.",
      icon: "Code"
    }
  ]
}
---
## Bestimmen Sie Ihr nächstes Locale basierend auf Daten

Die meisten Teams wählen Zielsprachen nach Bauchgefühl. Lokalisierungsanalysen ersetzen dies durch Signal. Fügen Sie das Web-SDK hinzu und Glossia zeigt Ihnen die Sprachen, die Ihre Besucherbrowser anfordern, die Länder, aus denen sie kommen und vor allem die Überschneidung mit den Sprachen, die Sie bereits unterstützen.

Die Schlüsselmetrik ist der **Lokalisierungslücke**: der prozentuale Anteil Ihrer Besucher, deren bevorzugte Sprache keine unterstützte Übersetzung hat. Analysieren Sie dies nach Land, nach Referer und nach Seite, um genau zu sehen, wo die ungedeckte Nachfrage konzentriert ist und welche neue Zielsprache den Unterschied macht.

## Datenschutz ohne Kompromisse

Glossia Analytics sammelt nichts, was nicht benötigt wird, und speichert nichts Identifizierbares. Der Browser übermittelt die Seiten-URL, den Referer, die bevorzugten Sprachen, die Zeitzone und die Bildschirmgröße. Der Server leitet den einzigartigen Besucher aus einem täglich rotierenden Hash der IP und User-Agent ab und verwirft diese Daten. Es werden keine Cookies gesetzt, es wird kein Fingerprinting betrieben und kein Besucher kann über Tage oder Websites hinweg verfolgt werden.

Das Ergebnis sind Analysen, die Sie ohne ein Einwilligungsbanner einsetzen können, in Übereinstimmung mit den Datenschutzerwartungen Ihrer internationalen Besucher.

## In Sekunden installieren

Fügen Sie eine Zeile in Ihre Website ein und Glossia beginnt zu messen:

```html
<script defer data-domain="example.com" src="https://cdn.glossia.ai/web.js"></script>
```

npm bevorzugen? Installieren `@glossia/web` und rufen Sie `init({ domain })`. In jedem Fall fließen Seitenansichten, clientseitige Navigation und benutzerdefinierte Ereignisse in dasselbe Dashboard ein, der Ihre Lokalisierungsbedarfe priorisiert.