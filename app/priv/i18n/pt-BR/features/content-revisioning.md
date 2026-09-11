%{
  title: "Revisão de conteúdo",
  summary:
    "Melhore seu conteúdo existente no local. O Glossia revê arquivos de origem quanto à clareza, precisão e tom, utilizando o contexto que você fornece, e então produz versões revisadas prontas para revisão.",
  order: 2,
  icon: "pencil",
  hero_cta_text: "Começar",
  hero_cta_url: "/signup",
  highlights: [
    %{
      title: "Tom e clareza",
      description:
        "Agentes revisam seu texto quanto à legibilidade, jargão e consistência com sua voz de marca.",
      icon: "message-circle"
    },
    %{
      title: "Não destrutivo",
      description:
        "O conteúdo revisado pode sobrescrever o original ou ser escrito em um caminho separado. Você sempre controla o destino da saída.",
      icon: "shield-check"
    },
    %{
      title: "Ciclo de feedback",
      description:
        "Revisores corrigem a saída, atualizam o contexto e cada ciclo reduz a lacuna entre o rascunho e a versão final.",
      icon: "refresh-cw"
    }
  ]
}
---
## Como a revisão funciona

O agente lê seus arquivos de origem e o grafo de contexto, fundindo instruções locais (arquivos `L10N.md` na raiz ou em subdiretórios) com o contexto remoto (sua voz em nível de conta, terminologia e configurações de estilo). Com a visão completa montada, ele reescreve o conteúdo para clareza, precisão e tom, e emite a versão revisada pronta para revisão.

## Grafo de contexto

O contexto no Glossia é um grafo que abrange sua conta e seu repositório. Configurações em nível de conta, como voz e terminologia, fornecem uma base global, enquanto arquivos `L10N.md` posicionados ao lado do seu conteúdo adicionam sobrescritas locais. O agente resolve este grafo em cada execução, para que suas instruções permaneçam consistentes entre os arquivos sem a necessidade de repetição. As revisões são incrementais graças a arquivos de bloqueio que rastreiam o que já foi processado, de modo que apenas o conteúdo alterado ou novo seja reexaminado.

## Refinamento progressivo

Cada ciclo de revisão torna a saída melhor. As correções são retroalimentadas nos arquivos de contexto, de modo que os erros repetidos desaparecem e a saída converge para o padrão da sua equipe ao longo do tempo.