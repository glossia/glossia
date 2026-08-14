%{
  title: "Instalar análise da web",
  summary: "Adicione o SDK web da Glossia ao seu site com uma linha de HTML ou via npm e comece a coletar sinais de localização.",
  category: "how-to",
  order: 1
}
---
Este guia pressupõe que você tenha um projeto do Glossia com o domínio do site configurado nas definições de análise do projeto. A coleta é identificada por esse domínio, portanto, não há nenhuma chave ou segredo para copiar.

## Opção A: tag de script

Adicione este trecho a todas as páginas, idealmente em `<head>`:

```html
<script defer data-domain="example.com" src="https://cdn.glossia.ai/web.js"></script>
```

O SDK é inicializado automaticamente, envia uma visualização de página ao carregar e registra as visualizações de página subsequentes durante a navegação no lado do cliente em aplicações de página única. Quando omitido, `data-domain` usa `window.location.hostname` como padrão, portanto, você pode adicioná-lo diretamente a um site com um único domínio. Para hospedar o endpoint de coleta em sua própria infraestrutura, adicione `data-endpoint="https://collect.your-host.com"`.

## Opção B: npm

Instale o pacote:

```bash
npm install @glossia/web
```

Inicialize-o uma vez no ponto de entrada da aplicação:

```ts
import glossia from "@glossia/web";

glossia.init();
```

O `domain` é inferido de `window.location.hostname`, permitindo que o SDK registre os dados no projeto cadastrado para o seu site. Passe `{ domain: "example.com" }` para substituir esse valor, por exemplo, para enviar eventos de uma origem de homologação ao mesmo projeto usado em produção.

Para registrar um evento personalizado, como um cadastro:

```ts
glossia.track("signup");
```

## Verifique o funcionamento

1. Abra seu site em um navegador.
2. Abra a guia de rede e confirme se uma solicitação `POST` para `/api/analytics/events` retorna `202 Accepted`.
3. Em até um minuto, a visualização de página será exibida no painel de análise do projeto.

## Dados coletados

O navegador envia o URL da página, a referência, `navigator.languages`, o fuso horário e a largura da tela, além de um identificador de sessão por guia. O servidor adiciona o país, com base no GeoIP, e calcula a lacuna de localização em relação aos idiomas de destino do projeto. Nenhum cookie é definido e nenhuma técnica de impressão digital é utilizada.