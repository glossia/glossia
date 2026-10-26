%{
  title: "Por que Glossia",
  summary:
    "Um sistema operacional de idioma que mantém conteúdo, contexto e revisão alinhados com a entrega contínua.",
  category: "explicação",
  section: "translation",
  order: 1
}
---

Um produto pode ser lançado continuamente enquanto suas traduções permanecem presas em um ciclo de lançamento separado. O conteúdo de origem muda no Git, alguém o exporta para um sistema de tradução, editores trabalham lá e alguém importa o resultado. O produto e suas versões em idioma se afastam.

O Glossia é um sistema operacional de idiomas construído em torno de uma premissa diferente: o trabalho de idioma deve seguir o mesmo ciclo de entrega versionado e revisável que o próprio produto.

## O problema é maior do que a tradução

Equipes precisam preservar o significado, aplicar a terminologia, ajustar o tom para o público e atualizar o conteúdo conforme o produto evolui. Essas decisões afetam a documentação, strings da interface, páginas de marketing e a escrita gerada por agentes igualmente.

Um modelo pode produzir um rascunho útil. Por si só, ele não conhece as decisões de idioma da sua organização, registra por que uma frase mudou, valida seus formatos de arquivo ou sincroniza a próxima revisão de origem. Repetir um prompt não é um sistema de entrega.

O Glossia combina contexto de idioma com as mecânicas ao redor da geração: configuração, detecção de alterações, validação, recuperação de falhas, histórico de revisão e revisão.

## O conteúdo permanece com o produto

O repositório permanece como autoridade para o conteúdo publicado. Arquivos de origem, configuração, traduções geradas e alterações revisáveis podem viajar pelo Git e pull requests. Equipes não precisam fazer uma interface de edição hospedada a autoridade para cada frase antes de poderem entregar uma versão localizada.

Isso torna as mudanças de idioma visíveis ao lado da mudança do produto que as motivou. Um revisor pode inspecionar o diff, o CI pode validar a saída e o mesmo pipeline de entrega pode publicá-la.

Leia [Localização contínua](./continuous-localization) para o modelo de entrega e [Propriedade do conteúdo](./content-ownership) para suas implicações de portabilidade.

## Contexto é uma entrada, não uma jaula

Orientação de Voz e terminologia ajudam tanto humanos quanto agentes a escrever consistentemente. São decisões de idioma reutilizáveis, não apenas uma coleção proprietária de pares de segmentos de origem-destino.

Memórias de tradução permanecem úteis para traduções estabelecidas e conteúdo repetitivo. O ponto não é descartá-las. O ponto é evitar fazer o formato de memória de um fornecedor ou fluxo de trabalho de edição o único lugar onde o conhecimento de idioma de uma empresa pode viver.

## Melhoria é um ciclo

O modelo de refinamento progressivo do Glossia usa hashes de conteúdo para evitar trabalho redundante, roda validação em torno das transformações e expõe falhas para que uma execução possa se recuperar. Correções humanas podem informar a próxima iteração em vez de desaparecerem em uma geração isolada.

Análise de localização fornece outra entrada: entender as línguas e lugares que um público usa pode ajudar uma equipe a decidir onde investir. É evidência para priorização, não uma promessa de que uma tradução produzirá crescimento.

## Para quem isso serve

O Glossia é especialmente relevante quando devs, linguistas e equipes de produto querem colaborar sobre conteúdo gerenciado em repositório e lançá-lo continuamente. Não é uma afirmação de que todas as organizações devem abandonar seu TMS existente. Uma equipe cuja exigência central é um editor baseado em navegador maduro, coordenação de agência de tradução ou uma memória estabelecida grande pode preferir outro fluxo de trabalho.

## Implementação inspecionável

O código do Glossia está publicamente disponível, incluindo seu aplicativo Phoenix, CLI Rust, SDK web e infraestrutura de implantação. Isso torna as mecânicas do trabalho de idioma inspecionáveis em vez de uma caixa preta.

O repositório atualmente usa a [licença O'Saasy](https://github.com/glossia/glossia/blob/main/LICENSE.md), que permite uso e modificação, mas restringe serviços hospedados concorrentes. A disponibilidade de código-fonte público e liberdades de licenciamento são distintas; leia a licença antes de redistribuir ou operar um serviço.
