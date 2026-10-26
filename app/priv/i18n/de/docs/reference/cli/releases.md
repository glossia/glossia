%{
  title: "Veröffentlichungen",
  summary: "Verlauf der CLI-Veröffentlichungen.",
  category: "Referenz",
  subcategory: "CLI",
  order: 2
}
---

## 0.14.1

*2026-02-14*

#### Fehlerbehebungen
- Umbenennung des Binaries in den Release-Archiven von einem system-spezifischen Namen zu `glossia`.
- Entfernung der macOS-Quarantäne-Eigenschaft von Binaries vor der Verpackung.

## 0.14.0

*2026-02-14*

#### Neuheiten
- Hinzufügen eines lokalen Releaseskripts und eines manuell gepflegten Changelog-Workflows.

## 0.2.0

*2026-02-14*

#### Fehlerbehebungen
- Korrektur der Konfigurationshandhabung des gehosteten Login-Providers.
- Korrektur der Gesundheitschecks des gehosteten Services.

#### Neuheiten
- Hinzufügen einer Phoenix-App mit OAuth-Anmeldung, Dokumentenverbesserungen und UI-Verbesserungen.
- Verwendung des abgerundeten Logos als Favicon.
- Migration der CLI auf Bun und Aktualisierung der CI-ausführbaren Builds.

## 0.1.0

*2026-02-12*

#### Fehlerbehebungen
- Vermeidung des horizontalen Überlaufs von Code-Snippets auf mobilen Geräten.
- Hinzufügen eines angemessenen rechten Randes zu Code-Snippets auf mobilen Geräten.
- Erweiterung des mobilen responsiven Layouts, um horizontalen Überlauf zu verhindern.
- Anwendung der Biome-Formatierung.
- Hinzufügen von Gruppenüberschriften zur Release-Notes-Vorlage.
- Aktualisierung des Übersetzungs-Workflows von Bun auf Rust.
- Ausrichtung des Post-Textes auf dem Hero-Layout und Verbesserung des Blog-Inhalts.
- Horizontale Zentrierung des Blog-Inhalts.
- Korrektur von Paniken bei der Verkürzung mehrbyte UTF-8-Tool-Ergebnisse.

#### Neuheiten
- Hinzufügen von First-Party-Tools und Website-Sektion.
- Anzeige der Tool-Überprüfungsschritte.
- Vereinfachung des Fortschrittausgangs.
- Anfärben der Fortschrittslinien.
- Anzeige von Übersetzungs- und Validierungstätigkeit.
- Formatierung der Tool-Zeilen.
- Erstellung eines responsiven Designs für die Website mit Mobilmenü und Multipoint-Layout.
- Neuimplementierung der CLI in Bun/TypeScript.
- Hinzufügen eines CI-Workflows und Tests.
- Hinzufügen von Formatüberprüfung mit Biome.
- Hinzufügen eines Abschnitts Progressive Verfeinerung zur Startseite.
- Hinzufügen einer Blog-Sektion mit SEO-Unterstützung und erstem Blogbeitrag.
- Vereinheitlichung der CLI-Ausgabe im rechtsausgerichteten Verb-Format.
- Anfärben der CLI-Ausgabe mit formatierter Nachrichten.
- Hinzufügen eines quadratischen Open-Graph-Bildes und Twitter-Karten-Meta-Tags.
- Machen Sie den Koordinatoren-Agenten autonom durch Tool-Einsatz.
- Neuschreibung von `glossia init` mit Agent Client Protocol (ACP).
- Hinzufügen von Gemini-Unterstützung, automatischer Validierung, Token-Tracking und Verbesserungen der Zuverlässigkeit.

#### Refaktorierungen
- Aufteilung der CI in getrennte Format-, Typecheck-, Test- und Build-Jobs.
- Neuschreibung der CLI von TypeScript/Bun zu Rust.
