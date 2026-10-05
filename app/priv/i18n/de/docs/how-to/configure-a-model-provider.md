%{
  title: "Konfigurieren Sie einen Modellanbieter",
  summary: "Fügen Sie ein Kontomodell hinzu und referenzieren Sie es sicher aus Repositorien.",
  category: "Anleitung",
  section: "translation",
  order: 3
}
---
Projekt-Einrichtung und Übersetzungsläufe verwenden Modelle, die für das aktuelle Glossia-Konto konfiguriert sind. Konfigurieren Sie mindestens ein Modell, bevor Sie ein Projekt erstellen.

## Modell hinzufügen

1. Öffnen **Einstellungen** und wählen Sie aus **Modelle**.
2. Auswählen **Neues Modell**.
3. Geben Sie einen eindeutigen Handle ein, beispielsweise `translation-default`.
4. Öffnen Sie den Modellauswahlbereich und geben Sie einen Teil des Anbieters- oder Modellnamens ein, um die Liste zu filtern.
5. Wählen Sie ein Modell und geben Sie dessen Anbieterschlüssel ein.
6. Modell speichern.

Der Handle ist stabil, auch wenn Sie später das dahinterliegende Anbietermodell ändern. Das erste Modell, das einem Konto hinzugefügt wurde, wird dessen Standardmodell.

## Referenziere das Modell aus einem Repository

Festlegen `model` im relevanten `L10N.md` frontmatter:

```yaml
---
model: translation-default
---
```

Das Repository enthält nur den Handle. Der Provider-Schlüssel verbleibt in den Kontoeinstellungen.

## Wähle, welches Modell standardmäßig verwendet wird

Wenn `L10N.md` übersieht `model`, Glossia verwendet das Standardmodell des Kontos. Um es zu ändern, öffnen Sie das Modell, das Standard werden soll, und wählen **Als Standard festlegen**.

Für ein vorhersagbares Verhalten über mehrere Modelle verweisen Sie explizit auf einen `L10N.md`.

Sie können einen anderen `model` Handle in einer verschachtelten `L10N.md` für einen Inhaltsbereich, oder in `L10N/<locale>.md` für eine Ziel-Lokalisierung. Glossia verwendet für jedes Dokument und jede Lokalisierung die passendste verfügbare Einstellung. Es teilt die Arbeit nicht automatisch unter konfigurierte Modelle auf.

Wenn ein expliziter Handle nicht im Konto vorhanden ist, endet die Übersetzung mit einem Fehler. Es greift nicht auf ein anderes Modell zurück.

## Anbieter-Schlüssel ändern oder rotieren

Öffnen **Einstellungen**, wählen **Modelle**, und öffnen Sie den Modell-Handle. Geben Sie einen neuen Anbieter-Schlüssel ein und speichern Sie. Lassen Sie das Schlüsselfeld leer, um den aktuellen Schlüssel beizubehalten.

Repositorien, die den Handle referenzieren, benötigen keine Änderung.

## Jev für Übersetzungsqualitätsentscheidungen hinzufügen

1. Öffnen **Einstellungen → Modelle → Neues Modell** und wählen **Entscheidung** als Kategorie.
2. Verwenden Sie einen Handle wie `translation-quality`. Beibehalten `typesafe/jev-latest`, oder geben Sie eine gepinnte TypeSafe-Jev-Modellversion ein.
3. ,Geben Sie Ihren TypeSafe-Anbieter-Schlüssel ein. Lassen Sie die Basisadresse leer, um den nativen TypeSafe-Endpunkt zu verwenden; eine benutzerdefinierte Adresse muss ihren Versionspräfix enthalten, wie `https://api.typesafe.ai/v1`.
4. ,Stellen Sie die Mindestqualitätspunktzahl von 1 bis 10 ein und speichern Sie. Das erste Entscheidungsmodell wird zum Standard-Entscheidungsmodell und ermöglicht die Evaluierung automatisch.
5. ,Starten Sie die Übersetzung. Fehlgeschlagene Qualitätsdimensionen erfordern eine Korrektur innerhalb des `retries` ,Budget, das in Ihrem Repository konfiguriert ist.

,Generative- und Entscheidungsmodelle haben separate Standards. Behalten Sie die Handles für Ihre Übersetzungsmodelle unverändert. Entscheidungsmodelle können nicht durch Repository-Translation-Handles oder Lokale-Routing-Regeln ausgewählt werden. Entfernen Sie alle Entscheidungsmodelle, um die Evaluierung zu deaktivieren.