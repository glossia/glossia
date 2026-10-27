%{
  title: "Veröffentlichung von Übersetzungen",
  summary:
    "Wiederverwendung von Pull-Requests, Bündelung und die Push-Obergrenze für das gesamte Projekt.",
  category: "Referenz",
  section: "translation",
  order: 10
}
---

Glossia hält pro Projekt eine offene Übersetzungs-Pull Request bereit. Neue Commits auf dem Hauptzweig setzen den Zweig fort anstatt einen Pull-Request für jeden Quell-Commit zu öffnen. Ein neuer Pull-Request wird erstellt, nachdem der vorherige zusammengeführt oder geschlossen wurde. Eine abgeschlossene Veröffentlichung erhält einen frischen Zweignamen, auch wenn derselbe Quell-Commit erneut versucht wird; ihre abgelehnten Ausgaben werden nicht als abgeschlossene Arbeit wieder verwendet.

Die Quellsynchronisation erfolgt vor der Bewertung in einem wegschmeissbaren lokalen Checkout, wobei die abgeschlossenen Übersetzungen und Sperrdateien des offenen Zweigs erhalten bleiben. Ein Durchlauf, der keine Ausgaben oder Sperrdatei-Änderungen findet, schreitet den Remote-Zweig nicht weiter, um mit dem Standardzweig aufzuholen, und verbraucht keinen Veröffentlichungs-Platz. Wenn ein Batch bereit ist, werden die Quellsynchronisation und die validierten Änderungen in einer einzigen nicht erzwungenen Zweig-Update gemeinsam veröffentlicht. Der Commit behält sowohl die vorherige Veröffentlichung als auch den bewerteten Quell-Commit als Vorfahren.

Veröffentlichung und Session-Ersatz teilen sich eine datenbankgestützte Projektsperre, auch wenn sie auf unterschiedlichen Anwendungsrepliken oder detached Runnern ausgeführt werden. Wenn ein Runner eine Pull-Request erstellt hat, aber seine Metadaten nicht speichern konnte, stellt die nächste Veröffentlichung die offene Glossia-Pull-Request aus GitHub wieder her, bevor eine neue erstellt wird. Eine offene Pull-Request wird nicht aufgegeben, wenn ihr Zweig mit der Quelle konfl or die Quellen historii umgeschrieben wird: die Session versagt und behält die bestehende Veröffentlichung zur Klärung.

## Push-Limit

Das Limit ist **4 Pushes pro Stunde pro Projekt** festgelegt, wird auf Sitzungen und Repliken verteilt. Es ist derzeit nicht konfigurierbar.

Pushes sind gleichmäßig verteilt, nicht in feste Uhrenstunde-Boxen eingefügt. Zweig-Updates liegen mindestens 15 Minuten auseinander. Das nächste Intervall startet, wenn ein Veröffentlichungs-Versuch abgeschlossen ist, so dass ein langsames Batch nicht sofort von einem schnellen gefolgt werden kann. Zwischen-Batches, Neuversuche und finale Flushes teilen sich alle dasselbe Budget. Zweideutige gescheiterte Versuche verbrauchen ebenfalls einen Slot, weil GitHub den Zweig möglicherweise vor einem Verbindungs-Error advance hat. Das Budget wird in PostgreSQL gespeichert und nicht durch eine neue Session oder Prozess-Neustart zurückgesetzt.

Bevor veröffentlicht wird, liest Glossia den Remote-Head erneut und fusioniert die Quellcode der Session lokal erneut. Dies bewahrt frühere Batches und erkennt Konflikte ohne den Zweig zu verschieben. Wenn ein frühes Update erfolgreich war, aber seine Antwort verloren ging, werden bereits vorhandene Änderungen nicht erneut commited; Veröffentlichungsmetadaten und der Pull-Request werden ohne weiteren Zweig-Update wiederhergestellt. Wenn der Ref erstellt wurde, aber der Runner vor der Erstellung seiner Pull-Request stoppte, erstellt eine kein-Änderungs-Bewertung dennoch den fehlenden Pull-Request, ohne einen Zweig-Update-Slot zu verbrauchen.

Ein unerwarteter Remote-Advancement wird nur akzeptiert, wenn seine Unterschiede von der synchronisierten erwarteten Struktur bereits vorhandene Teile des ausstehenden Batches sind. Andere Änderungen, die während der Bewertung vorgenommen wurden, führen zu Veröffentlichungsfehlern statt überschrieben zu werden oder Übersetzungen zu veröffentlichen, die gegen veraltete Eingaben überprüft wurden. Der bestehende Pull-Request wird zur Klärung beibehalten.

## Batching

Ein Durchlauf sammelt validierte Datei-Änderungen und bittet um Veröffentlichung nach 25 Dateien oder 15 Minuten. Diese Schwellenwerte umgehen das Push-Limit nicht. Während einer Abkühlphase schließen sich zusätzliche abgeschlossene Dateien dem pending Batch an; wiederholte Änderungen zum gleichen Pfad behalten den neuesten Inhalt.

Am Ende des Durchlaufs wartet der finale Flush auf das gleiche Budget. Die Session bleibt aktiv und sendet Herzschläge, während sie wartet. Sie prüft periodisch Stornierung und Zulassung, ohne eine Datenbank-Transaktion offen zu halten, während sie schläft.
