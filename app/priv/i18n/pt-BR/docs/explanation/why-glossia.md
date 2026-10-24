%{
  title: "Por que Glossia",
  summary:
    "Um sistema operacional de idioma que mantém conteúdo, contexto e revisão alinhados com a entrega contínua.",
  category: "explicação",
  section: "translation",
  order: 1
}
---

Um produto pode ser lançado continuamente enquanto suas traduções permanecem presas em um ciclo de lançamento separado. O conteúdo de origem muda no Git, alguém exporta para um sistema de tradução, os editores trabalham lá e alguém importa o resultado. O produto e suas versões linguísticas se afastam.

Glossia é um sistema operacional de linguagem construído em torno de uma premissa diferente: o trabalho com linguagem deve seguir o mesmo loop de entrega versionado e revisável do próprio produto.

## ## O problema é maior do que a tradução

Equipes precisam preservar o significado, aplicar terminologia, adaptar-se ao tom da audiência e atualizar o conteúdo conforme o produto evolui. Essas decisões afetam documentação, strings de UI, páginas de marketing e textos gerados por agentes da mesma forma.

Um modelo pode produzir um rascunho útil. Ele não sabe, por si só, das decisões linguísticas da sua organização, registra por que uma frase mudou, valida seus formatos de arquivo, ou sincroniza a próxima revisão da fonte. Repetir um prompt não é um sistema de entrega.

Glossia combina contexto linguístico com a mecânica em torno da geração: configuração, detecção de mudanças, validação, recuperação de falhas, histórico de revisões e revisão.

## ## O conteúdo fica com o produto

O repositório permanece a autoridade para o conteúdo publicado. Arquivos de origem, configuração, traduções geradas e alterações revisáveis podem viajar pelo Git e pull requests. Equipes não precisam tornar uma interface de edição hospedada a autoridade para cada frase antes de entregar uma versão localizada.

Isso torna as alterações linguísticas visíveis ao lado da alteração de produto que as motivou. Um revisor pode inspecionar o diff, o CI pode validar a saída, e o mesmo pipeline de entrega pode publicá-la.

Leia [Localização contínua](./continuous-localization) para o modelo de entrega e [Propriedade do conteúdo](./content-ownership) para suas implicações de portabilidade.

## ## O contexto é uma entrada, não uma gaiola

Orientação de voz e terminologia ajudam humanos e agentes a escrever consistentemente. São decisões linguísticas reutilizáveis, não apenas uma coleção proprietária de pares de segmentos de fonte-destino.

Memórias de tradução continuam úteis para traduções estabelecidas e conteúdo repetitivo. O ponto não é descartá-las. O ponto é evitar tornar o formato de memória de um fornecedor ou fluxo de trabalho de edição o único lugar onde o conhecimento linguístico de uma empresa pode viver.

## ## Melhoria é um ciclo

O modelo de refinamento progressivo do Glossia usa hashes de conteúdo para evitar trabalho redundante, executa validação em torno das transformações e expõe falhas para que uma execução possa se recuperar. Correções humanas podem informar a próxima iteração em vez de desaparecerem em uma geração isolada.

Análise de localização fornece outra entrada: entender as línguas e lugares que um público usa pode ajudar uma equipe a decidir onde investir. É evidência para priorização, não uma promessa de que uma tradução produzirá crescimento.

## ## A quem isso se destina

Glossia é especialmente relevante quando desenvolvedores, linguistas e equipes de produto querem colaborar em conteúdo gerenciado por repositório e lançá-lo continuamente. Não é um argumento de que toda organização deve abandonar seu TMS existente. Uma equipe cuja exigência central seja um editor baseado em navegador maduro, coordenação tipo agência de tradução, ou uma memória estabelecida grande pode preferir outro fluxo de trabalho.

## ## Implementação inspecionável

O código do Glossia está publicamente disponível, incluindo sua aplicação Phoenix, CLI em Rust, SDK web e infraestrutura de implantação. Isso torna as mecânicas do trabalho com linguagem inspecionáveis ao invés de uma caixa preta.

O Glossia segue um modelo open core. O núcleo utiliza [Apache-2.0](https://github.com/glossia/glossia/blob/main/LICENSE-APACHE), que permite uso comercial, modificação, distribuição, auto-hospedagem e serviços hospedados concorrentes conforme seus termos. O código em `ee/` é visível, mas não é código aberto. Ele possui uma [licença Enterprise](https://github.com/glossia/glossia/blob/main/ee/LICENSE.md) separada e seu uso em produção exige um acordo comercial por escrito.
