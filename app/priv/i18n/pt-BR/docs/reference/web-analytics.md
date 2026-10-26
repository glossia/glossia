%{
  title: "SDK de Análise",
  summary:
    "Os campos coletados, o endpoint de eventos e o modelo de privacidade por trás das análises web da Glossia.",
  category: "Referência",
  section: "analytics",
  order: 1
}
---

## Endpoint de Eventos

`POST https://glossia.ai/v1/collect`

`POST /api/analytics/events` permanece disponível para compatibilidade. O script hospedado deriva `/v1/collect` de sua própria origem; integrações de pacote devem definir `endpoint` explicitamente.

Aceita um evento JSON do SDK `@glossia/web`. Sempre responde `202 Accepted`, inclusive para domínios desconhecidos ou cargas de dados malformadas, para que o SDK nunca divulgue quais projetos coletam análises.

O projeto é resolvido pelo domínio do site que o trecho declara. `d` é autoritativo; quando ausente, o servidor recai para o host de `u` (o URL da página) e depois para o cabeçalho do pedido `Origin`/`Referer`.

### Corpo do pedido

| Campo | Tipo   | Descrição                                                  |
|-------|--------|--------------------------------------------------------------|
| `d`   | string | Domínio do site que identifica o projeto (por exemplo, `example.com`). Enviado pela biblioteca do navegador; a resolução alternativa é descrita acima. |
| `n`   | string | Nome do evento. Padrão `pageview`.                          |
| `u`   | string | URL da página (`location.href`).                                  |
| `r`   | string | Referrer (`document.referrer`).                              |
| `l`   | string | Idiomas do navegador (`navigator.languages.join(",")`).         |
| `sl`  | string | Idioma da página atual (`document.documentElement.lang`). Vazio se não declarado. |
| `al`  | string | Idiomas de tradução separados por vírgula de `link[rel="alternate"][hreflang]`, excluindo `x-default`. |
| `tz`  | string | Fuso horário IANA (`Intl.DateTimeFormat().resolvedOptions().timeZone`). |
| `sw`  | string | Largura da tela em pixels CSS.                                  |
| `sid` | string | ID de sessão por aba (sessionStorage, limpo ao fechar).       |

CORS está aberto (`Access-Control-Allow-Origin: *`) porque o endpoint não aceita credenciais.

## Campos derivados do servidor

Estes são computados na ingestão e armazenados no lado do servidor. O IP bruto e o User-Agent nunca são armazenados.

| Campo             | Origem        | Descrição                                                         |
|-------------------|---------------|---------------------------------------------------------------------|
| `visitor_id`      | HMAC          | Hash rotativo diariamente de IP + UA + projeto. Não vinculável entre dias.  |
| `country_code`    | Cloudflare / GeoIP | Código ISO 3166-1 alpha-2 de um cabeçalho `CF-IPCountry` confiável, ou o adaptador de geolocalização de IP configurado. Vazio quando nenhum resolve um país. |
| `device`          | User-Agent    | `desktop`, `mobile`, `tablet`, `bot`, ou `unknown`.                 |
| `browser`         | User-Agent    | `chrome`, `safari`, `firefox`, `edge`, `opera`, ou `unknown`.       |
| `os`              | User-Agent    | `windows`, `macos`, `ios`, `android`, `linux`, ou `unknown`.        |
| `hostname`        | URL da página      | Host com minúsculas.                                                    |
| `pathname`        | URL da página      | Componente do caminho.                                                     |
| `referrer_source` | Referrer      | Host do referrer, iniciando com `www.`/`m.` removido.                        |
| `browser_language`| Idiomas     | Local mais preferido normalizado (por exemplo, `pt-BR`).                    |
| `served_locale`   | Idioma da página | `sl` normalizado, ou vazio (mostrado como Não notificado) se não foi coletado. |
| `has_locale_gap`  | Computado      | `1` quando nenhum dos idiomas preferidos do visitante corresponde aos alvos do projeto, traduções anunciadas (`al`), ou idioma da página (`sl`). Preferências ausentes não contam como uma lacuna. |

### Resolução do IP do cliente

