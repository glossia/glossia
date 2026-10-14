%{
  title: "Revisão de conteúdo",
  summary:
    "Melhore seu conteúdo existente no local. O Glossia analisa arquivos fonte em busca de clareza, precisão e tom, utilizando o contexto que você fornece, e produz versões revisadas prontas para revisão.",
  order: 2,
  icon: "pencil",
  hero_cta_text: "Comece subito",
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
        "O conteúdo revisado pode sobrescrever o original ou ser escrito em um caminho distinto. Você sempre controla o destino da saída.",
      icon: "shield-check"
    },
    %{
      title: "Ciclo de feedback",
      description:
        "Os revisores corrigem a saída, atualizam o contexto e cada ciclo reduz a lacuna entre o rascunho e a versão final.",
      icon: "refresh-cw"
    }
  ]
}
---

## Como funciona a revisão

O agente lê seus arquivos de origem e o gráfico de contexto, fundindo instruções locais (`L10N.md` arquivos na raiz ou em subdiretórios) com o contexto remoto (sua voz de nível de conta, glossário e definições de estilo). Com todo o panorama reunido, ele reelabora o conteúdo para clareza, precisão e tom, e então entrega a versão revisada pronta para revisão.

## Gráfico de contexto

O contexto no Glossia é um gráfico que abrange sua conta e seu repositório. Definições de nível de conta, como voz e glossário, fornecem uma base global, enquanto `L10N.md` arquivos colocados ao lado de seu conteúdo adicionam sobrescrições locais. O agente resolve esse gráfico em cada execução, para que suas instruções permaneçam consistentes entre os arquivos sem que você precise se repetir. As revisões são incrementais graças aos lockfiles que rastreiam o que já foi processado, para que apenas o conteúdo alterado ou novo seja revisitado.

## Refinamento progressivo

Cada ciclo de revisão torna o resultado melhor. As correções retornam aos arquivos de contexto, para que os erros repetidos desapareçam e o resultado converja para o padrão da sua equipe com o tempo.
