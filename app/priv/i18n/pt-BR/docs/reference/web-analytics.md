%{
  title: "SDK de Análise",
  summary:
    "Os campos coletados, o endpoint de eventos e o modelo de privacidade por trás da análise web do Glossia.",
  category: "referência",
  order: 1
}
---
## Endpoint de eventos

`POST /api/analytics/events`

Aceita um evento JSON do SDK `@glossia/web`. Sempre responde `202 Accepted`, inclusive para domínios desconhecidos ou cargas malformadas, para que o SDK nunca revele quais projetos coletam análises.

O projeto é resolvido pelo domínio do site que o trecho declara. `d` é autoritário; quando ausente, o servidor recorre ao host de `u` (a URL da página) e depois aos cabeçalhos de requisição `Origin`/`Referer`.

### Corpo da requisição

| Campo | Tipo   | Descrição                                                  |
|-------|--------|--------------------------------------------------------------|
| `d`   | string | Domínio do site que identifica o projeto (ex. `example.com`). Obrigatório. |
| `n`   | string | Nome do evento. Padrão `pageview`.                          |
| `u`   | string | URL da página (`location.href`).                            |
| `r`   | string | Referidor (`document.referrer`).                            |
| `l`   | string | Idiomas do navegador (`navigator.languages.join(",")`).     |
| `tz`  | string | Fuso horário IANA (`Intl.DateTimeFormat().resolvedOptions().timeZone`). |
| `sw`  | number | Largura da tela em pixels CSS.                              |
| `sid` | string | ID de sessão por aba (sessionStorage, limpo ao fechar).     |

CORS está aberto (`Access-Control-Allow-Origin: *`) porque o endpoint não aceita credenciais.

## Campos derivados do servidor

Estes são computados durante a ingestão e armazenados no lado do servidor. O IP e o User-Agent originais nunca são armazenados.

| Campo             | Origem       | Descrição                                                         |
|-------------------|--------------|---------------------------------------------------------------------|
| `visitor_id`      | HMAC         | Hash rotativo diário de IP + UA + projeto. Não vinculável entre dias.  |
| `country_code`    | GeoIP        | Código ISO 3166-1 alpha-2. Vazio quando o GeoIP não está configurado.     |
| `device`          | User-Agent   | `desktop`, `mobile`, `tablet`, `bot` ou `unknown`.                 |
| `browser`         | User-Agent   | `chrome`, `safari`, `firefox`, `edge`, `opera` ou `unknown`.       |
| `os`              | User-Agent   | `windows`, `macos`, `ios`, `android`, `linux` ou `unknown`.        |
| `hostname`        | URL da página | Host em minúsculas.                                                     |
| `pathname`        | URL da página | Componente de path.                                                   |
| `referrer_source` | Referidor    | Host do referidor, prefixo `www.`/`m.` removido.                    |
| `browser_language`| Idiomas      | Localização preferida normalizada (ex. `pt-BR`).                |
| `served_locale`   | Computado    | Primeira localização suportada correspondente a um idioma preferido, senão vazio.   |
| `has_locale_gap`  | Computado    | `1` quando o visitante prefere um idioma que o projeto não atende.   |

## Modelo de privacidade

- **Nenhum armazenamento no lado do cliente.** O SDK não define cookies e armazena apenas um ID de sessão por aba no `sessionStorage`, o qual é limpo pelo navegador ao fechar.
- **Sem fingerprinting.** Impressões digitais de Canvas, WebGL, fonte e áudio não são coletadas. O hash rotativo diário do servidor fornece identidades únicas sem elas.
- **Nenhum identificador cru persistido.** O IP e o User-Agent são lidos uma vez, hashados com um segredo do servidor e um sal diário, em seguida descartados.
- **Escopo por projeto.** O mesmo navegador em dois projetos gera IDs de visitantes não relacionados, de modo que os visitantes não podem ser rastreados entre clientes da Glossia.