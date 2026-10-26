%{
  title: "Refinamento progressivo",
  summary: "Por que a qualidade do conteúdo converge ao longo do tempo, não em uma única etapa.",
  category: "explicação",
  section: "translation",
  order: 1
}
---

Os primeiros rascunhos provenientes de [modelos de linguagem grandes](https://en.wikipedia.org/wiki/Large_language_model) são estruturalmente corretos, mas podem perder nuances, tom ou formulação específica do domínio. Isso é por design. A Glossia trata a geração de conteúdo da mesma forma que as equipes de software tratam o código: libere uma versão funcional, revise-o e melhore-o iterativamente.

## O ciclo de refinamento

1. **Rascunho**: A Glossia gera um primeiro passo estruturalmente válido com base nos seus arquivos de origem e no contexto em `L10N.md`.
2. **Revisão**: Sua equipe identifica questões por meio de pull requests e diffs, o mesmo fluxo que você já usa para código.
3. **Refinamento**: Arquivos de contexto atualizados, correções do glossário e feedback da revisão alimentam a próxima execução.
4. **Convergência**: Cada ciclo reduz a distância para a qualidade de produção. O sistema aprende a voz do seu produto por meio do contexto que você fornece.

## Por que isso funciona

A percepção chave é que o contexto se acumula. Todo comentário de revisão que leva a um `L10N.md` ou a uma entrada de glossário corrigida melhora todas as execuções futuras, não apenas o arquivo que disparou a revisão.

Isso segue o mesmo princípio por trás do Kaizen na fabricação e da aproximação sucessiva na engenharia: comece com uma linha de base aceitável e melhore-a sistematicamente com julgamento humano no loop.

## Implicações práticas

- Não espere perfeição na primeira execução. Planeje um ou dois ciclos de revisão.
- Invista tempo na escrita de arquivos de contexto claros. Eles são a melhoria de maior alavanca que você pode fazer.
- Use a sessão de tradução na Glossia para rastrear quais arquivos foram traduzidos, ignorados ou falharam.
