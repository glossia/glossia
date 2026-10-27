%{
  title: "Warum Lokalisierungsanalysen",
  summary:
    "Wie die gesammelten Signale in Lokalisierungsentscheidungen umgesetzt werden und warum die Gap-Metrik wichtig ist.",
  category: "Erklärung",
  section: "analytics",
  order: 2
}
---

Die Wahl der Sprache für die nächste Übersetzung ist eine Wette: Sie kostet Zeit und Geld, und die Auszahlung hängt von der Nachfrage ab, die man normalerweise nicht sieht. Lokalisierungsanalysen machen diese Nachfrage sichtbar.

## Die Entscheidung, nicht das Dashboard

Der Zweck der Datenerhebung hier ist eng und zielgerichtet: Um die Frage zu beantworten, "Sollten wir in die Sprache X übersetzen?". Die Signale sind darauf ausgerichtet, diese Frage zu beantworten, nicht als allgemeine Analyseinstrumente zu dienen.

Drei Einträge treiben die Entscheidung an:

1. **Nachfrage.** Wie viele Besucher möchten diese Sprache? Browser-Sprachen und das Land zeigen, wo das Interesse liegt.
2. **Die Lücke.** Ist diese Nachfrage bereits gedeckt? Der Vergleich der bevorzugten Sprachen mit den Zielsprachen Ihres Projekts, der Seitensprache und den angekündigten Übersetzungen zeigt den Anteil des Traffics, der auf eine Barriere trifft.
3. **Wert.** Lohnt sich die Lokalisierung? Engagement je nach Lückendefizit, die Seiten, auf die verarbeiteter Traffic landet, und die Herkunft dieses Traffics zeigen, ob eine neue Lokallösung konvertiert.

## Warum die Lücke zum Zeitpunkt der Eingabe berechnet wird

`served_locale` protokolliert die tatsächlich in `<html lang>` deklarierte Seitensprache, nicht die Sprache, die wir einem Besucher unterstellen. `has_locale_gap` vergleicht eine gültige explizite Sprachwahl oder Browserpräferenzen, wenn keine Wahl bekannt ist, gegen die Zielsprachen Ihres Projekts, die Seitensprache und `hreflang` Links beworbene Übersetzungen. Eine Wahl zeigt Bedarf, nicht Verfügbarkeit an: Wenn eine nicht unterstützte Sprache ausgewählt wird, bleibt trotzdem eine Lücke. Browserpräferenz, Auswahl und Seitensprache bleiben separate Signale.

Die Lückenentscheidung wird pro Ereignis so gespeichert, wie sie zum Zeitpunkt des Besuchs war. Historische Flags, einschließlich derer, die gesammelt wurden, bevor explizite Wahlen die Lückenberechnung beeinflussten, werden nicht anhand der heutigen Zielsprachen oder späterer Wahlen neu berechnet. Die komplette Browserpräferenzliste und die beworbenen Übersetzungen werden nicht beherrscht, sodass sie nicht zuverlässig rekonstruiert werden können. Wenn Sie nächsten Monat Portugiesisch hinzufügen, schrumpft die Lücke des letzten Monats nicht retroaktiv; Sie behalten das ursprüngliche Aufzeichnen der Nachfrage.

## Warum cookieless, insbesondere

Der Instinkt, wenn man "einzigartige Besucher" will, besteht darin, ein Cookie zu setzen oder den Browser zu fingerprinten. Beides erstellt langlebige Kennungen, und unter den meisten Datenschutzbestimmungen ist Fingerprinting schwieriger zu löschen als ein Cookie. Weder ist hier notwendig.

Einzigartige Besucher für einen Tag erfordern lediglich einen Identifikator, der *innerhalb des Tages* stabil ist. Ein Hash aus der IP und dem User-Agent, der täglich rotiert und pro Projekt begrenzt ist, unterstützt tägliche Besucherzahlen, während es unmöglich macht, einen Besucher über Tage oder Webseiten hinweg zu verknüpfen. Dies bietet keine langfristige Nachverfolgung von wiederkehrenden Besuchern.

Dieses Design begrenzt die Kennungen, die von den Analysen beherrschen. Es klärt nicht, ob eine bestimmte Webseite Einwilligung erfordert; das hängt davon ab, wie die Webseite Analysen verwendet und denen Regeln, die auf sie anwendbar sind.
