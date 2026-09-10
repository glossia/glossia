%{
  title: "Revisão de conteúdo",
  summary:
    "Melhore seu conteúdo existente no local. A Glossia revisa arquivos de origem quanto à clareza, precisão e tom usando o contexto que você fornece, em seguida produz versões revisadas prontas para revisão.",
  order: 2,
  icon: "pencil",
  hero_cta_text: "Começar",
  hero_cta_url: "/signup",
  highlights: [
    %{
      title: "Tom e clareza",
      description:
        "Os agentes revisam seu texto quanto à legibilidade, jargões e consistência com a voz da sua marca.",
      icon: "message-circle"
    },
    %{
      title: "Não destrutivo",
      description:
        "O conteúdo revisado pode sobrescrever o original ou escrever em um caminho separado. Você sempre controla o destino de saída.",
      icon: "shield-check"
    },
    %{
      title: "Ciclo de feedback",
      description:
        "Examinadores corrigem a saída, atualizam o contexto e cada ciclo reduz a diferença entre o rascunho e o final.",
      icon: "refresh-cw"
    }
  ]
}
---
## Como funciona a revisão

O agente lê seus arquivos fonte e o grafo de contexto, integrando instruções locais (arquivos `L10N.md` na raiz ou em subdiretórios) com o contexto remoto (configurações de voz, terminologia e estilo em nível de conta). Com o panorama completo montado, ele reescreve o conteúdo para clareza, precisão e tom, e em seguida gera a versão revisada, pronta para revisão.

## Grafo de contexto

O contexto no Glossia é um grafo que abrange sua conta e seu repositório. Configurações em nível de conta, como voz e terminologia, fornecem uma linha base global, enquanto os arquivos `L10N.md` posicionados ao lado do seu conteúdo adicionam sobrescritas locais. O agente resolve este grafo em cada execução, de modo que suas instruções permaneçam consistentes entre os arquivos sem que você precise se repetir. As revisões são incrementais graças aos arquivos de bloqueio que rastreiam o que já foi processado, de modo que apenas conteúdo alterado ou novo é revisitado.

## Refinamento progressivo

Cada ciclo de revisão torna a saída melhor. As correções retroalimentam os arquivos de contexto, de modo que erros repetidos desaparecem e a saída converge para o padrão da sua equipe ao longo do tempo.