%{
  title: "Modellanbieter konfigurieren",
  summary: "Fügen Sie ein Account-Modell hinzu und referenzieren Sie es sicher aus Repositorien.",
  category: "Anleitung",
  section: "translation",
  order: 3
}
---

Projekt-Einrichtung und Übersetzungsläufe verwenden Modelle, die für das aktuelle Glossia-Konto konfiguriert sind. Konfigurieren Sie mindestens ein Modell, bevor Sie ein Projekt erstellen.

## Modell hinzufügen

1. Öffnen **Einstellungen** und wählen Sie **Modelle** aus.
2. Wählen Sie **Neues Modell** aus.
3. Geben Sie einen eindeutigen Handle ein, z. B. `translation-default`.
4. Öffnen Sie den Modell-Selektor und geben Sie einen Teil des Namens des Anbieters oder Modells ein, um die Liste zu filtern.
5. Wählen Sie ein Modell aus und geben Sie dessen Anbieterschlüssel ein.
6. Speichern Sie das Modell.

Der Handle bleibt stabil, selbst wenn Sie später das dahinterliegende Anbietermodell ändern. Das erste hinzugefügte Modell eines Kontos wird dessen Standardmodell.

## Referenzieren Sie das Modell aus einem Repository

Geben Sie `model` in das relevante `L10N.md` frontmatter ein:

```yaml
---
model: translation-default
---
```

Das Repository speichert nur den Handle. Der Anbieterschlüssel verbleibt in den Kontoeinstellungen.

## Wählen Sie das Standardmodell aus

Wenn `L10N.md` `model` weglässt, verwendet Glossia das Standardmodell des Kontos. Um dies zu ändern, öffnen Sie das Modell, das als Standard dienen soll, und wählen Sie **Als Standard festlegen**.

Um ein konsistentes Verhalten über mehrere Modelle sicherzustellen, verweisen Sie explizit auf einen Handle in `L10N.md`.

Sie können einen anderen `model`-Handle in einem verschachtelten `L10N.md` für einen Inhaltsbereich oder in `L10N/<locale>.md` für eine Zielsprache platzieren. Glossia verwendet die passendste verfügbare Einstellung für jedes Dokument und jede lokale. Es teilt die Arbeit nicht automatisch zwischen den konfigurierten Modellen auf.

Wenn ein expliziter Handle im Konto nicht existiert, stoppt die Übersetzung mit einem Fehler. Es wird nicht auf ein anderes Modell zurückgefallen.

## Ändern Sie oder rotieren Sie einen Anbieterschlüssel

Öffnen **Einstellungen**, wählen **Modelle** und öffnen Sie den Modell-Handle. Geben Sie einen neuen Anbieterschlüssel ein und speichern Sie. Lassen Sie das Schlüsselfeld leer, um den aktuellen Schlüssel beizubehalten.

Repositorys, die sich auf den Handle beziehen, müssen sich nicht ändern.

## Fügen Sie Jev für Übersetzungsqualitätsentscheidungen hinzu

1. Öffnen **Einstellungen → Modelle → Neues Modell** und wählen Sie **Entscheidung** als Kategorie.
2. Verwenden Sie einen Handle wie `translation-quality`. Halten Sie `typesafe/jev-latest` oder geben Sie eine feste TypeSafe Jev-Modellversion ein.
3. Geben Sie Ihren TypeSafe-Anbieterschlüssel ein. Lassen Sie die Basisadresse leer, um das native TypeSafe-Endpunkt zu verwenden; eine benutzerdefinierte Adresse muss ihren Versionsprfix enthalten, wie z. B. `https://api.typesafe.ai/v1`.
4. Stellen Sie die Mindestqualitätsnote von 1 bis 10 ein und speichern Sie. Das erste Entscheidungsmodell wird zum Standard-Entscheidungsmodell und ermöglicht die automatische Auswertung.
5. Starten Sie die Übersetzung. Fehlgeschlagene Qualitätsdimensionen beantragen eine Korrektur innerhalb des `retries` Budgets, das in Ihrem Repository konfiguriert ist.

Generative und Entscheidungsmodelle haben separate Standards. Halten Sie Ihre Übersetzungsmodell-Handles unverändert. Entscheidungsmodelle können nicht über Repository-Übersetzungs-Handles oder Locale-Weiterleitungsregeln ausgewählt werden. Entfernen Sie alle Entscheidungsmodelle, um die Auswertung zu deaktivieren.
