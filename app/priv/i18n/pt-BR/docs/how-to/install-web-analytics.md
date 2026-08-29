%{
  title: "Instale a análise web",
  summary: "Adicione o SDK web da Glossia ao seu site com uma linha de HTML ou via npm e comece a coletar sinais de localização.",
  category: "instruções",
  order: 1
}
---
Este guia pressupõe que você tem um projeto Glossia com seu domínio do site configurado nas configurações de análise do projeto. A coleta é identificada por esse domínio, e portanto não há chave ou segredo para copiar.

## Opção A: tag script

Adicione este trecho a cada página, idealmente no `<head>`:

```html
<script defer data-domain="example.com" src="https://cdn.glossia.ai/web.js"></script>
```

O SDK se inicializa automaticamente, envia uma visualização de página ao carregar e registra visualizações de página subsequentes em navegação do lado do cliente em aplicações de página única. O atributo `data-domain` padrão é `window.location.hostname` quando omitido, portanto você pode omiti-lo em um site de domínio único. Para usar um endpoint de coleta personalizado, adicione `data-endpoint="https://collect.your-host.com"`.

## Opção B: npm

Instale o pacote:

```bash
npm install @glossia/web
```

Inicialize-o uma vez no ponto de entrada do seu aplicativo:

```ts
import glossia from "@glossia/web";

glossia.init();
```

O `domain` é inferido a partir de `window.location.hostname`, de modo que o SDK registra no projeto registrado para o seu site. Passe `{ domain: "example.com" }` para sobrescrever, por exemplo, para enviar eventos de uma origem de teste para o mesmo projeto do que produção.

Para registrar um evento personalizado, por exemplo, uma inscrição:

```ts
glossia.track("signup");
```

## Verifique se funciona

1. Abra seu site em um navegador.
2. Abra a guia de rede e confirme que uma requisição `POST` para `/api/analytics/events` retorna `202 Accepted`.
3. Dentro de um minuto, a visualização de página aparece no painel de análise do seu projeto.

## O que é coletado

O navegador envia a URL da página, referrer, `navigator.languages`, fuso horário e largura da tela, além de um ID de sessão por aba. O servidor adiciona o país (via GeoIP) e calcula o gap de localização em relação às línguas-alvo do seu projeto. Nenhum cookie é definido e nada é rastreado por impressão digital.