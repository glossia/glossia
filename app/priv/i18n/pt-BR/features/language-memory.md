%{
  title: "Memória Linguística",
  summary:
    "Uma camada de contexto versionada que captura a voz, o glossário e o estilo da sua organização. A Memória Linguística guia cada fluxo de trabalho de agente e estende-se para suas próprias ferramentas através da API e do MCP.",
  order: 5,
  icon: "brain",
  hero_cta_text: "Começar",
  hero_cta_url: "/signup",
  highlights: [
    %{
      title: "Versionado e auditável",
      description:
        "Cada alteração na sua voz ou glossário cria uma nova versão imutável. Você pode revisar o histórico, comparar iterações e reverter se algo divergir.",
      icon: "git-branch"
    },
    %{
      title: "Além da localização",
      description:
        "A Memória Linguística não é apenas para localização. Use-a para gerar textos de marketing, rascunhar documentação, revisar pull requests ou criar posts para redes sociais, tudo na voz da sua organização.",
      icon: "megaphone"
    },
    %{
      title: "Aberto e extensível",
      description:
        "Acesse a Memória Linguística através da REST API ou do servidor MCP. Alimente-a em seus próprios pipelines de CI, ferramentas de conteúdo ou agentes personalizados para manter a consistência em todos os lugares onde você escreve.",
      icon: "puzzle"
    }
  ]
}
---

## O que é a memória de linguagem?

A memória de linguagem é o contexto acumulado que diz aos agentes do Glossia como sua organização se comunica. Ela é composta por dois primitivos centrais que você cria e refina com o tempo:

**Voz** define como o conteúdo deve soar. Tom, formalidade, público-alvo e diretrizes livres estão aqui. Você pode definir uma voz base para sua conta e depois substituir campos específicos para locais individuais, para que seu texto em japonês possa ser mais formal enquanto o seu em inglês permanece conversacional.

**Glossário** define o que os termos significam e como devem ser localizados. Cada entrada possui uma definição e traduções por locale. Quando um agente encontra "workspace" em seu conteúdo de origem, o glossário indica se ele deve localizar, transliterar ou deixar intocado, e exatamente qual palavra usar em cada idioma-alvo.

Juntos, voz e glossário formam uma camada de contexto que os agentes consultam em cada execução. Quanto mais você investir nesta camada, menos revisão seu output precisará.

## Versionamento imutável

A memória de linguagem é somente para adição. Quando você atualiza sua voz ou glossário, o Glossia cria uma nova versão em vez de substituir a antiga. Cada versão registra quem criou, quando e uma nota de mudança opcional explicando o que evoluiu.

Isso significa que você sempre terá um rastro de auditoria completo. Você pode comparar a versão 3 contra a versão 7 para entender como seu tom mudou em um trimestre. Se uma mudança recente introduziu inconsistências, reverta para uma versão anterior e continue.

O versionamento também torna a colaboração mais segura. Membros de equipe podem propor mudanças na voz sem se preocupar com conflitos, porque cada mudança é um evento discreto e traçável.

## Resolução adaptada ao locale

Quando um agente executa um workflow para um locale específico, o Glossia resolve a memória de linguagem para esse contexto. Começa com suas configurações de voz base e então aplica qualquer substituição específica do locale por cima. O mesmo ocorre com o glossário: apenas entradas que têm um termo localizado para o locale-alvo são incluídas.

Esta etapa de resolução significa que os agentes sempre trabalham com o contexto mais relevante. Você não precisa manter configurações separadas por idioma. Defina seus padrões uma vez, substitua onde importa, e deixe o sistema de resolução lidar com o resto.

## Use-o em todos os lugares

A memória de linguagem foi desenhada para localização, mas é útil em qualquer lugar onde você produza texto. Como o contexto é acessível através do [REST API](/features/rest-api) e do [Servidor MCP](/features/mcp-server), você pode integrá-lo a workflows além da localização:

**Marketing e conteúdo social** -- Importe a voz da sua organização em um agente de conteúdo que redija postagens nas redes sociais, campanhas de e-mail ou texto de página de aterrissagem. O glossário mantém termos da marca consistentes e as configurações de voz garantem que o tom corresponda à sua marca.

**Documentação** -- Alimente a memória de linguagem em um pipeline de documentação para que a escrita técnica siga as mesmas regras de estilo do resto do seu conteúdo. Entradas do glossário impedem a deriva entre documentos, artigos de ajuda e texto dentro do produto.

**Revisão de código** -- Construa um agente que revise o texto de solicitação de pull (mensagens de erro, rótulos da UI, texto de onboarding) contra sua voz e glossário. Marque inconsistências antes que elas sejam lançadas.

**Agentes personalizados** -- Qualquer cliente compatível com MCP pode ler e escrever memória de linguagem. Peça ao seu assistente de programação para "atualizar o glossário com o novo nome do produto" ou "definir o tom de voz para profissional para o locale alemão" e ele traduzirá sua intenção no chamado API correto.

## Refinamento progressivo

A memória de linguagem melhora com o uso. Cada vez que um revisor corrige um output do agente, essa correção retroalimenta na próxima versão de sua voz ou glossário. Com o tempo, a lacuna entre o primeiro rascunho e a saída final diminui, e a etapa de revisão torna-se mais rápida.

Este é o ciclo de feedback no coração do Glossia: gerar, revisar, refinar contexto, gerar novamente. Os agentes não apenas seguem instruções. Eles trabalham com um contexto que fica melhor a cada ciclo.
