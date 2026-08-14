%{
  title: "Releases",
  summary: "Release-Historie des CLI.",
  category: "reference",
  subcategory: "cli",
  order: 2
}
---
## 0.14.1

*2026-02-14*

#### Fehlerbehebungen
- Umbenennung der Binärdatei innerhalb der Release-Archive von einem plattformspezifischen Namen in einfach `glossia`.
- Entfernen des macOS-Quarantäne-Attributs (xattr) von Binärdateien vor dem Paketieren.

## 0.14.0

*2026-02-14*

#### Funktionen
- Hinzufügen eines lokalen Release-Skripts und eines manuell gepflegten Changelog-Workflows.

## 0.2.0

*2026-02-14*

#### Fehlerbehebungen
- Optionale Konfiguration von OAuth-Anbietern in der Produktionsumgebung. Die Anwendung sollte auch ohne festgelegte GitHub/GitLab-OAuth-Anmeldedaten starten. Anbieter werden nur konfiguriert, wenn die entsprechenden Umgebungsvariablen vorhanden sind.
- Standardmäßige Verwendung von Port 4000 für die Produktion und Beibehaltung von Port 4050 für die Entwicklung. Der Produktions-Proxy erwartet die Anwendung auf Port 4000. Der Standardwert von `runtime.exs` war 4050, was zu Fehlern bei den Health-Checks während des Deployments führte.

#### Funktionen
- Hinzufügen der Phoenix-Anwendung mit OAuth-Login, Erweiterungen der Dokumentation und UI-Verbesserungen.
- Verwendung des abgerundeten Logos als Favicon.
- Migration der CLI zu Bun und Aktualisierung der ausführbaren CI-Builds.

## 0.1.0

*2026-02-12*

#### Fehlerbehebungen
- Verhindern von horizontalem Textüberlauf bei Code-Snippets auf Mobilgeräten.
- Hinzufügen eines angemessenen rechten Rands bei Code-Snippets auf Mobilgeräten.
- Verbesserung des responsiven Layouts für Mobilgeräte zur Vermeidung von horizontalem Überlauf.
- Anwendung der Biome-Formatierung.
- Hinzufügen von Gruppenüberschriften zur Vorlage für Release-Notes.
- Aktualisierung des Übersetzungsworkflows von Bun auf Rust.
- Ausrichtung des Beitrags-Bodys am Hero-Layout und Verbesserung des Inhalts von Blog-Beiträgen.
- Horizontale Zentrierung von Blog-Beitragsinhalten.
- Behebung eines Absturzes (Panic) beim Abschneiden von Multibyte-UTF-8-Tool-Ergebnissen.

#### Funktionen
- Hinzufügen von First-Party-Tools und eines Website-Bereichs.
- Sichtbarmachen der Schritte zur Tool-Verifizierung.
- Vereinfachung der Fortschrittsausgabe.
- Einfärben von Fortschrittszeilen.
- Anzeige von Übersetzungs- und Validierungsaktivitäten.
- Formatierung von Tool-Zeilen.
- Umsetzung einer responsiven Website mit mobilem Menü und Multi-Breakpoint-Layout.
- Neuimplementierung der CLI in Bun/TypeScript.
- Hinzufügen von CI-Workflow und Tests.
- Hinzufügen der Formatierungsprüfung mit Biome.
- Hinzufügen des Bereichs „Progressive Refinement“ zur Homepage.
- Hinzufügen eines Blog-Bereichs mit SEO-Unterstützung und des ersten Blog-Beitrags.
- Vereinheitlichung der CLI-Ausgabe mit rechtsbündigem Verb-Format.
- Einfärben der CLI-Ausgabe mit detaillierterer Nachrichtenformatierung.
- Hinzufügen eines quadratischen OG-Bildes und von Twitter-Card-Meta-Tags.
- Ausstatten des Koordinations-Agenten mit agentischen Fähigkeiten durch Tool-Nutzung.
- Neuschreiben von `glossia init` mit dem Agent Client Protocol (ACP).
- Hinzufügen von Gemini-Unterstützung, automatischer Validierung, Token-Tracking und Zuverlässigkeitsverbesserungen.

#### Refaktorierungen
- Aufteilung der CI in separate Jobs für Formatierung, Typprüfung, Tests und Build.
- Neuschreiben der CLI von TypeScript/Bun in Rust.