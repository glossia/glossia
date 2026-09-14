%{
  title: "Revisão de conteúdo",
  summary:
    "Melhore seu conteúdo existente no local. O Glossia revisa arquivos de origem quanto à clareza, precisão e tom usando o contexto que você fornece, produzindo versões revisadas prontas para revisão.",
  order: 2,
  icon: "pencil",
  hero_cta_text: "Comece agora",
  hero_cta_url: "/signup",
  highlights: [
    %{
      title: "Tom e clareza",
      description:
        "Os agentes revisam sua redação quanto à legibilidade, jargão e consistência com a voz da sua marca.",
      icon: "message-circle"
    },
    %{
      title: "Não destrutivo",
      description:
        "O conteúdo revisado pode substituir o original ou escrever em um caminho separado. Você sempre controla o destino da saída.",
      icon: "shield-check"
    },
    %{
      title: "Ciclo de feedback",
      description:
        "Revisores corrigem a saída, atualizam o contexto e cada ciclo reduz a diferença entre o rascunho e a versão final.",
      icon: "refresh-cw"
    }
  ]
}
---
## Como funciona a revisão

O agente lê seus arquivos de origem e o grafo de contexto, mesclando instruções locais (arquivos `L10N.md` na raiz ou em subdiretórios) com contexto remoto (suas definições de voz, terminologia e estilo no nível da conta). Com o panorama completo montado, ele reescreve o conteúdo para clareza, precisão e tom, e então exporta a versão revisada pronta para revisão.

## Grafo de contexto

O contexto no Glossia é um grafo que abrange sua conta e seu repositório. As definições no nível da conta, como voz e terminologia, fornecem uma base global, enquanto arquivos `L10N.md` posicionados ao lado do seu conteúdo adicionam sobrescritas locais. O agente resolve este grafo em cada execução, garantindo que suas instruções permaneçam consistentes entre os arquivos, sem que você precise se repetir. As revisões são incrementais graças aos arquivos de bloqueio que rastreiam o que já foi processado, assim apenas o conteúdo alterado ou novo é reexaminado.

## Refinamento progressivo

Cada ciclo de revisão melhora a saída. As correções alimentam de volta os arquivos de contexto, assim os erros recorrentes desaparecem e a saída converge para o padrão da sua equipe ao longo do tempo.