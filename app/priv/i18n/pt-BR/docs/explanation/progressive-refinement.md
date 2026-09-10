%{
  title: "Refinamento progressivo",
  summary:
    "Por que a qualidade do conteúdo converge ao longo do tempo, e não em uma única passada.",
  category: "explicação",
  order: 1
}
---
Primeiras versões de [modelos de linguagem de grande porte](https://en.wikipedia.org/wiki/Large_language_model) São estruturalmente corretas, mas podem perder nuances, tom ou terminologia específica do domínio. Isso é intencional. A Glossia trata a geração de conteúdo da mesma forma que as equipes de software tratam o código: ela lança uma versão funcional, revisa e melhora iterativamente.

## O ciclo de refinamento

1. **Rascunho**: A Glossia gera uma primeira versão estruturalmente válida com base nos seus arquivos de origem e o contexto em `L10N.md`.
2. **Revisão**: Sua equipe levanta problemas por meio de pull requests e diffs, o mesmo fluxo de trabalho que você já usa para código.
3. **Refinar**: Arquivos de contexto atualizados, correções de terminologia e feedback de revisão alimentam a próxima execução.
4. **Convergir**: Cada ciclo encurta a distância para a qualidade de produção. O sistema aprende a voz do seu produto através do contexto que você fornece.

## Por que isso funciona

A ideia central é que o contexto se acumula. Todo comentário de revisão que leva a uma atualização `L10N.md` ou uma entrada de terminologia corrigida melhora todas as execuções futuras, não apenas o arquivo que acionou a revisão.

Isso segue o mesmo princípio por trás do Kaizen na manufatura e da aproximação sucessiva na engenharia: comece com uma base boa o suficiente e melhore-a sistematicamente com o julgamento humano no loop.

## Implicações práticas

- Não espere perfeição na primeira execução. Planeje uma ou duas rodadas de revisão.
- Invista tempo em escrever arquivos de contexto claros. Eles são a melhoria de maior alavancagem que você pode realizar.
- Utilize a sessão de tradução do servidor para rastrear quais arquivos foram traduzidos,
  ignorados, ou falhados.