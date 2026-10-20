%{
  title: "Instale analítica web",
  summary:
    "Adicione o Glossia Web SDK ao seu site com uma linha de HTML ou via npm, e comece a coletar sinais de localização.",
  category: "Tutorial",
  section: "analytics",
  order: 1
}
---

Este guia pressupõe que você tenha um projeto do Glossia com o domínio do site configurado nas configurações de análise do projeto. A coleta é identificada por esse domínio, portanto não há chave ou segredo a copiar.

## Opção A: tag script

Adicione este fragmento a todas as páginas, idealmente no `<head>`:

```html
<script defer data-domain="example.com" src="https://glossia.ai/assets/glossia-web.js"></script>
```

O SDK é inicializado automaticamente, envia uma visualização de página ao carregar e registra visualizações de página subsequentes na navegação do lado do cliente em aplicativos de página única. O `data-domain` padrão é `window.location.hostname` quando omitido, então você pode omiti-lo em um site de domínio único. Para usar um ponto de extremidade de coleta personalizado, adicione `data-endpoint="https://collect.your-host.com"`.

Se seu site usa uma política de segurança de conteúdo, permita `https://glossia.ai` tanto em `script-src` (ou `script-src-elem` quando presente) quanto em `connect-src`. O script carrega de `/assets/glossia-web.js` e envia eventos para `/v1/collect` na mesma origem.

## Opção B: npm

Instale o pacote:

```bash
npm install @glossia/web
```

Iniciliaze-o uma vez no ponto de entrada do seu aplicativo:

```ts
import glossia from "@glossia/web";

glossia.init({ endpoint: "https://glossia.ai/v1/collect" });
```

Set the collection endpoint explicitly when using the package in your own bundle, since there is no hosted script address from which to infer it.

`domain` is inferred from `window.location.hostname` so the SDK records against the project registered for your site. Pass `{ domain: "example.com" }` to override, for example to send events from a staging origin to the same project as production.

To record a custom event, for example a signup:

```ts
glossia.track("signup");
```

## Verify your domain

In your project's **Analytics settings**, save your site domain. The **Verify domain ownership** card shows the exact record name and value for your project. Add a text record with your domain provider:

| Field | Value |
| --- | --- |
| Type | `TXT` ([text record](https://www.cloudflare.com/learning/dns/dns-records/dns-txt-record/)) |
| Name | `_glossia-verify.example.com` |
| Value | `glossia-site-verification=YOUR_VERIFICATION_TOKEN` |

Use the domain and token shown in your settings. Some providers add the domain automatically; in that case enter only `_glossia-verify` as the name. After publishing the record, click **Verify domain**. Changes may take time to become available, so retry if the record is not found immediately.

If you cannot edit your domain records, expand **Alternative: verify with a homepage meta tag**. Copy the generated tag into the `<head>` of your homepage and publish it:

```html
<meta name="glossia-site-verification" content="YOUR_VERIFICATION_TOKEN">
```

Either method proves control over the configured domain. Glossia checks that domain's record or homepage, so copying the token onto another website does not verify ownership. The token is public proof, not a password.

Once the domain is verified, Glossia records events from your tracking snippet. The snippet alone does not verify ownership. Changing the configured domain requires verification again.

## Verify it works

1. Open your site in a browser.
2. Open the network tab and confirm a `POST` request to `https://glossia.ai/v1/collect` returns `202 Accepted`.
3. After collection and processing, the pageview appears under **Analytics** in your project's dashboard. Translation runs on the Overview page are separate from website traffic.

A `202 Accepted` response confirms the request reached the collector. Unknown or unverified domains are also accepted but do not record events, so confirm the configured domain is verified in the project's analytics settings.

## What is collected

The browser sends the page URL, referrer, `navigator.languages`, timezone, and screen width, plus a per-tab session id. The server adds the country (from GeoIP) and computes the localization gap against your project's target languages. No cookies are set and nothing is fingerprinted.
