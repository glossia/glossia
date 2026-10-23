# Glossia: um OS de Linguagem para equipes

Glossia reúne voz, terminologia, tradução, histórico de revisões e análises de localização em um único sistema. Ajuda desenvolvedores, linguistas e equipes de produto a se comunicarem consistentemente em vários idiomas sem mover o conteúdo para fora do Git.

## O problema

Lançar em outro idioma não é apenas substituir palavras. As equipes precisam preservar o significado, utilizar a terminologia correta, adaptar o tom ao público e manter as traduções atualizadas conforme o produto muda. Contextos espalhados em planilhas, prompts e ferramentas de tradução levam a escrita inconsistente e trabalho manual repetitivo.

Um LLM pode criar um rascunho de tradução, mas um rascunho sozinho não fornece histórico de versões, validação, atualizações seletivas ou um ciclo de feedback para a próxima alteração.

## O papel da Glossia

- **Memória de linguagem:** orientações de voz compartilhadas e entradas de glossário ajudam pessoas e agentes a usar linguagem consistente.
- **Localização de repositório:** conecte um repositório, descreva arquivos de origem e locais-alvo na configuração e revise alterações por meio de pull requests.
- **Refinamento progressivo:** hashes de conteúdo ajudam a evitar traduzir conteúdo inalterado. Validação e recuperação tornam falhas visíveis e acionáveis.
- **Revisão de conteúdo:** preserve o histórico de decisões e alterações de idioma em vez de tratar cada geração como um prompt isolado.
- **Análises de localização:** análises web conscientes da privacidade ajudam as equipes a entenderem seu público e onde vale a pena investir em localização.
- **Integração de agentes:** um servidor MCP autenticado via OAuth e interfaces REST tornam o contexto de idioma disponível para fluxos de trabalho existentes.

A Glossia não substitui o julgamento editorial. Ela fornece o contexto, automação e fluxo de revisão que permitem às equipes aplicar esse julgamento repetidamente.

## Explorar

- [Primeiros passos](/docs/tutorials/getting-started.md): conecte um repositório e execute seu primeiro fluxo de localização.
- [Por que Glossia](/docs/explanation/why-glossia.md): os problemas que o OS de Linguagem foi projetado para resolver.
- [Recursos](/features.md): capacidades do produto e casos de uso.
- [Documentação](/docs.md): tutoriais, guias de uso, referência e explicações.
- [Blog](/blog.md): artigos sobre localização e sistemas de idioma.
- [Log de alterações](/changelog.md): alterações no produto.
- [Código-fonte](https://github.com/glossia/glossia): inspecione a implementação e contribua.

## Comparativos

- [Glossia vs Crowdin](/docs/explanation/glossia-vs-crowdin.md)
- [Glossia vs Lokalise](/docs/explanation/glossia-vs-lokalise.md)
- [Glossia vs Phrase](/docs/explanation/glossia-vs-phrase.md)
- [Glossia vs Weblate](/docs/explanation/glossia-vs-weblate.md)

## Para crawlers e agentes

As páginas publicadas estão disponíveis como Markdown anexando `.md` à sua URL, ou solicitando `Accept: text/markdown` na URL do HTML. A URL Markdown da página inicial é `/index.md`. O conteúdo traduzido usa os mesmos prefixos de localização do HTML e retorna ao inglês quando nenhuma tradução é publicada.

Use [/llms.txt](/llms.txt) para descoberta, [/llms-full.txt](/llms-full.txt) para uma exportação de documentação consolidada e [/sitemap.xml](/sitemap.xml) para URLs HTML canônicos. Os painéis de conta são interfaces de aplicação, não documentação; não os rastreie para aprender sobre a Glossia.
