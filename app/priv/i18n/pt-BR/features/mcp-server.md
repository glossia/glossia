%{
  title: "Servidor MCP",
  summary:
    "Conecte agentes de IA e assistentes de codificação ao Glossia através do Protocolo de Contexto do Modelo. Gerencie vozes, terminologia, organizações e muito mais usando linguagem natural de qualquer cliente compatível com o MCP.",
  order: 3,
  icon: "CPU",
  hero_cta_text: "Começar agora",
  hero_cta_url: "/signup",
  highlights: [
    %{
      title: "Interface de linguagem natural",
      description:
        "Interaja com o motor linguístico do Glossia por meio de texto simples. Agentes de IA chamam ferramentas MCP para gerenciar vozes, terminologia e organizações sem escrever código.",
      icon: "Mensagem de Texto"
    },
    %{
      title: "Conecte a qualquer agente",
      description:
        "Funciona com Claude, Cursor, Windsurf e qualquer cliente compatível com o MCP. Adicione o servidor Glossia ao seu fluxo existente de agentes e comece a usá-lo imediatamente.",
      icon: "Quebra-cabeça"
    },
    %{
      title: "Protegido por padrão",
      description:
        "Cada solicitação do MCP é autenticada com tokens de portador OAuth 2.1 e autorizada contra escopos granulares. O mesmo modelo de segurança que a API REST.",
      icon: "Escudo verificoado"
    }
  ]
}
---
## O que é MCP?

O [Model Context Protocol](https://modelcontextprotocol.io) é um padrão aberto para conectar assistentes de IA a ferramentas e fontes de dados externas. Em vez de criar integrações personalizadas para cada assistente de código, você expõe um único servidor MCP e qualquer cliente compatível pode usá-lo.

O servidor MCP da Glossia concede aos agentes acesso direto ao núcleo linguístico da plataforma: configuração de voz, gerenciamento de terminologia, administração de organizações e listagem de projetos.

## Ferramentas disponíveis

O servidor MCP expõe 16 ferramentas organizadas ao redor dos recursos com os quais você trabalha diariamente. Consulte a [referência completa de ferramentas](/docs/reference/mcp/tools) para detalhes de parâmetros e uso.

**Contas e organizações** -- Liste suas contas, crie e gerencie organizações, convide membros e controle o acesso. Agentes podem configurar estruturas inteiras de equipe através da conversa.

**Configuração de voz** -- Leia e atualize as configurações de voz que controlam como a Glossia gera e revisa conteúdo. Ajuste o tom, a formalidade, o público-alvo e as sobrescritas por localização sem sair do seu editor.

**Gerenciamento de terminologia** -- Mantenha a consistência da terminologia em todo o seu conteúdo. Adicione, atualize e versione entradas de terminologia para que os agentes sempre usem os termos corretos.

**Projetos** -- Liste e inspecione projetos em várias organizações.

## Como funciona

Aponte seu cliente MCP para `https://your-glossia-instance/mcp` e autentique-se com um token bearer OAuth. O [guia de configuração do MCP](/docs/reference/mcp/overview) percorre o fluxo completo de conexão, incluindo registro dinâmico de clientes e PKCE. O servidor usa o mesmo sistema de autenticação e autorização da [REST API](/features/rest-api), de modo que qualquer token que funcione para a API também funciona para MCP.

A partir daí, seu assistente de IA pode invocar qualquer uma das 16 ferramentas. Peça-lhe para "criar uma organização chamada Acme" ou "atualizar o tom da minha voz para profissional" e o agente traduz sua intenção na chamada de ferramenta correta.

## Construído para fluxos de trabalho agênticos

O MCP não é apenas uma camada de conveniência. É a base para compor a Glossia em pipelines agênticos maiores. Um assistente de código pode ler sua base de código, detectar conteúdo não localizado, atualizar terminologia com novos termos, ajustar configurações de voz para uma localização específica e acionar uma execução de localização, tudo em uma única conversa.

Como o protocolo é padronizado, você não fica preso a qualquer cliente único. Troque entre o Claude, o Cursor ou seu próprio agente personalizado sem alterar uma única linha de configuração.