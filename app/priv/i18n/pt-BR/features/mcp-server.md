%{
  title: "Servidor MCP",
  summary:
    "Conecte agentes de IA e assistentes de programação ao Glossia pelo Model Context Protocol. Gerencie vozes, terminologia, organizações e muito mais usando linguagem natural de qualquer cliente compatível com MCP.",
  order: 3,
  icon: "cpu",
  hero_cta_text: "Começar",
  hero_cta_url: "/signup",
  highlights: [
    %{
      title: "Interface de linguagem natural",
      description:
        "Interaja com o motor linguístico do Glossia por meio de texto simples. Agentes de IA chamam ferramentas MCP para gerenciar vozes, terminologia e organizações sem precisar escrever código.",
      icon: "message-square-text"
    },
    %{
      title: "Conecte-se a qualquer agente",
      description:
        "Funciona com Claude, Cursor, Windsurf e qualquer cliente compatível com MCP. Adicione o servidor Glossia ao seu fluxo de trabalho com agentes existente e comece a usá-lo imediatamente.",
      icon: "puzzle"
    },
    %{
      title: "Seguro por padrão",
      description:
        "Cada solicitação MCP é autenticada com tokens OAuth 2.1 bearer e autorizada segundo escopos granulares. O mesmo modelo de segurança da API REST.",
      icon: "shield-check"
    }
  ]
}
---
## O que é MCP?

O [Protocolo de Contexto do Modelo](https://modelcontextprotocol.io) é um padrão aberto para conectar assistentes de IA a ferramentas e fontes de dados externas. Em vez de criar integrações personalizadas para cada assistente de codificação, você expõe um único servidor MCP e qualquer cliente compatível pode usá-lo.

O servidor MCP do Glossia dá aos agentes acesso direto ao núcleo linguístico da plataforma: configuração de voz, gestão de terminologia, administração de organizações e listagem de projetos.

## Ferramentas disponíveis

O servidor MCP expõe 16 ferramentas organizadas em torno dos recursos com os quais você trabalha diariamente. Veja o [referência completa de ferramentas](/docs/reference/mcp/tools) para detalhes de parâmetros e uso.

**Contas e organizações** -- Liste suas contas, crie e gerencie organizações, convide membros e controle o acesso. Agentes podem configurar estruturas inteiras de equipe por meio de conversação.

**Configuração de voz** -- Leia e atualize configurações de voz que controlam como o Glossia gera e revisa conteúdo. Ajuste tom, formalidade, público-alvo e sobrescritas por local sem sair do editor.

**Gestão de terminologia** -- Mantenha a consistência terminológica em todo o seu conteúdo. Adicione, atualize e versionize entradas de terminologia para que os agentes sempre usem os termos corretos.

**Projetos** -- Listar e inspecionar projetos de várias organizações.

## Como funciona

Aponte seu cliente MCP para `https://your-glossia-instance/mcp` e autentique com um token de portador OAuth. O [Guia de configuração do MCP](/docs/reference/mcp/overview) descreve o fluxo completo de conexão, incluindo registro dinâmico do cliente e PKCE. O [REST API](/features/rest-api), então qualquer token que funcione para a API também funciona para o MCP.

A partir daqui, seu assistente de IA pode invocar qualquer uma das 16 ferramentas. Peça para ele "criar uma organização chamada Acme" ou "atualizar meu tom de voz para profissional" e o agente traduzirá sua intenção na chamada correta da ferramenta.

## Construído para fluxos de trabalho de agentes

O MCP não é apenas uma camada de conveniência. É a base para compor o Glossia em pipelines de agentes maiores. Um assistente de programação pode ler sua base de código, detectar conteúdo não localizado, atualizar a terminologia com novos termos, ajustar configurações de voz para um local específico e acionar uma execução de localização, tudo em uma única conversa.

Como o protocolo é padronizado, você não fica preso a nenhum cliente único. Alterne entre o Claude, o Cursor ou seu próprio agente personalizado sem alterar uma única linha de configuração.