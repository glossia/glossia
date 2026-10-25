%{
  title: "Instalar análises web",
  summary:
    "Adicione o SDK web da Glossia ao seu site com uma linha de HTML ou via npm e comece a coletar sinais de localização.",
  category: "Como fazer",
  section: "analytics",
  order: 1
}
---

Este guia pressupõe que você tenha um projeto Glossia com seu domínio do site configurado nas configurações de análise do projeto. A coleta é identificada por aquele domínio, não havendo chave ou segredo para copiar.

## Opção A: tag de script

Adicione este trecho a todas as páginas, idealmente no `<head>`:

```html
<script defer data-domain="example.com" src="https://glossia.ai/assets/glossia-web.js"></script>
```

O SDK inicia automaticamente, envia uma visualização de página ao carregar e registra as visualizações de página subsequentes na navegação do cliente em aplicações de página única. O `data-domain` padrão é `window.location.hostname` quando omitido, então você pode removê-lo em um site de único domínio. Para usar um endpoint de coleta personalizado, adicione `data-endpoint="https://collect.your-host.com"`.

Se seu site usa uma política de segurança de conteúdo, permita `https://glossia.ai` tanto em `script-src` (ou `script-src-elem` quando presente) quanto em `connect-src`. O script carrega de `/assets/glossia-web.js` e envia eventos para `/v1/collect` na mesma origem.

## Opção B: npm

Instale o pacote:

```bash
npm install @glossia/web
```

Inicie-o uma vez no ponto de entrada da sua aplicação:

```ts
import glossia from "@glossia/web";

glossia.init({ endpoint: "https://glossia.ai/v1/collect" });
```

Defina o endpoint de coleta explicitamente ao usar o pacote no seu próprio bundle, pois não há endereço de script hospedado a partir do qual inferi-lo.

O `domain` é inferido a partir de `window.location.hostname` para que o SDK registre contra o projeto registrado para seu site. Passe `{ domain: "example.com" }` para sobrescrever, por exemplo, para enviar eventos de uma origem de teste para o mesmo projeto que a produção.

Para registrar um evento personalizado, por exemplo, um cadastro:

```ts
glossia.track("signup");
```

## Verifique seu domínio

Em suas **Configurações de análise** do projeto, salve o domínio do seu site. O cartão de **Verifique a propriedade do domínio** exibe o nome exato do registro e o valor para o seu projeto. Adicione um registro de texto com seu provedor de domínio:

| Campo | Valor |
| --- | --- |
| Tipo | `TXT` ([registro de texto](https://www.cloudflare.com/learning/dns/dns-records/dns-txt-record/)) |
| Nome | `_glossia-verify.example.com` |
| Valor | `glossia-site-verification=YOUR_VERIFICATION_TOKEN` |

Use o domínio e o token mostrados nas suas configurações. Alguns provedores adicionam o domínio automaticamente; nesse caso, digite apenas `_glossia-verify` como o nome. Após publicar o registro, clique em **Verificar o domínio**. As alterações podem levar tempo para ficar disponíveis, então reinicie se o registro não for encontrado imediatamente.

Se não puder editar seus registros de domínio, expanda **Alternativa: verificar com uma tag meta de página inicial**. Copie a tag gerada no `<head>` da sua página inicial e publique:

```html
<meta name="glossia-site-verification" content="YOUR_VERIFICATION_TOKEN">
```

Ambos os métodos comprovam o controle sobre o domínio configurado. O Glossia verifica o registro ou a página inicial desse domínio, portanto copiar o token para outro site não valida a propriedade. O token é uma prova pública, não uma senha.

Assim que o domínio for verificado, o Glossia registra eventos do seu trecho de rastreamento. O trecho sozinho não valida a propriedade. Alterar o domínio configurado requer verificação novamente.

## Verifique se funciona

1. Abra seu site em um navegador.
2. Abra a aba de rede e confirme que uma requisição `POST` para `https://glossia.ai/v1/collect` retorna `202 Accepted`.
3. Após a coleta e o processamento, a visualização de página aparece em **Análise** no painel do seu projeto. As traduções na página de Visão Geral são separadas do tráfego do site.

Uma resposta `202 Accepted` confirma que a requisição chegou ao coletor. Domínios desconhecidos ou não verificados também são aceitos, mas não registram eventos, portanto confirme que o domínio configurado é verificado nas configurações de análise do projeto.

## O que é coletado

O navegador envia a URL da página, o referrer, `navigator.languages`, o fuso horário e a largura da tela, além de um ID de sessão por aba. O servidor adiciona o país (via GeoIP) e calcula a lacuna de localização contra os idiomas-alvo do seu projeto. Nenhum cookie é definido e nada é rastreado por impressão digital.
