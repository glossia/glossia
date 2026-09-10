%{
  title: "Localização",
  summary:
    "Localize seu conteúdo em qualquer idioma preservando a estrutura, blocos de código e formatação. Os agentes Glossia assumem o trabalho pesado para que sua equipe possa focar na revisão.",
  order: 1,
  icon: "Idiomas",
  hero_cta_text: "Começar",
  hero_cta_url: "/signup",
  highlights: [
    %{
      title: "Consciente da estrutura",
      description:
        "Blocos de código, frontmatter e formatação permanecem intactos após a localização. Nenhuma limpeza manual é necessária.",
      icon: "código"
    },
    %{
      title: "Qualquer par de idiomas",
      description:
        "Localize entre qualquer combinação de idiomas. Adicione novos alvos editando uma única linha na sua configuração.",
      icon: "Mundo"
    },
    %{
      title: "Atualizações incrementais",
      description:
        "Apenas o conteúdo alterado é relocalizado. Arquivos de bloqueio rastreiam o que já foi processado, economizando tempo e custo.",
      icon: "Relâmpago"
    }
  ]
}
---
## Como funciona a localização

A Glossia lê o conteúdo do seu repositório junto com arquivos de lock que rastreiam o que já foi processado. Em seguida, ela integra seu contexto local (`L10N.md` arquivos na raiz ou em subdiretórios) com o contexto global (voz, terminologia e configurações de nível de conta) para construir uma visão completa de como o seu conteúdo deve soar em cada idioma-alvo. Com esse contexto montado, um fluxo de agente localiza o conteúdo alterado enquanto preserva a estrutura, blocos de código e formatação. Uma vez que a execução for concluída, os resultados são enviados de volta ao seu repositório como um pull request pronto para revisão.

## Qualidade orientada pelo contexto

Toda localização se beneficia do contexto que você fornece. Termos, notas de estilo e instruções específicas de domínio fluem para o prompt para que o agente produza uma saída que corresponda à voz do seu produto.

## Revisão com confiança

Os resultados aparecem como pull requests ou arquivos em rascunho, prontos para revisão pela sua equipe. Os revisores sinalizam problemas, atualizam arquivos de contexto e a próxima execução incorpora essas correções automaticamente.