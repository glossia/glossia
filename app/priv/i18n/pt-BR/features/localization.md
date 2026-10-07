%{
  title: "Localização",
  summary:
    "Localize seu conteúdo para qualquer idioma preservando estrutura, blocos de código e formatação. Os agentes do Glossia assumem a carga pesada, permitindo que sua equipe foque na revisão.",
  order: 1,
  icon: "Idiomas",
  hero_cta_text: "Iniciar",
  hero_cta_url: "/signup",
  highlights: [
    %{
      title: "Consciente de Estrutura",
      description:
        "Blocos de código, frontmatter e formatação sobrevivem à localização intactos. Não é necessária limpeza manual.",
      icon: "Código"
    },
    %{
      title: "Qualquer par de idiomas",
      description:
        "Localize entre qualquer combinação de idiomas. Adicione novos destinos editando uma única linha na sua configuração.",
      icon: "Globo"
    },
    %{
      title: "Atualizações incrementais",
      description:
        "Apenas conteúdo alterado é relocalizado. Os arquivos de bloqueio rastreiam o que já foi processado, economizando tempo e custos.",
      icon: "Rápido"
    }
  ]
}
---
## Como funciona a localização

O Glossia lê o conteúdo do seu repositório junto com os arquivos de lock que rastreiam o que já foi processado. Em seguida, ele mescla seu contexto local (arquivos `L10N.md` na raiz ou em subdiretórios) com o contexto global (voz, glossário e configurações em nível de conta) para construir uma visão completa de como seu conteúdo deve soar em cada idioma de destino. Com esse contexto montado, um fluxo de trabalho autônomo localiza o conteúdo alterado, preservando estrutura, blocos de código e formatação. Assim que a execução termina, os resultados são enviados de volta ao seu repositório como um pull request pronto para revisão.

## Qualidade impulsionada pelo contexto

Toda localização se beneficia do contexto que você fornece. O glossário, notas de estilo e instruções específicas do domínio são inseridos no prompt para que o agente produza uma saída que corresponda à voz do seu produto.

## Revisão com confiança

As saídas chegam como pull requests ou arquivos em rascunho, prontos para a sua equipe revisar. Os revisores sinalizam problemas, atualizam arquivos de contexto e a próxima execução incorpora essas correções automaticamente.