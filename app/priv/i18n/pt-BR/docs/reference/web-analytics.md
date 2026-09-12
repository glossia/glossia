%{
  title: "SDK de Análises",
  summary:
    "Os campos coletados, o endpoint de eventos e o modelo de privacidade por trás das análises web da Glossia.",
  category: "referência",
  order: 1
}
---
## Endpoint de eventos

`POST /api/analytics/events`

Aceita um evento JSON do `@glossia/web` SDK. Sempre responde `202 Accepted`, incluindo para domínios desconhecidos ou cargas malformadas, de modo que o SDK nunca exponha quais projetos coletam análises.

O projeto é resolvido pelo domínio do site que o snippet declara. `d` é autoritativo; quando ausente, o servidor recorre ao host de `u` (a URL da página) e em seguida a requisição `Origin`/`Referer`.

### Corpo da requisição

| Campo | Tipo   | Descrição                                                  |
|-------|--------|--------------------------------------------------------------|
| `d`   | string | Domínio do site que identifica o projeto (ex. `example.com`) Obrigatório. |
| `n`   | string | Nome do evento. Padrão. `pageview`.                          |
| `u`   | string | URL da página (`location.href`).                                  |
| `r`   | string | Referer (`document.referrer`).                              |
| `l`   | string | Idiomas do navegador (`navigator.languages.join(",")`).         |
| `tz`  | string | Zona horária IANA (`Intl.DateTimeFormat().resolvedOptions().timeZone`) |
| `sw`  | número | Largura da tela em pixels CSS.                                  |
| `sid` | Texto | ID de sessão por aba (sessionStorage, limpo ao fechar).       |

CORS está aberto (`Access-Control-Allow-Origin: *`)

## Campos derivados do servidor

Estes são calculados durante a ingestão e armazenados no lado do servidor. O IP bruto e o User-Agent nunca são armazenados.

| Campo             | Origem        | Descrição                                                         |
|-------------------|---------------|---------------------------------------------------------------------|
| `visitor_id`      | HMAC          | Hash rotativo diário de IP + UA + projeto. Não vinculável entre dias.  |
| `country_code`    | GeoIP         | ISO 3166-1 alpha-2 código. Vazio quando o GeoIP não está configurado.        |
| `device`          | User-Agent    | `desktop`, `mobile`, `tablet`, `bot`, ou `unknown`.                 |
| `browser`         | Agente-Utilizador    | `chrome`, `safari`, `firefox`, `edge`, `opera`, ou `unknown`.       |
| `os`              | User-Agent    | `windows`, `macos`, `ios`, `android`, `linux`, ou `unknown`.        |
| `hostname`        | URL da Página      | host em minúsculas.                                                    |
| `pathname`        | URL da Página      | componente do caminho.                                                     |
| `referrer_source` | Referer      | Referer host, inicial `www.`/`m.` removido.                        |
| `browser_language`| Idiomas     | Local normalizado mais preferido (ex. `pt-BR`).                    |
| `served_locale`   | Calculado      | Primeiro alvo suportado que corresponda à linguagem preferida, caso contrário vazio.   |
| `has_locale_gap`  | Computado      | `1` quando o visitante prefere um idioma que o projeto não oferece. |

## Modelo de privacidade

- **Sem armazenamento do lado do cliente.** O SDK não define cookies e armazena apenas um id de sessão por aba em `sessionStorage`, que o navegador limpa ao fechar.
- **Sem rastreamento.** Impressões digitais de Canvas, WebGL, fonte e áudio não são coletadas. O hash do servidor rotativo diariamente fornece identificadores únicos sem elas.
- **Nenhum identificador bruto persistido.** IP e User-Agent são lidos uma vez, hashados com um segredo do servidor e um sal diário, e depois descartados.
- **Escopo por projeto.** O mesmo navegador em dois projetos gera IDs de visitante não relacionados, de modo que os visitantes não podem ser rastreados entre clientes do Glossia.