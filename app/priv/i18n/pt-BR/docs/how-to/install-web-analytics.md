%{
  title: "Instalar análise web",
  summary:
    "Adicione o Glossia Web SDK ao seu site com uma única linha de HTML ou via npm, e comece a coletar sinais de localização.",
  category: "Passo a passo",
  order: 1
}
---
Este guia pressupõe que você tenha um projeto Glossia com o domínio do site configurado nas configurações de analytics do projeto. A coleta é identificada por esse domínio, portanto não há chave nem segredo para copiar.

## Opção A: tag de script

Adicione este trecho a cada página, idealmente no `<head>`:

```html
<script defer data-domain="example.com" src="https://cdn.glossia.ai/web.js"></script>
```

O SDK inicializa automaticamente, envia uma visualização de página ao carregar e registra visualizações subsequentes durante a navegação no lado do cliente em aplicativos de página única. `data-domain` padrão é `window.location.hostname` quando omitido, então você pode omiti-lo em sites de domínio único. Para usar um endpoint de coleta personalizado, adicione `data-endpoint="https://collect.your-host.com"`.

## Opção B: npm

Instale o pacote:

```bash
npm install @glossia/web
```

Inicialize-o uma vez no ponto de entrada da sua aplicação:

```ts
import glossia from "@glossia/web";

glossia.init();
```

O `domain` é inferido a partir de `window.location.hostname`, para que o SDK registre baseado no projeto registrado para o seu site. Passe `{ domain: "example.com" }` para sobrescrever, por exemplo, para enviar eventos de uma origem de staging para o mesmo projeto do que production.

Para registrar um evento personalizado, por exemplo, um cadastro:

```ts
glossia.track("signup");
```

## Verifique se funciona

1. Abra seu site em um navegador.
2. Abra a aba de rede e confirme que uma solicitação `POST` para `/api/analytics/events` retorna `202 Accepted`.
3. Dentro de um minuto, a visualização de página aparece no painel de analytics do seu projeto.

## O que é coletado

O navegador envia a URL da página, referrer, `navigator.languages`, zona horária e largura da tela, além de um ID de sessão por aba. O servidor adiciona o país (proveniente de GeoIP) e calcula o gap de localização em relação aos idiomas-alvo do seu projeto. Nenhum cookie é definido e nada é identificado por impressão digital.