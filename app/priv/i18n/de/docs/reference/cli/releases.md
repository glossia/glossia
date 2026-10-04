%{
  title: "Versionen",
  summary: "CLI Versionsgeschichte.",
  category: "Referenz",
  subcategory: "CLI",
  order: 2
}
---
## 0.14.1

*2026-02-14*

#### Fehlerbehebungen

- Umbenennung der Binärdatei in Release-Archiven vom plattformspezifischen Namen auf `glossia`.
- Entfernung des macOS quarantine xattr aus Binärdateien vor dem Verpacken.

## 0.14.0

*2026-02-14*

#### Funktionen

- Hinzufügung eines lokalen Release-Skripts und eines manuell gepflegten Changelog-Workflows.

## 0.2.0

*2026-02-14*

#### Fehlerbehebungen

- Korrektur der Konfigurationsbehandlung des gehosteten Login-Providers.
- Korrektur der Health Checks der gehosteten Dienste.

#### Funktionen

- Phoenix-App hinzufügen mit OAuth-Login, Dokumentationsverbesserungen und UI-Verbesserungen.
- Das abgerundete Logo als Favicon verwenden.
- CLI auf Bun migrieren und CI-ausführbare Builds aktualisieren.

## 0.1.0

*2026-02-12*

#### Fehlerbehebungen

- Horizontalen Überlauf von Code-Snippets auf mobilen Geräten verhindern.
- Einen angemessenen rechten Rand für Code-Snippets auf mobilen Geräten hinzufügen.
- Mobile Responsive-Layout verbessern, um horizontalen Überlauf zu verhindern.
- Biome-Formatierung anwenden.
- Gruppenüberschriften zum Release-Notizen-Template hinzufügen.
- Übersetzungs-Workflow von Bun zu Rust aktualisieren.
- Beitragstext mit Hero-Layout ausrichten und Blogbeitrag-Inhalte verbessern.
- Blogbeitrag-Inhalte horizontal zentrieren.
- Panic beim Kürzen Mehrbyte UTF-8-Tool-Ergebnisse beheben.

#### Funktionen

- Sektion für First-Party-Tools und Website hinzufügen.
- Tool-Verifizierungsschritte sichtbar machen.
- Fortschrittsausgabe vereinfachen.
- Fortschrittszeilen einfärben.
- Übersetzungs- und Validierungsaktivität anzeigen.
- Toolzeilen formatieren.
- Website mit Mobile-Menu und Multi-Breakpoint-Layout responsiv gestalten.
- CLI in Bun/TypeScript neuimplementieren.
- CI-Workflow und Tests hinzufügen.
- Formatprüfung mit Biome hinzufügen.
- Abschnitt Progressive Refinement auf der Startseite hinzufügen.
- Blog-Sektion mit SEO-Unterstützung und erstem Blog-Beitrag hinzufügen.
- CLI-Ausgabe mit rechtsausgerichtetem Verbformat vereinheitlichen.
- CLI-Ausgabe mit reicherer Nachrichtenformatierung farbig gestalten.
- Quadratische Open-Graph-Bilder und Twitter-Karten Meta-Tags hinzufügen.
- Koordinierungsagent mit Tool-Nutzung agentic machen.
- Neuschreiben `glossia init` mit Agent Client Protocol (ACP).
- Hinzufügen von Gemini-Unterstützung, automatischer Validierung, Token-Tracking und Verbesserungen der Zuverlässigkeit.

#### Refaktorisierungen

- CI in separate Formatierung-, Typenprüfung-, Test- und Build-Jobs aufteilen.
- Neuschreiben der CLI von TypeScript/Bun nach Rust.