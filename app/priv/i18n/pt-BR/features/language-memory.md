%{
  title: "Memória linguística",
  summary:
    "Uma camada de contexto versionada que captura a voz, terminologia e estilo da sua organização. A memória linguística orienta cada fluxo de agente e estende-se às suas próprias ferramentas através da API e MCP.",
  order: 5,
  icon: "brain",
  hero_cta_text: "Começar",
  hero_cta_url: "/signup",
  highlights: [
    %{
      title: "Versionado e auditável",
      description:
        "Toda alteração na sua voz ou terminologia cria uma nova versão imutável. Você pode revisar o histórico, comparar iterações e reverter se algo desviar.",
      icon: "git-branch"
    },
    %{
      title: "Além da localização",
      description:
        "A memória linguística não é apenas para localização. Use-a para gerar texto de marketing, rascunhar documentação, revisar solicitações de pull ou criar postagens sociais, tudo na voz da sua organização.",
      icon: "megaphone"
    },
    %{
      title: "Aberto e extensível",
      description:
        "Acesse a memória linguística via API REST ou servidor MCP. Integre-a aos seus próprios pipelines de CI, ferramentas de conteúdo ou agentes personalizados para manter a consistência em todo lugar onde escreve.",
      icon: "puzzle"
    }
  ]
}
---
## O que é memória de idioma?

A memória de idioma é o contexto acumulado que informa aos agentes da Glossia como sua organização se comunica. É composta por dois primitivos centrais que você cria e aprimora ao longo do tempo:

**Voz** define como o conteúdo deve soar. Tom, formalidade, público-alvo e diretrizes livres estão todos aqui. Você pode definir uma voz base para sua conta e depois sobrescrever campos específicos para localizações individuais, assim seu conteúdo em japonês pode ser mais formal enquanto seu conteúdo em inglês permanece conversacional.

**Terminologia** define o que os termos significam e como devem ser localizados. Cada entrada carrega uma definição e traduções por localização. Quando um agente encontra "workspace" em seu conteúdo de origem, a terminologia indica a ele se deve localizar, transliterar ou deixá-lo inalterado e exatamente qual palavra usar em cada idioma de destino.

Juntos, voz e terminologia formam uma camada de contexto que os agentes consultam em cada execução. Quanto mais você investir nessa camada, menos revisão seu resultado precisa.

## Versionamento imutável

A memória de idioma é apenas para adição de novos registros. Quando você atualizar sua voz ou terminologia, a Glossia cria uma nova versão em vez de sobrescrever a anterior. Cada versão registra quem a criou, quando e uma nota de alteração opcional explicando o que evoluiu.

Isso significa que você sempre terá um histórico completo de auditoria. Você pode comparar a versão 3 contra a versão 7 para entender como seu tom mudou em um trimestre. Se uma mudança recente introduziu inconsistências, reverta para uma versão anterior e continue.

O versionamento também torna a colaboração mais segura. Múltiplos membros da equipe podem propor mudanças de voz sem se preocupar com conflitos, porque cada mudança é um evento discreto e rastreável.

## Resolução sensível à localização

Quando um agente executa um fluxo de trabalho para uma localização específica, a Glossia resolve a memória de idioma para esse contexto. Começa com suas configurações de voz base e aplica quaisquer sobrescritas específicas da localização em cima. O mesmo acontece com a terminologia: apenas as entradas que têm um termo localizado para a localização de destino são incluídas.

Esse passo de resolução significa que os agentes sempre trabalham com o contexto mais relevante. Você não precisa manter configurações separadas por idioma. Defina seus padrões uma vez, sobrescreva onde importa e deixe o sistema de resolução lidar com o resto.

## Use em qualquer lugar

A memória de idioma foi projetada para a localização, mas é útil em qualquer lugar onde você produza texto. Como o contexto está acessível através do [REST API](/features/rest-api) e do [MCP server](/features/mcp-server), você pode integrá-lo em fluxos de trabalho além da localização:

**Marketing e conteúdo social** -- Utilize a voz da sua organização em um agente de conteúdo que redige posts para redes sociais, campanhas de e-mail ou copy de landing page. A terminologia mantém os termos da marca consistentes e as configurações de voz garantem que o tom esteja de acordo com sua marca.

**Documentação** -- Alimente a memória de idioma em um pipeline de documentação para que a escrita técnica siga as mesmas regras de estilo que o restante do seu conteúdo. As entradas de terminologia evitam desvios em documentos, artigos de ajuda e textos no produto.

**Revisão de código** -- Construa um agente que revise o texto de solicitação de pull (mensagens de erro, rótulos de interface, texto de onboarding) contra sua voz e terminologia. Identifique inconsistências antes de serem lançados.

**Agentes personalizados** -- Qualquer cliente compatível com o MCP pode ler e escrever na memória de idioma. Peça ao seu assistente de codificação para "atualizar a terminologia com o novo nome do produto" ou "definir o tom da voz como profissional para a localização em alemão" e ele traduzirá sua intenção na chamada de API adequada.

## Refinamento progressivo

A memória de idioma melhora com o uso. Cada vez que um revisor corrige a saída de um agente, essa correção é retroalimentada para a próxima versão de sua voz ou terminologia. Ao longo do tempo, a lacuna entre o primeiro rascunho e a saída final diminui, e a etapa de revisão se torna mais rápida.

Este é o ciclo de feedback no centro da Glossia: gerar, revisar, refinar o contexto, gerar novamente. Os agentes não apenas seguem instruções. Eles trabalham com contexto que melhora a cada ciclo.