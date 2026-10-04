%{
  title: "Memória de Linguagem",
  summary:
    "Uma camada de contexto versionada que captura a voz, o glossário e o estilo da sua organização. A Memória de Linguagem guia cada fluxo de agente e se estende às suas próprias ferramentas via API e MCP.",
  order: 5,
  icon: "Cérebro",
  hero_cta_text: "Começar agora",
  hero_cta_url: "/signup",
  highlights: [
    %{
      title: "Versionado e auditável",
      description:
        "Toda alteração na sua voz ou no glossário cria uma nova versão imutável. Você pode revisar o histórico, comparar iterações e reverter caso haja deriva.",
      icon: "Ramo Git"
    },
    %{
      title: "Além da localização",
      description:
        "A Memória de Linguagem não é apenas para localização. Use-a para gerar texto de marketing, rascunhar documentação, revisar pull requests ou criar posts sociais, tudo na voz da sua organização.",
      icon: "Megafone"
    },
    %{
      title: "Aberto e extensível",
      description:
        "Acesse a Memória de Linguagem através da API REST ou servidor MCP. Alimente-o nos seus próprios pipelines CI, ferramentas de conteúdo ou agentes personalizados para manter a consistência onde você escreve.",
      icon: "Quebra-cabeça"
    }
  ]
}
---
## O que é memória de linguagem?

A memória de linguagem é o contexto acumulado que indica aos agentes do Glossia como sua organização se comunica. Ela é composta por dois primitivos principais que você cria e refina com o tempo:

**Voz** define como o conteúdo deve soar. Tom, formalidade, público-alvo e diretrizes livres vivem aqui. Você pode definir uma voz base para sua conta e, em seguida, sobrescrever campos específicos para locais individuais, para que seu conteúdo em japonês possa ser mais formal enquanto seu conteúdo em inglês permaneça conversacional.

**Glossário** define o que os termos significam e como devem ser localizados. Cada entrada carrega uma definição e traduções locais específicas. Quando um agente encontra "workspace" no seu conteúdo de origem, o glossário informa se deve localizar, transliterar ou deixar inalterado, e exatamente qual palavra usar em cada idioma de destino.

Juntos, voz e glossário formam uma camada de contexto que os agentes consultam em cada execução. Quanto mais você investe nessa camada, menos revisão o resultado precisa.

## Versionamento imutável

A memória linguística é de apenas adição. Quando você atualiza sua voz ou glossário, o Glossia cria uma nova versão em vez de sobrescrever a anterior. Cada versão registra quem a criou, quando, e uma nota de mudança opcional explicando o que evoluiu.

Isso significa que você sempre tem um registro completo de auditoria. Você pode comparar a versão 3 com a versão 7 para entender como seu tom mudou em um trimestre. Se uma mudança recente introduziu inconsistências, reverta para uma versão anterior e continue.

O versionamento também torna a colaboração mais segura. Membros da equipe podem propor mudanças na voz sem se preocupar com conflitos, porque cada mudança é um evento discreto e rastreável.

## Resolução consciente de local

Quando um agente executa um fluxo de trabalho para um local específico, o Glossia resolve a memória linguística para aquele contexto. Começa com suas configurações básicas de voz e aplica então qualquer sobrescrita específica do local por cima. O mesmo acontece com o glossário: apenas entradas que possuem um termo localizado para o local-alvo são incluídas.

Essa etapa de resolução significa que os agentes sempre trabalham com o contexto mais relevante. Não é necessário manter configurações separadas por idioma. Defina seus padrões uma vez, substitua onde importa e deixe o sistema de resolução cuidar do resto.

## Use-o em todos os lugares

A memória linguística foi projetada para localização, mas é útil em qualquer lugar onde você produza texto. Porque o contexto é acessível através do [REST API](/features/rest-api) e o [servidor MCP](/features/mcp-server), você pode integrá-lo a fluxos de trabalho além da localização:

**Marketing e conteúdo social** -- Transforme a voz da sua organização em um agente de conteúdo que redige publicações em redes sociais, campanhas de e-mail ou textos para páginas de destino. O Glossário mantém os termos de marca consistentes e as configurações de voz garantem que o tom corresponda à sua marca.

**Documentação** -- Alimente a memória linguística em um pipeline de documentação para que a escrita técnica siga as mesmas regras de estilo que o restante do seu conteúdo. As entradas do Glossário evitam a divergência entre documentos, artigos de ajuda e os textos do produto.

**Revisão de código** -- Crie um agente que revise o texto do pull request (mensagens de erro, rótulos de interface, textos de onboarding) contra sua voz e glossário. Sinalize inconsistências antes que sejam publicadas.

**Agentes personalizados** -- Qualquer cliente compatível com o MCP pode ler e escrever memória de linguagem. Peça ao seu assistente de programação para "atualizar o glossário com o novo nome do produto" ou "ajustar o tom de voz para profissional na localização alemã" e ele traduzirá sua intenção na chamada de API correta.

## Refinamento progressivo

A memória de linguagem melhora com o uso. Cada vez que um revisor corrige a saída de um agente, essa correção é retroalimentada na próxima versão da sua voz ou glossário. Com o tempo, a distância entre o primeiro rascunho e a saída final diminui, e a etapa de revisão se torna mais ágil.

Este é o ciclo de feedback no coração do Glossia: gerar, revisar, refinar contexto, gerar novamente. Os agentes não apenas seguem instruções. Eles trabalham com contexto que melhora a cada ciclo.