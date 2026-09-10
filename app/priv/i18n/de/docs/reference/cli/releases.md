%{
  title: "Veröffentlichungen",
  summary: "CLI Release-Verlauf.",
  category: "Referenz",
  subcategory: "cli",
  order: 2
}
---
## 0.14.1

*2026-02-14*

#### Bugfixes

- Umbenennen der Binary in Release-Archiven vom plattformspezifischen Namen auf `glossia`.
- Entfernen der macOS-Quarantäne-xattr aus Binaries vor der Verpackung.

## 0.14.0

*2026-02-14*

#### Funktionen

- Hinzufügen lokaler Release-Skripte und eines manuell gepflegten Changelog-Arbeitsablaufs.

## 0.2.0

*2026-02-14*

#### Fehlerbehebungen

- Machen Sie die OAuth-Anbieterkonfiguration in der Produktion optional. Die App startet auch ohne GitHub/GitLab OAuth-Credentials. Objekte nur konfigurieren, wenn Umgebungsvariablen gesetzt sind.
- Verwenden Sie standardmäßig Port 4000 für die Produktion und behalten Sie 4050 für die Entwicklung bei. Der Produktions-Proxy erwartet die App auf Port 4000. Der `runtime.exs` Standardwert war 4050, was die Health Checks während der Bereitstellung fehlschlagen ließ.

#### Funktionen

- Phoenix-App mit OAuth-Anmeldung, Dokumentationsverbesserungen und UI-Verbesserungen hinzufügen.
- Rundes Logo als Favicon verwenden.
- CLI auf Bun migrieren und CI-ausführbare Builds aktualisieren.

## 0.1.0

*2026-02-12*

#### Fehlerbehebungen

- Verhindern horizontalen Überlauf von Code-Snippets auf Mobilgeräten.
- Fügen Sie eine angemessene Rechtsmarge für Codeausschnitte auf mobilen Geräten hinzu.
- Verbessern Sie das mobile-responsive Layout, um horizontalen Überlauf zu verhindern.
- Wenden Sie Biome-Formatierung an.
- Fügen Sie Gruppenüberschriften in die Release-Notes-Vorlage ein.
- Aktualisieren Sie den Übersetzungs-Workflow von Bun auf Rust.
- Richten Sie den Beitragstext am Hero-Layout aus und verbessern Sie die Blogbeitragsinhalte.
- Zentrieren Sie den Blogbeitragsinhalt horizontal.
- Beheben Sie den Panic beim Kürzen mehrbyte UTF-8-Werkzeugergebnisse.

#### Funktionen

- Hinzufügen von first-party-Tools und Website-Abschnitt.
- Hervorheben der Tool-Verifizierungsschritte.
- Vereinfachung der Fortschrittsausgabe.
- Farbgebung der Fortschrittslinien.
- Anzeige von Übersetzungs- und Validierungsaktivitäten.
- Formatierung der Toolzeilen.
- Responsive Gestaltung der Website mit Mobile-Menu und Multi-Breakpoint-Layout.
- CLI in Bun/TypeScript neuimplementieren.
- CI-Workflow und Tests hinzufügen.
- Formatprüfung mit Biome hinzufügen.
- Abschnitt Progressive Verfeinerung zur Homepage hinzufügen.
- Blog-Bereich mit SEO-Unterstützung und erstem Blogbeitrag hinzufügen.
- CLI-Ausgabe mit rechtsbündigem Verb-Format vereinheitlichen.
- CLI-Ausgabe mit reicherer Nachrichtenformatierung einfärben.
- Quadratisches OG-Bild und Twitter-Card-Metatags hinzufügen.
- Koordinierungs-Agenten autonom machen mit Werkzeugnutzung.
- Neuschreiben. `glossia init` mit Agent Client Protocol (ACP).
- Hinzufügen von Gemini-Unterstützung, automatischer Validierung, Token-Tracking und Zuverlässigkeitsverbesserungen.

#### Refaktorisierungen.

- CI in getrennte Format-, Typecheck-, Test- und Build-Jobs aufteilen.
- CLI von TypeScript/Bun zu Rust umschreiben.