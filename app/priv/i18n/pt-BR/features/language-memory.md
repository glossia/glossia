%{
  title: "Memória de linguagem",
  summary:
    "Uma camada de contexto versionada que captura a voz, terminologia e estilo da sua organização. A memória de linguagem guia todo o fluxo de trabalho do agente e estende-se até suas próprias ferramentas através da API e do MCP",
  order: 5,
  icon: "brain",
  hero_cta_text: "Começar agora",
  hero_cta_url: "/signup",
  highlights: [
    %{
      title: "Versionado e auditável",
      description:
        "Todas as alterações na sua voz ou terminologia criam uma nova versão imutável. Você pode revisar o histórico, comparar iterações e reverter se algo se desviar.",
      icon: "git-branch"
    },
    %{
      title: "Além da localização",
      description:
        "A memória de linguagem não é apenas para localização. Use-a para gerar copy de marketing, rascunhar documentação, revisar pull requests ou criar posts sociais, tudo na voz da sua organização.",
      icon: "megaphone"
    },
    %{
      title: "Aberto e extensível",
      description:
        "Acesse a memória de linguagem através da API REST ou servidor MCP. Alimente-a em seus próprios pipelines de CI, ferramentas de conteúdo ou agentes personalizados para manter a consistência em todo o lugar onde você escreve.",
      icon: "puzzle"
    }
  ]
}
---
## O que é memória de idioma?

A memória de idioma é o contexto acumulado que informa os agentes do Glossia sobre como sua organização se comunica. Ela é composta por dois primitivos centrais que você cria e refina ao longo do tempo:

**Voz** define como o conteúdo deve soar. Tom, formalidade, público-alvo e diretrizes livres constam aqui. Você pode definir uma voz base para sua conta e, em seguida, sobrescrever campos específicos para localizações individuais, de modo que seu texto em japonês possa ser mais formal enquanto seu texto em inglês permanece conversacional.

**Terminologia** define o que os termos significam e como eles devem ser localizados. Cada entrada possui uma definição e traduções por local. Quando um agente encontra o "área de trabalho" em seu conteúdo de origem, a terminologia informa ao agente se deve localizar, transliterar ou deixá-lo como está, e exatamente qual palavra usar em cada idioma de destino.

Juntos, voz e terminologia formam uma camada de contexto que os agentes consultam em cada execução. Quanto mais você investir nessa camada, menos revisão seu resultado precisa.

## Versionamento imutável

A memória de idioma é apenas de adição. Quando você atualiza sua voz ou terminologia, o Glossia cria uma nova versão em vez de sobrescrever a antiga. Cada versão registra quem a criou, quando e uma nota de mudança opcional explicando o que evoluiu.

Isso significa que você sempre tem um histórico completo de auditoria. Você pode comparar a versão 3 com a versão 7 para entender como seu tom mudou ao longo de um trimestre. Se uma mudança recente introduziu inconsistências, retorne para uma versão anterior e continue.

O versionamento também torna a colaboração mais segura. Vários membros da equipe podem propor mudanças de voz sem se preocupar com conflitos, porque cada mudança é um evento discreto e rastreável.

## Resolução baseada na localização

Quando um agente executa um fluxo de trabalho para uma localização específica, o Glossia resolve a memória de idioma para esse contexto. Ele começa com suas configurações de voz base e depois aplica quaisquer sobrescritas específicas da localização por cima. O mesmo ocorre com a terminologia: apenas as entradas que possuem um termo localizado para a localização alvo são incluídas.

Este passo de resolução significa que os agentes sempre trabalham com o contexto mais relevante. Você não precisa manter configurações separadas por idioma. Defina seus valores padrão uma vez, sobrescreva onde importa e deixe o sistema de resolução cuidar do resto.

## Use em qualquer lugar

A memória de idioma foi projetada para localização, mas é útil em qualquer lugar onde você produza texto. Porque o contexto é acessível através do [REST API](/features/rest-api) e o [servidor MCP](/features/mcp-server), você pode integrá-lo a workflows além da localização:

**Marketing e conteúdo social** -- Incorpore a voz da sua organização em um agente de conteúdo que redige postagens de mídia social, campanhas de e-mail ou textos para páginas de destino. A Terminologia mantém os termos da marca consistentes e as configurações de voz garantem que o tom corresponda à sua marca.

**Documentação** -- Alimente a memória de linguagem em um pipeline de documentação para que a redação técnica siga as mesmas regras de estilo que o resto do seu conteúdo. As entradas de Terminologia impedem a deriva em documentos, artigos de ajuda e textos do produto.

**Revisão de código** -- Crie um agente que revise o conteúdo do pull request (mensagens de erro, rótulos de interface, texto de onboarding) com base na sua voz e terminologia. Sinalize inconsistências antes de lançar.

**Agentes personalizados** -- Qualquer cliente compatível com MCP pode ler e escrever na memória de linguagem. Peça ao seu assistente de programação para "atualizar a terminologia com o novo nome do produto" ou "definir o tom de voz como profissional para a localização alemã" e ele traduzirá sua intenção na chamada de API correta.

## Refinamento progressivo

A memória de linguagem melhora com o uso. Cada vez que um revisor corrige a saída de um agente, essa correção retroalimenta a próxima versão da sua voz ou terminologia. Com o tempo, a lacuna entre o primeiro rascunho e a saída final diminui, e a etapa de revisão torna-se mais rápida.

Este é o ciclo de feedback no coração de Glossia: gerar, revisar, refinar contexto, gerar novamente. Os agentes não seguem apenas instruções. Eles trabalham com contexto que melhora a cada ciclo.