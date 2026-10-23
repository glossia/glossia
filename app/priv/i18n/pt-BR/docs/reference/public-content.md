%{
  title: "Conteúdo público e interfaces do rastreador",
  summary: "HTML, Markdown, descoberta, cache e limites do rastreador para o site público.",
  category: "referência",
  section: "platform",
  order: 10
}
---

O Glossia expõe o conteúdo publicado do site separadamente das superfícies de aplicação de conta e de projeto.

## Representações

| Interface | Comportamento |
|---|---|
| Um URL HTML publicado | A representação do navegador, com metadados canônicos e um cabeçalho de resposta de alternativa Markdown `Link`. |
| `Accept: text/markdown` naquela URL | Uma representação Markdown quando o tipo de mídia explícito tem qualidade positiva e não é menos preferido que `text/html`. |
| O URL da página com `.md` anexado | Uma representação Markdown explícita, independente da preferência de idioma do navegador. |
| `/index.md` | O resumo Markdown da página inicial. |
| `/docs.md`, `/blog.md`, `/features.md` | Índices Markdown de conteúdo publicado. |
| `/changelog.md` | Entradas de changelog publicadas em um único documento Markdown. |
| `/terms.md`, `/privacy.md`, `/cookies.md` | Os documentos legais mais recentes publicados. URLs legais com data também suportam `.md`. |

Apenas o `*/*` não opta para o Markdown. Respostas HTML e Markdown compartilham `Vary: Accept` para que os caches não misturem as representações.

O conteúdo individual de documentação, blog, recursos e legais usa Markdown escrito em vez de uma conversão do HTML renderizado. Páginas de índice são geradas a partir do inventário publicado; a página inicial tem um resumo Markdown curado. A referência interativa REST direciona os leitores para a especificação OpenAPI em vez de incorporar um widget de API exclusivo para navegador.

## Idiomas

O inglês está sem prefixo. URLs de marketing traduzidos usam prefixos literais: `/de`, `/es`, `/fr`, `/ja`, `/ko`, `/pt-br` e `/zh-hans`. Por exemplo, `/es/docs/tutorials/getting-started.md` serve a versão em espanhol quando ela é publicada.

A URL escolhe o idioma do conteúdo Markdown. `Accept-Language` não redireciona uma requisição Markdown. Uma tradução de conteúdo ausente volta para a fonte em inglês. O resumo da página inicial é atualmente escrito em inglês.

## Descoberta

- O `/robots.txt` por padrão proíbe a raspagem e opta pelo inventário publicado de HTML e Markdown, feeds localizados, ativos de renderização sob `/assets/`, `/fonts/` e `/images/`, o favicon e pré-visualizações de marketing públicas sob `/og/marketing/`. Imagens de pré-visualização de conta sob `/og/app/` permanecem proibidas. É uma orientação para crawlers cooperativos, não um mecanismo de autorização.
- O `/sitemap.xml` lista conteúdo HTML público canônico com alternativos de idioma. Fragmentos de changelog não são URLs separados.
- O `/llms.txt` apresenta o Glossia e vincula à documentação pública, guias de recursos e escritos recentes, incluindo links Markdown explícitos.
- O `/llms-full.txt` exporta o resumo da página inicial e o inventário completo de documentação em um único documento de texto contendo Markdown.

Autenticação, painéis de conta, APIs e outras respostas de aplicação são marcadas com `noindex, nofollow`. Conteúdo publicado bem-sucedido é marcado com `index, follow`; erros permanecem não indexáveis. Arquivos de texto de descoberta (`/robots.txt`, `/llms.txt` e `/llms-full.txt`) usam `noindex, follow`: leitores podem buscá-los e seguir seus links, mas motores de busca devem indexar as páginas canônicas em vez de um despejo de documentação duplicada.

## Cacheamento e uso de recursos

As respostas de descoberta de Markdown e texto incluem:

| Cabeçalho | Valor ou significado |
|---|---|
| `Content-Type` | `text/markdown; charset=utf-8`, ou `text/plain; charset=utf-8` para texto de descoberta. |
| `Cache-Control` | `public, max-age=300, stale-while-revalidate=60`. |
| `ETag` | Um resumo SHA-256 citado da representação. |
| `X-Markdown-Tokens` | Uma estimativa grosseira de caracteres divididos por quatro, arredondado para cima; não é uma contagem de tokenizador específica de modelo. |

`If-None-Match` suporta validadores fortes ou fracos, múltiplos validadores e `*`. Uma correspondência retorna `304` sem corpo. `HEAD` retorna cabeçalhos de representação sem corpo.

O inventário Markdown publicado é compilado no lançamento. Requisições não realizam tradução de conteúdo, leem arquivos-fonte, carregam uma conta autenticada ou renderizam uma LiveView. Nenhuma falsificação de User-Agent é necessária para acessar essas representações públicas.

## Limites operacionais

A negociação Markdown não fornece acesso aos painéis de conta ou de projeto. Os limites de taxa de navegação de conta existentes e as verificações Turnstile permanecem como proteções separadas.

Os limites de taxa na borda de produção se aplicam tanto a `GET` quanto a `HEAD`. Os crawlers verificados ainda estão sujeitos a limites de taxa. Requisições excessivas recebem uma resposta de limite de taxa em vez de um desafio de navegador; os leitores devem reduzir a velocidade e tentar novamente mais tarde. Cache compartilhado e solicitações condicionais não isentam os clientes dos limites de taxa.

Alterações na política de crawler no repositório entram em vigor apenas após o aplicativo e a configuração de infraestrutura relevantes serem implantados.
