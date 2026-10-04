%{
  title: "Instale análises web",
  summary:
    "Adicione o SDK da Glossia para a web ao seu site com uma única linha de HTML ou via npm, e comece a coletar sinais de localização.",
  category: "como-fazer",
  section: "analytics",
  order: 1
}
---
Este guia pressupõe que você tem um projeto Glossia com seu domínio do site configurado nas configurações de analytics do projeto. A coleção é identificada por esse domínio, portanto não há chave ou segredo para copiar.

## Opção A: tag script

Adicione este trecho a cada página, idealmente na `<head>`:

```html
<script defer data-domain="example.com" src="https://glossia.ai/assets/glossia-web.js"></script>
```

O SDK se inicializa automaticamente, envia uma visualização de página ao carregar e registra visualizações subsequentes em navegação de lado do cliente em aplicações de página única. `data-domain` padrão para `window.location.hostname` quando omitido, permitindo que você o use em um site de domínio único. Para usar um endpoint de coleção personalizado, adicione `data-endpoint="https://collect.your-host.com"`.

Se o seu site usa uma política de segurança de conteúdo, permita `https://glossia.ai` em ambos `script-src` (ou `script-src-elem` quando presente) e `connect-src`. O script carrega a partir de `/assets/glossia-web.js` e envia eventos para `/v1/collect` na mesma origem.

## Opção B: npm

Instale o pacote:

```bash
npm install @glossia/web
```

Inicialize-o uma vez no ponto de entrada do seu aplicativo:

```ts
import glossia from "@glossia/web";

glossia.init({ endpoint: "https://glossia.ai/v1/collect" });
```

Defina o endpoint de coleta explicitamente ao usar o pacote em seu próprio bundle, já que não há um endereço de script hospedado do qual inferi-lo.

`domain` é inferido a partir `window.location.hostname` Assim, o SDK grava os dados no projeto registrado para o seu site. Passe `{ domain: "example.com" }` para sobrescrever, por exemplo, enviando eventos de uma origem de staging para o mesmo projeto que o de produção.

Para registrar um evento personalizado, por exemplo, uma inscrição:

```ts
glossia.track("signup");
```

## Verifique seu domínio

Em seu projeto **Configurações de análise**, salve o domínio do seu site. O **Verifique a propriedade do domínio** cartão mostra o nome e o valor exatos do registro para o seu projeto. Adicione um registro de texto com seu provedor de domínio:

| Campo | Valor |
| --- | --- |
| Tipo | `TXT` ([registro de texto](https://www.cloudflare.com/learning/dns/dns-records/dns-txt-record/)) |
| Nome | `_glossia-verify.example.com` |
| Valor | `glossia-site-verification=YOUR_VERIFICATION_TOKEN` |

Use o domínio e o token exibidos nas suas configurações. Alguns provedores adicionam o domínio automaticamente; nesse caso, insira apenas `_glossia-verify` como o nome. Após publicar o registro, clique **Verificar domínio**. As alterações podem levar tempo para ficarem disponíveis, então tente novamente se o registro não for encontrado imediatamente.

Se você não puder editar seus registros do domínio, expanda **Alternativa: verifique com uma tag de metadados da página inicial**. Copie a tag gerada na `<head>` da sua página inicial e publique-a:

```html
<meta name="glossia-site-verification" content="YOUR_VERIFICATION_TOKEN">
```

Ambos os métodos comprovam o controle sobre o domínio configurado. O Glossia verifica o registro ou a página inicial deste domínio, então copiar o token para outro site não verifica a propriedade. O token é prova pública, não uma senha.

Assim que o domínio for verificado, o Glossia registra eventos do seu trecho de rastreamento. O trecho, por si só, não verifica a propriedade. Alterar o domínio configurado requer nova verificação.

## Verifique se funciona

1. Abra seu site em um navegador.
2. Abra a aba de rede e confirme uma `POST` requisição para `https://glossia.ai/v1/collect` retorna `202 Accepted`.
3. Após a coleta e processamento, a visualização da página aparece em **Análises** no dashboard do seu projeto. As traduções na página Visão Geral estão separadas do tráfego do site.

Uma `202 Accepted` a resposta confirma que o pedido chegou ao coletor. Domínios desconhecidos ou não verificados são também aceitos, mas não registram eventos, então confirme que o domínio configurado é verificado nas configurações de análise do projeto.

## O que é coletado

O navegador envia o URL da página, o referer, `navigator.languages`fuso horário, e largura da tela, além de um ID de sessão por guia. O servidor adiciona o país (via GeoIP) e calcula a lacuna de localização em relação às línguas-alvo do seu projeto. Não há cookies definidos e nada é rastreado.