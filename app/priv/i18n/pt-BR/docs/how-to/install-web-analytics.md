%{
  title: "Instalar análise do site",
  summary:
    "Adicione o SDK Web do Glossia ao seu site com uma linha de HTML ou via npm e comece a coletar sinais de localização.",
  category: "Passo a passo",
  order: 1
}
---
Este guia pressupõe que você tenha um projeto Glossia com o domínio do site do projeto configurado nas configurações de análise do projeto. A coleta é identificada por esse domínio, assim não há chave nem segredo para copiar.

## Opção A: tag script

Adicione este fragmento em todas as páginas, idealmente no `<head>`:

```html
<script defer data-domain="example.com" src="https://cdn.glossia.ai/web.js"></script>
```

O SDK se inicializa automaticamente, envia uma visualização de página ao carregar e registra visualizações subsequentes em navegação do lado do cliente em aplicativos de página única. `data-domain` assume por padrão `window.location.hostname` quando omitido, para que você possa omiti-lo em um site de domínio único. Para usar um endpoint de coleta personalizado, adicione `data-endpoint="https://collect.your-host.com"`.

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

O `domain` é inferido de `window.location.hostname` assim, o SDK registra no projeto associado ao seu site. Passe `{ domain: "example.com" }` para sobrescrever, por exemplo, enviar eventos de uma origem de staging para o mesmo projeto de produção.

Para registrar um evento personalizado, por exemplo, um cadastro:

```ts
glossia.track("signup");
```

## Verifique se funciona

1. Abra seu site no navegador.
2. Abra a aba de rede e confirme uma `POST` requisição para `/api/analytics/events` retorna `202 Accepted`.
3. Em menos de um minuto, a visualização da página aparecerá no painel de análises do seu projeto.

## O que é coletado

O navegador envia a URL da página, referrer, `navigator.languages`o fuso horário, e a largura da tela, além de um ID de sessão por aba. O servidor adiciona o país (via GeoIP) e calcula a lacuna de localização em relação aos idiomas de destino do seu projeto. Nenhum cookie é definido e nada é identificado por meio de fingerprinting.