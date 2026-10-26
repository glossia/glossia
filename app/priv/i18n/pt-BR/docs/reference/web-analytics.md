%{
  title: "SDK de Análise",
  summary:
    "Os campos coletados, o endpoint de eventos e o modelo de privacidade por trás das análises web do Glossia.",
  category: "referência",
  section: "analytics",
  order: 1
}
---

## Endpoint de eventos

`POST https://glossia.ai/v1/collect`

`POST /api/analytics/events` continua disponível para compatibilidade. O script hospedado deriva `/v1/collect` de sua própria origem; integrações de pacote devem definir `endpoint` explicitamente.

Aceita um evento JSON do `@glossia/web` SDK. Sempre responde `202 Accepted`, inclusive para domínios desconhecidos ou cargas malformadas, para que o SDK nunca revele quais projetos coletam análises.

O projeto é resolvido pelo domínio do site que o snippet declara. `d` é autoritativo; quando ausente, o servidor recorre ao host de `u` (a URL da página) e depois aos cabeçalhos de requisição `Origin`/`Referer`.

### Corpo da solicitação

| Campo | Tipo   | Descrição                                                  |
|-------|--------|--------------------------------------------------------------|
| `d`   | string | Domínio do site que identifica o projeto (ex. `example.com`). Enviado pela biblioteca do navegador; a resolução de fallback é descrita acima. |
| `n`   | string | Nome do evento. Padrão `pageview`.                          |
| `u`   | string | URL da página (`location.href`).                                  |
| `r`   | string | Referer (`document.referrer`).                              |
| `l`   | string | Idiomas do navegador (`navigator.languages.join(",")`).         |
| `sl`  | string | Idioma atual da página (`document.documentElement.lang`). Vazio se não declarado. |
| `al`  | string | Idiomas de tradução separados por vírgula de `link[rel="alternate"][hreflang]`, excluindo `x-default`. |
| `cl`  | string | Idioma escolhido explicitamente, ou vazio quando nenhuma seleção foi observada. O SDK padroniza as tags BCP 47 e limita a entrada a 64 caracteres. |
| `tz`  | string | Fuso horário IANA (`Intl.DateTimeFormat().resolvedOptions().timeZone`). |
| `sw`  | number | Largura da tela em pixels CSS.                                  |
| `sid` | string | ID de sessão por aba (sessionStorage, limpo ao fechar).       |

O CORS está aberto (`Access-Control-Allow-Origin: *`) porque o endpoint não aceita credenciais.

## Seleção explícita de idioma

`selectLanguage(language)` está disponível como uma exportação nomeada, na exportação padrão do SDK e no global `glossia` do script hospedado. Chame-o após a inicialização de um manipulador de ação do usuário, antes da navegação. Tags de idioma inválidas e chamadas antes da inicialização são ignoradas.

O método envia um evento `language_selection` imediatamente. Seu `sl` ainda descreve a página atual, não o destino. Eventos subsequentes incluem a escolha em `cl` até que outra escolha explícita a substitua. Sem uma seleção observada, `cl` está vazio. A escolha é armazenada como `__glossia_selected_language` na mesma origem, por aba `sessionStorage`; quando o armazenamento falha, é retido apenas na memória até o unload.

Para links, `data-glossia-language="zh-Hans"` habilita o rastreamento delegado de cliques primários confiáveis e não modificados, incluindo ativação por teclado. Cliques programados, cliques já cancelados, downloads, links de outra origem e links que apontam para outra aba ou frame são ignorados. O listener roda na fase de captura antes que os roteadores naveguem, não impede a navegação e também lida com links inseridos dinamicamente. Use ou a anotação ou a API para uma ação, não ambas.

Este é um sinal de intenção reportado pelo cliente, não uma prova de que a navegação teve sucesso. Mudanças de URL, redirecionamentos e alterações de idioma HTML não são interpretadas como escolhas. A seleção não sobrescreve `l` ou `sl`, nem atualmente altera `has_locale_gap` ou insígnias do painel.

## Campos derivados do servidor

Estes são computados na ingestão e armazenados no lado do servidor. O IP bruto e o User-Agent nunca são armazenados.

| Campo             | Origem        | Descrição                                                         |
|-------------------|---------------|---------------------------------------------------------------------|
| `visitor_id`      | HMAC          | Hash rotativo diário de IP + UA + projeto. Não é vinculável entre dias.  |
| `country_code`    | Cloudflare / GeoIP | Código ISO 3166-1 alpha-2 de um cabeçalho `CF-IPCountry` confiável, ou o adaptador de geolocalização de IP configurado. Vazio quando nenhum resolve um país. |
| `device`          | User-Agent    | `desktop`, `mobile`, `tablet`, `bot` ou `unknown`.                 |
| `browser`         | User-Agent    | `chrome`, `safari`, `firefox`, `edge`, `opera` ou `unknown`.       |
| `os`              | User-Agent    | `windows`, `macos`, `ios`, `android`, `linux` ou `unknown`.        |
| `hostname`        | URL da página      | Host em minúsculas.                                                    |
| `pathname`        | URL da página      | Componente de caminho.                                                     |
| `referrer_source` | Referer      | Host do Referer, com `www.`/`m.` removidos na frente.                        |
| `browser_language`| Idiomas     | Local mais normalizado preferido (por exemplo, `pt-BR`).                    |
| `served_locale`   | Idioma da página | `sl` padronizado, ou vazio se não foi coletado. Linhas com um idioma da página vazio são omitidas na classificação de idioma do navegador. |
| `selected_locale` | Escolha explícita | `cl` padronizado, ou vazio para entrada faltante, malformada ou sem tamanho. Armazenado separadamente da preferência do navegador e idioma da página. |
| `has_locale_gap`  | Computado      | `1` quando nenhum dos idiomas preferidos do visitante coincide com os objetivos do projeto, traduções anunciadas (`al`) ou idioma da página (`sl`). Preferências ausentes não contam como uma lacuna. |

