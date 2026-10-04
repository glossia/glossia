%{
  title: "Lokalisierungsanalytik",
  summary:
    "Finden Sie heraus, welche Sprachen und Länder Ihre Besucher tatsächlich bevorzugen und wo Sie eine Lokalisierungslücke haben, bevor Sie in eine neue Lokalisierung investieren.",
  order: 6,
  icon: "Globus",
  hero_cta_text: "Loslegen",
  hero_cta_url: "/signup",
  highlights: [
    %{
      title: "Opportunität, nicht Vanity",
      description:
        "Die Dashboards konzentrieren sich auf die Lokalisierungslücke: Den Anteil des Traffics, der eine Sprache wünscht, die Sie noch nicht bieten.",
      icon: "Globus"
    },
    %{
      title: "Per Design ohne Cookies",
      description:
        "Keine Cookies, kein Fingerprinting, keine Einwilligungs-Banner. Einzigartige Besucher stammen aus einem täglich rotierenden Hash, der nicht über Tage hinweg verknüpft werden kann.",
      icon: "Blitz"
    },
    %{
      title: "Eine Zeile zum Installieren",
      description:
        "Integrieren Sie einen einzelnen Script-Tag in Ihre Website und Glossia misst sich selbst. Veröffentlichen Sie via npm oder CDN.",
      icon: "Code"
    }
  ]
}
---
## Bestimmen Sie Ihr nächstes Sprachgebiet mit Daten

Die meisten Teams wählen Zielsprachen nach Bauchgefühl. Lokalisierungsanalysen ersetzen dies durch Signale. Verwenden Sie das Web-SDK, und Glossia zeigt Ihnen die Sprachen, die die Browser Ihrer Besucher anfordern, die Herkunftsländer und entscheidend den Deckungsgrad mit den bereits unterstützten Sprachen.

Das wichtigste Maß ist die **Lokalisierungslücke**: der Prozentsatz Ihrer Besucher, deren bevorzugte Sprache keine unterstützte Übersetzung besitzt. Untersuchen Sie diese nach Land, nach Referrer und nach Seite, um genau zu erkennen, wo die ungedeckte Nachfrage konzentriert ist und welches neue Sprachgebiet den Unterschied macht.

## Privatsphäre ohne Kompromisse

Die Glossia-Analytics sammelt nichts, das nicht benötigt wird, und speichert keine identifizierbaren Daten. Der Browser sendet die Seiten-URL, Referrer, bevorzugte Sprachen, Zeitzone und Bildschirmgröße. Der Server leitet den eindeutigen Besucher aus einem täglich rotierenden Hash der IP und des User-Agents ab und verwirft ihn daraufhin. Es werden keine Cookies gesetzt, kein Fingerprinting erfolgt, und kein Besucher kann über Tage oder Websites hinweg verfolgt werden.

Das Ergebnis sind Analysen, die Sie ohne Einwilligungsbanner bereitstellen können, die den Datenschutz-Erwartungen entsprechen, die Ihre internationalen Besucher bereits haben.

## In Sekunden installieren

Fügen Sie eine Zeile zu Ihrer Seite hinzu und Glossia beginnt mit der Messung:

```html
<script defer data-domain="example.com" src="https://cdn.glossia.ai/web.js"></script>
```

npm bevorzugen? Installieren `@glossia/web` und rufen Sie `init({ domain })`. Egal wie, fließen Seitenaufrufe, clientseitige Navigation und benutzerdefinierte Ereignisse in das gleiche Dashboard, das Ihre Lokalisierungschancen rangiert.