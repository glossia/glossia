%{
  title: "Instalar análise de web",
  summary:
    "Adicione o SDK web do Glossia ao seu site com uma linha de HTML ou via npm e comece a coletar sinais de localização.",
  category: "Guia prático",
  section: "Análise",
  order: 1
}
---
Este guia pressupõe que você tenha um projeto Glossia com seu domínio do site configurado nas configurações de análise do projeto. A coleta é identificada por esse domínio, portanto, não há chave ou segredo para copiar.

## Opção A: tag script

Adicione este trecho a cada página, idealmente no `<head>`:

```html
<script defer data-domain="example.com" src="https://cdn.glossia.ai/web.js"></script>
```

O SDK se inicializa automaticamente, envia uma visualização de página ao carregar e registra visualizações subsequentes de navegação em aplicativos de página única. `data-domain` adota como padrão `window.location.hostname` quando omitido, para que você possa omiti-lo em um site de domínio único. Para usar um endpoint de coleta personalizado, adicione `data-endpoint="https://collect.your-host.com"`.

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

O `domain` é inferido de `window.location.hostname` portanto o SDK registra no projeto registrado para o seu site. Passe `{ domain: "example.com" }` para sobrescrever, por exemplo, para enviar eventos de uma origem de homologação para o mesmo projeto de produção.

Para registrar um evento personalizado, por exemplo, um cadastro:

```ts
glossia.track("signup");
```

## Verifique se funciona

1. Abra seu site em um navegador.
2. Abra a guia de rede e confirme uma `POST` solicitação para `/api/analytics/events` retorna `202 Accepted`.
3. Em um minuto, a visualização da página aparece no painel de análise do seu projeto.

## O que é coletado

O navegador envia a URL da página, referrer, `navigator.languages`, fuso horário, e largura da tela, além de um ID de sessão por aba. O servidor adiciona o país (do GeoIP) e calcula a lacuna de localização em relação às linguagens-alvo do seu projeto. Nenhum cookie é definido e nada é fingerprinted.