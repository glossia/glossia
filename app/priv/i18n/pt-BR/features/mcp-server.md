%{
  title: "Servidor MCP",
  summary:
    "Conecte agentes de IA e assistentes de programação ao Glossia através do Protocolo de Contexto do Modelo. Gerencie vozes, terminologia, organizações e muito mais usando linguagem natural de qualquer cliente compatível com MCP.",
  order: 3,
  icon: "cpu",
  hero_cta_text: "Começar",
  hero_cta_url: "/signup",
  highlights: [
    %{
      title: "Interface de linguagem natural",
      description:
        "Interaja com o motor linguístico do Glossia através de texto simples. Agentes de IA chamam ferramentas do MCP para gerenciar vozes, terminologia e organizações sem escrever código.",
      icon: "message-square-text"
    },
    %{
      title: "Conecte-se a qualquer agente",
      description:
        "Compatível com Claude, Cursor, Windsurf e qualquer cliente compatível com MCP. Insira o servidor do Glossia no seu fluxo de trabalho de agentes existente e comece a usá-lo imediatamente.",
      icon: "puzzle"
    },
    %{
      title: "Seguro por padrão",
      description:
        "Cada solicitação do MCP é autenticada com tokens OAuth 2.1 bearer e autorizada com base em escopos granulares. O mesmo modelo de segurança da API REST.",
      icon: "shield-check"
    }
  ]
}
---
## O que é MCP?

O [Protocolo de Contexto do Modelo](https://modelcontextprotocol.io) é um padrão aberto para conectar assistentes de IA a ferramentas e fontes de dados externas. Em vez de criar integrações personalizadas para cada assistente de codificação, você expõe um único servidor MCP e qualquer cliente compatível pode utilizá-lo.

O servidor MCP do Glossia dá aos agentes acesso direto ao núcleo linguístico da plataforma: configuração de voz, gerenciamento de terminologia, administração organizacional e lista de projetos.

## Ferramentas disponíveis

A [referência completa de ferramentas](/docs/reference/mcp/tools) para parâmetros e detalhes de uso.

**Contas e organizações** -- Liste suas contas, crie e gerencie organizações, convide membros e controle o acesso. Os agentes podem configurar estruturas inteiras de equipe por meio de conversa.

**Configuração de voz** -- Leia e atualize configurações de voz que controlam como o Glossia gera e revisa conteúdo. Ajuste tom, formalidade, público-alvo e sobrescritas por locale sem sair do seu editor.

**Gestão de terminologia** -- Mantenha a consistência terminológica em todo o seu conteúdo. Adicione, atualize e versione entradas de terminologia para que os agentes sempre usem os termos corretos.

**Projetos** -- Liste e inspecione projetos em todas as organizações.

## Como funciona

Aponte seu cliente MCP para `https://your-glossia-instance/mcp` e autentique com um token portador do OAuth. O [guia de configuração do MCP](/docs/reference/mcp/overview) passa pelo fluxo completo de conexão, incluindo registro dinâmico do cliente e PKCE. O servidor utiliza o mesmo sistema de autenticação e autorização que a [API REST](/features/rest-api), de modo que qualquer token que funcione para a API também funcione para o MCP.

A partir daí, seu assistente de IA pode invocar qualquer uma das 16 ferramentas. Peça-lhe para "criar uma organização chamada Acme" ou "atualizar o tom da minha voz para profissional" e o agente traduz sua intenção na chamada de ferramenta correta.

## Construído para fluxos de trabalho agênticos

O MCP não é apenas uma camada de conveniência. É a base para compor o Glossia em pipelines agênticos maiores. Um assistente de codificação pode ler sua base de código, detectar conteúdo não localizado, atualizar terminologia com novos termos, ajustar configurações de voz para um local específico e acionar uma execução de localização, tudo em uma única conversa.

Como o protocolo é padronizado, você não fica preso a nenhum cliente único. Alterne entre Claude, Cursor ou seu próprio agente personalizado sem alterar uma linha de configuração.