%{
  title: "Instalar análise web",
  summary:
    "Adicione o SDK web do Glossia ao seu site com uma linha de HTML ou via npm, e comece a coletar sinais de localização.",
  category: "Passo a passo",
  order: 1
}
---
Este guia pressupõe que você possui um projeto Glossia com seu domínio do site configurado nas configurações de analytics do projeto. A coleta é identificada por esse domínio, portanto não há chave ou segredo para copiar.

## Opção A: tag de script

Adicione este trecho a todas as páginas, idealmente no `<head>`:

```html
<script defer data-domain="example.com" src="https://cdn.glossia.ai/web.js"></script>
```

O SDK se inicializa automaticamente, envia uma visualização de página ao carregar e grava visualizações subsequentes durante a navegação do lado do cliente em aplicativos de página única. `data-domain` padrão é `window.location.hostname` quando omitido, assim você pode omiti-lo em um site de domínio único. Para usar um endpoint de coleta personalizado, adicione `data-endpoint="https://collect.your-host.com"`.

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

O `domain` é inferido a partir de `window.location.hostname` assim o SDK registra-se no projeto registrado para o seu site. Forneça `{ domain: "example.com" }` para sobrescrever, por exemplo para enviar eventos de uma origem de staging para o mesmo projeto de produção.

Para registrar um evento personalizado, por exemplo um cadastro:

```ts
glossia.track("signup");
```

## Verifique se funciona

1. Abra seu site em um navegador.
2. Abra a aba de rede e confirme uma `POST` requisição para `/api/analytics/events` retorna `202 Accepted`.
3. Em menos de um minuto, a visualização da página aparece no painel de análise do seu projeto.

## O que é coletado

O navegador envia o URL da página, o referênciaur, `navigator.languages`, o horário, a largura da tela e um id de sessão por aba. O servidor adiciona o país (do GeoIP) e calcula o gap de localização em relação às linguagens-alvo do projeto. Nenhum cookie é definido e nada é fingerprinted.