%{
  title: "Webanalyse installieren",
  summary:
    "Fügen Sie das Glossia Web SDK mit einer Zeile HTML oder über npm in Ihrer Website ein und beginnen Sie damit, Lokalisierungssignale zu sammeln.",
  category: "Anleitung",
  section: "analytics",
  order: 1
}
---

Dieser Leitfaden geht davon aus, dass Sie ein Glossia-Projekt haben, dessen Website-Domain in den Analyse-Einstellungen des Projekts konfiguriert ist. Die Erfassung wird durch diese Domain identifiziert, sodass es keinen Schlüssel oder Secret gibt, der kopiert werden muss.

## Option A: Skripttag

Fügen Sie diesen Ausschnitt auf jede Seite ein, idealerweise in `<head>`:

```html
<script defer data-domain="example.com" src="https://glossia.ai/assets/glossia-web.js"></script>
```

Die SDK initialisiert sich automatisch, sendet beim Laden eine Pageview und erfasst nachfolgende Pageviews bei clientsseitiger Navigation in Single-Page-Apps. `data-domain` wird standardmäßig auf `window.location.hostname` gesetzt, wenn nicht angegeben, sodass Sie es bei einer Single-Domain-Website entfernen können. Um einen benutzerdefinierten Sammelpunkt zu verwenden, fügen Sie `data-endpoint="https://collect.your-host.com"` hinzu.

Wenn Ihre Website eine Content Security Policy verwendet, erlauben Sie `https://glossia.ai` sowohl in `script-src` (oder `script-src-elem` falls vorhanden) als auch in `connect-src`. Das Skript lädt von `/assets/glossia-web.js` und sendet Ereignisse nach `/v1/collect` vom gleichen Ursprung.

## Option B: npm

Installieren Sie das Paket:

```bash
npm install @glossia/web
```

Initialisieren Sie es einmal in Ihrem Anwendungseingabestart:

```ts
import glossia from "@glossia/web";

glossia.init({ endpoint: "https://glossia.ai/v1/collect" });
```

Setzen Sie das Collection-Endpoint explizit, wenn Sie das Paket in Ihrem eigenen Bundle verwenden, da es keinen gehosteten Skript-Adresse gibt, von der aus es abgeleitet werden könnte.

`domain` wird aus `window.location.hostname` abgeleitet, sodass das SDK im für Ihre Website registrierten Projekt erfasst wird. Geben Sie `{ domain: "example.com" }` an, um dies zu überschreiben, beispielsweise, um Ereignisse von einem Staging-Ursprung an das gleiche Projekt wie die Produktion zu senden.

Um ein benutzerdefiniertes Ereignis zu erfassen, z. B. eine Anmeldung:

```ts
glossia.track("signup");
```

## Verifizieren Sie Ihre Domain

In den **Analyse-Einstellungen** Ihres Projekts speichern Sie die Website-Domain. Die **Domain-Besitz verifizieren**-Karte zeigt den genauen Eintrag-Namen und -Wert für Ihr Projekt an. Fügen Sie einen Text-Record bei Ihrem Domain-Anbieter hinzu:

| Feld | Wert |
| --- | --- |
| Typ | `TXT` ([TXT-Eintrag](https://www.cloudflare.com/learning/dns/dns-records/dns-txt-record/)) |
| Name | `_glossia-verify.example.com` |
| Wert | `glossia-site-verification=YOUR_VERIFICATION_TOKEN` |

Verwenden Sie die in Ihren Einstellungen angezeigte Domain und den Token. Einige Anbieter fügen die Domain automatisch hinzu; in diesem Fall geben Sie nur `_glossia-verify` als Namen ein. Nach dem Veröffentlichen des Eintrags klicken Sie **Domain verifizieren**. Änderungen können Zeit benötigen, um verfügbar zu werden, daher wiederholen Sie den Vorgang, falls der Eintrag sofort nicht gefunden wird.

Wenn Sie Ihre Domain-Einträge nicht bearbeiten können, erweitern Sie **Alternative: Verifizierung mit einem Startseiten-Metadaten-Tag**. Kopieren Sie den generierten Tag in das `<head>` Ihrer Startseite und veröffentlichen Sie ihn:

```html
<meta name="glossia-site-verification" content="YOUR_VERIFICATION_TOKEN">
```

Beide Methoden beweisen die Kontrolle über die konfigurierte Domain. Glossia prüft den Eintrag oder die Startseite dieser Domain, so dass das Kopieren des Tokens auf eine andere Website die Besitzüberprüfung nicht bewirkt. Das Token ist ein öffentlicher Nachweis, kein Passwort.

Sobald die Domain verifiziert ist, erfasst Glossia Ereignisse aus Ihrem Tracking-Ausschnitt. Der Ausschnitt allein verifiziert den Besitz nicht. Eine Änderung der konfigurierten Domain erfordert eine erneute Überprüfung.

## Überprüfen Sie, ob es funktioniert

1. Öffnen Sie Ihre Website in einem Browser.
2. Öffnen Sie den Netzwerk-Tab und bestätigen Sie, dass eine `POST`-Anfrage an `https://glossia.ai/v1/collect` eine `202 Accepted`-Antwort zurückgibt.
3. Nach Erfassung und Verarbeitung erscheint der Seitenbesuch unter **Analyse** in Ihrem Projekt-Dashboard. Übersetzungen auf der Seite Übersicht sind vom Website-Verkehr getrennt.

Eine `202 Accepted`-Antwort bestätigt, dass die Anfragen den Erfassungs-Service erreicht hat. Unbekannte oder unverifizierte Domains werden ebenfalls akzeptiert, erfassen aber keine Events, so prüfen Sie, ob die konfigurierte Domain in den Projekt-Analyse-Einstellungen verifiziert ist.

## Was wird erfasst

Der Browser sendet die Seiten-URL, den Referrer, `navigator.languages`, die Zeitzone und Bildschirmbreite sowie eine pro Tab Sessions-ID. Der Server fügt das Land hinzu (aus GeoIP) und berechnet den Lokalisierungs-Lücke gegen die Nachrichten Ihres Projekts. Es werden keine Cookies gesetzt und nichts wird gefingrigiert.
