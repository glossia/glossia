%{
  title: "Refinamento progressivo",
  summary:
    "Por que a qualidade do conteúdo converge ao longo do tempo, e não em uma única passada.",
  category: "explicação",
  order: 1
}
---
Primeiros rascunhos de [modelos de linguagem grandes](https://en.wikipedia.org/wiki/Large_language_model) são estruturalmente corretos, mas podem perder nuances, tom ou formulações específicas do domínio. Isso é intencional. O Glossia trata a geração de conteúdo da mesma maneira que equipes de software tratam o código: libere uma versão funcional, revise-a e melhore-a iterativamente.

## O ciclo de refinamento

1. **Rascunho**: O Glossia gera uma primeira versão estruturalmente válida com base nos seus arquivos de origem e no contexto em `L10N.md`.
2. **Revisão**: Sua equipe sinaliza problemas por meio de pull requests e diffs, o mesmo fluxo de trabalho que você já usa para código.
3. **Refinar**: Arquivos de contexto atualizados, correções de terminologia e feedback da revisão alimentam a próxima execução.
4. **Convergir**: Cada ciclo reduz a distância para a qualidade de produção. O sistema aprende a voz do seu produto através do contexto que você fornece.

## Por que isso funciona

O insight principal é que o contexto se acumula. Cada comentário de revisão que leva a uma atualização `L10N.md` ou uma entrada terminológica corrigida melhora todas as execuções futuras, não apenas o arquivo que acionou a revisão.

Isso segue o mesmo princípio por trás do Kaizen na manufatura e da aproximação sucessiva na engenharia: comece com uma base boa o suficiente e melhore-a sistematicamente com o julgamento humano no loop.

## Implicações práticas

- Não espere perfeição na primeira execução. Planeje um ou dois ciclos de revisão.
- Invista tempo na criação de arquivos de contexto claros. Eles são a melhoria de maior alavancagem que você pode fazer.
- Use a sessão de tradução do servidor para acompanhar quais arquivos foram traduzidos,
  pulados ou que falharam.