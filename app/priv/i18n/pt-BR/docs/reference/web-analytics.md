%{
  title: "SDK de análise",
  summary: "Os campos coletados, o endpoint de eventos e o modelo de privacidade da análise web da Glossia.",
  category: "reference",
  order: 1
}
---
## Endpoint de eventos

`POST /api/analytics/events`

Aceita um evento JSON do SDK `@glossia/web`. Sempre responde com `202 Accepted`, inclusive para domínios desconhecidos ou cargas malformadas, para que o SDK nunca revele quais projetos coletam dados analíticos.

O projeto é identificado pelo domínio do site declarado pelo trecho de código. `d` é a fonte autoritativa. Quando ele não está presente, o servidor usa como alternativa o host de `u` (a URL da página) e, em seguida, `Origin`/`Referer` da solicitação.

### Corpo da solicitação

| Campo | Tipo   | Descrição                                                  |
|-------|--------|--------------------------------------------------------------|
| `d`   | string | Domínio do site que identifica o projeto (por exemplo, `example.com`). Obrigatório. |
| `n`   | string | Nome do evento. O padrão é `pageview`.                          |
| `u`   | string | URL da página (`location.href`).                                  |
| `r`   | string | Referenciador (`document.referrer`).                              |
| `l`   | string | Idiomas do navegador (`navigator.languages.join(",")`).         |
| `tz`  | string | Fuso horário da IANA (`Intl.DateTimeFormat().resolvedOptions().timeZone`). |
| `sw`  | number | Largura da tela em pixels CSS.                                  |
| `sid` | string | ID de sessão por aba (sessionStorage, removido ao fechar).       |

O CORS é aberto (`Access-Control-Allow-Origin: *`) porque o endpoint não aceita credenciais.

## Campos derivados pelo servidor

Esses campos são calculados durante a ingestão e armazenados no servidor. O endereço IP bruto e o User-Agent nunca são armazenados.

| Campo             | Origem        | Descrição                                                         |
|-------------------|---------------|-------------------------------------------------------------------|
| `visitor_id`      | Código de autenticação de mensagem baseado em hash | Hash do endereço de Protocolo de Internet + agente do usuário + projeto, alternado diariamente. Não pode ser correlacionado entre dias. |
| `country_code`    | Geolocalização | Código alfa-2 do padrão 3166-1 da Organização Internacional de Normalização. Vazio quando a geolocalização não está configurada. |
| `device`          | Agente do usuário | `desktop`, `mobile`, `tablet`, `bot` ou `unknown`. |
| `browser`         | Agente do usuário | `chrome`, `safari`, `firefox`, `edge`, `opera` ou `unknown`. |
| `os`              | Agente do usuário | `windows`, `macos`, `ios`, `android`, `linux` ou `unknown`. |
| `hostname`        | Endereço da página | Host convertido em letras minúsculas. |
| `pathname`        | Endereço da página | Componente do caminho. |
| `referrer_source` | Referenciador | Host referenciador, sem o prefixo `www.`/`m.`. |
| `browser_language`| Idiomas | Localidade normalizada de maior preferência (por exemplo, `pt-BR`). |
| `served_locale`   | Calculado | Primeiro idioma de destino compatível com um idioma preferido ou vazio se não houver correspondência. |
| `has_locale_gap`  | Calculado | `1` quando o visitante prefere um idioma que não é oferecido pelo projeto. |

## Modelo de privacidade

- **Nenhum armazenamento no cliente.** O kit de desenvolvimento de software não define cookies e armazena apenas um identificador de sessão por aba em `sessionStorage`, que o navegador apaga ao ser fechado.
- **Nenhuma coleta de impressão digital.** Não são coletadas impressões digitais de canvas, gráficos da Web, fontes ou áudio. O hash do servidor, alternado diariamente, permite contabilizar visitantes únicos sem esses dados.
- **Nenhum identificador bruto armazenado.** O endereço de Protocolo de Internet e o agente do usuário são lidos uma vez, processados por hash com um segredo do servidor e um salt diário e, em seguida, descartados.
- **Escopo por projeto.** O mesmo navegador em dois projetos gera identificadores de visitante não relacionados. Assim, os visitantes não podem ser rastreados entre clientes da Glossia.