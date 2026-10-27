%{
  title: "Web-Analytik installieren",
  summary:
    "Fügen Sie das Glossia-Web-SDK mit einer HTML-Zeile oder über npm zu Ihrer Website hinzu und beginnen Sie, Lokalisierungssignale zu sammeln.",
  category: "Anleitung",
  section: "analytics",
  order: 1
}
---

Dieser Leitfaden geht davon aus, dass Sie ein Glossia-Projekt besitzen, dessen Site-Domain in den Analyseneinstellungen des Projekts konfiguriert ist. Die Erfassung erfolgt anhand dieser Domain, sodass es keinen zum Kopieren bestimmten Schlüssel oder geheimen Wert gibt.

## Option A: Script-Tag

Fügen Sie diesen Snippet jeder Seite hinzu, idealerweise in `<head>`:

```html
<script defer data-domain="example.com" src="https://glossia.ai/assets/glossia-web.js"></script>
```

Das SDK initialisiert sich automatisch, sendet beim Laden einen Seitenaufruf und protokolliert nachfolgende Seitenaufrufe bei Client-seitiger Navigation in Single-Page-Apps. `data-domain` wird standardmäßig auf `window.location.hostname` gesetzt, wenn weggelassen, sodass Sie es auf einer Single-Domain-Seite entfallen lassen können. Um einen benutzerdefinierten Collection Endpoint zu verwenden, fügen Sie `data-endpoint="https://collect.your-host.com"` hinzu.

Wenn Ihre Website eine Content-Security-Policy verwendet, erlauben Sie `https://glossia.ai` sowohl in `script-src` (bzw. `script-src-elem` wenn vorhanden) als auch in `connect-src`. Das Script lädt von `/assets/glossia-web.js` und sendet Ereignisse an `/v1/collect` am selben Origin.

## Option B: npm

Installieren Sie das Paket:

```bash
npm install @glossia/web
```

Initialisieren Sie es einmalig in Ihrem Anwendungseintrittspunkt:

```ts
import glossia from "@glossia/web";

glossia.init({ endpoint: "https://glossia.ai/v1/collect" });
```

Stellen Sie den Collection Endpoint explizit ein, wenn Sie das Paket in Ihrem eigenen Bundle verwenden, da es keinen gehosteten Script-Adresse gibt, von der man ihn ableiten könnte.

Der `domain` wird aus `window.location.hostname` abgeleitet, sodass das SDK für das in Ihrem System registrierte Projekt protokolliert. Geben Sie `{ domain: "example.com" }` an, um dies zu überschreiben, z. B. um Ereignisse von einem Staging-Endpunkt an dasselbe Projekt wie die Produktion zu senden.

Um ein benutzerdefiniertes Ereignis zu protokollieren, z. B. eine Anmeldung:

```ts
glossia.track("signup");
```

## Erfassen Sie explizite Sprachauswahlen (Track explicit language choices)

Um die Besucherwahl von ihrer Browser-Einstellung zu unterscheiden, rufen Sie das SDK im Nutzer-Aktions-Handler Ihrer Sprachauswahlkomponente auf, bevor Sie navigieren:

```js
glossia.selectLanguage("zh-Hans");
```

Diese Methode ist auf dem importierten SDK nach `glossia.init()` verfügbar, und auf dem `glossia` global, wenn das gehostete Script verwendet wird.

Alternativ können Sie gleichursprüngliche Sprachumschalt-Links annotieren:

```html
<a href="/zh-hans/docs" data-glossia-language="zh-Hans">简体中文</a>
```

Verwenden Sie eine Integration pro Aktion, nicht beide. Annotierte Links erfassen echte Benutzeraktivierung, einschließlich Tastaturaktivierung. Sie ignorieren skriptierte Klicks, Downloads, bearbeitete Klicks, Ziele mit fremden Origins und Links, die einen Tab öffnen, sodass die Navigation nicht verhindert wird.

Das SDK sendet sofort ein `language_selection`-Ereignis und enthält die ausgewählte Sprache (`cl`) in nachfolgenden Ereignissen. Die Wahl wird in `sessionStorage` für den aktuellen Tab und Ursprung gespeichert, bis eine andere Wahl sie ersetzt. Wenn Speicher nicht verfügbar ist, dauert es nur bis zum Unerladen der Seite. Keine Wahl wird abgeleitet von Umleitungen, URLs oder Änderungen an `<html lang>`.

