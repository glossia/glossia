%{
  title: "Memória de linguagem",
  summary:
    "Uma camada de contexto versionada que captura a voz, terminologia e estilo da sua organização. A memória de linguagem guia todo o fluxo de trabalho de agentes e se estende às suas próprias ferramentas via API e MCP.",
  order: 5,
  icon: "brain",
  hero_cta_text: "Começar",
  hero_cta_url: "/signup",
  highlights: [
    %{
      title: "Versionado e auditável",
      description:
        "Toda mudança na voz ou terminologia cria uma nova versão imutável. Você pode revisar o histórico, comparar iterações e reverter no caso de desvios.",
      icon: "git-branch"
    },
    %{
      title: "Além da localização",
      description:
        "A memória de linguagem não é apenas para localização. Use-a para gerar textos de marketing, redigir documentação, revisar pull requests ou criar posts sociais, tudo na voz da sua organização.",
      icon: "megaphone"
    },
    %{
      title: "Aberto e extensível",
      description:
        "Acesse a memória de linguagem pela API REST ou pelo servidor MCP. Integre-a aos seus próprios pipelines de CI, ferramentas de conteúdo ou agentes personalizados para manter a consistência em todo o que você escreve.",
      icon: "puzzle"
    }
  ]
}
---
## O que é memória de idioma?

A memória de idioma é o contexto acumulado que instrui os agentes do Glossia sobre como a sua organização se comunica. Ela é formada por dois primitivos principais que você cria e aprimora com o tempo:

**Voz** define como o conteúdo deve soar. Tom, formalidade, público-alvo e diretrizes livres ficam aqui. Você pode definir uma voz base para a sua conta e depois sobrescrever campos específicos para idiomas individuais, para que seu conteúdo em japonês possa ser mais formal enquanto o em inglês permanece conversacional.

**Terminologia** define o que os termos significam e como eles devem ser localizados. Cada entrada traz uma definição e traduções específicas por idioma. Quando um agente encontra "workspace" no seu conteúdo de origem, a terminologia indica se deve localizar, transliterar ou deixar inalterado, e exatamente qual palavra usar em cada idioma de destino.

Juntos, voz e terminologia formam uma camada de contexto que os agentes consultam a cada execução. Quanto mais você investe nessa camada, menos revisão o seu resultado necessita.

## Versionamento imutável

A memória linguística permite apenas acréscimos. Quando você atualiza sua voz ou terminologia, o Glossia cria uma nova versão em vez de sobrescrever a anterior. Cada versão registra quem a criou, quando e uma nota de mudança opcional explicando o que evoluiu.

Isso significa que você sempre possui um rastro de auditoria completo. Você pode comparar a versão 3 contra a versão 7 para entender como seu tom mudou ao longo de um trimestre. Se uma mudança recente introduziu inconsistências, reverta para uma versão anterior e continue.

O versionamento também torna a colaboração mais segura. Vários membros da equipe podem propor alterações na voz sem se preocupar com conflitos, pois cada mudança é um evento discreto e rastreável.

## Resolução baseada na localidade

Quando um agente executa um fluxo de trabalho para uma localidade específica, o Glossia resolve a memória linguística para esse contexto. Ele inicia com suas configurações base de voz e depois aplica qualquer alteração específica da localidade. A mesma regra se aplica à terminologia: apenas as entradas que possuem um termo localizado para a localidade de destino são incluídas.

Esta etapa de resolução garante que os agentes sempre trabalhem com o contexto mais relevante. Você não precisa manter configurações separadas por idioma. Defina seus padrões uma vez, ajuste onde for necessário e deixe o sistema de resolução cuidar do resto.

## Use em todos os lugares

A memória linguística foi projetada para localização, mas é útil em qualquer lugar onde você produza texto. Como o contexto é acessível através da [REST API](/features/rest-api) e o [servidor MCP](/features/mcp-server), você pode integrá-lo em fluxos de trabalho além da localização:

**Marketing e conteúdo social** -- Integre a voz da sua organização em um agente de conteúdo que elabora posts nas redes sociais, campanhas de e-mail ou conteúdo de páginas de destino. A Terminologia mantém termos da marca consistentes e as configurações de voz garantem que o tom corresponda à sua marca.

**Documentação** -- Alimente a memória de linguagem em um fluxo de documentação para que a escrita técnica siga as mesmas regras de estilo do resto do seu conteúdo. As entradas de Terminologia impedem a deriva entre documentos, artigos de ajuda e texto do produto.

**Revisão de código** -- Crie um agente que revisa o texto de solicitações de pull request (mensagens de erro, rótulos de interface, texto de onboarding) contra sua voz e terminologia. Indique inconsistências antes de lançar.

**Agentes personalizados** -- Qualquer cliente compatível com o MCP pode ler e escrever memória de linguagem. Peça ao seu assistente de programação para "atualizar a terminologia com o novo nome do produto" ou "definir o tom de voz como profissional para a localidade alemã" e ele traduzirá sua intenção na chamada de API correta.

## Refinamento progressivo

A memória de linguagem melhora com o uso. Cada vez que um revisor corrige a saída de um agente, essa correção é incorporada à próxima versão da sua voz ou terminologia. Com o tempo, a distância entre o primeiro rascunho e a saída final diminui, tornando a etapa de revisão mais rápida.

Este é o ciclo de feedback no coração do Glossia: gerar, revisar, refinar contexto e gerar novamente. Os agentes não seguem apenas instruções. Trabalham com contexto que melhora a cada ciclo.