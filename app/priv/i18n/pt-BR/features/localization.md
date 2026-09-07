%{
  title: "Localização",
  summary:
    "Localize seu conteúdo em qualquer idioma mantendo estrutura, blocos de código e formatação intactos. Os agentes do Glossia lidam com o trabalho pesado para que sua equipe possa focar na revisão.",
  order: 1,
  icon: "Idiomas",
  hero_cta_text: "Começar",
  hero_cta_url: "/signup",
  highlights: [
    %{
      title: "Consciente de estrutura",
      description:
        "Blocos de código, frontmatter e formatação sobrevivem à localização intactos. Nenhuma limpeza manual é necessária.",
      icon: "código"
    },
    %{
      title: "Qualquer par de idiomas",
      description:
        "Localize entre qualquer combinação de idiomas. Adicione novos alvos editando uma única linha na sua configuração.",
      icon: "globe"
    },
    %{
      title: "Atualizações incrementais",
      description:
        "Apenas o conteúdo alterado é relocalizado. Os arquivos de bloqueio rastreiam o que já foi processado, economizando tempo e custo.",
      icon: "Relâmpago"
    }
  ]
}
---
## Como funciona a localização

O Glossia lê o conteúdo do seu repositório junto com os arquivos de bloqueio que rastreiam o que já foi processado. Em seguida, ele funde seu contexto local (`GLOSSIA.md` nas raízes ou em subdiretórios) com o contexto global (voz, terminologia e configurações de nível de conta) para construir uma visão completa de como seu conteúdo deve soar em cada idioma de destino. Com esse contexto montado, um fluxo de trabalho autônomo localiza o conteúdo alterado enquanto preserva a estrutura, blocos de código e formatação. Assim que a execução termina, os resultados são enviados de volta ao seu repositório como um pull request pronto para revisão.

## Qualidade orientada pelo contexto

Toda localização se beneficia do contexto que você fornece. A terminologia, observações de estilo e instruções específicas do domínio fluem para o prompt para que o agente produza uma saída que corresponda à voz do seu produto.

## Revisão com confiança

As saídas são criadas como pull requests ou arquivos de rascunho, prontos para revisão pela sua equipe. Os revisores sinalizam problemas, atualizam os arquivos de contexto e a próxima execução incorpora essas correções automaticamente.