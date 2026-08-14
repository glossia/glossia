%{
  title: "Servidor MCP",
  summary: "Conecte agentes de IA e assistentes de programação à Glossia por meio do Protocolo de Contexto de Modelo. Gerencie vozes, terminologia, organizações e muito mais usando linguagem natural em qualquer cliente compatível com MCP.",
  order: 3,
  icon: "cpu",
  hero_cta_text: "Começar",
  hero_cta_url: "/signup",
  highlights: [
    %{title: "Interface em linguagem natural", description: "Interaja com o mecanismo linguístico da Glossia usando texto simples. Agentes de IA utilizam ferramentas MCP para gerenciar vozes, terminologia e organizações sem escrever código.", icon: "message-square-text"},
    %{title: "Integração com qualquer agente", description: "Funciona com Claude, Cursor, Windsurf e qualquer cliente compatível com MCP. Adicione o servidor da Glossia ao seu fluxo de trabalho com agentes e comece a usá-lo imediatamente.", icon: "puzzle"},
    %{title: "Segurança por padrão", description: "Cada solicitação MCP é autenticada com tokens de portador OAuth 2.1 e autorizada com escopos granulares. Utiliza o mesmo modelo de segurança da API REST.", icon: "shield-check"}
  ]
}
---
## O que é o MCP?

O [Model Context Protocol (MCP)](https://modelcontextprotocol.io) é um padrão aberto para conectar assistentes de inteligência artificial a ferramentas externas e fontes de dados. Em vez de criar integrações personalizadas para cada assistente de programação, você disponibiliza um único servidor MCP, que pode ser usado por qualquer cliente compatível.

O servidor MCP da Glossia oferece aos agentes acesso direto ao núcleo linguístico da plataforma: configuração de voz, gerenciamento de terminologia, administração de organizações e listagem de projetos.

## Ferramentas disponíveis

O servidor MCP disponibiliza 16 ferramentas organizadas em torno dos recursos com os quais você trabalha diariamente. Consulte a [referência completa das ferramentas](/docs/reference/mcp/tools) para ver os parâmetros e os detalhes de uso.

**Contas e organizações**: Liste suas contas, crie e gerencie organizações, convide membros e controle o acesso. Os agentes podem configurar estruturas completas de equipes por meio de uma conversa.

**Configuração de voz**: Consulte e atualize as configurações de voz que controlam como a Glossia gera e revisa conteúdo. Ajuste o tom, a formalidade, o público-alvo e as substituições específicas de cada localidade sem sair do editor.

**Gerenciamento de terminologia**: Mantenha a consistência terminológica em todo o seu conteúdo. Adicione, atualize e versione entradas de terminologia para que os agentes sempre usem os termos corretos.

**Projetos**: Liste e inspecione projetos de diferentes organizações.

## Como funciona

Configure seu cliente MCP para usar `https://your-glossia-instance/mcp` e autentique-se com um token bearer do OAuth. O [guia de configuração do MCP](/docs/reference/mcp/overview) explica todo o fluxo de conexão, incluindo o registro dinâmico de clientes e a Proof Key for Code Exchange (PKCE). O servidor usa o mesmo sistema de autenticação e autorização da [interface de programação de aplicações REST](/features/rest-api), portanto qualquer token válido para essa interface também funciona com o MCP.

A partir daí, seu assistente de inteligência artificial poderá chamar qualquer uma das 16 ferramentas. Peça para ele "criar uma organização chamada Acme" ou "alterar o tom da minha voz para profissional", e o agente converterá sua intenção na chamada de ferramenta adequada.

## Desenvolvido para fluxos de trabalho com agentes

O MCP não é apenas uma camada de conveniência. Ele é a base para integrar a Glossia a fluxos maiores com agentes. Um assistente de programação pode ler sua base de código, detectar conteúdo não localizado, atualizar a terminologia com novos termos, ajustar as configurações de voz para uma localidade específica e iniciar uma execução de localização, tudo em uma única conversa.

Como o protocolo é padronizado, você não fica limitado a um único cliente. Alterne entre Claude, Cursor ou seu próprio agente personalizado sem modificar nenhuma linha de configuração.