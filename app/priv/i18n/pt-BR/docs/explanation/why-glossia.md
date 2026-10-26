%{
  title: "Por que Glossia",
  summary:
    "Um sistema operacional de linguagem que mantém conteúdo, contexto e revisão alinhados com a entrega contínua.",
  category: "explicação",
  section: "translation",
  order: 1
}
---

Um produto pode ser lançado continuamente enquanto suas traduções permanecem presas em um ciclo de lançamento separado. O conteúdo de origem muda no Git, alguém o exporta para um sistema de tradução, os editores trabalham lá, e alguém importa o resultado. O produto e suas versões linguísticas divergem.

Glossia é um sistema operacional de linguagem construído em torno de um princípio diferente: o trabalho com idioma deve seguir o mesmo ciclo de entrega versionado e revisável que o próprio produto.

## ## O problema é maior que a tradução

Equipes precisam preservar significados, aplicar terminologia, combinar o tom do público e atualizar o conteúdo conforme o produto evolui. Essas decisões afetam documentação, strings de interface, páginas de marketing e textos gerados por agentes da mesma forma.

Um modelo pode produzir um rascunho útil. Por si só, ele não conhece as decisões linguísticas da sua organização, registra por que uma frase mudou, valida seus formatos de arquivo ou sincroniza a próxima revisão de origem. Repetir um prompt não é um sistema de entrega.

A Glossia combina o contexto linguístico com a mecânica ao redor da geração: configuração, detecção de alterações, validação, recuperação de falhas, histórico de revisões e revisão.

## ## O conteúdo fica com o produto

O repositório permanece a autoridade para o conteúdo publicado. Arquivos de origem, configuração, traduções geradas e alterações revisáveis podem viajar pelo Git e pull requests. As equipes não precisam tornar uma interface de edição hospedada a autoridade para cada frase antes de poderem entregar um lançamento localizado.

Isso torna as alterações linguísticas visíveis ao lado da alteração do produto que as motivou. Um revisor pode inspecionar o diff, o CI pode validar a saída e o mesmo pipeline de entrega pode publicá-lo.

Leia [Localização contínua](./continuous-localization) para o modelo de entrega e [Propriedade de conteúdo](./content-ownership) para suas implicações de portabilidade.

## ## O contexto é uma entrada, não uma gaiola

A orientação de voz e a terminologia ajudam tanto humanos quanto agentes a escrever consistentemente. São decisões linguísticas reutilizáveis, não apenas uma coleção proprietária de pares de segmentos fonte-alvo.

Memórias de tradução permanecem úteis para traduções estabelecidas e conteúdo repetitivo. O ponto não é descartá-las. O ponto é evitar tornar o formato de memória de um fornecedor ou fluxo de trabalho de edição o único lugar onde o conhecimento linguístico de uma empresa pode viver.

## ## A melhoria é um ciclo

O modelo de refinamento progressivo da Glossia usa hashes de conteúdo para evitar trabalho redundante, executa validação ao redor das transformações e expõe falhas para que uma execução possa se recuperar. Correções humanas podem informar a próxima iteração em vez de desaparecer para uma geração isolada.

A análise de localização fornece outra entrada: compreender as línguas e os lugares que um público usa pode ajudar uma equipe a decidir onde investir. É evidência para priorização, não uma promessa de que uma tradução produzirá crescimento.

## ## Para quem isso serve

A Glossia é especialmente relevante quando desenvolvedores, linguistas e equipes de produtos desejam colaborar em conteúdo gerenciado por repositório e lançá-lo continuamente. Não é uma afirmação de que todas as organizações devem abandonar seu TMS existente. Uma equipe cujo requisito central é um editor baseado em navegador maduro, coordenação com agência de tradução ou uma memória estabelecida grande pode preferir outro fluxo de trabalho.

## ## Implementação inspecionável

O código da Glossia está publicamente disponível, incluindo seu aplicativo Phoenix, CLI Rust, SDK web e infraestrutura de implantação. Isso torna a mecânica do trabalho linguístico inspecionável em vez de uma caixa preta.

O Glossia segue um modelo open core. O núcleo utiliza [Apache-2.0](https://github.com/glossia/glossia/blob/main/LICENSE-APACHE), que permite uso comercial, modificação, distribuição, auto-hospedagem e serviços hospedados concorrentes conforme seus termos. O código em `ee/` é visível, mas não é código aberto. Ele possui uma [licença Enterprise](https://github.com/glossia/glossia/blob/main/ee/LICENSE.md) separada e seu uso em produção exige um acordo comercial por escrito.
