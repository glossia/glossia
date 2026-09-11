%{
  title: "Revisão de conteúdo",
  summary:
    "Melhore seu conteúdo existente no local. A Glossia revisa arquivos de origem por clareza, precisão e tom usando o contexto que você fornece, e gera versões revisadas prontas para revisão.",
  order: 2,
  icon: "pencil",
  hero_cta_text: "Começar",
  hero_cta_url: "/signup",
  highlights: [
    %{
      title: "Tom e clareza",
      description:
        "Agentes revisam seu texto para legibilidade, jargão e consistência com sua voz de marca.",
      icon: "message-circle"
    },
    %{
      title: "Não destrutivo",
      description:
        "O conteúdo revisado pode sobrescrever o original ou escrever para um caminho separado. Você sempre controla o destino da saída.",
      icon: "shield-check"
    },
    %{
      title: "Ciclo de feedback",
      description:
        "Revisores corrigem a saída, atualizam o contexto e cada ciclo reduz a distância entre o rascunho e o final.",
      icon: "refresh-cw"
    }
  ]
}
---
## Como funciona a revisão

O agente lê seus arquivos fonte e o grafo de contexto, mesclando instruções locais (arquivos `L10N.md` na raiz ou em subdiretórios) com contexto remoto (suas definições de voz, terminologia e estilo em nível de conta). Com todo o panorama reunido, ele reescreve o conteúdo para clareza, precisão e tom, e em seguida exporta a versão revisada pronta para revisão.

## Grafo de contexto

O contexto no Glossia é um grafo que abrange sua conta e seu repositório. Configurações de nível de conta, como voz e terminologia, fornecem uma base global, enquanto os arquivos `L10N.md` colocados ao lado do seu conteúdo adicionam sobreposições locais. O agente resolve este grafo a cada execução, para que suas instruções permaneçam consistentes entre os arquivos sem necessidade de repetição. As revisões são incrementais graças aos arquivos de bloqueio que rastreiam o que já foi processado, para que apenas o conteúdo alterado ou novo seja revisado.

## Refinamento progressivo

Cada ciclo de revisão torna a saída melhor. Correções retroalimentam os arquivos de contexto, para que erros repetidos desapareçam e a saída converja para o padrão da sua equipe ao longo do tempo.