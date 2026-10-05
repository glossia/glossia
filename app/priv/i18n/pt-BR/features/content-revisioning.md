%{
  title: "Revisão de conteúdo",
  summary:
    "Melhore seu conteúdo existente diretamente. O Glossia analisa os arquivos de origem em busca de clareza, precisão e tom, utilizando o contexto que você fornece, e produz versões revisadas prontas para revisão.",
  order: 2,
  icon: "pencil",
  hero_cta_text: "Começar agora",
  hero_cta_url: "/signup",
  highlights: [
    %{
      title: "Tom e clareza",
      description:
        "Agentes revisam sua redação em busca de legibilidade, jargão e consistência com a voz da sua marca.",
      icon: "message-circle"
    },
    %{
      title: "Não destrutivo",
      description:
        "O conteúdo revisado pode substituir o original ou ser gravado em um caminho separado. Você sempre controla o destino de saída.",
      icon: "shield-check"
    },
    %{
      title: "Loop de feedback",
      description:
        "Os revisores corrigem a saída, atualizam o contexto e cada ciclo reduz a lacuna entre o rascunho e o final.",
      icon: "refresh-cw"
    }
  ]
}
---
## Como funciona a revisão

O agente lê seus arquivos fonte e o grafo de contexto, fundindo instruções locais (arquivos `L10N.md` na raiz ou em subdiretórios) com contexto remoto (sua voz, glossário e configurações de estilo de nível de conta). Com o panorama completo reunido, ele reescreve o conteúdo para clareza, precisão e tom, em seguida produzindo a versão revisada pronta para revisão.

## Grafo de contexto

O contexto no Glossia é um grafo que abrange sua conta e seu repositório. Configurações de nível de conta como voz e glossário fornecem uma base global, enquanto arquivos `L10N.md` colocados junto do seu conteúdo adicionam ajustes locais de substituição. O agente resolve este grafo a cada execução, para que suas instruções permaneçam consistentes entre os arquivos sem que você precise se repetir. As revisões são incrementais graças a arquivos de bloqueio que rastreiam o que já foi processado, assim apenas o conteúdo alterado ou novo é revisado novamente.

## Refinamento progressivo

Cada ciclo de revisão torna a saída melhor. Correções são reintegradas aos arquivos de contexto, para que erros recorrentes desapareçam e a saída converja para o padrão da sua equipe com o tempo.