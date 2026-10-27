%{
  title: "SDK de Análise",
  summary:
    "Os campos coletados, o endpoint de eventos e o modelo de privacidade por trás da análise web do Glossia.",
  category: "Referência",
  section: "analytics",
  order: 1
}
---

## Endpoint de eventos

`POST https://glossia.ai/v1/collect`

`POST /api/analytics/events` continua disponível para compatibilidade. O script hospedado deriva `/v1/collect` de sua própria origem; integrações de pacote devem definir `endpoint` explicitamente.

Aceita um evento JSON do SDK `@glossia/web`. Sempre responde `202 Accepted`, incluindo para domínios desconhecidos ou malas carregadas, para que o SDK nunca vaze quais projetos coletam dados de análise.

O projeto é resolvido pelo domínio do site declarado no fragmento. `d` é a autoridade; quando ausente, o servidor recorre ao host de `u` (a página URL) e, nach, as requisições `Origin`/`Referer`.

### Corpo da requisição

| Campo | Tipo   | Descrição                                                  |
|-------|--------|--------------------------------------------------------------|
| `d`   | string | Domínio do site que identifica o projeto (por exemplo, `example.com`). Enviado pela biblioteca do navegador; a resolução de fallback é descrita acima. |
| `n`   | string | Nome do evento. Padrão é `pageview`.                          |
| `u`   | string | URL da página (`location.href`).                                  |
| `r`   | string | Referer (`document.referrer`).                              |
| `l`   | string | Idiomas do navegador (`navigator.languages.join(",")`).         |
| `sl`  | string | Idioma real da página (`document.documentElement.lang`). Vazio se não declarado. |
| `al`  | string | Idiomas de tradução separados por vírgula de `link[rel="alternate"][hreflang]`, excluindo `x-default`. |
| `cl`  | string | Idioma escolhido explicitamente, ou vazio quando nenhuma seleção foi observada. O SDK canoniza as tags BCP 47 e limita a entrada a 64 caracteres. |
| `tz`  | string | Fuso horário IANA (`Intl.DateTimeFormat().resolvedOptions().timeZone`). |
| `sw`  | número | Largura da tela em pixels CSS.                                  |
| `sid` | string | ID de sessão por aba (sessionStorage, limpo ao fechar).       |

CORS está aberto (`Access-Control-Allow-Origin: *`) porque o endpoint não aceita credenciais.

## Seleção explícita de idioma

`selectLanguage(language)` está disponível como um export named, no export padrão do SDK e no global `glossia` do script hospedado. Chame-o após inicialização a partir de um manipulador de ação do usuário, antes da navegação. Tags de idioma inválidas e chamadas antes da inicialização são ignoradas.

O método envia um evento `language_selection` imediatamente. Seu `sl` ainda descreve a página atual, não o destino. Eventos subsequentes incluem a escolha em `cl` até que outra escolha explícita substitua. Sem uma seleção observada, `cl` está vazio. A escolha é armazenada como `__glossia_selected_language` na柬埔寨, por aba `sessionStorage`; quando o armazenamento falha, é retido apenas na memória até o unload.

Para links, `data-glossia-language="zh-Hans"` possibilita o rastreamento delegado de cliques primários confiáveis e não modificados, incluindo ativação via teclado. Cliques programáticos, cliques já cancelados, downloads, links de origem cruzada e links que visam outra aba ou iframe são ignorados. O listener roda na fase de captura antes de roteadores navegarem, não impede a navegação e também lida com links inseridos dinamicamente. Use a anotação ou o API para uma ação, mas não ambos.

Esta é um sinal de intenção relatado pelo cliente, não prova de que a navegação sucedeu. Mudanças de URL, redirecionamentos e mudanças de idioma HTML não são interpretados como escolhas. A seleção não sobrescreve `l` ou `sl`. Uma seleção válida tem precedência sobre preferências do navegador apenas ao computar `has_locale_gap`: o idioma escolhido deve corresponder a um alvo do projeto, uma tradução anunciada (`al`) ou o idioma real da página (`sl`). A escolha em si não é evidência de disponibilidade. O correspondimento usa correspondências exatas ou de idioma base normalizadas, como faz para preferências do navegador.

Por exemplo, um visitante que prefere japonês e escolhe explicitamente uma tradução de inglês disponível não tem lacuna. Um visitante que prefere inglês e escolhe japonês indisponível ainda tem lacuna, mesmo em uma página de inglês. Um evento de seleção emitido antes da navegação mantém a `sl` da página atual; o idioma do destino pode ser reconhecido através de alvos de projeto ou `al` sem assumir que a navegação sucedeu.

Escolhas ausentes, malformadas ou de tamanho excessivo recarregam para preferências do navegador. Se nem uma escolha nem preferências do navegador são conhecidas, não há lacuna. Totais do painel e badges leem a bandeira por evento armazenada. Bandeiras históricas, incluindo aquelas coletadas antes que escolhas afetassem o cálculo de lacuna, não são recomputadas: traduções anunciadas históricas e preferências completas do navegador não são armazenadas.

## Campos derivados do servidor

Estes são computados na ingestão e armazenados no lado do servidor. O IP bruto e o User-Agent nunca são armazenados.

