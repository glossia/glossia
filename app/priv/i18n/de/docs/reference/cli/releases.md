%{
  title: "Veröffentlichungen",
  summary: "Veröffentlichungsgeschichte der CLI.",
  category: "Referenz",
  subcategory: "CLI",
  order: 2
}
---
## 0.14.1

*2026-02-14*

#### Fehlerbehebungen

- Umbenennen der Binärdatei in Release-Archiven vom plattformspezifischen Namen auf `glossia`.
- Entfernen der macOS Quarantäne-xattr aus Binärdateien vor der Verpackung.

## 0.14.0

*2026-02-14*

#### Funktionen

- Lokales Release-Skript und manuell gepflegtes Changelog-Workflow hinzufügen.

## 0.2.0

*2026-02-14*

#### Fehlerbehebungen

- OAuth-Provider-Konfiguration in der Produktion optional machen. Die App sollte auch ohne GitHub/GitLab OAuth-Credentials starten. Nur Provider bei Vorhandensein der Umgebungsvariablen konfigurieren.
- Standardmäßig Port 4000 für Produktion verwenden und 4050 für Entwicklung behalten. Der Produktions-Proxy erwartet die App auf Port 4000. Die `runtime.exs` der Standardwert war 4050, was Health Checks während des Deployments zum Scheitern brachte.

#### Funktionen

- Hinzufügen einer Phoenix-App mit OAuth-Login, Dokumentationsverbesserungen und UI-Verbesserungen.
- Verwendung des gerundeten Logos als Favicon.
- CLI auf Bun migrieren und CI-ausführbare Builds aktualisieren.

## 0.1.0

*2026-02-12*

#### Fehlerkorrekturen

- Horizontalen Überlauf von Codeauschnitten auf mobilen Geräten verhindern.
- Fügen Sie auf mobilen Geräten einen passenden rechten Rand für Codeauszüge hinzu.
- Verbessern Sie das responsive mobile Layout, um horizontalen Überlauf zu verhindern.
- biome-Formatierung anwenden.
- Fügen Sie Gruppenüberschriften in die Release-Notes-Vorlage hinzu.
- Aktualisieren Sie den Übersetzungs-Workflow von Bun zu Rust.
- Beitragstext mit Hero-Layout ausrichten und Blog-Inhalt verbessern.
- Blogbeitrag-Inhalt horizontal zentrieren.
- Panic beim Abschneiden von Mehrzeichen-UTF-8-Tool-Ergebnissen beheben.

#### Funktionen

- Hinzufügen von First-Party-Tools und Website-Sektion.
- Tool-Validierungsschritte sichtbar machen.
- Fortschrittsausgabe vereinfachen.
- Fortschrittszeilen einfärben.
- Anzeige der Übersetzungs- und Validierungsaktivität.
- Toolzeilen formatieren.
- Website responsive gestalten mit mobilem Menü und Multi-Breakpoint-Layout.
- CLI in Bun/TypeScript neu implementieren.
- CI-Workflow und Tests hinzufügen.
- Formatprüfung mit Biome hinzufügen.
- Abschnitt Progressive Verfeinerung zur Startseite hinzufügen.
- Blog-Abschnitt mit SEO-Unterstützung und erstem Blogbeitrag hinzufügen.
- CLI-Ausgabe mit rechtsbündigem Verbformat vereinheitlichen.
- CLI-Ausgabe mit reichhaltigerer Nachrichtenformatierung farbig gestalten.
- quadratisches OG-Bild und Twitter-Card-Meta-Tags hinzufügen.
- Machen Sie den Koordinator-Agenten autonom mit Werkzeugnutzung.
- Umschreiben `glossia init` mit dem Agenten-Client-Protokoll (ACP).
- Hinzufügen von Gemini-Support, automatischer Validierung, Tokenverfolgung und Zuverlässigkeitsverbesserungen.

#### Refaktorisierung

- Aufteilung von CI in separate Format-, Typcheck-, Test- und Build-Jobs.
- CLI von TypeScript/Bun in Rust umschreiben.