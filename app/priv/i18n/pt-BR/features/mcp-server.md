%{
  title: "Servidor MCP",
  summary:
    "Conecte agentes de IA e assistentes de codificação ao Glossia através do Protocolo de Contexto do Modelo. Gerencie vozes, glossários, organizações e muito mais usando linguagem natural de qualquer cliente compatível com MCP.",
  order: 3,
  icon: "cpu",
  hero_cta_text: "Começar agora",
  hero_cta_url: "/signup",
  highlights: [
    %{
      title: "Interface de linguagem natural",
      description:
        "Interaja com o motor linguístico do Glossia através de texto simples. Os agentes de IA chamam ferramentas MCP para gerenciar vozes, glossários e organizações sem escrever código.",
      icon: "message-square-text"
    },
    %{
      title: "Conecte-se a qualquer agente",
      description:
        "Funciona com Claude, Cursor, Windsurf e qualquer cliente compatível com MCP. Adicione o servidor Glossia ao seu fluxo de trabalho existente e comece a utilizá-lo imediatamente.",
      icon: "puzzle"
    },
    %{
      title: "Seguro por padrão",
      description:
        "Todas as requisições MCP são autenticadas com tokens OAuth 2.1 Bearer e autorizadas contra escopos granulares. O mesmo modelo de segurança da API REST.",
      icon: "shield-check"
    }
  ]
}
---
## O que é o MCP?

O [Model Context Protocol](https://modelcontextprotocol.io) é um padrão aberto para conectar assistentes de IA a ferramentas e fontes de dados externas. Em vez de criar integrações personalizadas para cada assistente de programação, você expõe um único servidor MCP e qualquer cliente compatível pode utilizá-lo.

O servidor MCP do Glossia oferece aos agentes acesso direto ao núcleo linguístico da plataforma: configuração de voz, gerenciamento de glossário, administração de organizações e listagem de projetos.

## Ferramentas disponíveis

O servidor MCP expõe 16 ferramentas organizadas em torno dos recursos com os quais você trabalha diariamente. Veja a [referência completa de ferramentas](/docs/reference/mcp/tools) para parâmetros e detalhes de uso.

**Contas e organizações** -- Liste suas contas, crie e gerencie organizações, convide membros e controle o acesso. Agentes podem configurar toda a estrutura da equipe por meio de conversa.

**Configuração de voz** -- Leia e atualize as configurações de voz que controlam como o Glossia gera e revisa conteúdo. Ajuste tom, formalidade, público-alvo e ajustes por locale sem sair do seu editor.

**Gerenciamento de glossário** -- Mantenha a consistência do glossário em todo o seu conteúdo. Adicione, atualize e versione entradas de glossário para que os agentes sempre usem os termos corretos.

**Projetos** -- Liste e inspecione projetos em todas as organizações.

## Como funciona

Aponte seu cliente MCP para `https://your-glossia-instance/mcp` e autentique com um token bearer OAuth. O [guia de configuração MCP](/docs/reference/mcp/overview) percorre o fluxo completo de conexão, incluindo registro dinâmico do cliente e PKCE. O servidor usa o mesmo sistema de autenticação e autorização que o [REST API](/features/rest-api), então qualquer token que funcione para a API também funciona para o MCP.

A partir de aí, seu assistente de IA pode chamar qualquer uma das 16 ferramentas. Peça para ele "criar uma organização chamada Acme" ou "atualizar meu tom de voz para profissional" e o agente traduz sua intenção na chamada correta da ferramenta.

## Construído para fluxos de trabalho agênticos

MCP não é apenas uma camada de conveniência. É a base para integrar a Glossia em pipelines agênticos maiores. Um assistente de codificação pode ler sua base de código, detectar conteúdo não localizado, atualizar o glossário com novos termos, ajustar configurações de voz para uma localização específica e acionar uma execução de localização, tudo em uma única conversa.

Como o protocolo é padronizado, você não fica preso a nenhum único cliente. Alterne entre Claude, Cursor ou seu próprio agente personalizado sem modificar uma linha de configuração.