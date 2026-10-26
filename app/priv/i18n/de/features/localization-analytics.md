%{
  title: "Lokalisierungsanalysen",
  summary:
    "Sehen Sie, welche Sprachen und Länder Ihre Besucher tatsächlich wollen, und wo Sie eine Lokalisierungslücke haben, bevor Sie in eine neue Sprache investieren.",
  order: 6,
  icon: "Welt",
  hero_cta_text: "Loslegen",
  hero_cta_url: "/signup",
  highlights: [
    %{
      title: "Möglichkeit, nicht Leerstand",
      description:
        "Dashboards orientieren sich an der Lokalisierungslücke: der Anteil des Traffics, der auf eine Sprache wartet, die Sie noch nicht anbieten.",
      icon: "Welt"
    },
    %{
      title: "Ohne Cookies von Grund auf",
      description:
        "Keine Cookies, keine Fingerabdrücke, keine Zustimmungsbanner. Eindeutige Besucher stammen von einem täglich frisch generierten Hash, der nicht über Tage hinweg verknüpft werden kann.",
      icon: "Flash"
    },
    %{
      title: "Eine Zeile zum Installieren",
      description:
        "Tragen Sie ein einzelnes Script-Tag in Ihre Website ein, und Glossia misst sich. Verteilen Sie über npm oder CDN.",
      icon: "Code"
    }
  ]
}
---

## Bestimmen Sie Ihr nächstes Lokale mit Daten

Die meisten Teams wählen Zielsprachen aus Bauchgefühl heraus. Lokalisierungsanalysen ersetzen dies durch Signale. Fügen Sie das Web SDK hinzu, und Glossia zeigt Ihnen die Sprachen an, die die Browser Ihrer Besucher anfordern, die Länder, aus denen sie kommen, und, entscheidend, die Überschneidung mit den Sprachen, die Sie bereits unterstützen.

Die Schlüsselkennzahl ist der **Lokalisierungslücke**: der Prozentsatz Ihrer Besucher, deren bevorzugte Sprache keine übersetzte Version unterstützt. Drilling nach Land, nach Referrer und nach Seite um genau zu sehen, wo die unterversorgte Nachfrage konzentriert ist und welches neue Lokale sichtbaren Einfluss bringen würde.

## Datenschutz ohne Kompromisse

Glossia Analytics sammelt nur das Notwendige und speichert nichts Identifizierendes. Der Browser sendet die Seiten-URL, den Referrer, bevorzugte Sprachen, Zeitzone und Bildschirmauflösung. Der Server leitet den einzigartigen Besucher aus einem täglich rotierenden Hash der IP und User-Agent ab und darf nichts weiter speichern. Es werden keine Cookies gesetzt, nichts wird Fingerabdrücke gemacht, und kein Besucher kann über Tage oder über Websites hinweg verfolgt werden.

Das Ergebnis ist eine Analysen, die Sie ohne Zustimmungsbanner bereitstellen können, abgestimmt auf die Datenschutzerwartungen Ihrer internationalen Besucher.

## In Sekunden installieren

Fügen Sie eine Zeile zu Ihrer Website hinzu und Glossia beginnt mit der Messung:

```html
<script defer data-domain="example.com" src="https://cdn.glossia.ai/web.js"></script>
```

Verwenden Sie npm? Installieren Sie `@glossia/web` und rufen Sie `init({ domain })` auf. Auf jeden Fall fließen Selenium, Clientseitige Navigation und benutzerdefinierte Ereignisse in dasselbe Dashboard ein, das Ihre Lokalisierungsgelegenheiten bewertet.
