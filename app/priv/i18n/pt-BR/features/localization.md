%{
  title: "Localização",
  summary:
    "Localize seu conteúdo para qualquer idioma, preservando estrutura, blocos de código e formatação. Os agentes do Glossia assumem o trabalho pesado para que sua equipe possa se concentrar na revisão.",
  order: 1,
  icon: "idiomas",
  hero_cta_text: "Começar agora",
  hero_cta_url: "/signup",
  highlights: [
    %{
      title: "Consciente da estrutura",
      description:
        "Blocos de código, frontmatter e formatação permanecem íntegros após a localização. Nenhuma limpeza manual é necessária.",
      icon: "código"
    },
    %{
      title: "Qualquer par de idiomas",
      description:
        "Localize entre qualquer combinação de idiomas. Adicione novos alvos editando uma única linha na sua configuração.",
      icon: "globo"
    },
    %{
      title: "Atualizações incrementais",
      description:
        "Apenas o conteúdo alterado é relocalizado. Os arquivos de bloqueio rastreiam o que já foi processado, economizando tempo e custos.",
      icon: "relâmpago"
    }
  ]
}
---
## Como a localização funciona

Glossia lê o conteúdo do seu repositório juntamente com os arquivos de bloqueio que rastreiam o que já foi processado. Em seguida, ele mescla seu contexto local (`L10N.md` arquivos na raiz ou em subdiretórios) com o contexto global (voz, terminologia e configurações de nível de conta) para criar uma visão completa de como seu conteúdo deve soar em cada idioma de destino. Com esse contexto montado, um fluxo de trabalho autônomo localiza o conteúdo alterado enquanto preserva a estrutura, blocos de código e formatação. Assim que a execução é concluída, os resultados são enviados de volta ao seu repositório como um pull request pronto para revisão.

## Qualidade impulsionada pelo contexto

Cada localização se beneficia do contexto que você fornece. Terminologia, notas de estilo e instruções específicas do domínio fluem para o prompt para que o agente produza uma saída que corresponda à voz do seu produto.

## Revisão com confiança

As saídas são enviadas como pull requests ou arquivos de rascunho, prontos para sua equipe revisar. Os revisores marcam problemas, atualizam arquivos de contexto e a próxima execução incorpora essas correções automaticamente.