%{
  title: "Web-Analytik installieren",
  summary:
    "Fügen Sie das Glossia Web-SDK Ihrer Website mit einer einzigen HTML-Zeile oder über npm hinzu und beginnen Sie, Lokalisierungssignale zu sammeln.",
  category: "Anleitung",
  section: "analytics",
  order: 1
}
---

Diese Anleitung geht davon aus, dass Sie ein Glossia-Projekt mit der Site-Domain haben, die in den Analytics-Einstellungen des Projekts konfiguriert ist. Die Datenerfassung wird durch diese Domain identifiziert, sodass kein Schlüssel oder Geheimnis kopiert werden muss.

## Option A: script-Tag

Fügen Sie diesen Code auf jede Seite hinzu, idealerweise im `<head>`:

```html
<script defer data-domain="example.com" src="https://glossia.ai/assets/glossia-web.js"></script>
```

Die SDK initialisiert sich automatisch, sendet einen Seitenaufruf beim Laden und zeichnet nachfolgende Seitenaufrufe bei der clientseitigen Navigation in Single-Page-Apps auf. `data-domain` verwendet als Standardwert `window.location.hostname`, wenn dieser weggelassen wird, sodass Sie ihn auf einer Single-Domain-Seite entfernen können. Um einen benutzerdefinierten Collection-Endpunkt zu verwenden, fügen Sie `data-endpoint="https://collect.your-host.com"` hinzu.

Verwenden Sie bei einem Content Security Policy unter Ihrem Site die Erlaubnis für `https://glossia.ai` sowohl in `script-src` (oder `script-src-elem` falls vorhanden) als auch in `connect-src`. Das Skript wird von `/assets/glossia-web.js` geladen und sendet Ereignisse an `/v1/collect` auf demselben Ursprung.

## Option B: npm

Installieren Sie das Paket:

```bash
npm install @glossia/web
```

Initialisieren Sie es einmal in Ihrem Anwendungs-Einstiegspunkt:

```ts
import glossia from "@glossia/web";

glossia.init({ endpoint: "https://glossia.ai/v1/collect" });
```

Definieren Sie den Collection-Endpunkt explizit, wenn das Paket in Ihrem eigenen Bundle verwendet wird, da es keinen gehosteten Skript-Adresse gibt, auf die Sie daraus schließen könnten.

`domain` wird aus `window.location.hostname` abgeleitet, sodass das SDK dem für Ihre Seite registrierten Projekt zugeordnet wird. Übergeben Sie `{ domain: "example.com" }` zur Überschreibung, zum Beispiel, um Ereignisse von einem Staging-Ursprung an das gleiche Projekt wie in Produktion zu senden.

Um ein benutzerdefiniertes Ereignis zu erfassen, zum Beispiel eine Anmeldung:

```ts
glossia.track("signup");
```

## Ihre Domain verifizieren

In den Analytics-Einstellungen Ihres Projekts **Analytics settings**, speichern Sie Ihre Site-Domain. Die **Verify domain ownership** Karte zeigt den genauen Datensatz-Namen und Wert für Ihr Projekt. Fügen Sie einen Text-Datensatz mit Ihrem Domain-Anbieter hinzu:

| Feld | Wert |
| --- | --- |
| Typ | `TXT` ([Text-Eintrag](https://www.cloudflare.com/learning/dns/dns-records/dns-txt-record/)) |
| Name | `_glossia-verify.example.com` |
| Wert | `glossia-site-verification=YOUR_VERIFICATION_TOKEN` |

Verwenden Sie die Domain und den Token, die in Ihren Einstellungen angezeigt werden. Einige Anbieter fügen die Domain automatisch hinzu; in diesem Fall geben Sie nur `_glossia-verify` als Namen ein. Nach dem Veröffentlichung des Datensatzes, klicken Sie **Domain verifizieren**. Änderungen können Zeit benötigen, bevor sie verfügbar sind, also wiederholen Sie es, wenn der Datensatz nicht sofort gefunden wird.

Wenn Sie Ihre Domain-Datensätze nicht bearbeiten können, erweitern Sie **Alternative: verify with a homepage meta tag**. Kopieren Sie den generierten Tag in das `<head>` Ihrer Homepage und veröffentlichen Sie ihn:

```html
<meta name="glossia-site-verification" content="YOUR_VERIFICATION_TOKEN">
```

Beide Methoden beweisen die Kontrolle über die konfigurierte Domain. Glossia prüft den Datensatz oder die Homepage dieser Domain, sodass das Kopieren des Tokens auf eine andere Website den Besitz nicht verifiziert. Der Token ist öffentlicher Beweis, kein Passwort.

Sobald die Domain verifiziert ist, erfasst Glossia Ereignisse aus Ihrem Tracking-Code-Abschnitt. Der Codeabschnitt allein verifiziert den Besitz nicht. Eine Änderung der konfigurierten Domain erfordert erneut eine Verifizierung.

## Überprüfen Sie, ob es funktioniert

1. Öffnen Sie Ihre Site in einem Browser.
2. Öffnen Sie den Netzwerk-Tab und bestätigen Sie, dass eine `POST`-Anfrage zu `https://glossia.ai/v1/collect` die Antwort `202 Accepted` zurückgibt.
3. Nach Datenerfassung und Verarbeitung erscheint der Seitenaufruf unter **Analytics** im Dashboard Ihres Projekts. Übersetzungs-Abläufe auf der Übersichtsseite sind vom Website-Verkehr getrennt.

Eine `202 Accepted`-Antwort bestätigt, dass die Anfrage den Sammler erreicht hat. Unbekannte oder nicht verifizierte Domains werden ebenfalls akzeptiert, erfassen aber keine Ereignisse, daher bestätigen Sie, dass die konfigurierte Domain in den Projekt-Analytics-Einstellungen verifiziert ist.

## Was wird gesammelt

Der Browser sendet die Seiten-URL, Referrer, `navigator.languages`, Zeitzone und Bildschirmbreite sowie eine pro Tab-Sitzungs-ID. Der Server fügt das Land hinzu (aus GeoIP) und berechnet die Lokalisierungslücke gegenüber den Zieldsprachen Ihres Projekts. Es werden keine Cookies gesetzt und nichts wird Fingerprinting.
