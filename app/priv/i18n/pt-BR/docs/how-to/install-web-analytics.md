%{
  title: "Instalar analíticas web",
  summary:
    "Adicione o Glossia Web SDK ao seu site com uma linha de HTML ou via npm, e comece a coletar sinais de localização.",
  category: "guia",
  order: 1
}
---
Este guia assume que você possui um projeto Glossia com seu domínio do site configurado nas configurações de analytics do projeto. A Coleção é identificada por esse domínio, portanto, não há uma chave ou segredo para copiar.

## Opção A: tag script

Adicione este trecho a cada página, idealmente na `<head>`:

```html
<script defer data-domain="example.com" src="https://cdn.glossia.ai/web.js"></script>
```

O SDK se inicializa automaticamente, envia uma visualização de página ao carregar e registra visualizações de página subsequentes na navegação de lado do cliente em aplicativos de página única. `data-domain` define como padrão para `window.location.hostname` quando omitido, então você pode deixá-lo de lado em um site de domínio único. Para usar um endpoint de coleção personalizado, adicione `data-endpoint="https://collect.your-host.com"`.

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

O `domain` é inferido de `window.location.hostname` assim, o SDK registra-se no projeto registrado para o seu site. Passe `{ domain: "example.com" }` para substituir, por exemplo, para enviar eventos de uma origem de homologação para o mesmo projeto que a produção.

Para registrar um evento personalizado, por exemplo um cadastro:

```ts
glossia.track("signup");
```

## Verifique se funciona

1. Abra seu site em um navegador.
2. Abra a aba de rede e confirme um `POST` solicitação para `/api/analytics/events` retorna `202 Accepted`.
3. Em menos de um minuto, a visualização da página aparece no painel de análises do seu projeto.

## O que é coletado

O navegador envia a URL da página, o referrer, `navigator.languages`, fuso horário e largura da tela, além de um ID de sessão por aba. O servidor adiciona o país (do GeoIP) e calcula a lacuna de localização em relação às línguas-alvo do seu projeto. Nenhum cookie é definido e nada é fingerprintado.