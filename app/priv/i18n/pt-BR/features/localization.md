%{
  title: "Localização",
  summary:
    "Localize seu conteúdo em qualquer idioma, preservando a estrutura, blocos de código e formatação. Os agentes do Glossia cuidam da parte pesada para que sua equipe possa focar na revisão.",
  order: 1,
  icon: "idiomas",
  hero_cta_text: "Iniciar",
  hero_cta_url: "/signup",
  highlights: [
    %{
      title: "Sensível à estrutura",
      description:
        "Blocos de código, frontmatter e formatação sobrevivem à localização intactos. Nenhuma limpeza manual é necessária.",
      icon: "código"
    },
    %{
      title: "Qualquer par de idiomas",
      description:
        "Localize entre qualquer combinação de idiomas. Adicione novos alvos editando uma única linha em sua configuração.",
      icon: "mundo"
    },
    %{
      title: "Atualizações incrementais",
      description:
        "Apenas o conteúdo alterado é relocalizado. Arquivos de bloqueio rastreiam o que já foi processado, economizando tempo e custo.",
      icon: "relâmpago"
    }
  ]
}
---

## Como funciona a localização

O Glossia lê o conteúdo do seu repositório junto com arquivos de bloqueio que rastreiam o que já foi processado. Em seguida, combina o contexto local (`L10N.md` arquivos na raiz ou em subdiretórios) com o contexto global (voz, glosário e configurações de nível de conta) para construir uma visão completa de como seu conteúdo deve soar em cada idioma de destino. Com esse contexto montado, um fluxo de trabalho agêntico localiza o conteúdo alterado enquanto preserva a estrutura, blocos de código e formatação. Assim que a execução termina, os resultados são enviados de volta ao seu repositório como um pull request pronto para revisão.

## Qualidade orientada por contexto

Cada localização se beneficia do contexto que você fornece. O glosário, notas de estilo e instruções específicas de domínio alimentam o prompt para que o agente produza uma saída que corresponda à voz do seu produto.

## Revisar com confiança

As saídas são entregues como pull requests ou arquivos em rascunho, prontos para revisão pela sua equipe. Os revisores apontam problemas, atualizam os arquivos de contexto e a próxima execução incorpora essas correções automaticamente.
