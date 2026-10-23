%{
  title: "Lokalisierungsanalysen",
  summary:
    "Sehen Sie, welche Sprachen und Länder Ihre Besucher tatsächlich wünschen, und wo Sie eine Lokalisierungslücke haben, bevor Sie in eine neue Lokalisierung investieren.",
  order: 6,
  icon: "Welt",
  hero_cta_text: "Loslegen",
  hero_cta_url: "/signup",
  highlights: [
    %{
      title: "Chance, nicht Eitelkeit",
      description:
        "Dashboards basieren auf der Lokalisierungslücke: Der Anteil des Datenverkehrs, der eine Sprache wünscht, die Sie noch nicht bieten.",
      icon: "Welt"
    },
    %{
      title: "Von Haus aus ohne Cookies",
      description:
        "Keine Cookies, kein Fingerprinting, keine Einwilligungs-Banner. Einmalige Besucher kommen von einem täglich rotierten Hash, der nicht über Tage hinweg verknüpft werden kann.",
      icon: "Blitz"
    },
    %{
      title: "Eine Zeile zur Installation",
      description:
        "Fügen Sie ein einzelnes Script-Tag in Ihre Seite ein, und Glossia misst sich selbst. Veröffentlichen Sie über npm oder CDN.",
      icon: "Code"
    }
  ]
}
---

## Entscheide dich für die nächste Zielsprache mit Daten

Die meisten Teams wählen Zielsprachen nach Bauchgefühl. Lokalisierungsanalytik ersetzt das durch Signale. Füge das Web-SDK hinzu und Glossia zeigt dir die Sprachen, die die Browser deiner Besucher anfordern, die Länder, aus denen sie kommen, und, was am wichtigsten ist, die Überschneidung mit den Sprachen, die du bereits unterstützt.

Die Hauptmetrik ist die **Lokalisierungslücke**: der Prozentsatz deiner Besucher, deren bevorzugte Sprache keine unterstützte Übersetzung hat. Untersuche das nach Land, Referer und Seite, um genau zu sehen, wo die unterschätzte Nachfrage konzentriert ist und welche neue Lokalisierung den Ausschlag geben würde.

## Datenschutz ohne Kompromisse

Glossia-Analytik sammelt nichts, wofür sie nicht benötigt wird, und speichert nichts identifizierbares. Der Browser sendet die Seiten-URL, den Referer, bevorzugte Sprachen, die Zeitzonen und die Bildschirmgröße. Der Server leitet den eindeutigen Besucher aus einem täglich rotierenden Hash der IP und des User-Agent ab und verwirft ihn. Es werden keine Cookies gesetzt, nichts wird Fingerprinting unterzogen und kein Besucher kann über Tage oder über Websites hinweg verfolgt werden.

Das Ergebnis ist eine Analyse, die du bereitstellen kannst, ohne ein Einwilligungsbanner, im Einklang mit den Datenschutz-Erwartungen, die deine internationalen Besucher bereits haben.

## In Sekunden installieren

Füge eine Zeile zu deiner Website hinzu und Glossia beginnt die Erfassung:

```html
<script defer data-domain="example.com" src="https://cdn.glossia.ai/web.js"></script>
```

Nutzt du lieber npm? Installiere `@glossia/web` und rufe `init({ domain })` auf. Egal wie, fließen Pageviews, Client-seitige Navigation und benutzerdefinierte Ereignisse in dasselbe Dashboard, das deine Lokalisierungs-Chancen priorisiert.
