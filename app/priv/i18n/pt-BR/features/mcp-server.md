%{
  title: "Servidor MCP",
  summary:
    "Conecte agentes de IA e assistentes de codificação ao Glossia pelo Protocolo de Modelo de Contexto. Gerencie vozes, terminologia, organizações e muito mais usando linguagem natural de qualquer cliente compatível com o MCP.",
  order: 3,
  icon: "cpu",
  hero_cta_text: "Iniciar",
  hero_cta_url: "/signup",
  highlights: [
    %{
      title: "Interface de linguagem natural",
      description:
        "Interaja com o motor linguístico do Glossia usando texto plano. Agentes de IA chamam ferramentas MCP para gerenciar vozes, terminologia e organizações sem escrever código.",
      icon: "message-square-text"
    },
    %{
      title: "Conecte a qualquer agente",
      description:
        "Compatível com Claude, Cursor, Windsurf e qualquer cliente compatível com o MCP. Integre o servidor do Glossia ao seu fluxo de trabalho agêntico existente e comece a usá-lo imediatamente.",
      icon: "puzzle"
    },
    %{
      title: "Seguro por padrão",
      description:
        "Cada solicitação MCP é autenticada com tokens OAuth 2.1 e autorizada com escopos granulares. O mesmo modelo de segurança que a API REST.",
      icon: "shield-check"
    }
  ]
}
---
## O que é MCP?

O [Protocolo de Contexto do Modelo](https://modelcontextprotocol.io) É um padrão aberto para conectar assistentes de IA a ferramentas e fontes de dados externas. Em vez de criar integrações personalizadas para cada assistente de programação, você expõe um único servidor MCP e qualquer cliente compatível pode usá-lo.

O servidor MCP do Glossia dá aos agentes acesso direto ao núcleo linguístico da plataforma: configuração de voz, gerenciamento de terminologia, administração de organização e listagem de projetos.

## Ferramentas disponíveis

O servidor MCP expõe 16 ferramentas organizadas em torno dos recursos com os quais você trabalha diariamente. Veja a [referência completa de ferramentas](/docs/reference/mcp/tools) para parâmetros e detalhes de uso.

**Contas e organizações** -- Liste suas contas, crie e gerencie organizações, convide membros e controle o acesso. Agentes podem configurar toda a estrutura da equipe por meio de conversação.

**Configuração de voz** -- Leia e atualize configurações de voz que controlam como o Glossia gera e revisa conteúdo. Ajuste tom, formalidade, público-alvo e ajustes por localização, sem sair do seu editor.

**Gerenciamento de terminologia** -- Mantenha a consistência terminológica em todo o seu conteúdo. Adicione, atualize e versione as entradas de terminologia para que os agentes sempre usem os termos corretos.

**Projetos** -- Listar e inspecionar projetos em várias organizações.

## Como funciona

Aponte seu cliente MCP para `https://your-glossia-instance/mcp` e autentique com um token OAuth bearer. O [Guia de configuração do MCP](/docs/reference/mcp/overview) passa pelo fluxo completo de conexão, incluindo registro dinâmico do cliente e PKCE. O servidor usa o mesmo sistema de autenticação e autorização que [REST API](/features/rest-api), então qualquer token que funcione para a API funciona para o MCP.

A partir de lá, sua assistente de IA pode chamar qualquer uma das 16 ferramentas. Peça para "criar uma organização chamada Acme" ou "atualizar meu tom de voz para profissional" e o agente traduzirá sua intenção para a chamada correta da ferramenta.

## Construído para fluxos de trabalho agênticos

O MCP não é apenas uma camada de conveniência. É a base para compor o Glossia em pipelines agênticos maiores. Um assistente de codificação pode ler sua base de código, detectar conteúdo não localizado, atualizar a terminologia com novos termos, ajustar as configurações de voz para um local específico e iniciar um processo de localização, tudo em uma única conversa.

Como o protocolo é padronizado, você não fica preso a um único cliente. Troque entre o Claude, o Cursor ou seu próprio agente personalizado sem alterar uma linha de configuração.