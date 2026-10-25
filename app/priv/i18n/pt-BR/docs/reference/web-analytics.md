%{
  title: "SDK de Análises",
  summary:
    "Os campos coletados, o endpoint de eventos e o modelo de privacidade por trás da análise web do Glossia.",
  category: "referência",
  section: "analytics",
  order: 1
}
---

## Endpoint de eventos

`POST https://glossia.ai/v1/collect`

`POST /api/analytics/events` permanece disponível para compatibilidade. O script hospedado deriva `/v1/collect` de sua própria origem; as integrações de pacote devem definir `endpoint` explicitamente.

Aceita um evento JSON do SDK `@glossia/web`. Sempre responde `202 Accepted`, incluindo para domínios desconhecidos ou cargas malformadas, para que o SDK nunca revele quais projetos coletam análises.

O projeto é resolvido pelo domínio do site declarado no trecho. `d` é autoritário; quando ausente, o servidor recorre ao host de `u` (a URL da página) e em seguida aos cabeçalhos de requisição `Origin`/`Referer`.

### Corpo da solicitação

| Campo | Tipo   | Descrição                                                  |
|-------|--------|--------------------------------------------------------------|
| `d`   | string | Domínio do site que identifica o projeto (por exemplo, `example.com`). Enviado pela biblioteca do navegador; a resolução de fallback é descrita acima. |
| `n`   | string | Nome do evento. O padrão é `pageview`.                          |
| `u`   | string | URL da página (`location.href`).                                  |
| `r`   | string | Referer (`document.referrer`).                              |
| `l`   | string | Idiomas do navegador (`navigator.languages.join(",")`).         |
| `sl`  | string | Idioma real da página (`document.documentElement.lang`). Vazio se não declarado. |
| `al`  | string | Idiomas de tradução separados por vírgula de `link[rel="alternate"][hreflang]`, excluindo `x-default`. |
| `tz`  | string | Fuso horário IANA (`Intl.DateTimeFormat().resolvedOptions().timeZone`). |
| `sw`  | número | Largura da tela em pixels CSS.                                  |
| `sid` | string | ID de sessão por aba (sessionStorage, limpo ao fechar).       |

O CORS está aberto (`Access-Control-Allow-Origin: *`) porque o endpoint não aceita credenciais.

## Campos derivados do servidor

Esses são computados durante a ingestão e armazenados do lado do servidor. O IP bruto e o User-Agent nunca são armazenados.

| Campo             | Origem        | Descrição                                                         |
|-------------------|---------------|---------------------------------------------------------------------|
| `visitor_id`      | HMAC          | Hash rotacionado diariamente de IP + UA + projeto. Não vinculável entre dias.  |
| `country_code`    | Cloudflare / GeoIP | Código ISO 3166-1 alpha-2 de um cabeçalho `CF-IPCountry` de confiança, ou o adaptador de geolocalização de IP configurado. Vazio quando nenhum resolve um país. |
| `device`          | User-Agent    | `desktop`, `mobile`, `tablet`, `bot` ou `unknown`.                 |
| `browser`         | User-Agent    | `chrome`, `safari`, `firefox`, `edge`, `opera` ou `unknown`.       |
| `os`              | User-Agent    | `windows`, `macos`, `ios`, `android`, `linux` ou `unknown`.        |
| `hostname`        | URL da página      | Host em minúsculas.                                                    |
| `pathname`        | URL da página      | Componente de caminho.                                                     |
| `referrer_source` | Referer      | Host do referer, `www.`/`m.` removidos.                        |
| `browser_language`| Idiomas     | Local de idioma preferido normalizado (por exemplo, `pt-BR`).                    |
| `served_locale`   | Idioma da página | Normalizado `sl`, ou vazio (exibido como Não relatado) se não foi coletado. |
| `has_locale_gap`  | Computado      | `1` quando nenhum dos idiomas preferidos do visitante coincide com os alvos do projeto, traduções anunciadas (`al`) ou idioma da página (`sl`). Preferências ausentes não contam como lacuna. |

### Resolução de IP do cliente