Para pedidos de um reengressor privado, o Glossia usa o cabeçalho `X-Real-IP` sobrescrito do nginx, não a primeira entrada controlada pelo chamador em `X-Forwarded-For`. Conexões públicas diretas usam o endereço do socket. No Hetzner, tanto o balanciante de carga quanto o nginx devem habilitar o protocolo PROXY para que o nginx receba o endereço do visitante em vez do endereço do balanciante de carga. Outros proxies reversos também devem substituir `X-Real-IP` usando uma fonte autenticada, não um cabeçalho `X-Forwarded-For` de entrada não restrito. A política de cabeçalho encaminhado do gráfico genérico por si só não garante isso. Pares privados são infraestrutura confiável, portanto limite o acesso direto ao pod.

`GLOSSIA_TRUST_CLOUDFLARE_CLIENT_IP_HEADER=true` permite que `CF-Connecting-IP` sobreponha o endereço canônico para pedidos de um reengressor privado. Está **desabilitado por padrão**, independentemente da confiança no cabeçalho do país. Habilitar apenas depois que a borda autentica o Cloudflare ou remove cabeçalhos forjados em pedidos que desviam o Cloudflare. Implantações DNS-only devem mantê-lo desabilitado. Este endereço também chaveia limites de taxa de IP e o hash diário de visitante.

### Resolução de país

`GLOSSIA_TRUST_CLOUDFLARE_COUNTRY_HEADER=true` habilita o caminho rápido `CF-IPCountry`. Está **desabilitado por padrão**. Habilite apenas depois que o origem autentica o Cloudflare, rejeita pedidos que desviam o Cloudflare, ou o reengressor remove cópias não confiáveis do cabeçalho. A configuração de Geolocalização de IP do Cloudflare também deve estar habilitada para a zona. `CF-Connecting-IP`, `CF-Ray` e `use-forwarded-headers` do nginx não autenticam um pedido por si próprios.

Quando a confiança em cabeçalho está habilitada, um único código ISO de país válido é usado imediatamente, sem pesquisa de IP ou acesso ao cache. O valor atual da borda sempre tem prioridade sobre qualquer pesquisa em cache. Códigos ausentes, duplicados, malformados ou desconhecidos, inclusive os valores `XX` (desconhecido) e `T1` (Tor) do Cloudflare, recai para o adaptador de geolocalização configurado.

Sem banco de dados MaxMind configurado, as pesquisas alternativas usam `api.ipapi.is`, depois `api.country.is` quando o pedido primário falha ou retorna nenhum país reconhecido. Cada pedido tem um limite de tempo de conexão e resposta de um segundo com reenvios desabilitados. Resultados bem-sucedidos de qualquer provedor são cacheados pelo Cachex por 24 horas, com limite de tamanho agendado de 100.000 entradas e reclusão automática de expiração. `Cachex.fetch/3` colapsa erros concorrentes para o mesmo IP em um único resolutor. Falhas não são cacheadas. Endereços privados e reservados não são enviados a nenhum provedor.

### Idioma da página ausente

O painel exibe **Não notificado** quando um evento não tem `sl`. Isso inclui eventos coletados por versões mais antigas do rastreador e páginas sem um atributo HTML `lang`. O idioma da página não é inferido das preferências do navegador ou do URL. Eventos históricos mantêm os metadados coletados naquele momento; novas versões do rastreador não preenchem esses dados retrospectivamente.

## Modelo de Privacidade

- **Sem identificador persistente de sessão cruzada.** O SDK não define cookies e armazena apenas um ID de sessão por aba em `sessionStorage`, que o navegador limpa ao fechar.
- **Sem fingerprinting.** Prints de canvas, WebGL, fontes e áudio não são coletados. O hash rotativo diariamente do servidor fornece unicidade sem eles.
- **Sem identificadores brutos persistidos.** IP e User-Agent são lidos uma vez, hashados com um segredo do servidor e um sal diário, depois descartados.
- **Escopo por projeto.** O mesmo navegador em dois projetos gera IDs de visitante não relacionados, para que visitantes não possam ser rastreados entre clientes do Glossia.
