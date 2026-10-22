%{
  title: "Einen Modellanbieter konfigurieren",
  summary: "Ein Accountmodell hinzufügen und sicher aus Repositories verweisen",
  category: "Anleitung",
  section: "translation",
  order: 3
}
---

Projektsetup und Übersetzungsläufe verwenden Modelle, die für das aktuelle Glossia-Konto konfiguriert sind. Konfigurieren Sie mindestens ein Modell, bevor Sie ein Projekt erstellen.

## Modell hinzufügen

1. Öffnen Sie **Settings** und wählen Sie **Models**.
2. Wählen Sie **New model** aus.
3. Geben Sie einen eindeutigen Handle ein, z. B. `translation-default`.
4. Öffnen Sie den Model Picker und tippen Sie einen Teil von Anbieter oder Modellname ein, um die Liste zu filtern.
5. Wählen Sie ein Modell aus und geben Sie seinen Provider Key ein.
6. Speichern Sie das Modell.

Der Handle bleibt stabil, auch wenn Sie später das dahinterliegende Provider Modell ändern. Das erste Modell, das einem Konto hinzugefügt wird, wird dessen Standard.

## Verweisen Sie auf das Modell aus einem Repository

Legen Sie `model` im relevanten `L10N.md`-Frontmatter fest:

```yaml
---
model: translation-default
---
```

Das Repository speichert nur den Handle. Der Provider Key bleibt in den Kontoeinstellungen.

## Wählen Sie, welches Modell standardmäßig verwendet wird

Wenn `model` in `L10N.md` fehlt, verwendet Glossia das Standardmodell des Kontos. Um dies zu ändern, öffnen Sie das Modell, das zum Standardmodell werden soll, und wählen Sie **Als Standard festlegen**.

Für vorhersehbares Verhalten über mehrere Modelle hinweg: Verweisen Sie auf einen Handle explizit in `L10N.md`.

Sie können einen anderen `model`-Handle in eine verschachtelte `L10N.md` für einen Inhaltsbereich oder in `L10N/<locale>.md` für ein Ziel-lokal-Set legen. Glossia verwendet die nächstliegende anwendbare Einstellung für jedes Dokument und jede Lokalisierung. Es teilt die Arbeit nicht automatisch zwischen konfigurierten Modellen auf.

Wenn ein expliziter Handle nicht im Konto existiert, wird die Übersetzung mit einem Fehler gestoppt. Es wird nicht auf ein anderes Modell zurückgefallen.

## Ändern oder drehen Sie einen Provider Key

Öffnen Sie **Settings**, wählen Sie **Models** und öffnen Sie den Model Handle. Geben Sie einen neuen Provider Key ein und speichern. Wenn Sie das Key-Feld leer lassen, bleibt der aktuelle Key.

Repositories, die auf den Handle verweisen, müssen nicht geändert werden.

## Jev für Übersetzungsqualität Entscheidungen hinzufügen

1. Öffnen Sie **Settings → Models → New model** und wählen Sie **Decision** als Kategorie.
2. Verwenden Sie einen Handle wie `translation-quality`. Behalten Sie `typesafe/jev-latest` bei, oder geben Sie eine fixierte TypeSafe-Jev-Modellversion ein.
3. Geben Sie Ihren TypeSafe-Anbieterschlüssel ein. Lassen Sie die Basisadresse leer, um das native TypeSafe-Endpunkt zu verwenden; eine benutzerdefinierte Adresse muss ihr Versionspräfix enthalten, wie `https://api.typesafe.ai/v1`.
4. Setzen Sie die Mindestqualitätspunktzahl von 1 bis 10 fest, dann speichern. Das erste Entscheidung-Modell wird zum Standardentscheidungsmodell und ermöglicht Bewertung automatisch.
5. Starten Sie die Übersetzung. Fehlgeschlagene Qualitätsdimensionen beantragen Korrektur innerhalb des im Repository konfigurierten `retries`-Budgets.

Generative und Entscheidungsmodelle haben separate Standards. Behalten Sie Ihre Übersetzungsmodell-Handles unverändert. Entscheidungsmodelle können nicht über Repository Übersetzung Handles oder Locale Routing Regeln ausgewählt werden. Entfernen Sie alle Entscheidungsmodelle, um Bewertung zu deaktivieren.
