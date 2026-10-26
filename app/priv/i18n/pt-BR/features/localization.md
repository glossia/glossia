%{
  title: "Localização",
  summary:
    "Localize seu conteúdo em qualquer idioma enquanto preserva a estrutura, blocos de código e formatação. Os agentes da Glossia fazem a parte pesada para que sua equipe possa focar na revisão.",
  order: 1,
  icon: "Idiomas",
  hero_cta_text: "Começar agora",
  hero_cta_url: "/signup",
  highlights: [
    %{
      title: "Consciente da estrutura",
      description:
        "Blocos de código, frontmatter e formatação sobrevivem à localização intactos. Não é necessário limpeza manual.",
      icon: "Código"
    },
    %{
      title: "Qualquer par de idiomas",
      description:
        "Localize entre qualquer combinação de idiomas. Adicione novos alvos editando uma linha única em seu config.",
      icon: "Mundo"
    },
    %{
      title: "Atualizações incrementais",
      description:
        "Apenas o conteúdo alterado é relocalizado. Arquivos de bloqueio rastreiam o que já foi processado, economizando tempo e custo.",
      icon: "Rápido"
    }
  ]
}
---

## ## Como funciona a localização

Glossia lê o conteúdo de seu repositório junto com os arquivos de bloqueio que rastreiam o que já foi processado. Em seguida, ele mescla seu contexto local (`L10N.md` arquivos na raiz ou em subdiretórios) com o contexto global (voz, glossário e configurações de nível de conta) para criar uma imagem completa de como seu conteúdo deve soar em cada idioma destino. Com esse contexto montado, um fluxo de trabalho autônomo localiza o conteúdo alterado, preservando a estrutura, os blocos de código e a formatação. Após a conclusão da execução, os resultados são enviados de volta ao seu repositório como um pull request pronto para revisão.

## ## Qualidade orientada por contexto

Cada localização se beneficia do contexto que você fornece. Glossário, notas de estilo e instruções específicas de domínio fluem todas para o prompt para que o agente produza uma saída que corresponda à voz do seu produto.

## ## Revise com confiança

As saídas são entregues como pull requests ou arquivos em rascunho, prontos para sua equipe revisar. Revisores sinalizam problemas, atualizam os arquivos de contexto e a próxima execução incorpora automaticamente essas correções.
