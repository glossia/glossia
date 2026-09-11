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

#### Fehlerbehebungen

- Umbenennung der Binärdatei in Release-Archiven von plattformspezifischem Namen zu nur `glossia`.
- Entfernung von macOS Quarantäne-xattr aus Binärdateien vor dem Verpacken.

## 0.14.0

*2026-02-14*

#### Funktionen

- Hinzufügen eines lokalen Release-Skripts und eines manuell gepflegten Changelog-Workflows.

## 0.2.0

*2026-02-14*

#### Fehlerbehebungen

- OAuth-Anbieterkonfiguration im Produktionsbetrieb optional gestalten. Die App sollte auch dann starten, wenn keine GitHub/GitLab OAuth-Zugangsdaten gesetzt sind. Konfigurieren Sie Anbieter nur, wenn die Umgebungsvariablen vorhanden sind.
- Verwenden Sie für die Produktion den Standardwert Port 4000 und behalten Sie 4050 für die Entwicklung bei. Der Produktionsproxy erwartet die App auf Port 4000. Der `runtime.exs` Standard war 4050, was dazu führte, dass die Health-Checks während der Bereitstellung fehlschlugen.

#### Neuheiten

- Hinzufügen einer Phoenix-App mit OAuth-Anmeldung, Dokumentationsverbesserungen und UI-Verbesserungen.
- Verwendung des abgerundeten Logos als Favicon.
- Migration der CLI zu Bun und Aktualisierung der CI-ausführbaren Builds.

## 0.1.0

*2026-02-12*

#### Fehlerbehebungen

- Vermeidung des horizontalen Code-Snippet-Überlaufs auf mobilen Geräten.
- Füge Code-Snippets auf mobilen Geräten einen angemessenen rechten Rand hinzu.
- Verbessere das mobile Layout, um horizontalen Überlauf zu verhindern.
- Wende biome-Formatierung an.
- Füge Gruppenüberschriften in die Release-Notes-Vorlage ein.
- Aktualisiere den Übersetzungsworkflow von Bun zu Rust.
- Richte den Post-Body mit dem Hero-Layout aus und verbessere die Blog-Beiträge.
- Zentriere den Blog-Beitragsinhalt horizontal.
- Behebe Panik beim Kürzen mehrbyte UTF-8-Werkzeugergebnisse.

#### Funktionen

- First-Party-Tools und Website-Sektion hinzufügen.
- Tool-Verifizierungsschritte sichtbar machen.
- Fortschrittsausgabe vereinfachen.
- Fortschrittszeilen färben.
- Übersetzungs- und Validierungsaktivität anzeigen.
- Tool-Zeilen formatieren.
- Website mit Mobile-Menü und mehrstufigem Layout responsiv gestalten.
- CLI in Bun/TypeScript neuimplementieren.
- CI-Workflow und Tests hinzufügen.
- Formatprüfung mit Biome hinzufügen.
- Abschnitt Progressive Verfeinerung zur Startseite hinzufügen.
- Blog-Bereich mit SEO-Unterstützung und einem ersten Blogbeitrag hinzufügen.
- CLI-Ausgabe mit rechtsbündigem Verb-Format vereinheitlichen.
- CLI-Ausgabe mit reicherer Nachrichtenformatierung farbig gestalten.
- Quadratisches OG-Bild und Twitter-Karten-Meta-Tags hinzufügen.
- Machen Sie den Koordinierungs-Agenten agentisch mit Werkzeugnutzung.
- Neuschreiben `glossia init` mit dem Agent-Client-Protokoll (ACP).
- Hinzufügen von Unterstützung für Gemini, automatische Validierung, Token-Nachverfolgung und Zuverlässigkeitsverbesserungen.

#### Refaktorisierung

- Aufteilen von CI in separate Jobs für Formatierung, Typüberprüfung, Tests und Build.
- Neuschreiben der CLI von TypeScript/Bun nach Rust.