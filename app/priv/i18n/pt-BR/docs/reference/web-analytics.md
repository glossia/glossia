%{
  title: "SDK de Analítica",
  summary:
    "Os campos coletados, o endpoint de eventos e o modelo de privacidade por trás das análises web da Glossia.",
  category: "referência",
  order: 1
}
---
## Endpoint de Eventos

`POST /api/analytics/events`

Aceita um evento JSON do `@glossia/web` SDK. Sempre responde `202 Accepted`, inclusive para domínios desconhecidos ou payloads malformados, para que o SDK nunca revele quais projetos coletam análises.

O projeto é resolvido pelo domínio de site que o trecho declara. `d` é autoritário; quando ausente, o servidor recorre ao host de `u` (a URL da página) e em seguida o pedido `Origin`/`Referer`.

### Corpo da requisição

| Campo | Tipo   | Descrição                                                  |
|-------|--------|--------------------------------------------------------------|
| `d`   | string | Domínio do site que identifica o projeto (ex. `example.com`). Obrigatório. |
| `n`   | string | Nome do evento. Padrão para `pageview`.                          |
| `u`   | string | URL da página (`location.href`).                                  |
| `r`   | string | Referer (`document.referrer`).                              |
| `l`   | string | Idiomas do navegador (`navigator.languages.join(",")`)         |
| `tz`  | string | Fuso horário IANA (`Intl.DateTimeFormat().resolvedOptions().timeZone`) |
| `sw`  | number | Largura da tela em pixels CSS.                                  |
| `sid` | string | ID da sessão por aba (sessionStorage, limpo ao fechar).       |

CORS está aberto (`Access-Control-Allow-Origin: *`) porque o endpoint não aceita credenciais.

## Campos derivados do servidor

Esses são computados na ingestão e armazenados no servidor. O IP bruto e o User-Agent nunca são armazenados.

| Campo             | Origem        | Descrição                                                         |
|-------------------|---------------|---------------------------------------------------------------------|
| `visitor_id`      | HMAC          | Hash de IP + UA + projeto rotado diariamente. Não linkável entre dias.  |
| `country_code`    | GeoIP         | código ISO 3166-1 alpha-2. Vazio quando o GeoIP não está configurado.        |
| `device`          | User-Agent    | `desktop`, `mobile`, `tablet`, `bot`, ou `unknown`.                 |
| `browser`         | User-Agent    | `chrome`, `safari`, `firefox`, `edge`, `opera`, ou `unknown`.       |
| `os`              | User-Agent    | `windows`, `macos`, `ios`| User-Agent    | `android`, `linux`, ou `unknown`.        |
| `hostname`        | URL da Página      | Host em minúsculas.                                                    |
| `pathname`        | URL da Página      | Componente de caminho.                                                     |
| `referrer_source` | Referente      | Referente host, inicial `www.`/`m.` recortado.                        |
| `browser_language`| Idiomas     | Localização normalizada mais preferida (ex. `pt-BR`).                    |
\\u003cspan class=\\"hidden-paragraph\\" style=\\"display:none\\"\\u003e|\\u003c/span\\u003e `served_locale`   \\u003cspan class=\\"hidden-paragraph\\" style=\\"display:none\\"\\u003e| Calculado      | Primeiro alvo suportado que corresponde a um idioma preferido, senão vazio.   |\\u003c/span\\u003e
| `has_locale_gap`  | Calculado      | `1` quando o visitante prefere um idioma que o projeto não oferece. |

## Modelo de privacidade

- **Sem armazenamento no lado do cliente.** O SDK não define cookies e armazena apenas um ID de sessão por aba em `sessionStorage`", que o navegador limpa ao fechar.
- **Sem fingerprinting.** As impressões digitais de Canvas, WebGL, fonte e áudio não são coletadas. O hash do servidor rotacionado diariamente fornece identificadores únicos sem elas.
- **Nenhum identificador bruto persistido.** IP e User-Agent são lidos uma vez, hashados com um segredo do servidor e um sal diário, depois descartados.
- **Escopo por projeto.** O mesmo navegador em dois projetos gera identificadores de visitantes não relacionados, assim os visitantes não podem ser rastreados entre os clientes do Glossia.