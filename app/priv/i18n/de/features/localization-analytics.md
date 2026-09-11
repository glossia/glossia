%{
  title: "Lokalisierungs-Analytics",
  summary:
    "Finden Sie heraus, welche Sprachen und Länder Ihre Besucher tatsächlich wünschen und wo eine Lokalisierungslücke besteht, bevor Sie in eine neue Lokalisierung investieren.",
  order: 6,
  icon: "Welt",
  hero_cta_text: "Loslegen",
  hero_cta_url: "/signup",
  highlights: [
    %{
      title: "Chance, nicht Eitelkeit",
      description:
        "Die Dashboards basieren auf der Lokalisierungslücke: dem Anteil des Traffics, der eine Sprache wünscht, die Sie noch nicht bereitstellen.",
      icon: "Welt"
    },
    %{
      title: "Ohne Cookies konzipiert",
      description:
        "Keine Cookies, kein Fingerprinting, keine Einwilligungs-Banner. Einzigartige Besucher stammen aus einem täglich rotierenden Hash, der nicht über Tage hinweg verknüpft werden kann.",
      icon: "Blitz"
    },
    %{
      title: "Nur eine Zeile zum Installieren",
      description:
        "Setzen Sie ein einzelnes Script-Tag in Ihre Website ein und Glossia misst sich selbst. Veröffentlichen Sie über npm oder CDN.",
      icon: "Code"
    }
  ]
}
---
## Entscheiden Sie sich für Ihr nächstes Lokale mit Daten

Die meisten Teams entscheiden sich für Zielsprachen aus dem Bauchgefühl. Lokalisierungsanalytik ersetzt das durch Signale. Fügen Sie das Web-SDK hinzu und Glossia zeigt Ihnen die Sprachen, die die Browser Ihrer Besucher anfordern, die Länder, aus denen sie kommen, und entscheidend, die Überschneidung mit den Sprachen, die Sie bereits unterstützen.

Die wichtigste Metrik ist die **Lokalisierungslücke**: der Prozentsatz Ihrer Besucher, deren bevorzugte Sprache keine unterstützte Übersetzung hat. Untersuchen Sie nach Land, nach Referrer und nach Seite, um genau zu erkennen, wo die unversorgte Nachfrage konzentriert ist und welches neue Lokale die Nadel bewegen würde.

## Datenschutz ohne Kompromisse

Glossia-Analytik sammelt nichts, was sie nicht benötigt, und speichert keine identifizierbaren Daten. Der Browser sendet die Seiten-URL, den Referrer, die bevorzugten Sprachen, die Zeitzone und die Bildschirmgröße. Der Server leitet den einzigartigen Besucher aus einem täglich rotierenden Hash der IP und User-Agent ab und löscht sie. Keine Cookies werden gesetzt, nichts wird Fingerprinted, und kein Besucher kann über Tage oder Websites verfolgt werden.

Das Ergebnis ist Eine Analytik, die Sie ohne Zustimmungsbanner bereitstellen können und die den Datenschutz-Erwartungen Ihrer internationalen Besucher entspricht, die diese bereits haben.

## In Sekunden installieren

Fügen Sie eine Zeile in Ihre Website ein, und Glossia beginnt zu messen:

```html
<script defer data-domain="example.com" src="https://cdn.glossia.ai/web.js"></script>
```

Npm bevorzugen? Installieren `@glossia/web` und aufrufen `init({ domain })`. Egal wie, Seitenaufrufe, clientseitige Navigation und benutzerdefinierte Ereignisse fließen in dasselbe Dashboard, das Ihre Lokalisierungsgelegenheiten priorisiert.