| Campo             | Origem        | Descrição                                                         |
|-------------------|---------------|---------------------------------------------------------------------|
| `visitor_id`      | HMAC          | Hash rotativo diário de IP + User-Agent + projeto. Não vinculável entre dias.  |
| `country_code`    | Cloudflare / GeoIP | Código ISO 3166-1 alpha-2 de um cabeçalho `CF-IPCountry` confiável, ou o adaptador de geolocalização de IP configurado. Vazio quando nenhum resolve um país. |
| `device`          | User-Agent    | `desktop`, `mobile`, `tablet`, `bot` ou `unknown`.                 |
| `browser`         | User-Agent    | `chrome`, `safari`, `firefox`, `edge`, `opera` ou `unknown`.       |
| `os`              | User-Agent    | `windows`, `macos`, `ios`, `android`, `linux` ou `unknown`.        |
| `hostname`        | URL da página      | Host em minúsculas.                                                    |
| `pathname`        | URL da página      | Componente do caminho.                                                     |
| `referrer_source` | Referidor      | Host do referidor, prefixos `www.`/`m.` removidos.                        |
| `browser_language`| Idiomas     | Localidade normalizada mais preferida (por exemplo, `pt-BR`).                    |
| `served_locale`   | Idioma da página | `sl` normalizado, ou vazio se não foi coletado. Linhas com idioma da página vazio são omitidas da quebra de idioma do navegador. |
| `selected_locale` | Escolha explícita | `cl` normalizado, ou vazio para input ausente, malformado ou de tamanho excessivo. Armazenado separadamente da preferência do navegador e idioma da página. |
| `has_locale_gap`  | Computado      | `1` quando escolha explícita válida não tem correspondência entre alvos de projeto, traduções anunciadas (`al`) ou idioma da página (`sl`). Sem escolha válida, `1` apenas quando preferências do navegador não estiverem vazias e nenhuma corresponda. |

### Resolução de IP do cliente

Para solicitações de um par privado de entrada, o Glossia usa o cabeçalho `X-Real-IP` sobrescrito pelo nginx, não a primeira entrada controlada pelo chamador em `X-Forwarded-For`. Conexões públicas diretas usam o endereço do soquete. No Hetzner, tanto o balancer de carga quanto o nginx devem habilitar o protocolo PROXY para que o nginx receba o endereço do visitante em vez do endereço do balancer de carga. Outros proxies reversos também devem sobrescrever `X-Real-IP` usando uma fonte autenticada, não um cabeçalho `X-Forwarded-For` inbound sem restrições. Apenas a política de cabeçalho encaminhado do gráfico genérico não garante isso. Pares privados são infraestrutura confiável, por isso restrinja o acesso direto ao pod.

`GLOSSIA_TRUST_CLOUDFLARE_CLIENT_IP_HEADER=true` permite que `CF-Connecting-IP` sobrescreva o endereço canônico para solicitações de um par de entrada privado. Está **desabilitado por padrão**, independentemente da confiança no cabeçalho de país. Ative-o apenas após o edge autenticar a Cloudflare ou remover cabeçalhos forjados em solicitações que bypassam a Cloudflare. Implantações DNS-only devem mantê-lo desabilitado. Este endereço também chaves limites de taxa de IP e o hash de visitante diário.

### Resolução de país

`GLOSSIA_TRUST_CLOUDFLARE_COUNTRY_HEADER=true` permite o caminho rápido de `CF-IPCountry`. Está **desabilitado por padrão**. Ative-o apenas após a origem autenticar a Cloudflare, rejeitar solicitações que bypassam a Cloudflare ou o ingress remover cópias não confiáveis do cabeçalho. O ajuste de Geolocalização de IP da Cloudflare também deve estar habilitado para a zona. `CF-Connecting-IP`, `CF-Ray` e `use-forwarded-headers` do nginx não autenticam uma solicitação por si sós.

Quando a confiança no cabeçalho está habilitada, um código de país ISO válido único é usado imediatamente, sem consulta de IP ou acesso em cache. O valor atual do edge sempre tem precedência sobre qualquer consulta em cache. Códigos ausentes, duplicados, malformados ou desconhecidos, incluindo os `XX` (unknown) e `T1` (Tor) da Cloudflare, recarregam para o adaptador de geolocalização configurado.

Sem um banco de dados MaxMind configurado, consultas de fallback usam `api.ipapi.is`, depois `api.country.is` quando a solicitação primária falha ou não retorna um país reconhecido. Cada solicitação tem um tempo limite de conexão e resposta de um segundo com reatividades desativadas. Resultados bem-sucedidos de qualquer provedor são cacheados pelo Cachex por 24 horas, com limite de tamanho escalonado de 100.000 entradas e resgate automático de expiração. `Cachex.fetch/3` colapsa falhas simultâneas para o mesmo IP em um único resolutivo. Falhas não são cacheadas. Endereços privados e reservados não são enviados a qualquer provedor.

### Idioma da página ausente

A quebra de idiomas do navegador omite eventos sem `sl`. Isso inclui eventos coletados por versões mais antigas do rastreador e páginas sem um atributo `lang` HTML. Estes eventos ainda contribuem para o tráfego geral. O idioma da página não é inferido das preferências do navegador ou da URL. Eventos históricos mantêm os metadados coletados naquele momento; novas versões de rastreador não os preenchem.

## Modelo de privacidade

- **Sem identificador persistente entre sessões.** O SDK define nenhum cookie e armazena apenas um ID de sessão por aba e um idioma selecionado explicitamente em `sessionStorage`, que o navegador limpa ao fechar.
- **Sem impressão digital.** Impressões digitais de Canvas, WebGL, fontes e áudio não são coletadas. O hash do servidor rotativo diário fornece unicidades sem elas.
- **Sem identificadores brutos persistidos.** IP e User-Agent são lidos uma vez, hashados com um segredo do servidor e um sal diário, então descartados.
- **Escopo por projeto.** O mesmo navegador em dois projetos gera identificadores de visitantes não relacionados, por isso os visitantes não podem ser rastreados entre clientes do Glossia.
