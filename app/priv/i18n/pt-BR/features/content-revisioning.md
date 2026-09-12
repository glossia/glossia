%{
  title: "Revisão de Conteúdo",
  summary:
    "Melhore seu conteúdo existente no local. O Glossia revisa arquivos de origem quanto à clareza, precisão e tom, utilizando o contexto que você fornece, e produz versões revisadas prontas para revisão.",
  order: 2,
  icon: "pencil",
  hero_cta_text: "Começar",
  hero_cta_url: "/signup",
  highlights: [
    %{
      title: "Tom e clareza",
      description:
        "Agentes revisam seu texto quanto à legibilidade, jargão e consistência com a voz da sua marca.",
      icon: "message-circle"
    },
    %{
      title: "Não destrutivo",
      description:
        "O conteúdo revisado pode substituir o original ou salvar em um caminho separado. Você sempre controla o destino da saída.",
      icon: "shield-check"
    },
    %{
      title: "Ciclo de feedback",
      description:
        "Os revisores corrigem a saída, atualizam o contexto e, a cada ciclo, reduzem a diferença entre o rascunho e a versão final.",
      icon: "refresh-cw"
    }
  ]
}
---
## Como funciona o processo de revisão

O agente lê seus arquivos de origem e o grafo de contexto, fundindo instruções locais (arquivos `L10N.md` na raiz ou em subdiretórios) com o contexto remoto (suas configurações globais de voz, terminologia e estilo). Com a visão completa reunida, ele reescreve o conteúdo para clareza, precisão e tom, em seguida, gera a versão revisada pronta para revisão.

## Grafo de contexto

O contexto no Glossia é um grafo que abrange sua conta e seu repositório. Configurações de nível de conta, como voz e terminologia, fornecem uma base global, enquanto arquivos `L10N.md` colocados ao lado de seu conteúdo adicionam substituições locais. O agente resolve esse grafo em cada execução, para que suas instruções permaneçam consistentes entre os arquivos sem precisar se repetir. As revisões são incrementais graças aos arquivos de bloqueio que rastreiam o que já foi processado, de forma que apenas conteúdos alterados ou novos sejam revistos.

## Refinamento progressivo

Cada ciclo de revisão melhora o resultado. As correções retornam aos arquivos de contexto, para que os erros repetidos desapareçam e o resultado converge para o padrão do seu time com o tempo.