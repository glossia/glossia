%{
  title: "Veröffentlichungen",
  summary: "Historie der CLI-Veröffentlichungen.",
  category: "Referenz",
  subcategory: "CLI",
  order: 2
}
---
## 0.14.1

*2026-02-14*

#### Fehlerbehebungen

- Umbenennung der Binärdatei in Release-Archiven von plattformspezifischem Namen lediglich auf `glossia`.
- Entfernung des macOS Quarantäne-xattr von Binärdateien vor der Verpackung.

## 0.14.0

*2026-02-14*

#### Funktionen

- Hinzufügen eines lokalen Release-Skripts und eines manuell gepflegten Changelog-Workflows.

## 0.2.0

*2026-02-14*

#### Bugbehebungen

- Machen Sie die OAuth-Anbieterkonfiguration im Produktionsbetrieb optional. Die App sollte auch ohne festgelegte GitHub/GitLab OAuth-Zugangsdaten starten. Konfigurieren Sie Provider nur, wenn die Umgebungsvariablen gesetzt sind.
- Standardmäßig Port 4000 für die Produktion und 4050 für die Entwicklung verwenden. Der `runtime.exs` Standardwert war 4050, was dazu führte, dass Health-Checks während des Deployments fehlgeschlagen.

#### Funktionen

- Hinzufügen einer Phoenix-App mit OAuth-Anmeldung, Dokumentationsverbesserungen und UI-Verbesserungen.
- Verwenden Sie das abgerundete Logo als Favicon.
- CLI auf Bun migrieren und CI-Executable-Builds aktualisieren.

## 0.1.0

*2026-02-12*

#### Fehlerbehebungen

- Horizontalen Überlauf von Code-Snippets auf Mobilgeräten verhindern.
- Füge auf Mobilgeräten einen passenden rechten Rand für Codeausschnitte hinzu.
- Verbessere das responsive Layout für Mobilgeräte, um horizontale Überläufe zu verhindern.
- Biome-Formatierung anwenden.
- Füge Gruppenüberschriften zur Release-Notizen-Vorlage hinzu.
- Aktualisiere den Übersetzungs-Workflow von Bun auf Rust.
- Richte den Beitragstext nach dem Hero-Layout aus und verbessere den Blogbeitrag.
- Zentriere den Blogbeitrag horizontal.
- Behebe den Panic beim Beschneiden von Mehrbyte UTF-8-Werkzeug-Ergebnissen.

#### Funktionen

- first-party Tools und Website-Section hinzufügen.
- Werkzeug-Verifikationsschritte ans Licht führen.
- Fortschrittsausgabe vereinfachen.
- Fortschrittszeilen färben.
- Übersetzungs- und Validierungsaktivitäten anzeigen.
- Werkzeugzeilen formatieren.
- Website responsive gestalten mit Mobile-Menü und Multi-Breakpoint-Layout.
- CLI in Bun/TypeScript neuimplementieren.
- CI-Workflow und Tests hinzufügen.
- Formatprüfung mit Biome hinzufügen.
- Abschnitt Progressive Refinement zur Startseite hinzufügen.
- Blog-Bereich mit SEO-Unterstützung und erstem Blogbeitrag hinzufügen.
- CLI-Ausgabe mit rechtsbündigem Verbformat vereinheitlichen.
- CLI-Ausgabe mit farbiger Nachrichtenformatierung versehen.
- Quadratisches OG-Bild und Twitter-Karten-Metadaten hinzufügen.
- Machen Sie den Koordinationsagenten mit Tool-Nutzung autonom.
- Umschreiben `glossia init` mit Agent Client Protocol (ACP).
- Fügen Sie Unterstützung für Gemini, automatische Validierung, Token-Tracking und Zuverlässigkeitsverbesserungen hinzu.

#### Refaktorisierung

- Teilen Sie CI in getrennte Format-, Typenprüfung-, Test- und Build-Jobs auf.
- Umschreiben CLI von TypeScript/Bun zu Rust.