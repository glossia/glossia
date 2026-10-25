%{
  title: "Modellanbieter konfigurieren",
  summary: "Fügen Sie ein Account-Modell hinzu und verweisen Sie es sicher aus Repositories.",
  category: "Anleitungen",
  section: "translation",
  order: 3
}
---

Die Projekteinrichtung und Translationsläufe verwenden Modelle, die für das aktuelle Glossia-Konto konfiguriert sind. Konfiguriere mindestens ein Modell, bevor du ein Projekt erstellst.

## Modell hinzufügen

1. Öffne **Einstellungen** und wähle **Modelle** aus.
2. Wähle **Neues Modell** aus.
3. Geben Sie einen eindeutigen Handle ein, wie z. B. `translation-default`.
4. Öffne den Modellauswahl-Menü und gib einen Teil des Provider-Namens ein, um die Liste zu filtern.
5. Wähle ein Modell aus und gib seinen Provider-Schlüssel ein.
6. Speichere das Modell.

Der Handle bleibt stabil, auch wenn du später das zugrunde liegende Provider-Modell änderst. Das zuerst im Konto hinzugefügte Modell wird zum Standardmodell.

## Modell im Repository referenzieren

Definiere `model` im relevanten `L10N.md` Frontmatter:

```yaml
---
model: translation-default
---
```

Das Repository speichert nur den Handle. Der Provider-Schlüssel bleibt in den Kontoeinstellungen erhalten.

## Wählen Sie das Standardmodell

Wenn `L10N.md` `model` nicht enthält, verwendet Glossia das Standardmodell des Kontos. Um dies zu ändern, öffne das Modell, das Standard werden soll, und wähle **Als Standard festlegen** aus.

Um das Verhalten über mehrere Modelle hinweg vorhersehbar zu gestalten, verweise explizit auf einen Handle in `L10N.md`.

Sie können einen anderen `model`-Handle in einem verschachtelten `L10N.md` für einen Inhaltsbereich oder in `L10N/<locale>.md` für eine Zielsprache platzieren. Glossia verwendet die passendste Einstellung für jedes Dokument und jede Sprache. Es teilt die Arbeit nicht automatisch zwischen den konfigurierten Modellen auf.

Wenn kein expliziter Handle im Konto existiert, bricht die Übersetzung mit einem Fehler ab. Es wird nicht auf ein anderes Modell zurückgegriffen.

## Provider-Schlüssel ändern oder rotieren

Öffne **Einstellungen**, wähle **Modelle** und öffne den Modell-Handle. Gib einen neuen Provider-Schlüssel ein und speichere. Lasst das Schlüsselfeld leer, um den aktuellen Schlüssel zu behalten.

Repositorys, die den Handle referenzieren, müssen sich nicht ändern.

## Jev für Übersetzungsqualitätsentscheidungen hinzufügen

1. Öffne **Einstellungen → Modelle → Neues Modell** und wähle **Entscheidung** als Kategorie aus.
2. Verwende einen Handle wie `translation-quality`. Lass `typesafe/jev-latest`, oder gib eine festgelegte TypeSafe Jev-Modellversion ein.
3. Gib deinen TypeSafe-Provider-Schlüssel ein. Lass die Basisadresse leer, um den nativen TypeSafe-Endpunkt zu verwenden; eine benutzerdefinierte Adresse muss dessen Versionspräfix enthalten, wie z. B. `https://api.typesafe.ai/v1`.
4. Stelle den Mindestqualitätswert von 1 bis 10 ein und speichere. Das erste Entscheidungsmodell wird zum Standard-Entscheidungsmodell und ermöglicht die Bewertung automatisch.
5. Starte die Übersetzung. Fehlgeschlagene Qualitätsdimensionen bitten innerhalb der `retries` Budgets, die in deinem Repository konfiguriert sind, um Korrektur.

Generative und Entscheidungsmodelle haben eigene Standards. Lass deine Translationsmodell-Handles unverändert. Entscheidungsmodelle können nicht über Repository-Übersetzungs-Handles oder Lokalisierungs-Routing-Regeln ausgewählt werden. Entferne alle Entscheidungsmodelle, um die Bewertung zu deaktivieren.
