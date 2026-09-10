%{
  title: "Servidor MCP",
  summary:
    "Conecte agentes de IA e assistentes de codificação ao Glossia por meio do Protocolo de Contexto de Modelo. Gerencie vozes, terminologia, organizações e muito mais usando linguagem natural de qualquer cliente compatível com o MCP.",
  order: 3,
  icon: "cpu",
  hero_cta_text: "Começar",
  hero_cta_url: "/signup",
  highlights: [
    %{
      title: "Interface de linguagem natural",
      description:
        "Interaja com o motor linguístico do Glossia por meio de texto simples. Agentes de IA chamam ferramentas MCP para gerenciar vozes, terminologia e organizações sem escrever código.",
      icon: "message-square-text"
    },
    %{
      title: "Conecte-se a qualquer agente",
      description:
        "Funciona com Claude, Cursor, Windsurf e qualquer cliente compatível com o MCP. Insira o servidor do Glossia no seu fluxo de trabalho existente com agentes e comece a usá-lo imediatamente.",
      icon: "puzzle"
    },
    %{
      title: "Seguro por padrão",
      description:
        "Cada solicitação MCP é autenticada com tokens OAuth 2.1 Bearer e autorizada contra escopos granulares. O mesmo modelo de segurança que o REST API.",
      icon: "shield-check"
    }
  ]
}
---
## O que é o MCP?

O [Protocolo de Contexto do Modelo](https://modelcontextprotocol.io) é um padrão aberto para conectar assistentes de IA a ferramentas e fontes de dados externas. Em vez de criar integrações personalizadas para cada assistente de código, você expõe um único servidor MCP e qualquer cliente compatível pode utilizá-lo.

O servidor MCP da Glossia oferece aos agentes acesso direto ao núcleo linguístico da plataforma: configuração de voz, gestão de terminologia, administração da organização e listagem de projetos.

## Ferramentas disponíveis

O servidor MCP expõe 16 ferramentas organizadas em torno dos recursos com os quais você trabalha diariamente. Veja a [referência completa de ferramentas](/docs/reference/mcp/tools) para parâmetros e detalhes de uso.

**Contas e organizações** -- Liste suas contas, crie e gerencie organizações, convide membros e controle o acesso. Os agentes podem configurar toda a estrutura da equipe através da conversa.

**Configuração de voz** -- Leia e atualize as configurações de voz que controlam como o Glossia gera e revisa o conteúdo. Ajuste o tom, formalidade, público-alvo e sobrescritas por local sem sair de seu editor.

**Gestão de terminologia** -- Mantenha a consistência da terminologia em todo o seu conteúdo. Adicione, atualize e versione as entradas de terminologia para que os agentes sempre usem os termos corretos.

**Projetos** -- Listar e inspecionar projetos em várias organizações.

## Como funciona

Aponte seu cliente MCP para `https://your-glossia-instance/mcp` e autentique com um token bearer OAuth. O [guia de configuração MCP](/docs/reference/mcp/overview) descreve o fluxo completo de conexão, incluindo registro dinâmico de cliente e PKCE. O servidor usa o mesmo sistema de autenticação e autorização que o [REST API](/features/rest-api), portanto, qualquer token que funcione para a API também funciona para o MCP.

A partir daí, seu assistente de IA pode chamar qualquer uma das 16 ferramentas. Peça para "criar uma organização chamada Acme" ou "atualizar meu tom de voz para profissional" e o agente traduz sua intenção na chamada de ferramenta correta.

## Construído para fluxos de trabalho agênticos

O MCP não é apenas uma camada de conveniência. É a base para compor o Glossia em pipelines agênticos maiores. Um assistente de programação pode ler sua base de código, detectar conteúdo não localizado, atualizar a terminologia com novos termos, ajustar as configurações de voz para uma localização específica e acionar uma execução de localização, tudo em uma única conversa.

Como o protocolo é padronizado, você não fica preso a nenhum cliente único. Troque entre Claude, Cursor ou seu próprio agente personalizado sem alterar uma linha de configuração.