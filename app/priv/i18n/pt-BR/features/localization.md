%{
  title: "Localização",
  summary:
    "Localize seu conteúdo para qualquer idioma preservando estrutura, blocos de código e formatação. Os agentes do Glossia realizam todo o trabalho pesado para que sua equipe possa focar na revisão.",
  order: 1,
  icon: "Idiomas",
  hero_cta_text: "Começar",
  hero_cta_url: "/signup",
  highlights: [
    %{
      title: "Consciente da estrutura",
      description:
        "Blocos de código, frontmatter e formatação sobrevivem à localização intactos. Não é necessária limpeza manual.",
      icon: "Código"
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
      icon: "Zap"
    }
  ]
}
---
## Como funciona a localização

O Glossia lê o conteúdo do seu repositório junto com os arquivos de bloqueio que rastreiam o que já foi processado. Ele então mescla o contexto local (arquivos `L10N.md` na raiz ou em subdiretórios) com o contexto global (voz, terminologia e configurações de nível de conta) para criar uma visão completa de como seu conteúdo deve soar em cada idioma de destino. Com esse contexto montado, um fluxo de trabalho autônomo localiza o conteúdo alterado, preservando estrutura, blocos de código e formatação. Uma vez concluída a execução, os resultados são enviados de volta ao seu repositório como um pull request pronto para revisão.

## Qualidade orientada por contexto

Cada localização se beneficia do contexto que você fornece. A terminologia, notas de estilo e instruções específicas do domínio fluem para o prompt, de modo que o agente produza uma saída que corresponde à voz do seu produto.

## Revisão com confiança

As saídas são geradas como pull requests ou arquivos de rascunho, prontos para a sua equipe revisar. Os revisores indicam problemas, atualizam arquivos de contexto e a próxima execução incorpora essas correções automaticamente.