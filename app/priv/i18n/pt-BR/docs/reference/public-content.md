%{
  title: "Conteúdo público e interfaces de rastreadores",
  summary:
    "HTML, Markdown, descoberta, cacheamento e limites de rastreadores para o site público.",
  category: "referência",
  section: "platform",
  order: 10
}
---

O Glossia exibe conteúdo de site publicado separadamente das superfícies de aplicação de conta e projeto.

## Representações

| Interface | Comportamento |
|---|---|
| Uma URL HTML publicada | A representação do navegador, com metadados canônicos e um cabeçalho de resposta `Link` alternativo em Markdown. |
| `Accept: text/markdown` naquela URL | Uma representação em Markdown quando o tipo de mídia explícito tem qualidade positiva e não é menos preferido do que `text/html`. |
| A URL da página com `.md` anexado ao final | Uma representação explícita em Markdown, independente da preferência de idioma do navegador. |
| `/index.md` | A visão geral em Markdown da página inicial. |
| `/docs.md`, `/blog.md`, `/features.md` | Índices em Markdown de conteúdo publicado. |
| `/changelog.md` | Entradas de log de alterações publicadas em um único documento em Markdown. |
| `/terms.md`, `/privacy.md`, `/cookies.md` | Os documentos legais publicados mais recentes. URLs legais datadas também suportam `.md`. |

`*/*` sozinho não ativa o Markdown. Respostas HTML e respostas em Markdown compartilham `Vary: Accept` para que os caches não misturem as representações.

O conteúdo de documentação individual, de blog, de recursos e legal utiliza Markdown original em vez de uma conversão do HTML renderizado. As páginas de índice são geradas a partir do inventário publicado; a página inicial possui uma visão geral em Markdown curada. A referência interativa REST aponta os leitores para a especificação OpenAPI em vez de incorporar um widget de API exclusivo para navegador.

## Idiomas

O inglês não possui prefixo. URLs de marketing traduzidos usam prefixos literais: `/de`, `/es`, `/fr`, `/ja`, `/ko`, `/pt-br` e `/zh-hans`. Por exemplo, `/es/docs/tutorials/getting-started.md` serve a versão em espanhol quando é publicada.

A URL escolhe o idioma do conteúdo em Markdown. `Accept-Language` não redireciona uma solicitação em Markdown. Uma tradução de conteúdo ausente resgata sua fonte em inglês. A visão geral da página inicial é atualmente escrita em inglês.

## Descoberta

- `/robots.txt` por padrão impede o rastreamento e inclui o inventário HTML e Markdown publicado finito, feeds localizados, ativos de renderização em `/assets/`, `/fonts/` e `/images/`, o favicon e prévias de marketing públicas em `/og/marketing/`. Imagens de prévia de conta em `/og/app/` permanecem proibidas. É um guia para rastreadores cooperativos, não um mecanismo de autorização.
- `/sitemap.xml` lista o conteúdo público canônico com alternatas de idioma, incluindo URLs em Markdown para páginas apenas em Markdown. Fragmentos de log de alterações não são URLs separados.
- `/llms.txt` apresenta o Glossia e vincula à documentação pública, guias de recursos e escritos recentes, incluindo links explícitos em Markdown.
- `/llms-full.txt` exporta a visão geral da página inicial, documentação e conteúdo de comparação apenas em Markdown em um único documento de texto contendo Markdown.

O conteúdo de comparação é publicado apenas em Markdown. Ele permanece fora da documentação HTML, navegação, busca e índices de documentação, mas agentes podem descobri-lo através de `/llms.txt` e do sitemap. Sua URL canônica termina em `.md`; a antiga URL HTML também responde a `Accept: text/markdown`, mas não mais renderiza uma página do navegador.

Autenticação, painéis de controle de conta, APIs e outras respostas de aplicação são marcados `noindex, nofollow`. Conteúdo publicado de sucesso é marcado `index, follow`; erros permanecem não indexáveis. Arquivos de texto de descoberta (`/robots.txt`, `/llms.txt` e `/llms-full.txt`) usam `noindex, follow`: leitores podem recuperá-los e seguir seus links, mas motores de busca devem indexar as páginas canônicas em vez de um vazamento duplicado de documentação.

## Armazenamento em cache e uso de recursos

Respostas de descoberta em Markdown e texto incluem:

| Cabeçalho | Valor ou significado |
|---|---|
| `Content-Type` | `text/markdown; charset=utf-8` ou `text/plain; charset=utf-8` para texto de descoberta. |
| `Cache-Control` | `public, max-age=300, stale-while-revalidate=60`. |
| `ETag` | Um resumo SHA-256 citao da representação. |
| `X-Markdown-Tokens` | Uma estimativa aproximada de caracteres divididos por quatro, arredondados para cima; não é uma contagem de tokenizador específica do modelo. |

`If-None-Match` suporta a correspondência de validadores fortes ou fracos, múltiplos validadores e `*`. Uma correspondência retorna `304` sem um corpo. `HEAD` retorna cabeçalhos de representação sem um corpo.

O inventário em Markdown publicado é compilado no lançamento. Solicitações não realizam tradução de conteúdo, leem arquivos de origem, carregam uma conta autenticada ou renderizam um LiveView. Nenhuma falsificação de User-Agent é necessária para acessar essas representações públicas.

## Limites operacionais

A negociação em Markdown não fornece acesso aos painéis de controle de conta ou de projeto. Os limites de taxa existentes de navegação de conta e verificações de Turnstile permanecem proteções separadas.

Os limites de taxa de borda de produção se aplicam tanto a `GET` quanto a `HEAD`. Rastreadores verificados ainda são limitados na taxa. Solicitações em excesso recebem uma resposta de limitação de taxa em vez de um desafio do navegador; leitores devem retardar e tentar novamente depois. Cache compartilhado e solicitações condicionais não isentam clientes de limites de taxa.

Mudanças na política de rastreadores no repositório entram em vigor apenas após a aplicação e a configuração de infraestrutura relevante serem implantadas.
