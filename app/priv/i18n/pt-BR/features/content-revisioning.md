%{
  title: "Revisão de conteúdo",
  summary:
    "Melhore seu conteúdo existente no local. O Glossia revisa arquivos de origem quanto à clareza, precisão e tom usando o contexto que você fornece, em seguida produz versões revisadas prontas para revisão.",
  order: 2,
  icon: "pencil",
  hero_cta_text: "Começar",
  hero_cta_url: "/signup",
  highlights: [
    %{
      title: "Tom e clareza",
      description:
        "Os agentes revisam seu texto quanto à legibilidade, jargão e consistência com a sua voz de marca.",
      icon: "message-circle"
    },
    %{
      title: "Não destrutiva",
      description:
        "O conteúdo revisado pode sobrescrever o original ou ser escrito em um caminho separado. Você sempre controla o destino de saída.",
      icon: "shield-check"
    },
    %{
      title: "Ciclo de feedback",
      description:
        "Os revisores corrigem a saída, atualizam o contexto e, a cada ciclo, reduzem a distância entre o rascunho e o final.",
      icon: "refresh-cw"
    }
  ]
}
---
## Como funciona a revisão

O agente lê seus arquivos de origem e o grafo de contexto, mesclando instruções locais (`L10N.md` na raiz ou em subdiretórios) com contexto remoto (sua voz, terminologia e configurações de estilo em nível de conta). Com o panorama completo montado, ele reescreve o conteúdo para clareza, precisão e tom, e então exibe a versão revisada pronta para revisão.

## Grafo de contexto

O contexto no Glossia é um grafo que abrange sua conta e seu repositório. Configurações em nível de conta, como voz e terminologia, fornecem uma base global, enquanto arquivos `L10N.md` colocados ao lado do seu conteúdo adicionam sobrescritas locais. O agente resolve este grafo a cada execução, para que suas instruções fiquem consistentes entre os arquivos sem que você precise se repetir. As revisões são incrementais graças aos arquivos de bloqueio que rastreiam o que já foi processado, para que apenas o conteúdo alterado ou novo seja revisado novamente.

## Refinamento progressivo

Cada ciclo de revisão melhora o resultado. Correções alimentam os arquivos de contexto, para que erros repetidos desapareçam e o resultado converja para o padrão da sua equipe com o tempo.