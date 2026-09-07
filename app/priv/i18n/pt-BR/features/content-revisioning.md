%{
  title: "Revisão de conteúdo",
  summary:
    "Melhore seu conteúdo existente no lugar. O Glossia examina arquivos fonte em busca de clareza, precisão e tom utilizando o contexto que você fornece, e depois produz versões revisadas prontas para revisão.",
  order: 2,
  icon: "pencil",
  hero_cta_text: "Começar agora",
  hero_cta_url: "/signup",
  highlights: [
    %{
      title: "Tom e clareza",
      description:
        "Os Agentes revisam o seu texto quanto à legibilidade, jargão e consistência com a voz da sua marca.",
      icon: "message-circle"
    },
    %{
      title: "Não destrutivo",
      description:
        "O conteúdo revisado pode substituir o original ou ser escrito em um caminho separado. Você sempre controla o destino da saída.",
      icon: "shield-check"
    },
    %{
      title: "Ciclo de feedback",
      description:
        "Os revisores corrigem a saída, atualizam o contexto e cada ciclo reduz a distância entre o rascunho e a versão final.",
      icon: "refresh-cw"
    }
  ]
}
---
## Como funciona o revisionamento

O agente lê seus arquivos de origem e o gráfico de contexto, mesclando instruções locais (`GLOSSIA.md` arquivos na raiz ou em subdiretórios) com contexto remoto (sua voz, terminologia e configurações de estilo ao nível da conta). Com o panorama completo montado, ele reescreve o conteúdo para clareza, exatidão e tom, e então exibe a versão revisada pronta para revisão.

## Gráfico de contexto

O contexto no Glossia é um gráfico que abrange sua conta e seu repositório. Configurações ao nível da conta, como voz e terminologia, fornecem uma linha de base global, enquanto `GLOSSIA.md` arquivos colocados ao lado do seu conteúdo adicionam superposições locais. O agente resolve este gráfico a cada execução, para que suas instruções fiquem consistentes entre os arquivos sem que você repita a si mesmo. As revisões são incrementais graças aos arquivos de bloqueio que acompanham o que já foi processado, para que apenas o conteúdo alterado ou novo seja revisto.

## Refinamento progressivo

Cada ciclo de revisão torna a saída melhor. Correções são incorporadas aos arquivos de contexto, para que erros repetidos desapareçam e a saída convirja no padrão da equipe ao longo do tempo.