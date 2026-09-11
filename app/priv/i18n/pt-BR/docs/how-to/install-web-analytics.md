%{
  title: "Instalar análise web",
  summary:
    "Adicione o SDK web do Glossia ao seu site com apenas uma linha de HTML ou via npm e comece a coletar sinais de localização.",
  category: "Tutorial",
  order: 1
}
---
Este guia pressupõe que você tenha um projeto Glossia com seu domínio do site configurado nas configurações de análise do projeto. A coleta é identificada por esse domínio, portanto não há chave ou segredo para copiar.

## Opção A: tag de script

Adicione este trecho a cada página, idealmente no `<head>`:

```html
<script defer data-domain="example.com" src="https://cdn.glossia.ai/web.js"></script>
```

O SDK se inicializa automaticamente, envia uma visualização de página ao carregar e registra visualizações de página subsequentes na navegação do lado do cliente em aplicativos de página única. `data-domain` o padrão é `window.location.hostname` quando omitido, assim você pode omiti-lo em um site de domínio único. Para usar um endpoint de coleta personalizado, adicione `data-endpoint="https://collect.your-host.com"`.

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

O `domain` é inferido de `window.location.hostname` Assim, o SDK registra no projeto cadastrado para o seu site. Passe `{ domain: "example.com" }` para substituir, por exemplo, enviando eventos de uma origem de homologação para o mesmo projeto da produção.

Para registrar um evento personalizado, por exemplo, um cadastro:

```ts
glossia.track("signup");
```

## Verifique se funciona

1. Abra o seu site em um navegador.
2. Abra a aba de rede e confirme uma `POST` requisição para `/api/analytics/events` retorna `202 Accepted`.
3. Em menos de um minuto, a visualização da página aparece no painel de análise do seu projeto.

## O que é coletado

O navegador envia a URL da página, o referrer, `navigator.languages`, fuso horário, e largura da tela, além de um ID de sessão por aba. O servidor adiciona o país (do GeoIP) e calcula a lacuna de localização em relação aos idiomas-alvo do seu projeto. Nenhum cookie é definido e nada é fingerprintado.