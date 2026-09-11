%{
  title: "Versionen",
  summary: "Geschichte der CLI-Versionen.",
  category: "Referenz",
  subcategory: "cli",
  order: 2
}
---
## 0.14.1

*2026-02-14*

#### Fehlerbehebungen

- Umbenennung der Binärdatei innerhalb von Release-Archiven vom plattformspezifischen Namen zu `glossia`.
- Entfernung des macOS-Quarantäne-xattr aus Binärdateien vor der Verpackung.

## 0.14.0

*2026-02-14*

#### Funktionen

- Lokales Release-Skript und manuell gepflegtes Changelog-Workflow hinzufügen.

## 0.2.0

*2026-02-14*

#### Fehlerbehebungen

- OAuth-Anbieter-Konfiguration in der Produktion optional machen. Die App sollte auch ohne GitHub/GitLab OAuth-Anmeldedaten starten. Konfigurieren Sie Provider nur, wenn Umgebungsvariablen gesetzt sind.
- Auf Port 4000 für Produktion als Standard setzen und 4050 für Entwicklung beibehalten. Der `runtime.exs` Standardwert war 4050, was dazu führte, dass Health-Checks beim Deployment fehlgeschlagen.

#### Funktionen

- Hinzufügen einer Phoenix-App mit OAuth-Anmeldung, Dokumentationsverbesserungen und UI-Verbesserungen.
- Verwendung eines gerundeten Logos als Favicon.
- Migration vom CLI zu Bun und Aktualisierung der CI-Ausführungsbauten.

## 0.1.0

*2026-02-12*

#### Fehlerbehebungen

- Verhindern horizontalen Überlauf von Code-Snippets auf mobilen Geräten.
- Füge Code-Snippets auf Mobile einen korrekten rechten Rand hinzu.
- Verbessere das responsive Layout auf Mobile, um horizontalen Überlauf zu verhindern.
- Wende Biome-Formatierung an.
- Füge Gruppenüberschriften zur Release-Notes-Vorlage hinzu.
- Aktualisiere den Übersetzungs-Workflow von Bun zu Rust.
- Richte den Beitragstext mit dem Hero-Layout aus und verbessere den Blog-Beitrag-Inhalt.
- Zentriere den Blog-Beitrag-Inhalt horizontal.
- Behebe Panik beim Kürzen von mehrbyte UTF-8-Werkzeugergebnissen.

#### Funktionen

- Sektion für First-Party-Tools und Website hinzufügen.
- Tool-Verifizierungsschritte anzeigen.
- Fortschrittsausgabe vereinfachen.
- Fortschrittslinien färben.
- Übersetzungs- und Validierungsaktivität anzeigen.
- Toolzeilen formatieren.
- Website mit Mobilmenü und Multi-Breakpoint-Layout responsive gestalten.
- CLI in Bun/TypeScript neu implementieren.
- CI-Workflow und Tests hinzufügen.
- Format-Check mit Biome hinzufügen.
- Abschnitt schrittweise Verfeinerung auf der Homepage hinzufügen.
- Blog-Abschnitt mit SEO-Unterstützung und erstem Blog-Beitrag hinzufügen.
- CLI-Ausgabe mit rechtsausgerichtetem Verbformat vereinheitlichen.
- CLI-Ausgabe mit farbigerer Nachrichtenformatierung versehen.
- Quadratisches OG-Bild und Twitter-Card-Meta-Tags hinzufügen.
- Machen Sie den Koordinator-Agenten agentic mit Werkzeugnutzung.
- Umschreiben `glossia init` mit Agent Client Protocol (ACP).
- Fügen Sie Gemini-Unterstützung, automatische Validierung, Token-Tracking und Zuverlässigkeitsverbesserungen hinzu.

#### Refaktorisierung

- Teilen Sie CI in separate Format-, Type-Check-, Test- und Build-Jobs auf.
- Umschreiben der CLI von TypeScript/Bun nach Rust.