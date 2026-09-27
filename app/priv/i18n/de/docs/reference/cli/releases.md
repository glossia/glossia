%{
  title: "Versionen",
  summary: "Geschichte der CLI-Versionen.",
  category: "Referenz",
  subcategory: "CLI",
  order: 2
}
---
## 0.14.1

*2026-02-14*

#### Fehlerbehebungen

- Binärdatei in Release-Archiven vom plattformspezifischen Namen auf nur umbenennen `glossia`.
- macOS-Quarantäne-xattr aus Binärdateien vor der Verpackung entfernen.

## 0.14.0

*2026-02-14*

#### Funktionen

- Hinzufügen lokaler Release-Skripte und eines manuell gepflegten Changelog-Workflows.

## 0.2.0

*2026-02-14*

#### Fehlerbehebungen

- Machen Sie die OAuth-Anbieter-Konfiguration in der Produktion optional. Die Anwendung sollte auch ohne konfigurierte GitHub/GitLab OAuth-Anmeldedaten starten. Konfigurieren Sie Anbieter nur, wenn die entsprechenden Umgebungsvariablen gesetzt sind.
- Port 4000 als Standardwert für die Produktion verwenden und 4050 für die Entwicklung beibehalten. Der Produktions-Proxy erwartet die Anwendung auf Port 4000. Der `runtime.exs` Standardwert war 4050, was dazu führte, dass Healthchecks während der Bereitstellung fehlgeschlagen.

#### Funktionen

- Hinzufügen einer Phoenix-App mit OAuth-Anmeldung, Dokumentationsverbesserungen und UI-Verbesserungen.
- Verwendung des abgerundeten Logos als Favicon.
- Migration der CLI auf Bun und Aktualisierung der CI-ausführbaren Builds.

## 0.1.0

*2026-02-12*

#### Fehlerbehebungen

- Verhindern des horizontalen Überlaufs von Code-Snippets auf Mobilgeräten.
- Codeausschnitten auf Mobilgeräten einen passenden rechten Rand hinzufügen.
- Das mobile responsive Layout verbessern, um horizontalen Überlauf zu verhindern.
- Biome-Formatierung anwenden.
- Gruppentitel zur Release-Notizen-Vorlage hinzufügen.
- Übersetzungs-Workflow von Bun zu Rust aktualisieren.
- Beitragstext dem Hero-Layout anpassen und Blog-Inhalt verbessern.
- Blog-Inhalt horizontal zentrieren.
- Panik beim Kürzen mehbyte UTF-8-Werkzeugergebnisse beheben.

#### Funktionen

- Hinzufügen von First-Party-Werkzeugen und Website-Sektion.
- Werkzeug-Verifizierungsschritte aufzeigen.
- Fortschrittsausgabe vereinfachen.
- Fortschrittszeilen einfärben.
- Übersetzungs- und Validierungsaktivität anzeigen.
- Werkzeugzeilen formatieren.
- Website responsiv gestalten mit Mobile-Menü und Multi-Breakpoint-Layout.
- CLI in Bun/TypeScript neuimplementieren.
- CI-Workflow und Tests hinzufügen.
- Formatprüfung mit Biome hinzufügen.
- Sektion Progressive Verfeinerung auf der Startseite hinzufügen.
- Blog-Sektion mit SEO-Unterstützung und erstem Blogbeitrag hinzufügen.
- CLI-Ausgabe mit rechtsbündigem Verbformat vereinheitlichen.
- CLI-Ausgabe mit umfangreicheren Nachrichtenformatierung farblich gestalten.
- Quadratisches OG-Bild und Twitter-Karten-Meta-Tags hinzufügen.
- Machen Sie den Koordinationsagenten autonom durch Werkzeugnutzung.
- Umschreiben `glossia init` mit dem Agenten-Client-Protokoll (ACP).
- Fügen Sie Unterstützung für Gemini, automatische Validierung, Tokenverfolgung und Zuverlässigkeitsverbesserungen hinzu.

#### Refaktorisierungen

- Aufteilung der CI in getrennte Format-, Typecheck-, Test- und Build-Jobs.
- Umschreiben der CLI von TypeScript/Bun nach Rust.