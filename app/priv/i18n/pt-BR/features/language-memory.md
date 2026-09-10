%{
  title: "Memória de linguagem",
  summary:
    "Uma camada de contexto versionada que captura a voz, terminologia e estilo da sua organização. A memória de linguagem orienta cada fluxo de trabalho dos agentes e estende-se para suas próprias ferramentas por meio da API e MCP.",
  order: 5,
  icon: "brain",
  hero_cta_text: "Comece agora",
  hero_cta_url: "/signup",
  highlights: [
    %{
      title: "Versionado e auditável",
      description:
        "Cada alteração na sua voz ou terminologia cria uma nova versão imutável. Você pode revisar o histórico, comparar iterações e reverter se houver desvio.",
      icon: "git-branch"
    },
    %{
      title: "Além da localização",
      description:
        "A memória de linguagem não é apenas para localização. Use-a para gerar texto de marketing, rascunhar documentação, revisar pull requests ou criar posts sociais, tudo na voz da sua organização.",
      icon: "megaphone"
    },
    %{
      title: "Aberto e extensível",
      description:
        "Acesse a memória de linguagem por meio da REST API ou servidor MCP. Alimente-a em seus próprios pipelines CI, ferramentas de conteúdo ou agentes personalizados para manter a consistência em todo o lugar onde você escreve.",
      icon: "puzzle"
    }
  ]
}
---
## O que é memória linguística?

A memória linguística é o contexto acumulado que diz aos agentes do Glossia como sua organização se comunica. Ela é composta por dois fundamentos principais que você cria e refina com o tempo:

**Voz** Define como o conteúdo deve soar. Tom, formalidade, público-alvo e diretrizes livres estão todos aqui. Você pode definir uma voz base para sua conta e depois sobrescrever campos específicos para idiomas individuais, para que seu conteúdo em japonês possa ser mais formal enquanto seu conteúdo em inglês permanece conversacional.

**Terminologia** Define o que os termos significam e como eles devem ser tratados. Cada entrada carrega uma definição e traduções para cada idioma. Quando um agente encontra \\"workspace\\" no seu conteúdo de origem, a terminologia informa ao agente se deve traduzir, transliterar ou deixar inalterado, e exatamente qual palavra usar em cada idioma alvo.

Juntos, voz e terminologia formam uma camada de contexto que os agentes consultam a cada execução. Quanto mais você investe nessa camada, menos revisão seu resultado precisa.

## Versionamento Imutável

A memória linguística permite apenas adições. Quando você atualiza sua voz ou terminologia, Glossia cria uma versão nova em vez de sobrescrever a anterior. Cada versão registra quem a criou, quando e uma nota opcional de alteração explicando o que evoluiu.

Isso significa que você sempre terá um registro de auditoria completo. Você pode comparar a versão 3 com a versão 7 para entender como seu tom mudou ao longo do trimestre. Se uma mudança recente introduziu inconsistências, volte para uma versão anterior e continue.

O versionamento também torna a colaboração mais segura. Vários membros da equipe podem propor alterações de voz sem se preocupar com conflitos, porque cada alteração é um evento discreto e rastreável.

## Resolução consciente da localização

Quando um agente executa um fluxo de trabalho para uma localização específica, Glossia resolve a memória linguística para esse contexto. Ele começa com suas configurações de voz base e aplica então quaisquer sobrescritas específicas da localização por cima. O mesmo ocorre com a terminologia: apenas as entradas que possuem um termo localizado para a localização alvo são incluídas.

Essa etapa de resolução significa que os agentes sempre trabalham com o contexto mais relevante. Você não precisa manter configurações separadas por idioma. Defina seus padrões uma vez, aplique a sobrescrita onde necessário e deixe o sistema de resolução cuidar do resto.

## Use-a em todo lugar

A memória linguística foi projetada para localização, mas é útil em qualquer lugar que você produza texto. Porque o contexto é acessível através do [API REST](/features/rest-api) e o [servidor MCP](/features/mcp-server), você pode integrá-lo em fluxos de trabalho além da localização:

**Marketing e conteúdo social** -- Leve a voz da sua organização para um agente de conteúdo que redige posts em redes sociais, campanhas de e-mail ou textos de páginas de aterrissagem. A Terminologia mantém termos da marca consistentes e as configurações de voz garantem que o tom corresponda à sua marca.

**Documentação** -- Alimente a memória linguística em um pipeline de documentação para que a escrita técnica siga as mesmas regras de estilo do resto do seu conteúdo. Os itens de Terminologia previnem o desvio entre documentos, artigos de ajuda e textos do produto.

**Revisão de código** -- Crie um agente que revise os textos de pull request (mensagens de erro, rótulos de UI, textos de onboarding) contra sua voz e terminologia. Sinalize inconsistências antes do lançamento.

**Agentes personalizados** -- Qualquer cliente compatível com MCP pode ler e escrever na memória de linguagem. Peça ao seu assistente de código para "atualizar a terminologia com o novo nome do produto" ou "definir o tom da voz como profissional para o locale alemão" e ele traduz sua intenção para a chamada de API correta.

## Refinamento progressivo

A memória de linguagem melhora com o uso. Cada vez que um revisor corrige a saída de um agente, essa correção é incorporada na próxima versão da sua voz ou terminologia. Com o tempo, a diferença entre o primeiro rascunho e a saída final diminui, e a etapa de revisão torna-se mais rápida.

Este é o ciclo de feedback no coração do Glossia: gerar, revisar, refinar o contexto, gerar novamente. Os agentes não seguem apenas instruções. Trabalham com contexto que melhora a cada ciclo.