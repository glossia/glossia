%{
  title: "Versionen",
  summary: "Versionshistorie der CLI.",
  category: "Referenz",
  subcategory: "CLI",
  order: 2
}
---
## 0.14.1

*2026-02-14*

#### Fehlerbehebungen

- Umbenennung der Binärdatei in den Veröffentlichungsarchiven von der plattformspezifischen Bezeichnung auf `glossia`.
- Entfernen des macOS Quarantäne-Attributs (xattr) von Binärdateien vor der Paketierung.

## 0.14.0

*2026-02-14*

#### Funktionen

- Hinzufügung eines lokalen Release-Skripts und eines manuell verwalteten Changelog-Workflows.

## 0.2.0

*2026-02-14*

#### Fehlerbehebungen

- OAuth-Anbieter-Konfiguration in der Produktion optional. Die App sollte auch ohne festgelegte GitHub/GitLab OAuth-Anmeldeinformationen starten. Konfigurieren Sie Anbieter nur, wenn die Umgebungsvariablen vorhanden sind.
- Verwenden Sie standardmäßig Port 4000 für die Produktion und behalten Sie 4050 für die Entwicklung bei. Der Produktions-Proxy erwartet die App auf Port 4000. Der `runtime.exs` Standardwert war 4050, was zu fehlgeschlagenen Health Checks während des Deployments führte.

#### Neuheiten

- Hinzugefügte Phoenix-App mit OAuth-Login, Dokumentationsverbesserungen und UI-Verbesserungen.
- Abgerundetes Logo als Favicon.
- Migration der CLI auf Bun und Aktualisierung der CI-Executable-Builds.

## 0.1.0

*2026-02-12*

#### Bugbehebungen

- Verhinderung horizontalen Überlaufs von Code-Ausschnitten auf Mobilgeräten.
- Füge Code-Snippets auf Mobile einen passenden rechten Rand hinzu.
- Verbessere das responsive Mobile-Layout, um horizontales Überlaufen zu verhindern.
- Wende biome-Formatierung an.
- Füge Gruppenüberschriften zur Release-Notes-Vorlage hinzu.
- Aktualisiere den Übersetzungsworkflow von Bun auf Rust.
- Passe den Beitragsinhalt an das Hero-Layout an und verbessere den Blog-Beitragsinhalt.
- Zentriere den Blog-Beitragsinhalt horizontal.
- Behebe den Panic beim Abschneiden mehrbyte UTF-8-Tool-Ergebnisse.

#### Funktionen

- Füge First-Party-Tools und Website-Bereich hinzu.
- Zeige Werkzeugverifizierungsschritte an.
- Vereinfache die Fortschrittsausgabe.
- Färbe Fortschrittszeilen ein.
- Zeige Übersetzungs- und Validierungsaktivitäten an.
- Formatiere Werkzeugzeilen.
- Gestalte die Website responsiv mit mobilem Menü und einem Layout mit mehreren Breakpoints.
- CLI in Bun/TypeScript neuimplementieren.
- CI-Workflow und Tests hinzufügen.
- Formatprüfung mit Biome hinzufügen.
- Sektion Progressive Refinement zur Startseite hinzufügen.
- Blog-Bereich mit SEO-Unterstützung und erstem Blogbeitrag hinzufügen.
- CLI-Ausgabe mit rechtsausgerichtetem Verb-Format vereinheitlichen.
- CLI-Ausgabe mit reichhaltigerer Nachrichtenformatierung farbig gestalten.
- Quadratisches OG-Bild und Twitter-Karten-Meta-Tags hinzufügen.
- Machen Sie den Koordinator-Agenten autonom mit Werkzeugnutzung.
- Neuschreiben `glossia init` mit dem Agent Client Protocol (ACP).
- Fügen Sie Gemini-Support, automatische Validierung, Token-Tracking und Verbesserungen der Zuverlässigkeit hinzu.

#### Refaktorings

- Teilen Sie CI in getrennte format, typecheck, test, build-Jobs auf.
- CLI von TypeScript/Bun in Rust umschreiben.