%{
  title: "SDK de Análise",
  summary:
    "Os campos coletados, o endpoint de eventos e o modelo de privacidade por trás das análises web do Glossia.",
  category: "Referência",
  order: 1
}
---
## Endpoint de eventos

`POST /api/analytics/events`

Aceita um evento JSON do `@glossia/web` SDK. Sempre responde `202 Accepted`, inclusive para domínios desconhecidos ou cargas malformadas, para que o SDK nunca revele quais projetos coletam análises.

O projeto é resolvido pelo domínio do site que o trecho declara. `d` é autoritativo; quando está ausente o servidor recorre ao host de `u` (a URL da página) e depois da solicitação `Origin`/`Referer`.

### Corpo da requisição

| Campo | Tipo   | Descrição                                                  |
|-------|--------|--------------------------------------------------------------|
| `d`   | string | Domínio do site que identifica o projeto (por exemplo, `example.com`). Obrigatório. |
| `n`   | string | Nome do evento. Padrão `pageview`.                          |
| `u`   | string | URL da página (`location.href`).                                  |
| `r`   | string | Remetente (`document.referrer`).                              |
| `l`   | string | Idiomas do navegador (`navigator.languages.join(",")`).         |
| `tz`  | string | fuso horário IANA (`Intl.DateTimeFormat().resolvedOptions().timeZone`). |
| `sw`  | number | Largura da tela em pixels CSS.                                  |
| `sid` | string | ID de sessão por aba (sessionStorage, limpo ao fechar).       |

CORS está aberto (`Access-Control-Allow-Origin: *`) porque o endpoint não aceita credenciais.

## Campos derivados do servidor

Estes são calculados na ingestão e armazenados no servidor. O IP e o User-Agent brutos nunca são armazenados.

| Campo             | Origem        | Descrição                                                         |
|-------------------|---------------|---------------------------------------------------------------------|
| `visitor_id`      | HMAC          | Hash rotacionado diariamente de IP + UA + projeto. Não rastreável entre dias.  |
| `country_code`    | GeoIP         | Código ISO 3166-1 alpha-2. Vazio quando o GeoIP não está configurado.        |
| `device`          | User-Agent    | `desktop`, `mobile`, `tablet`, `bot`, ou `unknown`.                 |
| `browser`         | User-Agent    | `chrome`, `safari`. `firefox`. `edge`, `opera`, ou `unknown`.       |
| `os`              | User-Agent    | `windows`, `macos`, `ios`, `android`, `linux`, gu `unknown`.        |
| `hostname`        | URL da Página      | Host em minúsculas.                                                    |
| `pathname`        | URL da Página      | Componente do caminho.                                                     |
| `referrer_source` | Referenciador | Referenciador hospedeiro, inicial `www.`/`m.` removido. |
| `browser_language`| Idiomas     | Localidade normalizada mais preferida (ex. `pt-BR`).                    |
| `served_locale`   | Computado      | Primeiro alvo suportado correspondente a um idioma preferido, senão vazio.   |
| `has_locale_gap`  | Computado      | `1` quando o visitante prefere um idioma que o projeto não oferece. |

## Modelo de privacidade

- **Sem armazenamento do lado do cliente.** O SDK não define cookies e armazena apenas um identificador de sessão por aba em `sessionStorage`, que o navegador limpa ao fechar.
- **Sem fingerprinting.** As impressões digitais do Canvas, WebGL, fontes e áudio não são coletadas. O hash do servidor rotacionado diariamente fornece identificadores únicos sem elas.
- **Nenhum identificador bruto persistido.** O IP e o User-Agent são lidos uma vez, transformados em hash com um segredo do servidor e um sal diário, e depois descartados.
- **Escopo por projeto.** O mesmo navegador em dois projetos gera IDs de visitantes não relacionados, então visitantes não podem ser rastreados entre clientes do Glossia.