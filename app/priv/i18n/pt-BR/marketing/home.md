# Glossia: um sistema operacional de linguagem para equipes

A Glossia traz voz, terminologia, tradução, histórico de revisões e análise de localização em um único sistema. Ela ajuda desenvolvedores, linguistas e equipes de produto a se comunicarem consistentemente entre idiomas sem mover o conteúdo para fora do Git.

## O problema

Lançar em outro idioma não é apenas substituir palavras. As equipes precisam preservar o significado, usar a terminologia correta, adaptar o tom ao público e manter as traduções atualizadas conforme o produto evolui. O contexto disperso em planilhas, prompts e ferramentas de tradução leva a uma escrita inconsistente e a trabalho manual repetitivo.

Um LLM pode rascunhar uma tradução, mas apenas um rascunho não fornece histórico de versão, validação, atualizações seletivas ou um ciclo de feedback para a próxima alteração.

## O papel da Glossia

- **Memória de linguagem:** orientações de voz compartilhadas e entradas de glosário ajudam pessoas e agentes a usar linguagem consistente.
- **Localização de repositório:** conecte um repositório, descreva arquivos de origem e públicos-alvo na configuração e revise alterações através de pull requests.
- **Refinamento progressivo:** hashes de conteúdo ajudam a evitar a tradução de conteúdo não alterado. Validação e recuperação tornam as falhas visíveis e acionáveis.
- **Revisão de conteúdo:** preserve o histórico de decisões de linguagem e alterações, ao invés de tratar cada geração como um prompt isolado.
- **Análise de localização:** análises web que respeitam a privacidade ajudam equipes a entenderem seu público e onde vale a pena investir na localização.
- **Integração de agentes:** um servidor MCP autenticado via OAuth e interfaces REST tornam o contexto de linguagem disponível para fluxos de trabalho existentes.

A Glossia não substitui o julgamento editorial. Ela fornece o contexto, automação e fluxo de revisão que permitem às equipes aplicar esse julgamento repetidamente.

## Explore

- [Primeiros passos](/docs/tutorials/getting-started.md): conectar um repositório e executar seu primeiro fluxo de trabalho de localização.
- [Por que a Glossia](/docs/explanation/why-glossia.md): os problemas que o sistema operacional de linguagem foi projetado para resolver.
- [Recursos](/features.md): capacidades do produto e casos de uso.
- [Documentação](/docs.md): tutoriais, guias passo a passo, referências e explicações.
- [Blog](/blog.md): escritos sobre localização e sistemas de linguagem.
- [Changelog](/changelog.md): alterações do produto.
- [Código-fonte](https://github.com/glossia/glossia): inspecionar a implementação e contribuir.

## Comparações

- [Glossia vs Crowdin](/docs/explanation/glossia-vs-crowdin.md)
- [Glossia vs Lokalise](/docs/explanation/glossia-vs-lokalise.md)
- [Glossia vs Phrase](/docs/explanation/glossia-vs-phrase.md)
- [Glossia vs Weblate](/docs/explanation/glossia-vs-weblate.md)

## Para rastreadores e agentes

As páginas publicadas estão disponíveis como Markdown ao anexar `.md` ao seu URL, ou requisitando `Accept: text/markdown` no URL HTML. O URL Markdown da página inicial é `/index.md`. O conteúdo traduzido usa os mesmos prefixos de idioma que o HTML e recorre ao inglês quando nenhuma tradução está publicada.

Use [/llms.txt](/llms.txt) para descoberta, [/llms-full.txt](/llms-full.txt) para uma exportação de documentação consolidada e [/sitemap.xml](/sitemap.xml) para URLs HTML canônicas. Painéis de conta são superfícies de aplicação, não documentação; não os rastreie para aprender sobre a Glossia.
