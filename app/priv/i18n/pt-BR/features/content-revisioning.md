%{
  title: "Revisão de conteúdo",
  summary: "Aprimore seu conteúdo existente no próprio local. A Glossia revisa os arquivos de origem quanto à clareza, precisão e tom usando o contexto fornecido e, em seguida, produz versões revisadas prontas para análise.",
  order: 2,
  icon: "pencil",
  hero_cta_text: "Começar",
  hero_cta_url: "/signup",
  highlights: [
    %{title: "Tom e clareza", description: "Os agentes revisam seu texto quanto à legibilidade, ao uso de jargões e à consistência com a voz da sua marca.", icon: "message-circle"},
    %{title: "Não destrutivo", description: "O conteúdo revisado pode substituir o original ou ser gravado em um caminho separado. Você sempre controla o destino da saída.", icon: "shield-check"},
    %{title: "Ciclo de feedback", description: "Os revisores corrigem a saída, atualizam o contexto e, a cada ciclo, reduzem a diferença entre o rascunho e a versão final.", icon: "refresh-cw"}
  ]
}
---
## Como funciona o versionamento

O agente lê seus arquivos de origem e o grafo de contexto, combinando instruções locais (arquivos `GLOSSIA.md` na raiz ou em subdiretórios) com o contexto remoto (as configurações de voz, terminologia e estilo da sua conta). Com o contexto completo, ele reescreve o conteúdo para aprimorar a clareza, a precisão e o tom e, em seguida, gera a versão revisada, pronta para análise.

## Grafo de contexto

No Glossia, o contexto é um grafo que abrange sua conta e seu repositório. Configurações no nível da conta, como voz e terminologia, fornecem uma base global, enquanto os arquivos `GLOSSIA.md` posicionados junto ao conteúdo adicionam substituições locais. O agente resolve esse grafo a cada execução, mantendo suas instruções consistentes entre os arquivos sem que seja necessário repeti-las. As revisões são incrementais graças aos lockfiles, que registram o que já foi processado, portanto somente conteúdos alterados ou novos são revisados.

## Refinamento progressivo

Cada ciclo de revisão aprimora o resultado. As correções são incorporadas aos arquivos de contexto, eliminando erros recorrentes e fazendo com que o resultado convirja, ao longo do tempo, para o padrão da sua equipe.