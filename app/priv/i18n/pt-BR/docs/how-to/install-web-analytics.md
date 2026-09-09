%{
  title: "Instalar análises web",
  summary:
    "Adicione o SDK web do Glossia ao seu site com uma linha de HTML ou via npm, e comece a coletar sinais de localização.",
  category: "Tutorial",
  order: 1
}
---
Este guia assume que você possui um projeto Glossia com o domínio do site configurado nas configurações de análise do projeto. A coleção é identificada por esse domínio, portanto não há chave ou segredo para copiar.

## Opção A: tag de script

Adicione este trecho a cada página, idealmente na `<head>`:

```html
<script defer data-domain="example.com" src="https://cdn.glossia.ai/web.js"></script>
```

O SDK se inicializa automaticamente, envia uma visualização de página ao carregar e registra visualizações de página subsequentes na navegação do lado do cliente em aplicações de página única. `data-domain` define-se por padrão `window.location.hostname` quando omitido, para que você possa adicioná-lo a um site de domínio único. Para usar um endpoint de coleção personalizado, adicione `data-endpoint="https://collect.your-host.com"`.

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

O `domain` é inferido de `window.location.hostname` Portanto, o SDK registra-se no projeto registrado para o seu site. Passe `{ domain: "example.com" }` para sobrescrever, por exemplo, para enviar eventos de uma origem de staging para o mesmo projeto que em produção.

Para registrar um evento personalizado, por exemplo um cadastro:

```ts
glossia.track("signup");
```

## Verifique se funciona

1. Abra seu site em um navegador.
2. Abra a aba de rede e confirme uma `POST` requisição para `/api/analytics/events` retorna `202 Accepted`.
3. Em um minuto, a visualização da página aparece no painel de análise do seu projeto.

## O que é coletado

O navegador envia o URL da página, referrer, `navigator.languages`, fuso horário e largura da tela, além de um ID de sessão por aba. O servidor adiciona o país (do GeoIP) e calcula o gap de localização em relação aos idiomas-alvo do seu projeto. Não são definidos cookies e nada é fingerprintado.