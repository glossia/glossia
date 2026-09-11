%{
  title: "Lokalisierungsanalytik",
  summary:
    "Sehen Sie, welche Sprachen und Länder Ihre Besucher tatsächlich wünschen, und wo Sie eine Lokalisierungslücke haben, bevor Sie in eine neue Lokale investieren.",
  order: 6,
  icon: "Weltkugel",
  hero_cta_text: "Loslegen",
  hero_cta_url: "/signup",
  highlights: [
    %{
      title: "Chance, keine Eitelkeit",
      description:
        "Dashboards basieren auf der Lokalisierungslücke: der Anteil des Verkehrs, der eine Sprache wünscht, die Sie noch nicht anbieten.",
      icon: "Weltkugel"
    },
    %{
      title: "Ohne Cookies konzipiert",
      description:
        "Keine Cookies, kein Fingerprinting, keine Einwilligungs-Banner. Einzigartige Besucher stammen aus einem täglich neu generierten Hash, der nicht über Tage hinweg verknüpft werden kann.",
      icon: "Blitz"
    },
    %{
      title: "Installieren in einer einzigen Zeile",
      description:
        "Fügen Sie einen Script-Tag in Ihre Seite ein und Glossia misst sich selbst. Veröffentlichen Sie über npm oder CDN.",
      icon: "Code"
    }
  ]
}
---
## Entscheide dein nächstes Locale mit Daten

Viele Teams wählen Zielsprachen allein nach Bauchgefühl. Lokalisationsanalyse ersetzt das durch Signale. Fügen Sie das Web-SDK hinzu, und Glossia zeigt Ihnen die Sprachen, die die Browser Ihrer Besucher anfordern, die Länder, aus denen sie stammen, und, entscheidend, die Überschneidung mit den Sprachen, die Sie bereits unterstützen.

Die Hauptkennzahl ist die **lokalisierungsLücke**: Der Prozentsatz Ihrer Besucher, deren bevorzugte Sprache keine unterstützte Übersetzung hat. Untersuchen Sie das nach Land, nach Referrer und nach Seite, um genau festzustellen, wo sich die unbediente Nachfrage konzentriert und welche neue Lokalisierung den größten Effekt erzielt.

## Datenschutz ohne Kompromisse

Glossia Analytics sammelt keine Daten, die es nicht benötigt, und speichert nichts Identifizierbares. Der Browser sendet die Seiten-URL, den Referrer, bevorzugte Sprachen, die Zeitzone und die Bildschirmgröße. Der Server berechnet den eindeutigen Gast aus einem täglich rotierten Hash der IP-Adresse und des User-Agents und verwirft diese Informationen anschließend. Es werden keine Cookies gesetzt, es wird kein Fingerprinting betrieben, und kein Besucher kann über Tage oder Websites hinweg verfolgt werden.

Das Ergebnis sind Analysen, die Sie ohne Einwilligungs-Banner live schalten können, die den Datenschutz-Erwartungen Ihrer internationalen Besucher bereits entsprechen.

## In Sekunden installieren

Fügen Sie eine Zeile zu Ihrer Seite hinzu und Glossia beginnt zu messen:

```html
<script defer data-domain="example.com" src="https://cdn.glossia.ai/web.js"></script>
```

Preferieren Sie npm? Installieren `@glossia/web` und rufen Sie es aus `init({ domain })`. Egal wie, Seitenaufrufe, clientseitige Navigation und benutzerdefinierte Ereignisse fließen in dasselbe Dashboard ein, das Ihre Lokalisierungsmöglichkeiten priorisiert.