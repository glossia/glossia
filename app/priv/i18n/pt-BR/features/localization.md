%{
  title: "Localização",
  summary:
    "Localize seu conteúdo em qualquer idioma enquanto preserva estrutura, blocos de código e formatação. Os agentes do Glossia fazem o trabalho pesado enquanto sua equipe se concentra na revisão.",
  order: 1,
  icon: "idiomas",
  hero_cta_text: "Começar",
  hero_cta_url: "/cadastro",
  highlights: [
    %{
      title: "Estrutura-preservante",
      description:
        "Blocos de código, frontmatter e formatação permanecem intactos após a localização. Nenhuma limpeza manual é necessária.",
      icon: "código"
    },
    %{
      title: "Qualquer par de idiomas",
      description:
        "Localize entre qualquer combinação de idiomas. Adicione novos alvos editando uma única linha em sua configuração.",
      icon: "globo"
    },
    %{
      title: "Atualizações incrementais",
      description:
        "Apenas o conteúdo alterado é relocalizado. Os arquivos de bloqueio rastreiam o que já foi processado, economizando tempo e custo.",
      icon: "zap"
    }
  ]
}
---
## Como a localização funciona

O Glossia lê o conteúdo do seu repositório junto com os lockfiles que rastreiam o que já foi processado. Em seguida, mistura seu contexto local (`L10N.md` arquivos na raiz ou em subdiretórios) com o contexto global (voz, terminologia e configurações de conta) para construir uma visão completa de como seu conteúdo deve soar em cada idioma de destino. Com esse contexto montado, um fluxo de trabalho autônomo localiza o conteúdo alterado enquanto preserva a estrutura, blocos de código e formatação. Uma vez que o التنفيذ é concluído, os resultados são enviados de volta ao seu repositório como um pull request pronto para revisão.

## Qualidade orientada por contexto

Toda localização se beneficia do contexto que você fornece. Notas de terminologia, estilo e instruções específicas do domínio fluem para o prompt, de modo que o agente produza uma saída que corresponda à voz do seu produto.

## Revisão com confiança

Os resultados são entregues como pull requests ou arquivos em rascunho, prontos para sua equipe revisar. Os revisores marcam problemas, atualizam arquivos de contexto e a próxima execução incorpora essas correções automaticamente.