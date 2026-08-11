%{
  title: "Memória linguística",
  summary: "Uma camada de contexto versionada que registra a voz, a terminologia e o estilo da sua organização. A memória linguística orienta todos os fluxos de trabalho dos agentes e se estende às suas próprias ferramentas por meio da API e do MCP.",
  order: 5,
  icon: "brain",
  hero_cta_text: "Começar",
  hero_cta_url: "/signup",
  highlights: [
    %{title: "Versionada e auditável", description: "Cada alteração na voz ou na terminologia cria uma nova versão imutável. Você pode consultar o histórico, comparar iterações e reverter caso haja algum desvio.", icon: "git-branch"},
    %{title: "Além da localização", description: "A memória linguística não se limita à localização. Use-a para gerar textos de marketing, redigir documentação, revisar pull requests ou criar publicações para redes sociais, sempre com a voz da sua organização.", icon: "megaphone"},
    %{title: "Aberta e extensível", description: "Acesse a memória linguística por meio da API REST ou do servidor MCP. Integre-a aos seus próprios pipelines de CI, às ferramentas de conteúdo ou aos agentes personalizados para manter a consistência em todos os seus textos.", icon: "puzzle"}
  ]
}
---
## O que é memória linguística?

Memória linguística é o contexto acumulado que orienta os agentes da Glossia sobre como sua organização se comunica. Ela é composta por dois elementos fundamentais que você cria e aprimora ao longo do tempo:

**Voz** define como o conteúdo deve soar. Tom, formalidade, público-alvo e diretrizes em formato livre ficam todos registrados aqui. Você pode definir uma voz-base para sua conta e substituir campos específicos para cada localidade. Assim, seu conteúdo em japonês pode ser mais formal, enquanto o conteúdo em inglês permanece conversacional.

**Terminologia** define o significado dos termos e como eles devem ser localizados. Cada entrada contém uma definição e traduções específicas por localidade. Quando um agente encontra "workspace" no conteúdo de origem, a terminologia informa se o termo deve ser localizado, transliterado ou mantido sem alterações, além de indicar exatamente qual palavra usar em cada idioma de destino.

Juntas, voz e terminologia formam uma camada de contexto que os agentes consultam em cada execução. Quanto mais você investir nessa camada, menos revisão será necessária para o conteúdo gerado.

## Versionamento imutável

A memória linguística funciona somente por acréscimo. Quando você atualiza sua voz ou terminologia, a Glossia cria uma nova versão em vez de substituir a anterior. Cada versão registra quem a criou, quando ela foi criada e uma nota de alteração opcional que explica o que mudou.

Isso significa que você sempre terá uma trilha de auditoria completa. É possível comparar a versão 3 com a versão 7 para entender como o tom mudou ao longo de um trimestre. Se uma alteração recente introduzir inconsistências, restaure uma versão anterior e prossiga.

O versionamento também torna a colaboração mais segura. Vários integrantes da equipe podem propor alterações de voz sem se preocupar com conflitos, pois cada mudança é um evento independente e rastreável.

## Resolução ciente da localidade

Quando um agente executa um fluxo de trabalho para uma localidade específica, a Glossia resolve a memória linguística correspondente a esse contexto. Primeiro, ela utiliza as configurações da voz-base e, em seguida, aplica as substituições específicas da localidade. O mesmo ocorre com a terminologia: somente as entradas que possuem um termo localizado para a localidade de destino são incluídas.

Essa etapa de resolução garante que os agentes sempre trabalhem com o contexto mais relevante. Você não precisa manter configurações separadas para cada idioma. Defina os padrões uma vez, substitua-os onde for necessário e deixe que o sistema de resolução cuide do restante.

## Use em qualquer lugar

A memória linguística foi projetada para localização, mas é útil em qualquer processo de produção de texto. Como o contexto pode ser acessado pela [API REST](/features/rest-api) e pelo [servidor MCP](/features/mcp-server), você pode integrá-lo a fluxos de trabalho que vão além da localização:

**Conteúdo de marketing e para redes sociais**: incorpore a voz da sua organização a um agente de conteúdo que redija publicações para redes sociais, campanhas de e-mail ou textos para páginas de destino. A terminologia mantém a consistência dos termos da marca, enquanto as configurações de voz garantem que o tom esteja alinhado à marca.

**Documentação**: forneça a memória linguística a um pipeline de documentação para que a redação técnica siga as mesmas regras de estilo do restante do conteúdo. As entradas de terminologia evitam divergências entre documentos, artigos de ajuda e textos exibidos no produto.

**Revisão de código**: crie um agente que verifique os textos de solicitações de pull, como mensagens de erro, rótulos da interface e textos de integração, em relação à sua voz e terminologia. Sinalize inconsistências antes da publicação.

**Agentes personalizados**: qualquer cliente compatível com MCP pode ler e gravar a memória linguística. Peça ao seu assistente de programação para "atualizar a terminologia com o novo nome do produto" ou "definir o tom da voz como profissional para a localidade alemã", e ele converterá sua intenção na chamada apropriada à API.

## Aprimoramento progressivo

A memória linguística melhora com o uso. Sempre que um revisor corrige o conteúdo gerado por um agente, essa correção é incorporada à próxima versão da voz ou terminologia. Com o tempo, a diferença entre o primeiro rascunho e o resultado final diminui, e a etapa de revisão se torna mais rápida.

Este é o ciclo de feedback no centro do Glossia: gerar, revisar, refinar o contexto e gerar novamente. Os agentes não apenas seguem instruções. Eles trabalham com um contexto que melhora a cada ciclo.