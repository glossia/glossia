%{
  title: "SDK de Análise",
  summary:
    "Os campos coletados, o endpoint de eventos e o modelo de privacidade por trás das análises web do Glossia.",
  category: "referência",
  order: 1
}
---
## Endpoint de eventos

`POST /api/analytics/events`

Aceita um evento JSON do `@glossia/web` SDK. Sempre responde `202 Accepted`, incluindo para domínios desconhecidos ou cargas malformadas, para que o SDK nunca revele quais projetos coletam análises.

O projeto é resolvido pelo domínio do site que o trecho de código declara. `d` é autoritário; quando ausente o servidor recorre ao host de `u` (a URL da página) e, em seguida, a requisição `Origin`/`Referer`.

### Corpo da requisição

| Campo | Tipo   | Descrição                                                  |
|-------|--------|--------------------------------------------------------------|
| `d`   | string | Domínio do site que identifica o projeto (por exemplo, `example.com`). Obrigatório. |
| `n`   | string | Nome do evento. Padrão `pageview`.                          |
| `u`   | string | URL da página (`location.href`.                                  |
| `r`   | string | Referente (`document.referrer`.                              |
| `l`   | string | Idiomas do navegador (`navigator.languages.join(",")`)         |
| `tz`  | string | fuso horário IANA (`Intl.DateTimeFormat().resolvedOptions().timeZone`). |
| `sw`  | number | Largura da tela em pixels CSS.                                  |
| `sid` | string | ID de sessão por aba (sessionStorage, limpo ao fechar).       |

CORS está aberto (`Access-Control-Allow-Origin: *`" } porque o endpoint não aceita credenciais.

## Campos derivados do servidor

Esses são computados na ingestão e armazenados no servidor. O IP e o User-Agent brutos nunca são armazenados.

| Campo             | Origem        | Descrição                                                         |
|-------------------|---------------|---------------------------------------------------------------------|
| `visitor_id`      | HMAC          | Hash rotacionado diariamente de IP + UA + projeto. Não ligável entre dias.  |
| `country_code`    | GeoIP         | Código ISO 3166-1 alpha-2. Vazio quando o GeoIP não está configurado.        |
| `device`          | User-Agent    | `desktop`, `mobile`, `tablet`O documento reassemblado anteriormente falhou na validação: a recuperação de nó de texto de Markdown produziu uma tradução vazia `bot`O documento remontado anteriormente falhou na validação: a recuperação do nó de texto do Markdown produziu uma tradução vazia `unknown`.                 |
| `browser`         | Agente do Usuário    | `chrome`, `safari`, `firefox`, `edge`O documento remontado falhou na validação anteriormente: a recuperação do literal de texto Markdown retornou JSON inválido `opera`, ou `unknown`.&#9;|
| `os`              | User-Agent    | `windows`, `macos`, `ios`, `android`, `linux`ou `unknown`.        |
| `hostname`        | URL da página      | host em minúsculas.                                                    |
| `pathname`        | URL da página      | componente do caminho.                                                     |
| `referrer_source` | Referer      | Host do Referer, inicial `www.`/`m.` removido.                        |
| `browser_language`| Línguas         | Local de idioma normalizado mais preferido (ex. `pt-BR`).                    |
| `served_locale`   | Computado      | Primeiro idioma-alvo suportado correspondente a um idioma preferido, caso contrário vazio.   |
| `has_locale_gap`  | Computado      | `1` quando o visitante prefere um idioma que o projeto não suporta. |

## Modelo de privacidade

- **Sem armazenamento do lado do cliente.** O SDK não define cookies e armazena apenas um ID de sessão por aba em `sessionStorage`, o qual o navegador limpa ao fechar.
- **Sem rastreamento por impressão digital.** Impressões digitais de Canvas, WebGL, fonte e áudio não são coletadas. O hash rotativo diário do servidor fornece identificadores únicos sem elas.
- **Nenhum identificador bruto persistido.** IP e User-Agent são lidos uma vez, hashados com um segredo do servidor e um sal diário, e depois descartados.
- **Escopo por projeto.** O mesmo navegador em dois projetos gera IDs de visitantes não relacionados, assim os visitantes não podem ser rastreados entre clientes do Glossia.