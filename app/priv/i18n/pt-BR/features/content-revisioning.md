%{
  title: "Revisão de Conteúdo",
  summary:
    "Melhore seu conteúdo existente no local. O Glossia revisa arquivos fonte quanto à clareza, precisão e tom, usando o contexto que você fornece, e produz versões revisadas prontas para revisão.",
  order: 2,
  icon: "pencil",
  hero_cta_text: "Começar agora",
  hero_cta_url: "/signup",
  highlights: [
    %{
      title: "Tom e Clareza",
      description:
        "Agentes revisam sua redação quanto à legibilidade, jargão e consistência com a voz da sua marca.",
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
        "Os revisores corrigem a saída, atualizam o contexto e, a cada ciclo, reduzem a diferença entre o rascunho e o final.",
      icon: "refresh-cw"
    }
  ]
}
---
## Como funciona a revisão

O agente lê seus arquivos de origem e o grafo de contexto, unindo instruções locais (`L10N.md` na raiz ou em subdiretórios) com o contexto remoto (suas configurações de voz, terminologia e estilo de nível de conta). Com a visão completa reunida, ele reescreve o conteúdo para clareza, precisão e tom, e em seguida, gera a versão revisada pronta para revisão.

## Grafo de contexto

O contexto no Glossia é um grafo que abrange sua conta e seu repositório. Configurações em nível de conta, como voz e terminologia, fornecem uma base global, enquanto os arquivos `L10N.md` posicionados junto ao seu conteúdo adicionam exceções locais. O agente resolve esse grafo a cada execução, para que suas instruções permaneçam consistentes entre os arquivos sem precisar repetir-se. As revisões são incrementais graças aos arquivos de bloqueio que rastreiam o que já foi processado, de modo que apenas o conteúdo alterado ou novo seja revisitado.

## Refinamento progressivo

Cada ciclo de revisão aprimora a saída. As correções alimentam os arquivos de contexto, para que os erros repetidos desapareçam e a saída converja para o padrão da sua equipe com o tempo.