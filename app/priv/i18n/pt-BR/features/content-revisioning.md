%{
  title: "Revisão de conteúdo",
  summary:
    "Melhore seu conteúdo existente no local. O Glossia analisa arquivos de origem quanto à clareza, precisão e tom usando o contexto que você fornece, depois produz versões revisadas prontas para revisão.",
  order: 2,
  icon: "pencil",
  hero_cta_text: "Começar",
  hero_cta_url: "/signup",
  highlights: [
    %{
      title: "Tom e clareza",
      description:
        "Agentes revisam sua prosa quanto à legibilidade, jargão e consistência com a voz da sua marca.",
      icon: "message-circle"
    },
    %{
      title: "Não destrutivo",
      description:
        "O conteúdo revisado pode sobrescrever o original ou escrever para um caminho separado. Você sempre controla o destino de saída.",
      icon: "shield-check"
    },
    %{
      title: "Loop de feedback",
      description:
        "Revisores corrigem a saída, atualizam o contexto e cada ciclo reduz a distância entre o rascunho e o final.",
      icon: "refresh-cw"
    }
  ]
}
---

## Como funciona a revisão

O agente lê seus arquivos fonte e o gráfico de contexto, unindo instruções locais (`L10N.md` arquivos na raiz ou em subdiretórios) com contexto remoto (sua voz em nível de conta, glossário e configurações de estilo). Com a imagem completa montada, ele reescreve o conteúdo para clareza, precisão e tom, e em seguida produz a versão revisada pronta para revisão.

## Gráfico de contexto

O contexto no Glossia é um gráfico que abrange sua conta e seu repositório. Configurações em nível de conta, como voz e glossário, fornecem uma linha de base global, enquanto `L10N.md` arquivos colocados ao lado do seu conteúdo adicionam sobrescritas locais. O agente resolve este gráfico em cada execução, então suas instruções permanecem consistentes entre os arquivos sem precisar repeti-las. As revisões são incrementais graças aos arquivos de bloqueio que rastreiam o que já foi processado, então apenas o conteúdo alterado ou novo é revisado novamente.

## Refinamento progressivo

Cada ciclo de revisão melhora o resultado. Correções são incorporadas nos arquivos de contexto, então erros repetidos desaparecem e o resultado converge gradualmente para o padrão da sua equipe com o tempo.
