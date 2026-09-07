%{
  title: "Versionen",
  summary: "Historie der CLI-Veröffentlichungen.",
  category: "Referenz",
  subcategory: "CLI",
  order: 2
}
---
## 0.14.1

*2026-02-14*

#### Fehlerbehebungen

- Umbenennen der Binärdatei in den Releasearchiven vom plattformspezifischen Namen zu bloß `glossia`.
- Entfernen der macOS-Quarantäne-xattr aus den Binärdateien vor der Verpackung.

## 0.14.0

*2026-02-14*

#### Neue Funktionen

- Hinzufügen eines lokalen Release-Skripts und eines manuell gepflegten Changelog-Workflows.

## 0.2.0

*2026-02-14*

#### Fehlerbehebungen

- Machen Sie die OAuth-Provider-Konfiguration in der Produktion optional. Die App sollte auch ohne GitHub/GitLab OAuth-Credentials starten. Konfigurieren Sie Provider nur, wenn die Umgebungsvariablen vorhanden sind.
- Setzen Sie für die Produktion standardmäßig den Port 4000 und behalten Sie 4050 für die Entwicklung bei. Der Produktionsproxy erwartet die App am Port 4000. Der `runtime.exs` Standardwert war 4050, was zu fehlgeschlagenen Health Checks während der Bereitstellung führte.

#### Funktionen

- Hinzufügen einer Phoenix-App mit OAuth-Login, Verbesserungen der Dokumentation und UI-Verbesserungen.
- Verwenden Sie das abgerundete Logo als Favicon.
- CLI in Bun migrieren und CI-ausführbare Builds aktualisieren.

## 0.1.0

*2026-02-12*

#### Fehlerbehebungen

- Verhindern Sie horizontalen Überlauf bei Codeausschnitten auf mobilen Geräten.
- Füge Codeabschnitten auf mobilen Geräten einen passenden rechten Rand hinzu.
- Verbessere das responsive Layout für mobile Geräte, um horizontalen Überlauf zu verhindern.
- Wende biome-Formatierung an.
- Füge Gruppenüberschriften zur Release-Notes-Vorlage hinzu.
- Aktualisiere den Übersetzungsworkflow von Bun auf Rust.
- Richte den Beitragsinhalt mit dem Hero-Layout aus und verbessere Blog-Beiträge.
- Zentriere den Blog-Beitragsinhalt horizontal.
- Behebe Panic beim Abschneiden mehrbyte UTF-8 Tool-Ergebnisse.

#### Funktionen

- Füge die Sektion für eigene Tools und Website hinzu.
- Stelle Tool-Verifizierungsschritte hervor.
- Vereinfache die Fortschrittsausgabe.
- Fortschrittslinien einfärben.
- Übersetzungs- und Validierungsaktivitäten anzeigen.
- Werkzeuglinien formatieren.
- Website responsiv gestalten mit Mobile-Menü und Multi-Breakpoint-Layout.
- CLI in Bun/TypeScript neu implementieren.
- CI-Workflow und Tests hinzufügen.
- Formatprüfung mit Biome hinzufügen.
- Progressive-Verfeinerungssektion zur Startseite hinzufügen.
- Blog-Bereich mit SEO-Unterstützung und erstem Beitrag hinzufügen.
- CLI-Ausgabe auf rechtsausgerichtetes Verb-Format vereinheitlichen.
- CLI-Ausgabe mit reichhaltigerer Nachrichtenformatierung farbig gestalten.
- Quadratische OG-Bilder und Twitter-Card-Meta-Tags hinzufügen.
- Koordinations-Agent mit Werkzeugnutzung agentisch machen.
- Umschreiben `glossia init` mit Agent Client Protocol (ACP).
- Gemini-Unterstützung, automatische Validierung, Tokenverfolgung und Zuverlässigkeitsverbesserungen hinzufügen.

#### Refaktorisierungen

- CI in getrennte Format-, Typenprüfungs-, Test- und Build-Jobs aufteilen.
- CLI von TypeScript/Bun nach Rust umschreiben.