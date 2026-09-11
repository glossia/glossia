%{
  title: "Refinamento progressivo",
  summary:
    "Por que a qualidade do conteúdo converge ao longo do tempo, não em uma única passada.",
  category: "explicação",
  order: 1
}
---
Primeiros rascunhos de [grandes modelos de linguagem](https://en.wikipedia.org/wiki/Large_language_model) são estruturalmente corretos, mas podem perder nuances, tom ou formulações específicas do domínio. Isso é por design. O Glossia trata a geração de conteúdo da mesma forma que equipes de software tratam o código: envie uma versão funcional, revise-a e aprimore-a iterativamente.

## O ciclo de refinamento

1. **Rascunho**: O Glossia gera uma primeira versão estruturalmente válida com base nos seus arquivos de origem e no contexto em `L10N.md`.
2. **Revisao**: Sua equipe sinaliza problemas por meio de pull requests e diffs, o mesmo fluxo de trabalho que você já usa para código.
3. **Refinar**: Arquivos de contexto atualizados, correções de terminologia e feedback de revisões alimentam a próxima execução.
4. **Convergir**: Cada ciclo reduz a distância para a qualidade de produção. O sistema aprende a voz do seu produto através do contexto que você fornece.

## Por que isso funciona

A ideia principal é que o contexto acumula. Cada comentário de revisão que resulta em um termo atualizado `L10N.md` ou uma entrada de terminologia corrigida melhora todas as execuções futuras, não apenas o arquivo que disparou a revisão.

Isso segue o mesmo princípio por trás do Kaizen na manufatura e da aproximação sucessiva na engenharia: comece com uma base inicial satisfatória e melhore-a sistematicamente com o julgamento humano no processo.

## Implicações práticas

- Não espere perfeição na primeira execução. Planeje um ou dois ciclos de revisão.
- Invista tempo na criação de arquivos de contexto claros. Eles são a melhoria de maior alavancagem que você pode fazer.
- Use a sessão de tradução do servidor para rastrear quais arquivos foram traduzidos,
  pulados ou falhados.