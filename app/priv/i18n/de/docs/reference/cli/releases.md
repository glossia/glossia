%{
  title: "Veröffentlichungen",
  summary: "CLI-Releasehistorie.",
  category: "Referenz",
  subcategory: "CLI",
  order: 2
}
---
## 0.14.1

*2026-02-14*

#### Fehlerbehebungen

- Umbenennen der Binärdatei in Release-Archiven vom plattformspezifischen Namen auf lediglich `glossia`.
- Entfernen des macOS-Quarantäne-Attributs (xattr) aus Binärdateien vor der Paketierung.

## 0.14.0

*2026-02-14*

#### Neuheiten

- Hinzufügen eines lokalen Release-Skripts und eines manuell gepflegten Changelog-Arbeitsablaufs.

## 0.2.0

*2026-02-14*

#### Fehlerbehebungen

- Machen Sie die OAuth-Anbieter-Konfiguration im Produktionsmodus optional. Die App sollte auch ohne GitHub/GitLab OAuth-Zertifikate starten. Konfigurieren Sie Anbieter nur, wenn die Umgebungsvariablen gesetzt sind.
- Port 4000 als Standard für die Produktion verwenden und 4050 für die Entwicklung beibehalten. Der Produktions-Proxy erwartet die App auf Port 4000. Der `runtime.exs` Standardwert war 4050, was die Healthchecks während des Deployments zum Scheitern führte.

#### Funktionen

- Hinzufügen einer Phoenix-App mit OAuth-Login, Dokumentationsverbesserungen und UI-Verbesserungen.
- Abgerundetes Logo als Favicon verwenden.
- CLI auf Bun migrieren und CI-ausführbare Builds aktualisieren.

## 0.1.0

*2026-02-12*

#### Fehlerbehebungen

- Verhindern des horizontalen Überlaufs von Code-Snippets auf Mobilgeräten.
- Füge Codeausschnitten auf Mobilgeräten einen ordnungsgemäßen rechten Rand hinzu.
- Verbessere das Responsive-Layout für Mobilgeräte, um horizontalen Überlauf zu vermeiden.
- Biome-Formatierung anwenden.
- Füge Gruppenüberschriften zur Release-Notes-Vorlage hinzu.
- Aktualisiere den Übersetzungs-Workflow von Bun zu Rust.
- Richte den Post-Body mit dem Hero-Layout aus und verbessere den Blog-Beitrag.
- Zentriere den Blog-Beitragsinhalt horizontal.
- Behebe den Panic beim Abschneiden mehrbyte UTF-8-Tool-Ergebnisse.

#### Funktionen

- Hinzufügen von First-Party-Tools und einer Website-Sektion.
- Darstellung der Tool-Verifizierungsschritte.
- Vereinfachung der Fortschrittsausgabe.
- Färbung der Fortschrittslinien.
- Anzeige der Übersetzungs- und Validierungsaktivität.
- Formatierung der Tool-Linien.
- Gestaltung einer responsiven Website mit Mobilmenü und Multi-Breakpoint-Layout.
- CLI in Bun/TypeScript neuimplementieren.
- CI-Workflow und Tests hinzufügen.
- Formatprüfung mit Biome hinzufügen.
- Progressive Refinement-Bereich auf die Startseite hinzufügen.
- Blog-Sektion mit SEO-Unterstützung und erstem Blogbeitrag hinzufügen.
- CLI-Ausgabe mit rechtsausgerichtetem Verbformat vereinheitlichen.
- CLI-Ausgabe mit reicherer Nachrichtenformatierung farblich gestalten.
- Quadratische OG-Bilder und Twitter-Card-Meta-Tags hinzufügen.
- Koordinatoren-Agenten autonom mit Tool-Nutzung machen.
- Neuschreiben `glossia init` mit Agent Client Protocol (ACP).
- Hinzufügen von Gemini-Unterstützung, automatischer Validierung, Token-Tracking und Zuverlässigkeitsverbesserungen.

#### Refactoring

- CI in getrennte Format-, Typecheck-, Test- und Build-Jobs aufteilen.
- CLI von TypeScript/Bun nach Rust umschreiben.