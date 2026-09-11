%{
  title: "Versionen",
  summary: "Versionsverlauf der CLI.",
  category: "Referenz",
  subcategory: "CLI",
  order: 2
}
---
## 0.14.1

*2026-02-14*

#### Fehlerbehebungen

- Umbenennung der Binärdatei in Release-Archiven vom plattformspezifischen Namen auf nur `glossia`.
- Entfernung der macOS Quarantäne-xattr aus Binärdateien vor der Paketierung.

## 0.14.0

*2026-02-14*

#### Funktionen

- Lokales Release-Skript und manuell verwalteten Changelog-Workflow hinzufügen.

## 0.2.0

*2026-02-14*

#### Fehlerbehebungen

- Machen Sie die OAuth-Anbieterkonfiguration in der Produktion optional. Die App sollte auch ohne GitHub/GitLab OAuth-Anmeldedaten starten. Konfigurieren Sie Anbieter nur, wenn die Umgebungsvariablen vorhanden sind.
- Port 4000 standardmäßig für die Produktion und 4050 für die Entwicklung verwenden. Der Produktions-Proxy erwartet die App am Port 4000. Der `runtime.exs` Stztandwert war 4050, was dazu führte, dass Health-Checks während des Deployments fehlgeschlagen.

#### Funktionen

- Phoenix-App hinzufügen mit OAuth-Anmeldung, Dokumentationsverbesserungen und UI-Verbesserungen.
- Abgerundetes Logo als Favicon verwenden.
- CLI in Bun migrieren und CI-Executable-Builds aktualisieren.

## 0.1.0

*2026-02-12*

#### Fehlerbehebungen

- Horizontalen Überlauf von Code-Snippets auf Mobilgeräten verhindern.
- Fügen Sie einen angemessenen rechten Rand für Code-Snippets auf mobilen Geräten hinzu.
- Verbessern Sie das mobile responsive Layout, um horizontalen Überlauf zu verhindern.
- Wenden Sie biome-Formatierung an.
- Fügen Sie Gruppenüberschriften zur Release-Notes-Vorlage hinzu.
- Aktualisieren Sie den Übersetzungs-Workflow von Bun auf Rust.
- Richten Sie den Postbody am Hero-Layout aus und verbessern Sie den Blog-Beitrag.
- Zentrieren Sie den Blog-Beitrag-Inhalt horizontal.
- Beheben Sie den Panic beim Kürzen Multi-Byte UTF-8-Werkzeug-Ergebnisse.

#### Funktionen

- eigene Tools und Website-Sektion hinzufügen.
- Tool-Verifikations-Schritte aufzeigen.
- Fortschrittsausgabe vereinfachen.
- Fortschrittslinien einfärben.
- Übersetzungs- und Validierungstätigkeit anzeigen.
- Werkzeugzeilen formatieren.
- Website responsive gestalten mit Mobile-Menü und mehrstufigem Breakpoint-Layout.
- CLI in Bun/TypeScript neuimplementieren.
- CI-Workflow und Tests hinzufügen.
- Formatprüfung mit Biome hinzufügen.
- Abschnitt schrittweise Verfeinerung zur Homepage hinzufügen.
- Blog-Sektion mit SEO-Unterstützung und erstem Blogbeitrag hinzufügen.
- CLI-Ausgabe mit rechtsausgerichtetem Verbformat vereinheitlichen.
- CLI-Ausgabe mit verbesserter Nachrichtenformatierung farblich anpassen.
- Quadratisches OG-Bild und Twitter-Karten-Meta-Tags hinzufügen.
- Den Koordinator-Agenten agentic machen mittels Tool-Nutzung.
- Umschreiben `glossia init` mit Agent Client Protocol (ACP).
- Gemini-Support, automatische Validierung, Tokenverfolgung und Zuverlässigkeitsverbesserungen hinzufügen.

#### Refaktorisierung

- CI in getrennte Formatierungs-, Typenprüfungs-, Test- und Build-Jobs aufteilen.
- CLI von TypeScript/Bun zu Rust neu schreiben.