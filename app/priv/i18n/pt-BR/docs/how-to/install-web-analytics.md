%{
  title: "Instalar análise web",
  summary:
    "Adicione o SDK web da Glossia ao seu site com uma única linha de HTML ou via npm e comece a coletar sinais de localização.",
  category: "tutorial",
  section: "analytics",
  order: 1
}
---

Este guia pressupõe que você tenha um projeto Glossia com seu domínio do site configurado nas configurações de análise do projeto. A coleta é identificada por esse domínio, portanto, não há chave ou segredo para copiar.

## Opção A: tag de script

Adicione este trecho a todas as páginas, idealmente no `<head>`:

```html
<script defer data-domain="example.com" src="https://glossia.ai/assets/glossia-web.js"></script>
```

O SDK se initializa automaticamente, envia uma visualização de página ao carregar e registra as visualizações subsequentes ao realizar navegação do lado do cliente em aplicações de página única. `data-domain` padrão é `window.location.hostname` quando omitido, assim você pode removê-lo em sites de domínio único. Para usar um ponto de coleção personalizado, adicione `data-endpoint="https://collect.your-host.com"`.

Se seu site usa uma política de segurança de conteúdo, permita `https://glossia.ai` tanto em `script-src` (ou `script-src-elem` quando presente) quanto em `connect-src`. O script carrega de `/assets/glossia-web.js` e envia eventos para `/v1/collect` na mesma origem.

## Opção B: npm

Instale o pacote:

```bash
npm install @glossia/web
```

Inicialize-o uma vez no ponto de entrada da sua aplicação:

```ts
import glossia from "@glossia/web";

glossia.init({ endpoint: "https://glossia.ai/v1/collect" });
```

Configure explicitamente o ponto de coleção ao usar o pacote em seu próprio bundle, já que não há endereço de script hospedado do qual inferir.

O `domain` é inferido a partir de `window.location.hostname` assim o SDK registra no projeto registrado para o seu site. Passe `{ domain: "example.com" }` para sobrescrever, por exemplo, para enviar eventos de uma origem de testes para o mesmo projeto de produção.

Para registrar um evento personalizado, por exemplo, uma inscrição:

```ts
glossia.track("signup");
```

## Rastreie escolhas explícitas de idioma

Para distinguir a escolha do visitante de suas preferências do navegador, chame o SDK no manipulador de ação do usuário do seletor de idioma, antes de navegar:

```js
glossia.selectLanguage("zh-Hans");
```

Este método está disponível no SDK importado após `glossia.init()`, e no `glossia` global ao usar o script hospedado.

Alternativamente, anote os links de troca de idioma de mesma origem:

```html
<a href="/zh-hans/docs" data-glossia-language="zh-Hans">简体中文</a>
```

Use uma integração por ação, não ambas. Links anotados registram ativação real do usuário, incluindo ativação por teclado. Eles ignoram cliques feitos por script, downloads, cliques modificados, destinos de origem cruzada e links que abrem outra aba ou quadro, sem impedir a navegação.

O SDK envia imediatamente um evento `language_selection` e inclui o idioma escolhido (`cl`) em eventos subsequentes. A escolha é armazenada em `sessionStorage` para a aba e origem atual até que outra escolha a substitua. Se o armazenamento estiver indisponível, dura apenas até que a página seja desconectada. Nenhuma escolha é inferida de redirecionamentos, URLs ou alterações em `<html lang>`.

A seleção registra a intenção, não a navegação bem-sucedida. Preferência do navegador, idioma real da página e escolha explícita permanecem separados. O coletor armazena a escolha; o cálculo de lacuna baseado no navegador atual no painel não é alterado.

## Verifique seu domínio

Em **Configurações de análise** do seu projeto, salve o domínio do seu site. O cartão **Verificar propriedade do domínio** mostra o nome e valor exatos do registro para o seu projeto. Adicione um registro de texto com seu provedor de domínio:

| Campo | Valor |
| --- | --- |
| Tipo | `TXT` ([registro TXT](https://www.cloudflare.com/learning/dns/dns-records/dns-txt-record/)) |
| Nome | `_glossia-verify.example.com` |
| Valor | `glossia-site-verification=YOUR_VERIFICATION_TOKEN` |

Use o domínio e o token mostrados nas configurações. Alguns provedores adicionam o domínio automaticamente; nesse caso, insira apenas `_glossia-verify` como o nome. Após publicar o registro, clique em **Verificar domínio**. As alterações podem demorar para ficar disponíveis, tente novamente se o registro não for encontrado imediatamente.

Se você não puder editar seus registros de domínio, expanda **Alternativa: verificar com uma meta tag de página inicial**. Copie a tag gerada para o `<head>` da sua página inicial e publique-a:

```html
<meta name="glossia-site-verification" content="YOUR_VERIFICATION_TOKEN">
```

Qualquer método prova o controle sobre o domínio configurado. Glossia verifica o registro ou a página inicial desse domínio, portanto, copiar o token para outro site não comprova a propriedade. O token é uma prova pública, não uma senha.

Uma vez que o domínio é verificado, o Glossia registra eventos de seu snippet de rastreamento. O snippet sozinho não comprova a propriedade. Alterar o domínio configurado requer verificação novamente.

## Verifique o funcionamento

1. Abra o site em um navegador.
2. Abra a aba de rede e confirme que uma solicitação `POST` para `https://glossia.ai/v1/collect` retorna `202 Accepted`.
3. Após a coleta e o processamento, a visualização de página aparece em **Análise** no painel do seu projeto. As traduções executadas na página de Visão geral são separadas do tráfego do site.

Uma resposta `202 Accepted` confirma que a solicitação alcançou o coletor. Domínios desconhecidos ou não verificados também são aceitos, mas não registram eventos, portanto, confirme que o domínio configurado é verificado nas configurações de análise do projeto.

## O que é coletado

O navegador envia a URL da página, referenciante, `navigator.languages`, idioma real da página (`<html lang>`), traduções anunciadas (`hreflang` links), idioma escolhido explicitamente quando observado, fuso horário e largura da tela, além de um ID de sessão por aba. O servidor adiciona o país (do GeoIP) e calcula a lacuna de localização contra os idiomas-alvo do seu projeto, traduções anunciadas e idioma real da página. O ID de sessão e a escolha explícita usam `sessionStorage`; nenhum cookie é definido e nada é submetido a fingerprinting.
