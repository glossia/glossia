%{
  title: "Web-Analytik installieren",
  summary:
    "Integrieren Sie den Glossia Web-SDK in Ihre Webseite mit einer einzigen Zeile HTML oder via npm und beginnen Sie mit der Erfassung von Lokalisierungssignalen.",
  category: "Anleitung",
  section: "analytics",
  order: 1
}
---

Dieser Leitfaden setzt voraus, dass Sie ein Glossia-Projekt haben, dessen Website-Domain in den Analyse-Einstellungen des Projekts konfiguriert ist. Die Erfassung wird durch diese Domäne identifiziert, sodass es keinen Schlüssel oder ein Geheimnis gibt, das kopiert werden kann.

## Option A: Script-Tag

Fügen Sie diesen Codeabschnitt auf jede Seite ein, idealerweise in `<head>`:

```html
<script defer data-domain="example.com" src="https://glossia.ai/assets/glossia-web.js"></script>
```

Das SDK initialisiert sich automatisch, sendet bei Laden einen Page-View und protokolliert weitere Page-Views bei der Client-Seiten-Navigation in Single-Page-Anwendungen. `data-domain` wird auf `window.location.hostname` gesetzt, wenn es weggelassen wird, sodass Sie es auf einer Single-Domain-Seite weglassen können. Um einen benutzerdefinierten Erfassungsendpunkt zu verwenden, fügen Sie `data-endpoint="https://collect.your-host.com"` hinzu.

Wenn Ihre Website eine Content-Security-Policy verwendet, erlauben Sie `https://glossia.ai` sowohl in `script-src` (oder `script-src-elem`, wenn vorhanden) als auch in `connect-src`. Das Skript lädt von `/assets/glossia-web.js` und sendet Events an `/v1/collect` auf derselben Herkunft.

## Option B: npm

Installieren Sie das Paket:

```bash
npm install @glossia/web
```

Initialisieren Sie es einmal im Einstiegspunkt Ihrer Anwendung:

```ts
import glossia from "@glossia/web";

glossia.init({ endpoint: "https://glossia.ai/v1/collect" });
```

Stellen Sie den Erfassungsendpunkt explizit fest, wenn Sie das Paket in Ihrem eigenen Bundle verwenden, da es keinen gehosteten Skript-Adresse gibt, von der ausgeleitet werden kann.

`domain` wird aus `window.location.hostname` abgeleitet, sodass das SDK gegen das Projekt einzeichnet, das für Ihre Website registriert ist. Übergeben Sie `{ domain: "example.com" }` zur Überschreibung, beispielsweise, um Ereignisse von einem Staging-Ursprung an dasselbe Projekt wie Production zu senden.

Um ein benutzerdefiniertes Event zu protokollieren, beispielsweise eine Anmeldung:

```ts
glossia.track("signup");
```

## Verfolgung expliziter Sprachauswahlen

Um die Auswahl eines Besuchers von der Browserpräferenz abzugrenzen, rufen Sie das SDK im Benutzer-Aktions-Handler Ihres Sprachauswahlmenüs auf, bevor Sie navigieren:

```js
glossia.selectLanguage("zh-Hans");
```

Diese Methode ist auf dem importierten SDK nach `glossia.init()` verfügbar und auf dem `glossia`-Globalbereich beim Verwenden des gehosteten Skripts.

Alternativ können Sie same-origin-Links zum Sprachwechsel kennzeichnen:

```html
<a href="/zh-hans/docs" data-glossia-language="zh-Hans">简体中文</a>
```

Verwenden Sie eine Integration pro Aktion, nicht beide. Annotierte Links protokollieren echte Benutzeraktivierung, einschließlich Tastaturaktivierung. Sie ignorieren skriptgesteuerte Klicks, Downloads, modifizierte Klicks, fremdursprachige Ziele und Links, die ein anderes Tab oder einen Rahmen öffnen, ohne Navigation zu verhindern.

Das SDK sendet sofort ein `language_selection`-Event und enthält die gewählte Sprache (`cl`) in nachfolgenden Events. Die Auswahl wird in `sessionStorage` für das aktuelle Tab und die Herkunft bis ersetzt bis eine andere Auswahl diese ersetzt. Ist der Speicher nicht verfügbar, dauert es nur so lange, bis die Seite entlädt. Keine Auswahl wird aus Umleitungen, URLs oder Änderungen an `<html lang>` abgeleitet.

