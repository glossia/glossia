%{
  title: "Localização",
  summary: "Localize seu conteúdo para qualquer idioma, preservando a estrutura, os blocos de código e a formatação. Os agentes do Glossia executam o trabalho mais complexo para que sua equipe possa se concentrar na revisão.",
  order: 1,
  icon: "languages",
  hero_cta_text: "Começar",
  hero_cta_url: "/signup",
  highlights: [
    %{title: "Reconhecimento de estrutura", description: "Blocos de código, frontmatter e formatação permanecem intactos após a localização. Nenhum ajuste manual é necessário.", icon: "code"},
    %{title: "Qualquer par de idiomas", description: "Localize entre qualquer combinação de idiomas. Adicione novos idiomas de destino editando uma única linha na sua configuração.", icon: "globe"},
    %{title: "Atualizações incrementais", description: "Apenas o conteúdo alterado é localizado novamente. Os lockfiles registram o que já foi processado, reduzindo tempo e custos.", icon: "zap"}
  ]
}
---
## Como funciona a localização

A Glossia lê o conteúdo do seu repositório junto com os lockfiles que registram o que já foi processado. Em seguida, combina seu contexto local (arquivos `GLOSSIA.md` na raiz ou em subdiretórios) com o contexto global (voz, terminologia e configurações no nível da conta) para formar uma visão completa de como seu conteúdo deve soar em cada idioma de destino. Com esse contexto consolidado, um fluxo de trabalho agêntico localiza o conteúdo alterado, preservando a estrutura, os blocos de código e a formatação. Após a conclusão da execução, os resultados são enviados de volta ao seu repositório como uma pull request pronta para revisão.

## Qualidade orientada pelo contexto

Toda localização se beneficia do contexto fornecido. A terminologia, as orientações de estilo e as instruções específicas do domínio são incorporadas ao prompt para que o agente produza um conteúdo alinhado à voz do seu produto.

## Revise com confiança

Os resultados são disponibilizados como pull requests ou arquivos de rascunho, prontos para a revisão da sua equipe. Os revisores sinalizam problemas, atualizam os arquivos de contexto e a próxima execução incorpora essas correções automaticamente.