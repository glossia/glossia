%{
  title: "Modellanbieter konfigurieren",
  summary: "Fügen Sie ein Konto-Modell hinzu und verweisen Sie darauf sicher aus Repositories.",
  category: "Anleitung",
  section: "translation",
  order: 3
}
---

Projektseinrichtungs- und Übersetzungsläufe verwenden Modelle, die für das aktuelle Glossia-Konto konfiguriert wurden. Konfigurieren Sie mindestens ein Modell, bevor Sie ein Projekt erstellen.

## Ein Modell hinzufügen

1. Öffnen Sie **Settings** und wählen Sie **Models**.
2. Wählen Sie **New model**.
3. Geben Sie einen eindeutigen Handle an, wie etwa `translation-default`.
4. Öffnen Sie den Modellauswahl-Dialog und geben Sie einen Teil des Anbieter- oder Modellnamens ein, um die Liste zu filtern.
5. Wählen Sie ein Modell und geben Sie dessen Anbieter-Schlüssel ein.
6. Speichern Sie das Modell.

Der Handle bleibt stabil, auch wenn Sie später das dahinterliegende Modellauswahl-Anbieter-Modell ändern. Das zuerst zu einem Konto hinzugefügte Modell wird dessen Standard.

## Beziehen Sie das Modell auf ein Repository

Stellen Sie `model` im relevanten `L10N.md` frontmatter ein:

```yaml
---
model: translation-default
---
```

Das Repository speichert nur den Handle. Der Anbieter-Schlüssel bleibt in den Kontoeinstellungen.

## Wählen Sie, welches Modell standardmäßig verwendet wird

Wenn `L10N.md` `model` weglässt, verwendet Glossia das Standardmodell des Kontos. Um dieses zu ändern, öffnen Sie das Modell, das zum Standard werden soll, und wählen Sie **Make default**.

Für vorhersehbares Verhalten über mehrere Modelle hinweg beziehen Sie sich explizit auf einen Handle in `L10N.md`.

Sie können einen anderen `model` Handle in einer verschachtelten `L10N.md` für einen Inhaltsbereich oder in `L10N/<locale>.md` für eine Zielortsangabe platzieren. Glossia verwendet für jedes Dokument und jede Sprachangabe den passendsten Einstellungen. Es teilt die Arbeit nicht automatisch unter den konfigurierten Modellen auf.

Wenn ein expliziter Handle im Konto nicht existiert, wird die Übersetzung mit einem Fehler gestoppt. Es fällt nicht auf ein anderes Modell zurück.

## Ändern oder rotieren Sie einen Anbieter-Schlüssel

Öffnen Sie **Settings**, wählen Sie **Models** und öffnen Sie den Modell-Handle. Geben Sie einen neuen Anbieter-Schlüssel ein und speichern. Wenn Sie das Schlüsselfeld leer lassen, bleibt der aktuelle Schlüssel erhalten.

Repositorys, die auf den Handle referenzieren, müssen nicht geändert werden.

## Jev für Entscheidungen zur Übersetzungsqualität hinzufügen

1. Öffnen Sie **Settings → Models → New model** und wählen Sie **Decision** als Kategorie.
2. Verwenden Sie einen Handle wie `translation-quality`. Halten Sie `typesafe/jev-latest` bei, oder geben Sie eine TypeSafe-Jev-Modellversion ein.
3. Geben Sie Ihren TypeSafe-Anbieterschlüssel ein. Lassen Sie die Basis-Adresse leer, um den integrierten TypeSafe-Endpoint zu verwenden; eine benutzerdefinierte Adresse muss ihr Versionspräfix enthalten, wie etwa `https://api.typesafe.ai/v1`.
4. Stellen Sie die minimale Qualitätspunktzahl von 1 bis 10, dann speichern. Das erste Entscheidungsmodell wird zum standardmäßigen Entscheidungsmodell und aktiviert die Bewertung automatisch.
5. Starten Sie die Übersetzung. Fehlgeschlagene Qualitätskriterien fordern innerhalb des `retries` Budgets, das in Ihrem Repository konfiguriert wurde, eine Korrektur an.

Generative und Entscheidungsmodelle haben separate Standards. Halten Sie Ihre Übersetzungsmodell-Handles unverändert. Entscheidungsmodelle können nicht durch Repository-Ubersetzungs-Handles oder Sprachangabe-Verweispfade ausgewählt werden. Entfernen Sie alle Entscheidungsmodelle, um die Bewertung zu deaktivieren.
