%{
  title: "Elixir und Phoenix (Gettext)",
  summary:
    "Gettext-Übersetzungen konfigurieren, Katalogmetadaten beibehalten und Merge-Konflikte reduzieren.",
  category: "Anleitung",
  section: "ecosystems",
  order: 1
}
---

Verwenden Sie diesen Leitfaden, um eine bestehende Elixir- oder Phoenix-Anwendung mit [Gettext](https://hexdocs.pm/gettext/) an Glossia anzubinden und ihre Kataloge merge-friendly zu halten. Führen Sie Mix-Befehle aus dem Verzeichnis aus, das `mix.exs` enthält.

## 1. Konfigurieren Sie die deterministische Extraktion

Fügen Sie diese Optionen in Ihre bestehende `project/0`-Konfiguration in `mix.exs`:

```elixir
def project do
  [
    # Keep the application's other project options here.
    gettext: [
      write_reference_line_numbers: false,
      sort_by_msgid: :case_sensitive
    ]
  ]
end
```

Behalten Sie andere Gettext-Optionen bei, die Sie bereits verwenden. `sort_by_msgid: :case_sensitive` wird von der Gettext-Version unterstützt, die Glossia verwendet; überprüfen Sie die [Extraktionsoptionen](https://hexdocs.pm/gettext/Mix.Tasks.Gettext.Extract.html) Ihrer Abhängigkeit, wenn Sie dies auf ein anderes Projekt anwenden.

Regenerieren Sie die Templates und Locale-Dateien:

```sh
mix gettext.extract --merge
```

Prüfen Sie und übernehmen Sie diese einmalige Normalisierung getrennt von Änderungen an der Formulierung. Die Reihenfolge der Nachrichten sollte sich ändern, nicht bestehende Übersetzungen. Koordinieren Sie diese Normalisierung mit offenen Pull-Requests, damit ihre Kataloge auf dieselbe Reihenfolge aktualisiert werden können.

Bei Sortierung werden neue, unabhängige Nachrichten an ihren kanonischen Positionen platziert, statt jede neue Ergänzung an das Ende der Datei anzuhängen. Das Unterlassen von Referenz-Zeilenumbrüchen vermeidet unerwartete Änderungen, wenn sich Code verschiebt; Referenzen auf Quelldateien bleiben erhalten. Diese Optionen reduzieren Konflikte, eliminieren sie aber für dieselbe Nachricht nicht und garantieren, dass jedes Paar neuer Einfügungen automatisch verschmilzt.

## 2. Übersetzung von Templates, nicht von Anwendungs-Quellcode

Erstellen Sie neben `mix.exs` eine `L10N.md`, oder fügen Sie die folgenden Zuordnungen zu Ihrer bestehenden Konfiguration hinzu:

```yaml
---
source_language: en
sources:
  "priv/gettext/default.pot": "priv/gettext/{locale}/LC_MESSAGES"
  "priv/gettext/errors.pot": "priv/gettext/{locale}/LC_MESSAGES"
targets:
  - es
  - fr
---

Translate user-facing messages naturally and preserve all Gettext metadata.
Keep interpolation placeholders unchanged, including their names and syntax.
```

Fassen Sie nur Domänen auf, die in Ihrer Anwendung vorhanden sind. Fügen Sie für jede zusätzliche Domäne eine Zuordnung hinzu, wie zum Beispiel `dashboard_projects.pot`. Das Ziel ist ein Verzeichnis: der portable-object-Handler schreibt `default.po`, `errors.po` und andere passende Domänendateinamen dort hinein.

Verwenden Sie `.pot`-Templates als Quellen und `.po`-Locale-Dateien als Ausgaben. Verwenden Sie keine übersetzte Locale als Quelle für andere Locales. Sehen Sie die [L10N.md Referenz](/docs/reference/l10n-md) für verschachtelte Konfigurationen und das [Einstiegstutorial](/docs/tutorials/getting-started) zum Ankopplung des Repositories an Glossia.

## 3. Extrahieren vor Veröffentlichung von Quellcode-Änderungen

Wenn ein Pull Request einen `gettext`, `dgettext`, oder `ngettext`-Aufruf ändert:

1. Aktualisieren Sie den Anwendungsquellcode.
2. Führen Sie `mix gettext.extract --merge` aus.
3. Prüfen Sie die Template- und Locale-Diffs gemeinsam mit der Codeänderung.
4. Commiten Sie die generierten Änderungen vor dem Zusammenführen des Pull Requests.

Nachdem die Quellcode-Änderungen zusammengeführt wurden, übersetzt Glossia die aktualisierten Templates und veröffentlicht die Locale-Änderungen in einem Übersetzungs-Pull Request. Prüfen Sie diese Übersetzungen durch den normalen Prozess des Repositories.

Behalten Sie `msgid` und `msgctxt` als Quellidentifikatoren bei. Übersetzen Sie `msgstr`-Werte, einschließlich der erforderlichen Pluralvarianten. Bewahren Sie Interpolationsplatzehalter, Plural-Form-Köpfe, Quellenreferenzen, Übersetzerkommentare und Flaggen auf. Ein `fuzzy`-Eintrag benötigt Überprüfung: entfernen Sie die Kennzeichnung nicht nur, damit eine Prüfung durchläuft, und nehmen Sie nicht an, dass seine vorherige Übersetzung für eine geänderte Nachricht korrekt ist.

## 4. Validieren von Katalogänderungen in CI

Führen Sie aus:

```sh
mix gettext.extract --merge --check-up-to-date
mix compile --warnings-as-errors
```

Die Extraktionsprüfung erfasst Templates oder Locale-Dateien, die nicht mehr mit dem Anwendungsquellcode übereinstimmen. Die Kompilierung prüft, dass Gettext die Kataloge kompilieren kann. Weder Befehl überprüft linguistische Qualität noch beweist er, dass jede Nachricht eine überprüfte Übersetzung hat.

Wenn die Extraktion veraltete Dateien meldet, regenerieren Sie diese lokal, prüfen Sie die Unterschiede und melden Sie diese ein. Umgehen Sie die Prüfung nicht oder überschreiben Sie Templates im Übersetzungsworker wiederholt, um eine Quellcode-Uneinstimmigkeit zu verbergen.

## 5. Auflösen von Katalogkonflikten durch Nachrichtenidentität

Wenn Sie einen Branch vom Standard-Branch aktualisieren:

1. Auflösen Sie zuerst Anwendungsquellcode-Konflikte und bewahren Sie den beabsichtigten UI-Text bei.
2. Versöhnen Sie Katalogeinträge aus beiden Branches unter Verwendung ihres Kontexts und der Nachrichtenidentität in der Quelle, einschließlich Plural-Identifikatoren, sofern vorhanden. Behalten Sie bestehende Übersetzungen, Kommentare, Flaggen und Pluralformen bei; entfernen Sie Konfliktmarker und doppelte Einträge, bevor Sie den Parser ausführen.
3. Führen Sie `mix gettext.extract --merge` gegen die aufgelöste Quelle aus.
4. Führen Sie die oben genannten CI-Prüfungen aus und prüfen Sie das resultierende Katalogdiff.

Lösen Sie Katalogkonflikte nicht, indem Sie eine gesamte Seite blind akzeptieren, einen Text-Union-Merge-Treiber aktivieren oder die Kataloge zusammenfügen. Diese Ansätze können gültige Übersetzungen verlieren, Identifikatoren duplizieren oder eine ungültige Datei lassen. Für wiederkehrende Konflikte fügen Sie einen Regressionstest hinzu, der Kataloge auf zwei Branches mit verschiedenen neuen Nachrichten generiert und verifiziert, dass Git sowohl das Template als auch den übersetzten Katalog verschmilzt, ohne Einträge zu verlieren.
