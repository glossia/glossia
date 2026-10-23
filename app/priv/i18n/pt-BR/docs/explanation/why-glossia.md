%{
  title: "Por que Glossia",
  summary:
    "Um sistema operacional para linguagem que mantém conteúdo, contexto e revisão alinhados com a entrega contínua.",
  category: "explicação",
  section: "translation",
  order: 1
}
---

Um produto pode ser lançado continuamente enquanto suas traduções permanecem presas em um ciclo de lançamento separado. O conteúdo da fonte muda no Git, alguém exporta para um sistema de tradução, editores trabalham lá, e alguém importa o resultado. O produto e suas versões linguísticas ficam distantes.

Glossia é um sistema operacional de linguagem construído em torno de uma premissa diferente: o trabalho linguístico deve seguir o mesmo ciclo de entrega versionado e revisável que o próprio produto.

## O problema é maior que a tradução

Equipes precisam preservar significado, aplicar terminologia, alinhar o tom do público e atualizar o conteúdo conforme o produto evolui. Essas decisões afetam documentação, strings de interface, páginas de marketing e a escrita gerada por agentes de igual forma.

Um modelo pode produzir um rascunho útil. Por si só, ele não conhece as decisões linguísticas da sua organização, registra por que uma frase mudou, valida seus formatos de arquivo ou sincroniza a próxima revisão da fonte. Repetir um prompt não é um sistema de entrega.

Glossia combina o contexto de linguagem com os mecanismos em torno da geração: configuração, detecção de alterações, validação, recuperação de falhas, histórico de revisões e revisão.

## O conteúdo permanece com o produto

O repositório permanece a autoridade para o conteúdo publicado. Arquivos de fonte, configuração, traduções geradas e alterações revisáveis podem viajar por meio do Git e pull requests. As equipes não precisam tornar uma interface de edição hospedada a autoridade para cada frase antes de poderem entregar um lançamento localizado.

Isso torna as alterações linguísticas visíveis ao lado da alteração do produto que as motivou. Um revisor pode examinar os diffs, o CI pode validar a saída e o mesmo pipeline de entrega pode publicá-la.

Leia [Localização contínua](./continuous-localization) para o modelo de entrega e [Propriedade de conteúdo](./content-ownership) para suas implicações de portabilidade.

## O contexto é uma entrada, não uma gaiola

Orientação de voz e terminologia ajudam tanto humanos quanto agentes a escrever consistentemente. São decisões linguísticas reutilizáveis, não apenas uma coleção proprietária de pares de segmentos fonte-alvo.

Memórias de tradução permanecem úteis para traduções já estabelecidas e conteúdo repetitivo. O ponto não é descartá-las. O ponto é evitar que o formato de memória de um fornecedor ou fluxo de trabalho de edição se torne o único local onde o conhecimento linguístico de uma empresa pode viver.

Veja [Memória de linguagem e memória de tradução](./language-memory-and-translation-memory).

## Melhoria é um ciclo

O modelo de refinamento progressivo do Glossia usa hashes de conteúdo para evitar trabalho redundante, executa validação em torno de transformações e expõe falhas para que uma execução possa se recuperar. Correções humanas podem informar a próxima iteração em vez de desaparecerem em uma geração isolada.

A analítica de localização fornece outra entrada: compreender as línguas e os lugares que uma audiência usa pode ajudar uma equipe a decidir onde investir. É evidência para a priorização, não uma promessa de que uma tradução produzirá crescimento.

## A quem isso se destina

O Glossia é especialmente relevante quando desenvolvedores, linguistas e equipes de produto desejam colaborar em conteúdo gerenciado por repositório e lançá-lo continuamente. Não é uma afirmação de que cada organização deve abandonar seu TMS existente. Uma equipe cujo requisito central é um editor baseado em navegador maduro, coordenação com agências de tradução ou uma grande memória estabelecida pode preferir outro fluxo de trabalho.

As comparações [Crowdin](./glossia-vs-crowdin), [Lokalise](./glossia-vs-lokalise), [Phrase](./glossia-vs-phrase) e [Weblate](./glossia-vs-weblate) explicam esses trade-offs.

## Implementação inspecionável

O código do Glossia está disponível publicamente, incluindo seu aplicativo Phoenix, CLI em Rust, SDK Web e infraestrutura de implantação. Isso torna os mecanismos do trabalho linguístico inspecionáveis, não uma caixa preta.

O repositório atualmente usa a [licença O'Saasy](https://github.com/glossia/glossia/blob/main/LICENSE.md), que permite uso e modificação, mas restringe serviços concorrentes hospedados. A disponibilidade de código fonte público e liberdades de licenciamento são distintas; leia a licença antes de redistribuir ou operar um serviço.
