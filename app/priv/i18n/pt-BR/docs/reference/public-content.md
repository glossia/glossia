%{
  title: "Conteúdo público e interfaces de rastreador",
  summary: "HTML, Markdown, descoberta, cache e limites do rastreador para o site público.",
  category: "referência",
  section: "platform",
  order: 10
}
---

Glossia expõe conteúdo de site publicado separadamente das superfícies de aplicação de conta e projeto.

## Representações

| Interface | Comportamento |
|---|---|
| Uma URL HTML publicada | A representação de navegador, com metadados canônicos e um cabeçalho de resposta alternativo em `Link`. |
| A `Accept: text/markdown` naquela URL | Uma representação em Markdown quando o tipo de mídia explícito tiver qualidade positiva e não for menos preferido que `text/html`. |
| A URL da página com `.md` anexada | Uma representação explícita em Markdown, independente da preferência de idioma do navegador. |
| `/index.md` | Uma visão geral em Markdown da página inicial. |
| `/docs.md`, `/blog.md`, `/features.md` | Índices em Markdown de conteúdo publicado. |
| `/changelog.md` | Entradas de changelog publicadas em um único documento Markdown. |
| `/terms.md`, `/privacy.md`, `/cookies.md` | Os documentos legais publicados mais recentes. URLs legais datados também suportam `.md`. |

`*/*` sozinho não habilita o Markdown. As respostas HTML e Markdown compartilham `Vary: Accept` para que os caches não misturem as representações.

Documentação individual, de blog, de recurso e legal utiliza Markdown escrito, em vez de uma conversão do HTML renderizado. As páginas de índice são geradas a partir do inventário publicado; a página inicial possui uma visão geral em Markdown curada. A referência interativa REST orienta os leitores para a especificação OpenAPI, em vez de incorporar um widget de API exclusivo para navegador.

## Idiomas

O inglês não possui prefixo. URLs de marketing traduzidas usam prefixos literais: `/de`, `/es`, `/fr`, `/ja`, `/ko`, `/pt-br` e `/zh-hans`. Por exemplo, `/es/docs/tutorials/getting-started.md` serve para a versão espanhola quando for publicada.

A URL escolhe o idioma do conteúdo Markdown. `Accept-Language` não redireciona um pedido Markdown. Uma tradução de conteúdo faltante recorre à sua fonte em inglês. A visão geral da página inicial é atualmente escrita em inglês.

## Descoberta

- `/robots.txt` proíbe o rastreamento por padrão e inclui o inventário publicado finito de HTML e Markdown, feeds localizados, ativos de renderização em `/assets/`, `/fonts/` e `/images/`, o favicon e pré-visualizações de marketing públicas em `/og/marketing/`. Imagens de pré-visualização de conta em `/og/app/` permanecem proibidas. É uma orientação para rastreadores cooperativos, não um mecanismo de autorização.
- `/sitemap.xml` lista conteúdo público canônico com alternatas de idioma, incluindo URLs Markdown para páginas exclusivamente em Markdown. Fragmentos de changelog não são URLs separadas.
- `/llms.txt` apresenta o Glossia e liga para documentação pública, guias de recurso e escrita recente, incluindo links Markdown explícitos.
- `/llms-full.txt` exporta a visão geral da página inicial, documentação e conteúdo de comparação exclusivamente em Markdown em um único documento de texto contendo Markdown.

O conteúdo de comparação é publicado apenas como Markdown. Permanece fora da documentação HTML, navegação, busca e índices de documentação, mas agentes podem descobri-lo através de `/llms.txt` e do sitemap. Sua URL canônica termina em `.md`; a antiga URL HTML também responde a `Accept: text/markdown`, mas não renderiza mais uma página de navegador.

Autenticação, painéis de conta, APIs e outras respostas de aplicação são marcadas como `noindex, nofollow`. Conteúdo publicado bem-sucedido é marcado como `index, follow`; erros permanecem não indexáveis. Arquivos de texto de descoberta (`/robots.txt`, `/llms.txt` e `/llms-full.txt`) usam `noindex, follow`: leitores podem buscá-los e seguir seus links, mas os motores de busca devem indexar as páginas canônicas em vez de um despejo duplicado de documentação.

## Cache e uso de recursos

As respostas de descoberta de Markdown e de texto incluem:

| Cabeçalho | Valor ou significado |
|---|---|
| `Content-Type` | `text/markdown; charset=utf-8`, ou `text/plain; charset=utf-8` para texto de descoberta. |
| `Cache-Control` | `public, max-age=300, stale-while-revalidate=60`. |
| `ETag` | Um resumo (digest) SHA-256 aspas duplas da representação. |
| `X-Markdown-Tokens` | Uma estimativa aproximada de caracteres divididos por quatro, arredondados para cima; não é uma contagem de tokenizadores específica do modelo. |

`If-None-Match` suporta a correspondência de validadores fortes ou fracos, múltiplos validadores e `*`. Uma correspondência retorna `304` sem corpo. `HEAD` retorna cabeçalhos de representação sem corpo.

O inventário Markdown publicado é compilado no lançamento. Os pedidos não realizam tradução de conteúdo, leem arquivos de fonte, carregam uma conta autenticada ou renderizam uma LiveView. Nenhuma falsificação de User-Agent é necessária para acessar essas representações públicas.

## Limites operacionais

A negociação Markdown não fornece acesso a painéis de conta ou de projeto. Limites de taxa de navegação de conta e verificações do Turnstile permanecem como proteções separadas.

Limites de taxa da borda de produção aplicam-se tanto a `GET` quanto a `HEAD`. Rastreadores verificados ainda têm limite de taxa. Pedidos excessivos recebem uma resposta de limite de taxa, em vez de um desafio de navegador; os leitores devem reduzir a velocidade e tentar novamente depois. Cache compartilhado e pedidos condicionais não isentam clientes de limites de taxa.

As mudanças de política de rastreador no repositório entram em vigor apenas após a configuração da aplicação e infraestrutura relevante ser implantada.
