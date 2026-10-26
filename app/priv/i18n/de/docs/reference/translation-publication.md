%{
  title: "Veröffentlichung der Übersetzung",
  summary: "Pull-Request-Wiederverwendung, Batching und das projektweite Push-Limit.",
  category: "Referenz",
  section: "translation",
  order: 10
}
---

Glossia führt pro Projekt genau einen offenen Übersetzungs-Pull-Request. Neue Commits auf dem Standard-Zweig aktualisieren stets denselben Zweig, statt für jeden Quell-Commit einen separaten Pull-Request zu eröffnen. Ein neuer Pull-Request wird erstellt, wenn der vorherige verbunden oder geschlossen wurde.

Veröffentlichung und Sitzungsersatz teilen sich eine durch eine Datenbank unterlegte Projektsperrung, auch wenn sie auf verschiedenen Anwendungsreplikaten oder losgelösten Runnern ausgeführt werden. Erstellt ein Runner einen Pull-Request, konnte dessen Metadaten jedoch nicht gespeichert werden, stellt die nachfolgende Veröffentlichung den offenen Glossia-Pull-Request aus GitHub wieder her, bevor sie einen anderen erstellt. Ein offener Pull-Request wird nicht verworfen, wenn sein Zweig mit dem Quellcode kollidiert oder die Quellgeschichte umgeschrieben wird: Die Sitzung schlägt fehl und behält die bestehende Veröffentlichung zur Lösung.

## Push-Limit

Das Limit ist **4 Pushes pro Stunde pro Projekt** festgesetzt, gemeinsam genutzt über Sitzungen und Repliken. Es ist zurzeit nicht konfigurierbar.

Pushes sind gleichmäßig verteilt und werden nicht in festen Stundenzeitfenstern gezählt. Zweig-Updates liegen minimal 15 Minuten auseinander. Das nächste Intervall beginnt, wenn ein Veröffentlichungsversuch abgeschlossen ist, sodass ein langsamer Batch nicht sofort von einem schnellen gefolgt werden kann. Quellzweig-Merges, Zwischengruppen, Wiederholungen und Abschlüsse teilen sich das gleiche Budget. Mehrdeutige fehlgeschlagene Versuche verbrauchen ebenfalls ein Slot, da GitHub den Zweig möglicherweise weiterentwickelt hat, bevor die Verbindung fehlgeschlagen ist. Das Budget wird in PostgreSQL gespeichert und wird durch eine neue Sitzung oder Prozessneustart nicht zurückgesetzt.

## Batching

Ein Durchlauf sammelt geprüfte Dateiänderungen und fordert Veröffentlichung an, sobald 25 Dateien oder 15 Minuten vergangen sind. Diese Schwellenwerte umgehen das Push-Limit nicht. Während einer Abkühlphase fügen weitere abgeschlossene Dateien dem ausstehenden Batch hinzu; wiederholte Änderungen am gleichen Pfad bewahren den neuesten Inhalt.

Am Ende des Durchlaufs wartet der Abschluss auf dasselbe Budget. Die Sitzung bleibt aktiv und sendet Pings, während sie wartet. Sie überprüft regelmäßig Absage und Zulassung, ohne im Ruhezustand eine Datenbanktransaktion offen zu halten.
