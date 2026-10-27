%{
  title: "Instalar análise web",
  summary:
    "Adicione a SDK web da Glossia ao seu site com uma única linha de HTML ou via npm e comece a coletar sinais de localização.",
  category: "guia",
  section: "analytics",
  order: 1
}
---

Este guia pressupõe que você tem um projeto Glossia com seu domínio do site configurado nas configurações de análise do projeto. A coleta é identificada por aquele domínio, por isso não há chave ou segredo para copiar.

## Opção A: tag script

Adicione este trecho a cada página, idealmente em `<head>`:

```html
<script defer data-domain="example.com" src="https://glossia.ai/assets/glossia-web.js"></script>
```

O SDK inicializa automaticamente, envia uma visualização de página ao carregar e registra visualizações de página subsequentes na navegação do lado do cliente em SPAs. `data-domain` padrão é `window.location.hostname` quando omitido, por isso você pode removê-lo de um site de único domínio. Para usar um endpoint de coleta personalizado, adicione `data-endpoint="https://collect.your-host.com"`.

Se seu site usa política de segurança de conteúdo, permita `https://glossia.ai` tanto em `script-src` (ou `script-src-elem` quando presente) quanto em `connect-src`. O script carrega a partir de `/assets/glossia-web.js` e envia eventos para `/v1/collect` na mesma origem.

## Opção B: npm

Instale o pacote:

```bash
npm install @glossia/web
```

Inicialize-o uma vez no ponto de entrada de sua aplicação:

```ts
import glossia from "@glossia/web";

glossia.init({ endpoint: "https://glossia.ai/v1/collect" });
```

Defina o endpoint de coleta explicitamente ao usar o pacote em seu próprio bundle, visto que não há um endereço de script hospedado de onde inferir.

`domain` é inferido de `window.location.hostname` para que o SDK registre contra o projeto registrado para seu site. Passe `{ domain: "example.com" }` para sobrescrever, por exemplo para enviar eventos de uma origem de teste para o mesmo projeto que produção.

Para registrar um evento personalizado, por exemplo, uma inscrição:

```ts
glossia.track("signup");
```

## Rastrear escolhas explícitas de idioma

Para distinguir a escolha de um visitante de sua preferência de navegador, chame o SDK no manipulador de ação do usuário de seu seletor de idioma, antes da navegação:

```js
glossia.selectLanguage("zh-Hans");
```

Este método está disponível no SDK importado após `glossia.init()`, e na global `glossia` ao usar o script hospedado.

Alternativamente, anote links de troca de idioma de mesma origem:

```html
<a href="/zh-hans/docs" data-glossia-language="zh-Hans">简体中文</a>
```

Use uma integração por ação, não ambas. Links anotados registram ativação genuína do usuário, incluindo ativação pelo teclado. Eles ignoram cliques programáticos, downloads, cliques modificados, destinos de origem cruzada e links que abrem outra aba ou quadro, sem impedir a navegação.

O SDK envia imediatamente um evento `language_selection` e inclui o idioma escolhido (`cl`) em eventos subsequentes. A escolha é armazenada na `sessionStorage` para a aba atual e origem até que outra escolha a substitua. Se o armazenamento não estiver disponível, dura apenas até que a página descarregue. Nenhuma escolha é inferida de redirecionamentos, URLs, ou alterações em `<html lang>`.

A seleção registra intenção, não navegação bem-sucedida. Preferência do navegador, idioma real da página e escolha explícita permanecem separados. O coletor verifica uma escolha válida em vez de preferências do navegador ao calcular a lacuna de localização. Uma escolha elimina a lacuna apenas se corresponder a um objetivo do projeto, uma tradução anunciada, ou o idioma real da página; um idioma escolhido indisponível ainda tem lacuna. Escolhas ausentes ou inválidas usam preferências do navegador como antes. Totais do painel e insígnias usam a decisão armazenada de cada evento; bandeiras históricas permanecem inalteradas.

## Verifique seu domínio

Em suas **Configurações de análise** do projeto, grave seu domínio de site. O cartão **Verificar propriedade do domínio** mostra o nome e o valor exatos do registro para seu projeto. Adicione um registro de texto com seu provedor de domínio:

| Campo | Valor |
| --- | --- |
| Tipo | `TXT` ([registro de texto](https://www.cloudflare.com/learning/dns/dns-records/dns-txt-record/)) |
| Nome | `_glossia-verify.example.com` |
| Valor | `glossia-site-verification=YOUR_VERIFICATION_TOKEN` |

Use o domínio e o token mostrados em suas configurações. Alguns provedores adicionam o domínio automaticamente; nesses casos, insira apenas `_glossia-verify` como o nome. Após publicar o registro, clique em **Verificar domínio**. Alterações podem levar tempo para ficar disponíveis, portanto, tente novamente se o registro não for encontrado imediatamente.

Se não puder editar seus registros de domínio, expanda **Alternativa: verificar com uma meta tag de página inicial**. Copie a tag gerada no `<head>` de sua página inicial e publique-a:

```html
<meta name="glossia-site-verification" content="YOUR_VERIFICATION_TOKEN">
```

Ambos os métodos demonstram controle sobre o domínio configurado. O Glossia verifica o registro ou a página inicial daquele domínio, por isso copiar o token em outro site não confirma propriedade. O token é prova pública, não senha.

Assim que o domínio for verificado, o Glossia registra eventos de seu trecho de rastreamento. Apenas o trecho não confirma propriedade. Alterar o domínio configurado exige nova verificação.

## Verifique se funciona

1. Abra seu site em um navegador.
2. Abra a aba de rede e confirme que uma requisição `POST` para `https://glossia.ai/v1/collect` retorna `202 Accepted`.
3. Após a coleta e o processamento, a visualização de página aparece em **Análise** no painel de seu projeto. Execuções de tradução na página Visão geral são separadas do tráfego do site.

Uma resposta `202 Accepted` confirma que a requisição chegou ao coletor. Domínios desconhecidos ou não verificados também são aceitos, mas não registram eventos, por isso confirme que o domínio configurado foi verificado nas configurações de análise do projeto.

## O que é coletado

O navegador envia a URL da página, o remetente, `navigator.languages`, o idioma real da página (`<html lang>`), traduções anunciadas (`hreflang` links), idioma escolhido explicitamente quando observado, o fuso horário e a largura da tela, além de um ID de sessão por aba. O servidor adiciona o país (a partir do GeoIP) e calcula a lacuna de localização contra os idiomas-alvo do projeto, traduções anunciadas e idioma real da página. O ID da sessão e a escolha explícita usam `sessionStorage`; não há cookies definidos e nada é fingerprinted.
