%{
  title: "Revisão de conteúdo",
  summary:
    "Melhore seu conteúdo existente no local. A Glossia analisa arquivos-fonte quanto à clareza, precisão e tom usando o contexto que você fornece, então produz versões revisadas prontas para revisão.",
  order: 2,
  icon: "pencil",
  hero_cta_text: "Começar",
  hero_cta_url: "/signup",
  highlights: [
    %{
      title: "Tom e clareza",
      description:
        "Agentes revisam sua redação quanto à legibilidade, jargão e consistência com a voz da sua marca.",
      icon: "message-circle"
    },
    %{
      title: "Não destrutivo",
      description:
        "O conteúdo revisado pode substituir o original ou ser escrito em um caminho separado. Você sempre controla o destino da saída.",
      icon: "shield-check"
    },
    %{
      title: "Ciclo de feedback",
      description:
        "Os revisores corrigem a saída, atualizam o contexto e, em cada ciclo, estreitam a lacuna entre o rascunho e o final.",
      icon: "refresh-cw"
    }
  ]
}
---
## Como funciona a revisão

O agente lê seus arquivos de origem e o grafo de contexto, mesclando instruções locais (arquivos `L10N.md` na raiz ou em subdiretórios) com contexto remoto (suas configurações de voz, terminologia e estilo em nível de conta). Com toda a imagem montada, ele reescreve o conteúdo para clareza, precisão e tom, em seguida entrega a versão revisada pronta para revisão.

## Grafo de contexto

O contexto no Glossia é um grafo que abrange sua conta e seu repositório. Configurações em nível de conta, como voz e terminologia, fornecem uma base global, enquanto arquivos `L10N.md` colocados ao lado do seu conteúdo adicionam regras locais. O agente resolve este grafo a cada execução, para que suas instruções permaneçam consistentes entre os arquivos sem se repetir. As revisões são incrementais graças aos arquivos de bloqueio que acompanham o que já foi processado, de modo que apenas o conteúdo alterado ou novo seja reavaliado.

## Refinamento progressivo

Cada ciclo de revisão torna a saída melhor. As correções alimentam de volta os arquivos de contexto, para que erros repetidos desapareçam e a saída converja para o padrão da sua equipe ao longo do tempo.