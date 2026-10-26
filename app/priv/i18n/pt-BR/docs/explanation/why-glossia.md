%{
  title: "Por que Glossia",
  summary:
    "Um Sistema Operacional de Linguagem que mantém conteúdo, contexto e revisão alinhados com entrega contínua.",
  category: "explicação",
  section: "translation",
  order: 1
}
---

Um produto pode ser lançado continuamente enquanto suas traduções permanecem presas em um ciclo de lançamento separado. O conteúdo de origem muda no Git, alguém o exporta para um sistema de tradução, editores trabalham lá e alguém importa o resultado. O produto e suas versões em idioma se desalinham.

Glossia é um SO de idioma construído em torno de uma premissa diferente: o trabalho com idioma deve seguir o mesmo ciclo de entrega versionável e passível de revisão que o próprio produto.

## O problema é maior que a tradução

Equipes precisam preservar o significado, aplicar terminologia, adequar o tom do público-alvo e atualizar o conteúdo conforme o produto evolui. Essas decisões afetam documentação, strings de interface de usuário, páginas de marketing e textos gerados por agentes da mesma forma.

Um modelo pode produzir um rascunho útil. Ele não, por si só, conhece as decisões de idioma da sua organização, registra por que uma frase mudou, valida seus formatos de arquivo ou sincroniza a próxima revisão de fonte. Repetir um prompt não é um sistema de entrega.

O Glossia combina o contexto de idioma com as mecânicas em torno da geração: configuração, detecção de mudanças, validação, recuperação de falhas, histórico de revisões e revisão.

## O conteúdo permanece com o produto

O repositório permanece como a autoridade para o conteúdo publicado. Arquivos de origem, configuração, traduções geradas e alterações passíveis de revisão podem viajar através do Git e solicitações pull. As equipes não precisam tornar uma interface de edição hospedada a autoridade para cada frase antes de poderem entregar uma versão localizada.

Isso torna as mudanças de idioma visíveis ao lado da mudança de produto que as motivou. Um revisor pode inspecionar o diff, o CI pode validar a saída e o mesmo pipeline de entrega pode publicá-lo.

Leia [Localização contínua](./continuous-localization) para o modelo de entrega e [Propriedade do conteúdo](./content-ownership) para suas implicações de portabilidade.

## O contexto é uma entrada, não uma gaiola

A orientação de voz e terminologia ajudam tanto humanos quanto agentes a escrever de forma consistente. São decisões de idioma reutilizáveis, não apenas uma coleção proprietária de pares de segmentos de origem-alvo.

Memórias de tradução permanecem úteis para traduções estabelecidas e conteúdo repetitivo. O ponto não é descartá-las. O ponto é evitar fazer o formato de memória de um fornecedor ou o fluxo de trabalho de edição ser o único lugar onde o conhecimento linguístico de uma empresa pode viver.

## A melhoria é um ciclo

O modelo de refinamento progressivo do Glossia usa hashes de conteúdo para evitar trabalho redundante, executa validação em torno das transformações e expõe falhas para que uma execução possa recuperar. Correções humanas podem informar a próxima iteração em vez de desaparecerem em uma geração isolada.

A análise de localização fornece outra entrada: entender os idiomas e lugares que um público usa pode ajudar uma equipe a decidir onde investir. É evidência para priorização, não uma promessa de que uma tradução produzirá crescimento.

## Para quem serve

O Glossia é especialmente relevante quando desenvolvedores, linguistas e equipes de produto desejam colaborar em conteúdo gerenciado por repositório e lançá-lo continuamente. Não é uma afirmação de que todas as organizações devem abandonar seu TMS existente. Uma equipe cuja exigência central seja um editor baseado em navegador maduro, coordenação de agência de tradução ou uma memória estabelecida grande pode preferir outro fluxo de trabalho.

## Implementação inspecionável

O código do Glossia está publicamente disponível, incluindo seu aplicativo Phoenix, CLI do Rust, SDK web e infraestrutura de implantação. Isso torna as mecânicas do trabalho com idioma inspecionáveis em vez de uma caixa preta.

O Glossia segue um modelo open-core. O núcleo usa [Apache-2.0](https://github.com/glossia/glossia/blob/main/LICENSE-APACHE), que permite uso comercial, auto-hospedagem e serviços hospedados concorrentes. O diretório `ee/` possui uma [Licença Empresarial](https://github.com/glossia/glossia/blob/main/ee/LICENSE.md) separada exigindo um acordo comercial escrito para uso em produção. Leia a licença aplicável antes de redistribuir ou operar recursos empresariais.