Die Auswahl protokolliert die Absicht, nicht die erfolgreiche Navigation. Browserpräferenz, tatsächliche Pagesprache und explizite Auswahl bleiben getrennt. Der Sammler speichert die Auswahl; die berechnete Lückenberechnung auf Dashboard basierend auf Browser ist unverändert.

## Verifizieren Sie Ihre Domäne

In den **Analyse-Einstellungen** Ihres Projekts speichern Sie Ihre Website-Domain. Die **Verifizierung der Domainbesitz**-Karte zeigt den genauen Datensatznamen und den Wert für Ihr Projekt an. Fügen Sie einen Textdatensatz mit Ihrem Domain-Provider hinzu:

| Feld | Wert |
| --- | --- |
| Typ | `TXT` ([Textdatensatz](https://www.cloudflare.com/learning/dns/dns-records/dns-txt-record/)) |
| Name | `_glossia-verify.example.com` |
| Wert | `glossia-site-verification=YOUR_VERIFICATION_TOKEN` |

Verwenden Sie die Domäne und das Token, die in Ihren Einstellungen angezeigt werden. Einige Provider fügen die Domäne automatisch hinzu; in diesem Fall geben Sie nur `_glossia-verify` als Namen ein. Nach der Veröffentlichung des Datensatzes klicken Sie auf **Domain verifizieren**. Änderungen benötigen möglicherweise Zeit, um verfügbar zu werden, führen Sie den Versuch erneut aus, falls der Datensatz nicht sofort gefunden wird.

Wenn Sie Ihre Domain-Datensätze nicht bearbeiten können, erweitern Sie **Alternative: Verifizierung mit einem Homepage-Metadatensatz**. Kopieren Sie das generierte Tag in das `<head>` Ihrer Homepage und veröffentlichen Sie es:

```html
<meta name="glossia-site-verification" content="YOUR_VERIFICATION_TOKEN">
```

Jede der Methoden beweist Kontrolle über die konfigurierte Domäne. Glossia überprüft den Datensatz oder die Homepage der Domäne, sodass das Kopieren des Tokens auf eine andere Website den Besitz nicht bestätigt. Das Token ist öffentlicher Beweis, kein Passwort.

Sobald die Domäne verifiziert ist, protokolliert Glossia Events von Ihrem Tracking-Codeabschnitt. Der Codeabschnitt allein bestätigt den Besitz nicht. Eine Änderung des konfigurierten Domänenabschnitts erfordert erneut eine Verifizierung.

## Überprüfen Sie, ob es funktioniert

1. Öffnen Sie Ihre Website in einem Browser.
2. Öffnen Sie den Netzwerk-Tab und bestätigen Sie, dass eine `POST` Anfrage an `https://glossia.ai/v1/collect` `202 Accepted` zurückgibt.
3. Nach der Erfassung und Verarbeitung erscheint der Page-View unter **Analytik** im Dashboard Ihres Projekts. Übersetzungen, die auf der Übersicht-Seite laufen, sind getrennt vom Website-Volumen.

Eine `202 Accepted`-Antwort bestätigt, dass die Anfrage den Sammler erreicht hat. Unbekannte oder unverifizierte Domänen werden ebenfalls akzeptiert, protokollieren jedoch keine Events, also bestätigen Sie, dass die konfigurierte Domäne in den Analyse-Einstellungen des Projekts verifiziert wurde.

## Was wird erfasst

Der Browser sendet die Page-URL, den Referrer, `navigator.languages`, die tatsächliche Page-Sprache (`<html lang>`) angebotene Übersetzungen (`hreflang` Links), explizit gewählte Sprache, wenn beobachtet, Zeitzone und Bildschirmbreite, sowie eine pro Tab-Session-ID. Der Server fügt das Land hinzu (aus GeoIP) und berechnet die Lokalisierungslücke im Vergleich zu Ihren Projekt-Zielsprachen, angebotenen Übersetzungen und tatsächlichen Pagesprache. Die Session-ID und explizite Wahl verwenden `sessionStorage`; keine Cookies werden gesetzt und nichts wird vollständig gefingerzeichent.