### Resolução de endereço de IP do cliente

Para requisições de um par de entrada privada, o Glossia usa o cabeçalho `X-Real-IP` sobrescrito pelo nginx, não a primeira entrada controlada pelo chamador em `X-Forwarded-For`. Conexões públicas diretas usam o endereço de socket. No Hetzner, tanto o balanceador de carga quanto o nginx devem habilitar o protocolo PROXY para que o nginx receba o endereço do visitante em vez do endereço do balanceador. Outros proxies reversos também devem sobrescrever `X-Real-IP` usando uma fonte autenticada, não um cabeçalho `X-Forwarded-For` de entrada não restrito. A política genérica de cabeçalho encaminhado do gráfico não garante isso por si só. Pares privados são infraestrutura confiável, restrinja o acesso direto do pod.

`GLOSSIA_TRUST_CLOUDFLARE_CLIENT_IP_HEADER=true` permite que `CF-Connecting-IP` sobrescreva o endereço canônico para requisições de um par de entrada privada. Está **desabilitado por padrão**, independentemente da confiança no cabeçalho de país. Habilite-o apenas após a borda autenticar o Cloudflare ou remover cabeçalhos falsificados em requisições que contornam o Cloudflare. Implantações apenas DNS devem mantê-lo desabilitado. Este endereço também chave as limitações de taxa de IP e o hash diário de visitante.

### Resolução de país

`GLOSSIA_TRUST_CLOUDFLARE_COUNTRY_HEADER=true` habilita o caminho rápido `CF-IPCountry`. Está **desabilitado por padrão**. Habilite-o apenas após a origem autenticar o Cloudflare, rejeitar requisições que contornam o Cloudflare ou o ingress remover cópias não confiáveis do cabeçalho. A configuração de Geolocalização de IP do Cloudflare também deve estar habilitada para a zona. `CF-Connecting-IP`, `CF-Ray` e o `use-forwarded-headers` do nginx não autenticam uma requisição sozinhos.

Quando a confiança no cabeçalho é habilitada, um único código ISO de país válido é usado imediatamente, sem uma pesquisa de IP ou acesso em cache. O valor atual da borda sempre tem precedência sobre qualquer pesquisa em cache. Códigos ausentes, duplicados, malformados ou desconhecidos, incluindo os valores `XX` (desconhecido) e `T1` (Tor) do Cloudflare, retornam para o adaptador de geolocalização configurado.

Sem um banco de dados MaxMind configurado, as pesquisas de retorno usam `api.ipapi.is`, depois `api.country.is` quando a requisição principal falha ou não retorna um país reconhecido. Cada requisição tem um timeout de conexão e resposta de um segundo com retransmissões desabilitadas. Resultados bem-sucedidos de qualquer provedor são armazenados em cachê pelo Cachex por 24 horas, com um limite programado de tamanho de 100.000 entradas e recuperação automática de expiração. `Cachex.fetch/3` consolida falhas concurrentes para o mesmo IP em um único resolutor. Falhas não são armazenadas. Endereços privados e reservados não são enviados a nenhum provedor.

### Idioma da página ausente

A classificação de idioma do navegador omite eventos sem `sl`. Isso inclui eventos coletados por versões mais antigas do rastreador e páginas sem um atributo HTML `lang`. Esses eventos ainda contribuem para o tráfego geral. O idioma da página não é inferido das preferências do navegador ou da URL. Eventos históricos mantêm os metadados coletados na época; novas versões de rastreador não os preenchem.

## Modelo de privacidade

- **Sem identificador persistente de sessão cruzada.** O SDK não define cookies e armazena apenas um ID de sessão por aba e um idioma selecionado explicitamente em `sessionStorage`, que o navegador limpa ao fechar.
- **Sem digitalização.** Canvas, WebGL, fontes e impressões digitais de áudio não são coletados. O hash rotativo diário do servidor fornece unicidade sem eles.
- **Sem identificadores brutos persistidos.** IP e User-Agent são lidos uma vez, em hash com um segredo do servidor e um sal diário, e então descartados.
- **Escopo por projeto.** O mesmo navegador em dois projetos gera IDs de visitante não relacionados, então os visitantes não podem ser rastreados entre clientes Glossia.
