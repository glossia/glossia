%{
  title: "SDK de Análise",
  summary:
    "Os campos coletados, o endpoint de eventos e o modelo de privacidade por trás das análises web do Glossia.",
  category: "Referência",
  section: "analytics",
  order: 1
}
---
## Endpoint de eventos

`POST https://glossia.ai/v1/collect`

`POST /api/analytics/events` permanece disponível para compatibilidade. O script hospedado deriva `/v1/collect` de sua própria origem; integrações de pacote devem definir `endpoint` explicitamente.

Aceita um evento JSON do `@glossia/web` SDK. Sempre responde `202 Accepted`, incluindo para domínios desconhecidos ou cargas malformadas, de forma que a SDK nunca revele quais projetos coletam análises.

O projeto é resolvido pelo domínio do site que o snippet declara. `d` é autoridade; quando ausente o servidor recorre ao host da `u` (a URL da página) e, em seguida, a solicitação `Origin`/`Referer`.

### Corpo da solicitação

| Campo | Tipo   | Descrição                                                  |
|-------|--------|--------------------------------------------------------------|
| `d`   | string | Domínio do site que identifica o projeto (ex. `example.com`). Enviado pela biblioteca do navegador; a resolução de fallback está descrita acima. |
| `n`   | string | Nome do evento. Padrão: `pageview`.                          |
| `u`   | string | URL da página (`location.href`).                                  |
| `r`   | string | Referer (`document.referrer`).                              |
| `l`   | string | Idiomas do navegador (`navigator.languages.join(",")`).         |
| `sl`  | string | Idioma da página atual (`document.documentElement.lang`). Vazio se não declarado. |
| `al`  | string | Idiomas de tradução separados por vírgula a partir de `link[rel="alternate"][hreflang]`, excluindo `x-default`. |
| `tz`  | string | Fuso horário IANA (`Intl.DateTimeFormat().resolvedOptions().timeZone`,}. |
| `sw`  | number | Largura da tela em pixels CSS.                               |
| `sid` | string | ID de sessão por aba (sessionStorage, limpo no fechamento).      |

CORS está aberto (`Access-Control-Allow-Origin: *`) porque o endpoint não aceita credenciais.

## Campos derivados do servidor

Estes são computados na ingestão e armazenados no lado do servidor. O IP bruto e o User-Agent nunca são armazenados.

| Campo             | Fonte        | Descrição                                                         |
|-------------------|---------------|---------------------------------------------------------------------|
| `visitor_id`      | HMAC          | Hash rotacionado diariamente de IP + UA + projeto. Não vinculável entre dias.  |
| `country_code`    | Cloudflare / GeoIP | Código ISO 3166-1 alpha-2 de confiança `CF-IPCountry` header, ou o adaptador de geolocalização de IP configurado. Vazio quando nenhum resolve um país. |
| `device`          | User-Agent    | `desktop`, `mobile`, `tablet`, `bot`, ou `unknown`.                 |
| `browser`         | User-Agent    | `chrome`, `safari`, `firefox`, `edge`, `opera`ou `unknown`.       |
| `os`              | User-Agent    | `windows`, `macos`, `ios`O documento remontado falhou anteriormente na validação: a recuperação de texto-literal Markdown deve retornar um array de strings JSON com comprimento correspondente. `android`O documento reconstituído falhou na validação anteriormente: a recuperação de literal de texto Markdown deve retornar um array de strings JSON de tamanho correspondente. `linux`, ou `unknown`.        |
| `hostname`        | URL da Página      | Host minúsculo.                                                    |
| `pathname`        | URL da Página      | Componente do caminho.                                                     |
| `referrer_source` | Referência      | Host da referência, inicial `www.`/`m.` removido.                        |
| `browser_language`| Idiomas     | Localização normalizada mais preferida (ex. `pt-BR`).                    |
| `served_locale`   | Idioma da página | Normalizado `sl`, ou vazio (mostrado como Não reportado) se não foi coletado. |
| `has_locale_gap`  | Computado      | `1` quando nenhum dos idiomas preferidos do visitante corresponde aos alvos do projeto, traduções anunciadas (`al`), ou idioma da página (`sl`) . Preferências ausentes não contam como uma lacuna. |

### Resolução por país

`GLOSSIA_TRUST_CLOUDFLARE_COUNTRY_HEADER=true` habilita o caminho rápido `CF-IPCountry`. Ele está **desabilitado por padrão**. Habilitar somente após a origem autenticar o Cloudflare, rejeitar solicitações que contornem o Cloudflare, ou o ingress remover cópias não confiáveis do cabeçalho. A configuração de Localização de IP do Cloudflare também deve estar habilitada para a zona. `CF-Connecting-IP`, `CF-Ray` e `use-forwarded-headers` do nginx não autenticam uma solicitação por si mesmos.

Quando a confiança de cabeçalho está habilitada, um único código de país ISO válido é usado imediatamente, sem uma consulta de IP ou acesso ao cache. O valor atual da borda sempre tem precedência sobre qualquer consulta cacheada. Códigos ausentes, duplicados, malformados ou desconhecidos, incluindo os códigos `XX` (desconhecido) e `T1` (Tor) do Cloudflare, recorrem ao adaptador de geolocalização configurado.

Sem um banco de dados MaxMind configurado, as consultas de fallback usam `api.ipapi.is`, seguida de `api.country.is` quando a solicitação primária falha ou retorna nenhum país reconhecido. Cada solicitação possui um tempo limite de conexão e resposta de um segundo, com repetições desativadas. Resultados bem-sucedidos de ambos os provedores são armazenados em cache pelo Cachex por 24 horas, com um limite de tamanho programado de 100.000 entradas e liberação automática. `Cachex.fetch/3` agrupa misses concorrentes para o mesmo IP em um único resolutor. Falhas não são armazenadas em cache. Endereços privados e reservados não são enviados a nenhum dos provedores.

### Idioma da página ausente

O painel exibe **Não relatado** quando um evento não possui `sl`. Isso inclui eventos coletados por versões mais antigas do tracker e páginas sem o atributo `lang` HTML. O idioma da página não é inferido das preferências do navegador nem da URL. Eventos históricos mantêm os metadados coletados naquele momento; novas versões do tracker não os preenchem retroativamente.

## Modelo de privacidade

- **Nenhum identificador persistente entre sessões.** O SDK não define cookies e armazena apenas um ID de sessão por aba em `sessionStorage`, que o navegador limpa ao fechar.
- **Nenhuma pegada digital.** Impressões digitais do Canvas, WebGL, fontes e áudio não são coletadas. O hash do servidor rotativo diariamente fornece unicidade sem elas.
- **Nenhum identificador bruto persistente.** O IP e o User-Agent são lidos uma vez, hashificados com um segredo do servidor e um sal diário, depois descartados.
- **Escopo por projeto.** O mesmo navegador em dois projetos gera IDs de visitantes não relacionados, então os visitantes não podem ser rastreados entre clientes do Glossia.