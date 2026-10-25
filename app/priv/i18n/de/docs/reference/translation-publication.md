%{
  title: "Übersetzungsveröffentlichung",
  summary: "Wiederverwendung von Pull-Requests, Bündelung und das projektweite Push-Limit.",
  category: "Referenz",
  section: "translation",
  order: 10
}
---

Glossia verwaltet pro Projekt genau einen offenen Übersetzungspull-Request. Neue Commits des Hauptzweigs setzen diesen fort, statt für jeden Quellcommit einen Pull-Request zu erstellen. Ein neuer Pull-Request wird erstellt, nachdem der vorherige zusammengeführt oder geschlossen wurde.

Veröffentlichung und Sitzungsersatz teilen sich eine datenbankgestützte Projektsperre, auch wenn sie auf unterschiedlichen Anwendungsreplikaten oder getrennten Runnern ausgeführt werden. Wenn ein Runner einen Pull-Request erstellt hat, aber seine Metadaten nicht speichern konnte, holt die nächste Veröffentlichung den offenen Glossia-Pull-Request von GitHub ab, bevor sie eine andere erstellt. Ein offener Pull-Request wird nicht aufgegeben, wenn sein Zweig mit der Quelle kollidiert oder die Quellverlauf neu geschrieben wird: die Sitzung scheitert und behält die bestehende Veröffentlichung zur Beilegung.

## Push-Limit

Das Limit ist auf **4 Pushes pro Stunde pro Projekt** festgelegt, geteilt über Sitzungen und Replika. Es ist derzeit nicht konfigurierbar.

Pushes sind gleichmäßig verteilt und werden nicht in festen Zeitfenstern gezählt. Zweigaktualisierungen liegen mindestens 15 Minuten auseinander. Das nächste Intervall beginnt, sobald ein Veröffentlichungsversuch abgeschlossen ist, sodass ein langsames Batch nicht sofort von einem schnellen gefolgt werden kann. Quellzweig-Merges, Zwischenbatches, Wiederholungen und End-Flushes teilen sich das gleiche Budget. Auch mehrdeutige fehlgeschlagene Versuche verbrauchen einen Slot, da GitHub den Zweig möglicherweise weiter vorangeschritten sein könnte, bevor die Verbindung fehlgeschlagen ist. Das Budget wird in PostgreSQL gespeichert und wird durch eine neue Sitzung oder einen Prozessneustart nicht zurückgesetzt.

## Batching

Ein Lauf sammelt validierte Dateiänderungen und fordert die Veröffentlichung an, nachdem 25 Dateien oder 15 Minuten vergangen sind. Diese Schwellwerte umgehen das Push-Limit nicht. Während eines Cooldowns werden zusätzliche abgeschlossene Dateien dem ausstehenden Batch hinzugefügt; wiederholte Änderungen am gleichen Pfad behalten den neuesten Inhalt bei.

Am Ende des Laufs wartet der finale Flush auf das gleiche Budget. Die Sitzung bleibt aktiv und sendet Heartbeats, während sie wartet. Sie prüft Stornierung und Zulassung periodisch, ohne während des Wartens eine Datenbank-Transaktion offen zu halten.
