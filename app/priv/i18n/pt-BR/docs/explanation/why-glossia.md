%{
  title: "Por que Glossia",
  summary:
    "Um sistema operacional de linguagem que mantém conteúdo, contexto e revisão alinhados com a entrega contínua.",
  category: "explicação",
  section: "translation",
  order: 1
}
---

Um produto pode ser lançado continuamente enquanto suas traduções permanecem presas em um ciclo de lançamento separado. O conteúdo da fonte muda no Git, alguém o exporta para um sistema de tradução, os editores trabalham lá, e alguém importa o resultado. O produto e suas versões linguísticas divergem.

O Glossia é um sistema operacional de linguagem construído em torno de uma premissa diferente: o trabalho linguístico deve seguir o mesmo ciclo de entrega versionável e revisável que o próprio produto.

## O problema é maior que a tradução

Equipes precisam preservar o significado, aplicar terminologia, adequar o tom à audiência e atualizar o conteúdo conforme o produto evolui. Essas decisões afetam documentação, strings da UI, páginas de marketing e redações geradas por agentes.

Um modelo pode produzir um rascunho útil. Sozinho, ele não conhece as decisões linguísticas da sua organização, nem registra por que uma frase mudou, valida seus formatos de arquivo ou sincroniza a próxima revisão da fonte. Repetir um prompt não é um sistema de entrega.

O Glossia combina o contexto linguístico com as mecânicas em torno da geração: configuração, detecção de alterações, validação, recuperação de falhas, histórico de revisões e revisão.

## O conteúdo fica com o produto

O repositório permanece como a autoridade para o conteúdo publicado. Arquivos da fonte, configuração, traduções geradas e alterações revisáveis podem viajar pelo Git e pelo pull requests. Equipes não precisam tornar uma interface de edição hospedada a autoridade para cada frase antes de poderem entregar um lançamento localizado.

Isso torna as alterações linguísticas visíveis junto com a alteração do produto que as motivou. Um revisor pode inspecionar o diff, o CI pode validar a saída, e o mesmo pipeline de entrega pode publicá-lo.

Leia [Localização contínua](./continuous-localization) para o modelo de entrega e [Propriedade do conteúdo](./content-ownership) para suas implicações de portabilidade.

## O contexto é uma entrada, não uma gaiola

A orientação de voz e a terminologia ajudam tanto humanos quanto agentes a escrever consistentemente. São decisões linguísticas reutilizáveis, não apenas uma coleção proprietária de pares de segmentos fonte-alvo.

Memórias de tradução permanecem úteis para traduções estabelecidas e conteúdo repetitivo. O ponto não é descartá-las. O ponto é evitar tornar o formato de memória ou fluxo de trabalho de edição de um único fornecedor o único lugar onde o conhecimento linguístico de uma empresa pode viver.

Veja [Memória linguística e memória de tradução](./language-memory-and-translation-memory).

## Melhoria é um ciclo

O modelo de refinamento progressivo do Glossia usa hashes de conteúdo para evitar trabalho redundante, executa validação ao redor de transformações e expõe falhas para que uma frequência possa se recuperar. Correções humanas podem informar a próxima iteração em vez de desaparecerem em uma geração isolada.

As análises de localização fornecem outra entrada: entender as línguas e lugares que uma audiência usa pode ajudar uma equipe a decidir onde investir. É evidência para priorização, não uma promessa de que uma tradução produzirá crescimento.

## Para quem isso se aplica

O Glossia é especialmente relevante quando desenvolvedores, linguistas e equipes de produto desejam colaborar em conteúdo gerenciado por repositório e lançá-lo continuamente. Não é a afirmação de que toda organização deve abandonar seu TMS existente. Uma equipe cuja exigência central é um editor baseado no navegador maduro, coordenação de agência de tradução ou uma grande memória consolidada pode preferir outro fluxo de trabalho.

As comparações do [Crowdin](./glossia-vs-crowdin), [Lokalise](./glossia-vs-lokalise), [Phrase](./glossia-vs-phrase) e [Weblate](./glossia-vs-weblate) explicam esses trade-offs.

## Implementação inspecionável

O código do Glossia está publicamente disponível, incluindo sua aplicação Phoenix, CLI Rust, SDK web e infraestrutura de implantação. Isso torna as mecânicas do trabalho linguístico inspecionáveis, em vez de uma caixa preta.

O repositório atualmente usa a [licença O'Saasy](https://github.com/glossia/glossia/blob/main/LICENSE.md), que permite uso e modificação, mas restringe serviços hospedados concorrentes. A disponibilidade de código-fonte público e as liberdades de licenciamento são distintas; leia a licença antes de redistribuir ou operar um serviço.
