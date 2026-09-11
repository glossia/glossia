%{
  title: "Memória linguística",
  summary:
    "Uma camada de contexto versionada que captura a voz, terminologia e estilo da sua organização. A memória linguística guia cada fluxo de trabalho de agente e se estende para suas próprias ferramentas através da API e do MCP.",
  order: 5,
  icon: "brain",
  hero_cta_text: "Começar",
  hero_cta_url: "/signup",
  highlights: [
    %{
      title: "Versionado e auditável",
      description:
        "Todas as alterações à voz ou terminologia criam uma nova versão imutável. Você pode revisar o histórico, comparar iterações e reverter caso haja desvios.",
      icon: "git-branch"
    },
    %{
      title: "Além da localização",
      description:
        "A memória linguística não é apenas para localização. Use-a para gerar textos de marketing, elaborar documentação, revisar pull requests ou criar posts sociais, tudo na voz da sua organização.",
      icon: "megaphone"
    },
    %{
      title: "Aberto e extensível",
      description:
        "Acesse a memória linguística através da REST API ou do servidor MCP. Alimente-a em seus próprios pipelines CI, ferramentas de conteúdo ou agentes personalizados para manter a consistência em todos os lugares onde você escreve.",
      icon: "puzzle"
    }
  ]
}
---
## O que é memória de linguagem?

Memória de linguagem é o contexto acumulado que informa aos agentes do Glossia como sua organização se comunica. É composta por dois primitivos principais que você cria e refina com o tempo:

**Voz** define como o conteúdo deve soar. Tom, formalidade, público-alvo e diretrizes livres estão aqui. Você pode definir uma voz base para sua conta e depois sobrescrever campos específicos para locais individuais, para que seus textos em japonês sejam mais formais enquanto seu texto em inglês permanece conversacional.

**Terminologia** define o que os termos significam e como devem ser localizados. Cada entrada carrega uma definição e traduções por local. Quando um agente encontra "workspace" em seu conteúdo de origem, a terminologia indica se ele deve localizar, transliterar ou deixar inalterado, e exatamente qual palavra usar em cada idioma de destino.

Juntos, voz e terminologia formam uma camada de contexto que os agentes consultam em cada execução. Quanto mais você investir nessa camada, menos revisão sua saída precisará.

## Versionamento Imutável

A memória linguística é somente por adição. Ao atualizar sua voz ou terminologia, a Glossia cria uma nova versão em vez de sobrescrever a anterior. Cada versão registra quem a criou, quando, e uma nota opcional de alteração explicando o que evoluiu.

Isso significa que você sempre possui um rastro completo de auditoria. Você pode comparar a versão 3 contra a versão 7 para entender como seu tom mudou ao longo de um trimestre. Se uma alteração recente introduziu inconsistências, volte para uma versão anterior e continue.

O versionamento também torna a colaboração mais segura. Vários membros da equipe podem propor alterações de voz sem se preocupar com conflitos, porque cada alteração é um evento discreto e rastreável.

## Resolução sensível à localização

Quando um agente executa um fluxo de trabalho para uma localização específica, a Glossia resolve a memória linguística para esse contexto. Começa com suas configurações de voz base e então aplica quaisquer sobrescritas específicas para a localização sobre estas. O mesmo acontece com a terminologia: apenas as entradas que têm um termo localizado para a localização alvo são incluídas.

Esta etapa de resolução significa que os agentes sempre trabalham com o contexto mais relevante. Você não precisa manter configurações separadas por idioma. Defina seus valores padrão uma vez, sobrescreva onde importa e deixe o sistema de resolução cuidar do resto.

## Use-o em qualquer lugar

A memória linguística foi projetada para localização, mas é útil em qualquer lugar onde você produza texto. Como o contexto está acessível através do [REST API](/features/rest-api) e o [servidor MCP](/features/mcp-server), você pode integrá-lo a fluxos de trabalho além da localização:

**Marketing e conteúdo social** -- Incorpore a voz da sua organização em um agente de conteúdo que elabora mensagens para redes sociais, campanhas de e-mail ou textos para páginas de destino. A Terminologia mantém os termos da marca consistentes e as configurações de voz garantem que o tom combine com sua marca.

**Documentação** -- Alimente a memória linguística em um pipeline de documentação para que a redação técnica siga as mesmas regras de estilo do restante do conteúdo. As entradas de Terminologia impedem a divergência entre a documentação, artigos de ajuda e textos do produto.

**Revisão de código** -- Crie um agente que revise o texto dos pull requests (mensagens de erro, labels de UI, texto de integração) de acordo com sua voz e terminologia. Sinalize inconsistências antes de serem lançadas.

**Agentes personalizados** -- Qualquer cliente compatível com o MCP pode ler e escrever na memória da linguagem. Peça ao seu assistente de programação para "atualizar a terminologia com o novo nome do produto" ou "definir o tom de voz como profissional para a localização alemã" e ele traduz sua intenção na chamada de API correta.

## Refinamento progressivo

A memória da linguagem melhora com o uso. Sempre que um revisor corrige a saída de um agente, essa correção retroalimenta a próxima versão da sua voz ou terminologia. Com o tempo, a diferença entre o primeiro rascunho e a saída final diminui, e a etapa de revisão torna-se mais rápida.

Este é o ciclo de feedback no coração do Glossia: gerar, revisar, refinar o contexto e gerar novamente. Os agentes não seguem apenas instruções. Eles trabalham com contexto que melhora a cada ciclo.