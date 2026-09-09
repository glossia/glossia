%{
  title: "Servidor MCP",
  summary:
    "Conecte agentes de IA e assistentes de codificação ao Glossia por meio do Protocolo de Contexto de Modelo. Gerencie vozes, terminologia, organizações e muito mais usando linguagem natural de qualquer cliente compatível com MCP.",
  order: 3,
  icon: "cpu",
  hero_cta_text: "Começar",
  hero_cta_url: "/signup",
  highlights: [
    %{
      title: "Interface de linguagem natural",
      description:
        "Interaja com o motor linguístico do Glossia por meio de texto simples. Agentes de IA invocam ferramentas MCP para gerenciar vozes, terminologia e organizações sem escrever código.",
      icon: "message-square-text"
    },
    %{
      title: "Conecte-se a qualquer agente",
      description:
        "Funciona com Claude, Cursor, Windsurf e qualquer cliente compatível com MCP. Adicione o servidor do Glossia ao seu fluxo de trabalho agênico existente e comece a utilizá-lo imediatamente.",
      icon: "puzzle"
    },
    %{
      title: "Seguro por padrão",
      description:
        "Cada solicitação MCP é autenticada com tokens Bearer OAuth 2.1 e autorizada contra escopos granulares. O mesmo modelo de segurança da API REST.",
      icon: "shield-check"
    }
  ]
}
---
## O que é MCP?

O [Protocolo de Contexto do Modelo](https://modelcontextprotocol.io) é um padrão aberto para conectar assistentes de IA a ferramentas e fontes de dados externas. Em vez de criar integrações personalizadas para cada assistente de codificação, você expõe um único servidor MCP e qualquer cliente compatível pode usá-lo.

O servidor MCP da Glossia dá aos agentes acesso direto ao núcleo linguístico da plataforma: configuração de voz, gerenciamento de terminologia, administração da organização e listagem de projetos.

## Ferramentas disponíveis

O servidor MCP expõe 16 ferramentas organizadas em torno dos recursos com os quais você trabalha diariamente. Veja o [referência completa de ferramentas](/docs/reference/mcp/tools) para parâmetros e detalhes de uso.

**Contas e organizações** -- Liste suas contas, crie e gerencie organizações, convide membros e controle o acesso. Os agentes podem configurar toda a estrutura da equipe por meio de conversa.

**Configuração de voz** -- Leia e atualize as configurações de voz que controlam como o Glossia gera e revisa conteúdo. Ajuste o tom, a formalidade, o público-alvo e as sobreposições por localização sem sair do seu editor.

**Gestão de terminologia** -- Mantenha a consistência terminológica em todo o seu conteúdo. Adicione, atualize e versione entradas terminológicas para que os agentes sempre usem os termos corretos.

**Projetos** -- Listar e inspecionar projetos entre organizações.

## Como funciona

Aponte seu cliente MCP para `https://your-glossia-instance/mcp` e autentique-se com um token bearer OAuth. O [guia de configuração do MCP](/docs/reference/mcp/overview) passa pelo fluxo de conexão completo, incluindo o registro dinâmico de clientes e PKCE. O [REST API](/features/rest-api), então qualquer token que funcione na API também funciona para o MCP.

A partir de aí, seu assistente de IA pode chamar qualquer uma das 16 ferramentas. Peça para que ele "crie uma organização chamada Acme" ou "atualize o tom da minha voz para profissional" e o agente traduz sua intenção na chamada de ferramenta correta.

## Construído para fluxos de trabalho de agentes

O MCP não é apenas uma camada de conveniência. É a base para compor o Glossia em pipelines maiores de agentes. Um assistente de programação pode ler sua base de código, detectar conteúdo não localizado, atualizar a terminologia com novos termos, ajustar as configurações de voz para uma localidade específica e acionar uma execução de localização, tudo em uma única conversa.

Como o protocolo é padronizado, você não está preso a nenhum cliente único. Troque entre o Claude, o Cursor ou o seu próprio agente personalizado sem alterar uma linha de configuração.