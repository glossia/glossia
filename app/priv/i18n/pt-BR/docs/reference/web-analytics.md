%{
  title: "SDK de análise",
  summary:
    "Os campos coletados, o endpoint de eventos e o modelo de privacidade por trás da análise web do Glossia.",
  category: "referência",
  section: "analytics",
  order: 1
}
---

## Endpoint de eventos

`POST https://glossia.ai/v1/collect`

`POST /api/analytics/events` permanece disponível para compatibilidade. O script hospedado deriva `/v1/collect` de sua própria origem; integrações de pacote devem definir `endpoint` explicitamente.

Aceita um evento JSON do SDK `@glossia/web`. Sempre responde `202 Accepted`, inclusive para domínios desconhecidos ou cargas malformadas, para que o SDK nunca ause quais projetos coletam analytics.

O projeto é resolvido pelo domínio do site que o trecho declara. `d` é autoritativo; quando está ausente o servidor recorre ao host de `u` (a URL da página) e então ao request `Origin`/`Referer`.

### Corpo da solicitação

| Campo | Tipo   | Descrição                                                  |
|-------|--------|--------------------------------------------------------------|
| `d`   | string | Domínio do site que identifica o projeto (por exemplo, `example.com`). Enviado pela biblioteca do navegador; a resolução de fallback é descrita acima. |
| `n`   | string | Nome do evento. Padrão é `pageview`.                          |
| `u`   | string | URL da página (`location.href`).                                  |
| `r`   | string | Referidor (`document.referrer`).                              |
| `l`   | string | Idiomas do navegador (`navigator.languages.join(",")`).         |
| `sl`  | string | Idioma real da página (`document.documentElement.lang`). Vazio se não declarado. |
| `al`  | string | Idiomas de tradução separados por vírgulas a partir de `link[rel="alternate"][hreflang]`, excluindo `x-default`. |
| `tz`  | string | Fuso horário IANA (`Intl.DateTimeFormat().resolvedOptions().timeZone`). |
| `sw`  | number | Largura da tela em pixels CSS.                                  |
| `sid` | string | ID de sessão por aba (sessionStorage, limpo ao fechar).       |

CORS está aberto (`Access-Control-Allow-Origin: *` porque o endpoint não aceita credenciais.

## Campos derivados do servidor

Esses são computados durante a ingestão e armazenados no lado do servidor. O IP bruto e o User-Agent nunca são armazenados.

| Campo             | Fonte        | Descrição                                                         |
|-------------------|---------------|---------------------------------------------------------------------|
| `visitor_id`      | HMAC          | Hash rotativo diário de IP + UA + projeto. Não rastreável entre dias.  |
| `country_code`    | Cloudflare / GeoIP | Código ISO 3166-1 alpha-2 a partir de um cabeçalho `CF-IPCountry` de confiança, ou o adaptador de geolocalização de IP configurado. Vazio quando nenhum resolve um país. |
| `device`          | User-Agent    | `desktop`, `mobile`, `tablet`, `bot`, ou `unknown`.                 |
| `browser`         | User-Agent    | `chrome`, `safari`, `firefox`, `edge`, `opera`, ou `unknown`.       |
| `os`              | User-Agent    | `windows`, `macos`, `ios`, `android`, `linux`, ou `unknown`.        |
| `hostname`        | Page URL      | Host em minúsculas.                                                    |
| `pathname`        | Page URL      | Componente do caminho.                                                     |
| `referrer_source` | Referrer      | Host do referidor, o prefixo `www.`/`m.` removido.                        |
| `browser_language`| Languages     | Locale normalizado mais preferido (por exemplo, `pt-BR`).                    |
| `served_locale`   | Page language | Normalizado `sl`, ou vazio (exibido como Não relatado) se não foi coletado. |
| `has_locale_gap`  | Computed      | `1` quando nenhum dos idiomas preferidos do visitante corresponde aos alvos do projeto, traduções anunciadas (`al`), ou idioma da página (`sl`). Preferências ausentes não contam como uma lacuna. |

### Country resolution

`GLOSSIA_TRUST_CLOUDFLARE_COUNTRY_HEADER=true` ativa o caminho rápido `CF-IPCountry`. Está **desabilitado por padrão**. Ative-o somente após a origem autenticar o Cloudflare, rejeitar solicitações que contornam o Cloudflare, ou o ingress remover cópias não confiáveis do cabeçalho. A configuração IP Geolocation do Cloudflare também deve estar habilitada para a zona. `CF-Connecting-IP`, `CF-Ray` e o nginx's `use-forwarded-headers` não autenticam uma solicitação por conta própria.

Quando a confiança no cabeçalho está habilitada, um único código ISO de país válido é usado imediatamente, sem pesquisa de IP ou acesso ao cache. O valor atual de borda sempre tem precedência sobre qualquer pesquisa em cache. Códulos ausentes, duplicados, malformados ou desconhecidos, incluindo os valores `XX` (`T1`) do Cloudflare, (unknown) e valores (Tor), desviam-se para o adaptador de geolocalização configurado.

Sem um banco de dados MaxMind configurado, as pesquisas de fallback usam `api.ipapi.is`, então `api.country.is` quando a solicitação primária falha ou retorna nenhum país reconhecido. Cada solicitação tem um timeout de conexão e de resposta de um segundo com tentativas de reexecução desabilitadas. Resultados bem-sucedidos de qualquer provedor são cacheados pelo Cachex por 24 horas, com limite de tamanho agendado de 100.000 entradas e reutilização automática de expiração. `Cachex.fetch/3` elege falhas concorrentes para o mesmo IP em um único resolvor. Falhas não são cacheadas. Endereços privados e reservados não são enviados a nenhum provedor.

### Missing page language

O painel exibe **Não relatado** quando um evento não tem `sl`. Isso inclui eventos coletados por versões mais antigas do rastreador e páginas sem o atributo HTML `lang`. O idioma da página não é inferido a partir das preferências do navegador ou da URL. Eventos históricos mantêm o metadado coletado naquele momento; novas versões do rastreador não preenchem retroativamente esses dados.

## Privacy model

- **Sem identificador persistente entre sessões.** O SDK não define cookies e armazena apenas um id de sessão por aba em `sessionStorage`, o que o navegador limpa ao fechar.
- **Sem apontamento.** Impressões Canvas, WebGL, fonte e de áudio não são coletadas. O hash rotativo diário do servidor fornece unicidades sem elas.
- **Sem identificadores brutos persistidos.** IP e User-Agent são lidos uma vez, hashados com um segredo do servidor e um sal diário, e então descartados.
- **Escopo por projeto.** O mesmo navegador em dois projetos produz ids de visitantes não relacionados, para que visitantes não possam ser rastreados entre clientes Glossia.
