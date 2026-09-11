%{
  title: "Instalar Web Analytics",
  summary:
    "Adicione o SDK Web da Glossia ao seu site com uma única linha de HTML ou via npm e comece a coletar sinais de localização.",
  category: "Tutorial",
  order: 1
}
---
Este guia pressupõe que você tenha um projeto Glossia com o domínio do site configurado nas configurações de análise do projeto. A coleta é identificada por esse domínio, por isso não há chave ou segredo para copiar.

## Opção A: tag script

Adicione este trecho a cada página, idealmente no `<head>`:

```html
<script defer data-domain="example.com" src="https://cdn.glossia.ai/web.js"></script>
```

O SDK se inicializa automaticamente, envia uma visualização de página ao carregar e registra visualizações subsequentes durante a navegação do lado do cliente em aplicações de página única. `data-domain` padrão é `window.location.hostname` quando omitido, assim você pode adicioná-lo em um site de domínio único. Para usar um endpoint de coleta personalizado, adicione `data-endpoint="https://collect.your-host.com"`.

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

O `domain` é inferido de `window.location.hostname` assim, o SDK registra no projeto registrado para o seu site. Passe `{ domain: "example.com" }` para substituir, por exemplo, enviando eventos de uma origem staging para o mesmo projeto de produção.

Para registrar um evento personalizado, por exemplo, uma inscrição:

```ts
glossia.track("signup");
```

## Verifique se funciona

1. Abra seu site em um navegador.
2. Abra a aba de rede e confirme uma `POST` solicitação para `/api/analytics/events` retorna `202 Accepted`.
3. Em menos de um minuto, a visualização da página aparece no painel analítico do seu projeto.

## O que é coletado

O navegador envia a URL da página, o referer, `navigator.languages`, o fuso horário, e a largura da tela, além de um ID de sessão por aba. O servidor adiciona o país (via GeoIP) e calcula a lacuna de localização em relação aos idiomas-alvo do seu projeto. Nenhuma cookie é definida e nada é rastreado.