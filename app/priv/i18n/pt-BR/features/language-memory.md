%{
  title: "Memória de Linguagem",
  summary:
    "Uma camada de contexto versionada que captura a voz, terminologia e estilo da sua organização. A Memória de Linguagem guia cada fluxo de trabalho de agente e se estende às suas próprias ferramentas através da API e MCP.",
  order: 5,
  icon: "brain",
  hero_cta_text: "Começar",
  hero_cta_url: "/signup",
  highlights: [
    %{
      title: "Versionado e auditável",
      description:
        "Toda alteração na sua voz ou terminologia cria uma nova versão imutável. Você pode revisar o histórico, comparar iterações e reverter caso ocorra desvio.",
      icon: "git-branch"
    },
    %{
      title: "Além da localização",
      description:
        "A Memória de Linguagem não é apenas para localização. Use-a para gerar textos de marketing, redigir documentação, revisar pull requests ou criar posts sociais, tudo na voz da sua organização.",
      icon: "megaphone"
    },
    %{
      title: "Aberto e extensível",
      description:
        "Acesse a Memória de Linguagem através da API REST ou servidor MCP. Alimente-a em seus próprios pipelines de CI, ferramentas de conteúdo ou agentes personalizados para manter a consistência em todas as áreas onde você escreve.",
      icon: "puzzle"
    }
  ]
}
---
## O que é memória de idioma?

Memória de idioma é o contexto acumulado que indica aos agentes do Glossia como sua organização se comunica. Ela é formada por dois conceitos fundamentais que você cria e refina ao longo do tempo:

**Voz** Define como o conteúdo deve soar. Tom, formalidade, público-alvo e diretrizes livres vivem aqui. Você pode definir uma voz base para sua conta e depois sobrescrever campos específicos para cada localização, permitindo que seu conteúdo em japonês seja mais formal enquanto seu conteúdo em inglês permanece conversacional.

**Terminologia** Define o que os termos significam e como eles devem ser localizados. Cada entrada carrega uma definição e traduções por localização. Quando um agente encontra \\"workspace\\" no seu conteúdo de origem, a terminologia indica a ele se deve traduzir, transliterar ou deixá-lo inalterado, e exatamente qual palavra usar em cada idioma de destino.

Juntos, voz e terminologia formam uma camada de contexto que os agentes consultam a cada execução. Quanto mais você investe nesta camada, menos revisão sua saída precisa.

## Versionamento imutável

A memória de idioma é somente apêndice. Quando você atualiza sua voz ou terminologia, o Glossia cria uma nova versão em vez de sobrescrever a antiga. Cada versão registra quem a criou, quando e uma nota de alteração opcional explicando o que evoluiu.

Isso significa que você sempre terá um rastro completo de auditoria. Você pode comparar a versão 3 com a versão 7 para entender como seu tom mudou ao longo de um trimestre. Se uma alteração recente introduzir inconsistências, reverta para uma versão anterior e continue.

O versionamento também torna a colaboração mais segura. Vários membros da equipe podem propor alterações de voz sem se preocupar com conflitos, pois cada mudança é um evento discreto e rastreável.

## Resolução sensível à localização

Quando um agente executa um fluxo de trabalho para uma localização específica, o Glossia resolve a memória de idioma para aquele contexto. Começa com as configurações de voz base e, em seguida, aplica quaisquer sobrescrições específicas dessa localização por cima. O mesmo acontece com a terminologia: apenas as entradas que possuem um termo localizado para a localização-alvo são incluídas.

Esta etapa de resolução significa que os agentes sempre operam com o contexto mais relevante. Você não precisa manter configurações separadas por idioma. Defina suas configurações padrão uma vez, sobreponha onde for relevante e deixe o sistema de resolução cuidar do resto.

## Use em qualquer lugar

A memória de idioma foi projetada para localização, mas é útil em qualquer lugar que você produza texto. Porque o contexto é acessível através da [REST API](/features/rest-api) e o [servidor MCP](/features/mcp-server), você pode integrá-lo em fluxos de trabalho além da localização:

**Marketing e conteúdo social** -- Leve a voz da sua organização para um agente de conteúdo que elabora postagens em redes sociais, campanhas de e-mail ou textos para páginas de destino. Terminologia mantém termos da marca consistentes e as configurações de voz garantem que o tom corresponda à sua marca.

**Documentação** -- Alimente a memória de idioma em um pipeline de documentação para que a redação técnica siga as mesmas regras de estilo do resto do seu conteúdo. As entradas de Terminologia impedem o desvio entre a documentação, artigos de ajuda e cópias dentro do produto.

**Revisão de cópia** -- Crie um agente que revise o conteúdo das solicitações pull (mensagens de erro, rótulos da UI, texto de onboarding) contra sua voz e terminologia. Aponte inconsistências antes do lançamento.

**Agentes personalizados** -- Qualquer cliente compatível com MCP pode ler e escrever a memória de linguagem. Peça ao seu assistente de codificação para "atualizar a terminologia com o novo nome do produto" ou "definir o tom de voz como profissional para a localidade alemã" e ele traduza sua intenção na chamada da API correta.

## Refinamento progressivo

\-- A memória de linguagem melhora com o uso. Cada vez que um revisor corrige a saída de um agente, essa correção retroalimenta a próxima versão da sua voz ou terminologia. Com o tempo, a distância entre o primeiro rascunho e a saída final diminui, e o passo de revisão torna-se mais rápido.

Este é o ciclo de feedback no centro do Glossia: gerar, revisar, refinar o contexto, gerar novamente. Os agentes não apenas seguem instruções. Eles trabalham com contexto que melhora a cada ciclo.