Die Auswahl protokolliert die Absicht, nicht die erfolgreiche Navigation. Browser-Einstellung, tatsächliche Seiten-Sprache und explizite Wahl bleiben getrennt. Der Collector prüft eine gültige Wahl statt der Browser-Einstellungen bei der Berechnung der Lokalisierungslücke. Eine Wahl setzt die Lücke nur, wenn sie einem Projektziel, einer beworbenen Übersetzung oder der tatsächlichen Seiten-Sprache entspricht; eine nicht verfügbare gewählte Sprache führt zwar noch zu einer Lücke. Fehlende oder ungültige Wahlen verwenden Browser-Einstellungen wie zuvor. Dashboard-Gesamtsummen und Abzeichen verwenden die gespeicherte Entscheidung jedes Ereignisses; historische Flaggen bleiben unverändert.

## Verifizieren Sie Ihre Domain

In Ihren Projekt-**Analyseneinstellungen** speichern Sie Ihre Site-Domain. Die **Domainbesitz verifizieren**-Karte zeigt den genauen Record-Namen und Wert für Ihr Projekt. Fügen Sie einen Text-Eintrag mit Ihrem Domain-Anbieter hinzu:

| Feld | Wert |
| --- | --- |
| Typ | `TXT` ([Text-Eintrag](https://www.cloudflare.com/learning/dns/dns-records/dns-txt-record/)) |
| Name | `_glossia-verify.example.com` |
| Wert | `glossia-site-verification=YOUR_VERIFICATION_TOKEN` |

Verwenden Sie die Domain und den Token, die in Ihren Einstellungen angezeigt werden. Einige Anbieter fügen die Domain automatisch hinzu; geben Sie in diesem Fall nur `_glossia-verify` als Namen ein. Nach dem Veröffentlichen des Records klicken Sie **Domain verifizieren**. Änderungen können Zeit benötigen, um verfügbar zu werden, also wiederholen Sie es, wenn der Record nicht sofort gefunden wird.

Wenn Sie Ihre Domain-Records nicht bearbeiten können, erweitern Sie **Alternative: Verifizierung mit einem Homepage-Meta-Tag**. Kopieren Sie das generierte Tag in das `<head>` Ihrer Homepage und veröffentlichen Sie es:

```html
<meta name="glossia-site-verification" content="YOUR_VERIFICATION_TOKEN">
```

Beide Methoden beweisen Kontrolle über die konfigurierte Domain. Glossia prüft den Record oder die Homepage dieser Domain, sodass das Kopieren des Tokens auf eine andere Website den Besitz nicht verifiziert. Der Token ist öffentlicher Beweis, kein Passwort.

Sobald die Domain verifiziert ist, protokolliert Glossia Ereignisse aus Ihrem Tracking-Snippet. Das Snippet allein verifiziert den Besitz nicht. Eine Änderung der konfigurierten Domain erfordert erneut eine Verifizierung.

## Überprüfen Sie, ob es funktioniert

1. Öffnen Sie Ihre Website in einem Browser.
2. Öffnen Sie den Netzwerk-Tab und bestätigen Sie, dass eine `POST`-Anfrage an `https://glossia.ai/v1/collect` `202 Accepted` zurückgibt.
3. Nach der Sammlung und Verarbeitung erscheint der Seitenaufruf unter **Analytik** in Ihrem Dashboard des Projekts. Übersetzungsabläufe auf der Übersichtsseite sind von Website-Verkehr getrennt.

Eine `202 Accepted`-Antwort bestätigt, dass die Anfrage den Collector erreicht hat. Unbekannte oder nicht verifizierte Domains werden auch akzeptiert, protokollieren aber keine Ereignisse, so bestätigen Sie, dass die konfigurierte Domain in den Projekt-Analyseaestellungen verifiziert ist.

## Was wird gesammelt

Der Browser sendet die Seiten-URL, Referrer, `navigator.languages` (navigator.languages), tatsächliche Seiten-Sprache (`<html lang>`), beworbene Übersetzungen (`hreflang` Links), explizit gewählte Sprache, wenn beobachtet, Zeitzone und Bildschirmbreite, sowie eine pro-Tab Session-ID. Der Server fügt das Land hinzu (via GeoIP) und berechnet die Lokalisierungslücke gegenüber den Projekt-Zielsprachen, beworbenen Übersetzungen und tatsächlichen Seiten-Sprache. Die Session-ID und die explizite Wahl verwenden `sessionStorage`; keine Cookies werden gesetzt und nichts wird identifiziert.
