%{
  title: "Veröffentlichungen",
  summary: "Historie der CLI-Releases.",
  category: "Referenz",
  subcategory: "CLI",
  order: 2
}
---

## 0.14.1

*2026-02-14*

#### Bugfixes
- Benennen des Binaries in Release-Archiven von plattformspezifischem Namen auf nur `glossia` um.
- Quarantäne xattr von macOS aus Binaries entfernen, bevor verpackt wird.

## 0.14.0

*2026-02-14*

#### Funktionen
- Lokale Release-Skripte und manuell unterhaltene Changelog-Arbeitsablauf hinzufügen.

## 0.2.0

*2026-02-14*

#### Bugfixes
- Konfigurationsbewältigung des gehosteten login-provider einrichten.
- Gehostete Service-Gesundheitsüberwachung überprüfen.

#### Funktionen
- Phoenix-Anwendung mit OAuth-Login, Dokumentationserweiterungen und UI-Verbesserungen hinzufügen.
- Abgerundetes Logo als Favicon verwenden.
- CLI auf Bun migrieren und CI-ausführbare Builds aktualisieren.

## 0.1.0

*2026-02-12*

#### Bugfixes
- Horizontalen Überlauf von Codeausschnitten auf mobilen Geräten verhindern.
- Rechte Ränder für Codeausschnitte auf mobilen Geräten hinzufügen.
- Responsives mobiles Layout verbessern, um horizontalen Überlauf zu verhindern.
- Biome-Formatierung anwenden.
- Gruppenüberschriften zum Release-Notiz-Template hinzufügen.
- Translationsworkflow von Bun auf Rust aktualisieren.
- Inhaltskörper der Beiträge mit Hero-Layout ausrichten und Blog-Beiträge verbessern.
- Blog-Beiträge horizontal zentrieren.
- Panik beheben beim Abschneiden mehrbytes UTF-8-Werkzeugergebnisse.

#### Funktionen
- Eigene Tools und Website-Sektion hinzufügen.
- Werkzeugüberprüfungsschritte genauer machen.
- Fortschrittsausgabe vereinfachen.
- Fortschrittszeilen einfarbigen.
- Übersetzungs- und Validierungstätigkeit anzeigen.
- Werkzeugzeilen formatieren.
- Website responsiv machen mit mobiler Menü und mehrbreitlinien-Layout.
- CLI neu in Bun/TypeScript implementieren.
- CI-Arbeitsablauf und Tests hinzufügen.
- Formatprüfung mit Biome hinzufügen.
- Schrittverfeinerung-Sektion zur Startseite hinzufügen.
- Blog-Sektion mit SEO-Unterstützung und erstem Blogbeitrag hinzufügen.
- CLI-Ausgabe mit rechtsausgerichteten Verbformat vereinheitlichen.
- CLI-Ausgabe mit ausführlicherer Nachrichtenformatierung einfärbens.
- Quadratische OG-Bild und Twitter-Karte Meta-Tags hinzufügen.
- Koordinator-Agent agentisch mit Werkzeugmachen.
- `glossia init` mit Agent Client Protocol (ACP) umschreiben.
- Gemini-Unterstützung, automatische Validierung, Token-Tracking und Verbesserungen der Zuverlässigkeit hinzufügen.

#### Refaktorisierungen
- CI in getrennte Formatierungs-, Typüberprüfungs-, Test- und Build-Jobs aufteilen.
- CLI von TypeScript/Bun auf Rust umschreiben.
