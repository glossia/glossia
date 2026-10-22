%{
  title: "Memória de Linguagem",
  summary:
    "Uma camada de contexto versionada que captura a voz, glossário e estilo da sua organização. A memória de linguagem guia cada fluxo de trabalho de agente e se estende às suas próprias ferramentas através da API e MCP.",
  order: 5,
  icon: "brain",
  hero_cta_text: "Começar agora",
  hero_cta_url: "/signup",
  highlights: [
    %{
      title: "Versionado e auditável",
      description:
        "Cada mudança na sua voz ou glossário cria uma nova versão imutável. Você pode revisar o histórico, comparar iterações e reverter se algo desviar.",
      icon: "git-branch"
    },
    %{
      title: "Além da localização",
      description:
        "A memória de linguagem não é apenas para localização. Use-a para gerar textos de marketing, rascunhar documentação, revisar pull requests ou criar posts sociais, tudo na voz da sua organização.",
      icon: "megaphone"
    },
    %{
      title: "Aberto e extensível",
      description:
        "Acesse a memória de linguagem pela API REST ou servidor MCP. Alimente-o em seus próprios pipelines de CI, ferramentas de conteúdo ou agentes personalizados para manter a consistência em todos os lugares onde você escreve.",
      icon: "puzzle"
    }
  ]
}
---

## O que é memória de linguagem?

A memória de linguagem é o contexto acumulado que diz aos agentes do Glossia como sua organização se comunica. Ela é composta por dois primitivos centrais que você cria e refinam ao longo do tempo:

**Voz** define como o conteúdo deve soar. Tom, formalidade, público-alvo e diretrizes livres vivem aqui. Você pode definir uma voz básica para sua conta e depois sobrescrever campos específicos para locais individuais, para que seu texto em japonês possa ser mais formal enquanto seu texto em inglês permaneça conversacional.

**Glossário** define o que significam os termos e como eles devem ser localizados. Cada entrada carrega uma definição e traduções por local. Quando um agente encontra "workspace" no seu conteúdo de origem, o glossário informa se ele deve localizar, transliterar ou deixar o termo inalterado, e exatamente qual palavra usar em cada língua de destino.

Juntos, voz e glossário formam uma camada de contexto que os agentes consultam a cada execução. Quanto mais você investir nessa camada, menos revisão seu resultado precisa.

## Versionamento imutável

A memória de linguagem é de apenas adição. Quando você atualiza sua voz ou glossário, o Glossia cria uma nova versão em vez de sobrescrever a antiga. Cada versão registra quem a criou, quando e uma nota de mudança opcional explicando o que evoluiu.

Isso significa que você sempre terá um rastro de auditoria completo. Você pode comparar a versão 3 contra a versão 7 para entender como seu tom mudou em um trimestre. Se uma mudança recente introduzisse inconsistências, reverta para uma versão anterior e continue.

O versionamento também torna a colaboração mais segura. Múltiplos membros da equipe podem propor alterações de voz sem se preocupar com conflitos, porque cada mudança é um evento discreto e rastreável.

## Resolução baseada no local

Quando um agente executa um fluxo de trabalho para um local específico, o Glossia resolve a memória de linguagem para esse contexto. Ele começa com suas configurações de voz base e depois aplica quaisquer atualizações específicas do local por cima. O mesmo acontece com o glossário: apenas as entradas que têm um termo localizado para o local de destino são incluídas.

Essa etapa de resolução significa que os agentes sempre trabalham com o contexto mais relevante. Você não precisa manter configurações separadas por idioma. Defina seus padrões uma vez, sobrescreva onde importa e deixe o sistema de resolução tratar o resto.

## Use em qualquer lugar

A memória de linguagem foi projetada para localização, mas é útil em qualquer lugar onde você produza texto. Como o contexto é acessível através do [REST API](/features/rest-api) e do [MCP server](/features/mcp-server), você pode integrá-lo a fluxos de trabalho além da localização:

**Marketing e conteúdo para redes sociais** -- Arraste a voz da sua organização para um agente de conteúdo que redija postagens de mídia social, campanhas de e-mail ou peças de texto para páginas de destino. O glossário mantém os termos da marca consistentes e as configurações de voz garantem que o tom corresponda à sua marca.

**Documentação** -- Alimente a memória de linguagem em um pipeline de documentação para que a escrita técnica siga as mesmas regras de estilo do resto do seu conteúdo. As entradas do glossário impedem desvios entre documentos, artigos de ajuda e textos no produto.

**Revisão de código** -- Crie um agente que revise o texto de solicitações de pull request (mensagens de erro, rótulos de UI, textos de integração) em relação à sua voz e glossário. Marque inconsistências antes que sejam lançadas.

**Agentes personalizados** -- Qualquer cliente compatível com MCP pode ler e escrever memória de linguagem. Peça ao seu assistente de codificação para "atualizar o glossário com o novo nome do produto" ou "definir o tom da voz para profissional para o local alemão" e ele traduzirá sua intenção na chamada de API correta.

## Refinamento progressivo

A memória de linguagem melhora com o uso. Toda vez que um revisor corrige a saída de um agente, essa correção é alimentada de volta para a próxima versão da sua voz ou glossário. Com o tempo, o espaço entre o primeiro rascunho e a saída final se estreita, e a etapa de revisão se torna mais rápida.

Isso é o ciclo de feedback no centro do Glossia: gerar, revisar, refinar contexto, gerar novamente. Os agentes não apenas seguem instruções. Eles trabalham com um contexto que melhora a cada ciclo.