Para requisições de um próximo ponto de entrada privado, o Glossia usa o cabeçalho `X-Real-IP` sobrescrito pelo nginx, não a primeira entrada controlada pelo chamador em `X-Forwarded-For`. Conexões públicas diretas usam o endereço do socket. No Hetzner, tanto o balanceador de carga quanto o nginx devem habilitar o protocolo PROXY para que o nginx receba o endereço do visitante em vez do endereço do balanceador de carga. Outros proxies reversos também devem sobrescrever `X-Real-IP` usando uma fonte autenticada, não um cabeçalho `X-Forwarded-For` de entrada não restrito. A política de cabeçalho encaminhado do diagrama genérico por si só não garante isso. Pares privados são infraestrutura confiável, portanto restrinja o acesso direto ao pod.

`GLOSSIA_TRUST_CLOUDFLARE_CLIENT_IP_HEADER=true` permite `CF-Connecting-IP` substituir o endereço canônico para requisições de um próximo ponto de entrada privado. É **disabled by default**, independentemente da confiança do cabeçalho de país. Habilite-o apenas após a borda autenticar a Cloudflare ou remover cabeçalhos falsificados em requisições que contornam a Cloudflare. Implantações de apenas DNS devem deixá-lo desativado. Este endereço também controla a revisão de limites de IP e o hash diário de visitantes.

### Resolução de país

`GLOSSIA_TRUST_CLOUDFLARE_COUNTRY_HEADER=true` ativa o caminho rápido `CF-IPCountry`. É **disabled by default**. Habilite-o apenas após a origem autenticar a Cloudflare, rejeitar requisições que contornam a Cloudflare ou o ingress remover cópias não confiáveis do cabeçalho. A configuração de Geolocalização de IP da Cloudflare também deve estar habilitada para a zona. `CF-Connecting-IP`, `CF-Ray` e o `use-forwarded-headers` do nginx por si só não autenticam uma requisição.

Quando a confiança do cabeçalho está habilitada, um único código ISO de país válido é usado imediatamente, sem uma consulta de IP ou acesso ao cache. O valor atual de borda sempre tem precedência sobre qualquer consulta de cache. Códigos ausentes, duplicados, malformados ou desconhecidos, incluindo os códigos `XX` (desconhecido) e `T1` (Tor) da Cloudflare, recaem no adaptador de geolocalização configurado.

Sem uma base de dados MaxMind configurada, as buscas de resgate usam `api.ipapi.is`, em seguida `api.country.is` quando a requisição principal falha ou retorna nenhum país reconhecido. Cada requisição tem um timeout de conexão e resposta de um segundo, com retentativas desativadas. Resultados bem-sucedidos de qualquer provedor são armazenados em cache pelo Cachex por 24 horas, com um limite de tamanho agendado de 100.000 entradas e reutilização automática de expiração. `Cachex.fetch/3` consolida falhas concorrentes para o mesmo IP em um único resolutor. Falhas não são armazenadas. Endereços privados e reservados não são enviados a nenhum dos provedores.

### Idioma da página ausente

O painel exibe **Not reported** quando um evento não possui `sl`. Isso inclui eventos coletados por versões mais antigas do rastreador e páginas sem a atribuição HTML `lang`. O idioma da página não é inferido das preferências do navegador ou da URL. Eventos históricos mantêm os metadados coletados na época; novas versões do rastreador não preenchem retroativamente.

## Modelo de privacidade

- **No persistent cross-session identifier.** O SDK não define cookies e armazena apenas um ID de sessão por aba em `sessionStorage`.
- **No fingerprinting.** Fingerprinting de Canvas, WebGL, fonte e áudio não são coletados. O hash rotativo diário do servidor fornece unicidades sem elas.
- **No raw identifiers persisted.** O IP e o User-Agent são lidos apenas uma vez, criptografados com um segredo do servidor e um sal diário, em seguida descartados.
- **Per-project scoping.** O mesmo navegador em dois projetos gera IDs de visitantes desconexos, portanto, os visitantes não podem ser rastreados entre clientes do Glossia.
