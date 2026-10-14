%{
  title: "Servidor MCP",
  summary:
    "Conecte agentes de IA e assistentes de codificação ao Glossia através do Protocolo de Contexto de Modelo. Gerencie vozes, glossários, organizações e muito mais usando linguagem natural a partir de qualquer cliente compatível com MCP.",
  order: 3,
  icon: "cpu",
  hero_cta_text: "Começar agora",
  hero_cta_url: "/signup",
  highlights: [
    %{
      title: "Interface de linguagem natural",
      description:
        "Interaja com o motor linguístico do Glossia via texto simples. Agentes de IA chamam ferramentas MCP para gerenciar vozes, glossários e organizações sem escrever código.",
      icon: "message-square-text"
    },
    %{
      title: "Conecte-se a qualquer agente",
      description:
        "Funciona com o Claude, Cursor, Windsurf e qualquer cliente compatível com MCP. Integre o servidor Glossia ao seu fluxo de trabalho de agentes existente e comece a usá-lo imediatamente.",
      icon: "puzzle"
    },
    %{
      title: "Seguro por padrão",
      description:
        "Cada requisição MCP é autenticada com tokens Bearer OAuth 2.1 e autorizada com escopos granulares. O mesmo modelo de segurança da API REST.",
      icon: "shield-check"
    }
  ]
}
---

## O que é o MCP?

O [Model Context Protocol](https://modelcontextprotocol.io) é um padrão aberto para conectar assistentes de IA a ferramentas e fontes de dados externas. Em vez de criar integrações personalizadas para cada assistente de código, você expõe um único servidor MCP e qualquer cliente compatível pode usá-lo.

O servidor MCP do Glossia dá aos agentes acesso direto ao núcleo linguístico da plataforma: configuração de voz, gestão de glossário, administração de organização e listagem de projetos.

## Ferramentas disponíveis

O servidor MCP expõe 16 ferramentas organizadas em torno dos recursos com os quais você trabalha diariamente. Consulte a [referência completa de ferramentas](/docs/reference/mcp/tools) para parâmetros e detalhes de uso.

**Contas e organizações** -- Liste suas contas, crie e gerencie organizações, convide membros e controle o acesso. Os agentes podem configurar estruturas inteiras de equipes por meio de conversação.

**Configuração de voz** -- Leia e atualize configurações de voz que controlam como o Glossia gera e revisa conteúdo. Ajuste tom, formalidade, público-alvo e sobrescrições por localização sem sair do seu editor.

**Gestão de glossário** -- Mantenha a consistência do glossário em todo o seu conteúdo. Adicione, atualize e versionamento de entradas de glossário para que os agentes sempre usem os termos corretos.

**Projetos** -- Liste e inspecione projetos entre organizações.

## Como funciona

Aponte seu cliente MCP para `https://your-glossia-instance/mcp` e autentique-se com um token de acesso OAuth. O [Guia de configuração do MCP](/docs/reference/mcp/overview) descreve o fluxo completo de conexão, incluindo o registro dinâmico de clientes e o PKCE. O servidor usa o mesmo sistema de autenticação e autorização que o [API REST](/features/rest-api), de modo que qualquer token que funcione para a API também funciona para o MCP.

A partir daí, seu assistente de IA pode invocar qualquer uma das 16 ferramentas. Peça para "criar uma organização chamada Acme" ou "atualizar meu tom de voz para profissional" e o agente traduz sua intenção na chamada de ferramenta correta.

## Construído para fluxos de trabalho agênticos

O MCP não é apenas uma camada de conveniência. É a base para compor o Glossia em pipelines agênticos maiores. Um assistente de código pode ler seu codebase, detectar conteúdo não localizado, atualizar o glossário com novos termos, ajustar configurações de voz para uma localização específica e disparar uma execução de localização, tudo em uma única conversação.

Como o protocolo é padronizado, você não fica preso a nenhum cliente específico. Alterne entre o Claude, o Cursor ou o próprio agente personalizado sem alterar uma linha de configuração.
