%{
  title: "Servidor MCP",
  summary:
    "Conecte agentes de IA e assistentes de codificação ao Glossia por meio do Modelo de Contexto Protocol. Gerencie idiomas, glossário, organizações e mais usando linguagem natural de qualquer cliente compatível com MCP.",
  order: 3,
  icon: "cpu",
  hero_cta_text: "Iniciar",
  hero_cta_url: "/signup",
  highlights: [
    %{
      title: "Interface de linguagem natural",
      description:
        "Interaja com o motor linguístico do Glossia por meio de texto simples. Agentes de IA chamam ferramentas MCP para gerenciar idiomas, glossário e organizações sem escrever código.",
      icon: "message-square-text"
    },
    %{
      title: "Conecte-se a qualquer agente",
      description:
        "Funciona com Claude, Cursor, Windsurf e qualquer cliente compatível com MCP. Adicione o servidor Glossia ao seu fluxo de trabalho atual de agente e comece a usá-lo imediatamente.",
      icon: "puzzle"
    },
    %{
      title: "Seguro por padrão",
      description:
        "Cada solicitação MCP é autenticada com tokens OAuth 2.1 e autorizada em escopos finos. O mesmo modelo de segurança da API REST.",
      icon: "shield-check"
    }
  ]
}
---

## Qual é o MCP?

O [Protocolo do Modelo de Contexto](https://modelcontextprotocol.io) é um padrão aberto para conectar assistentes de IA a ferramentas e fontes de dados externas. Em vez de criar integrações personalizadas para cada assistente de código, você expõe um único servidor MCP e qualquer cliente compatível pode usá-lo.

O servidor MCP da Glossia concede aos agentes acesso direto ao núcleo linguístico da plataforma: configuração de voz, gerenciamento de glossário, administração de organizações e lista de projetos.

## Ferramentas disponíveis

O servidor MCP expõe 16 ferramentas organizadas em torno dos recursos com os quais você trabalha diariamente. Consulte a [referência completa das ferramentas](/docs/reference/mcp/tools) para detalhes de parâmetros e uso.

**Contas e organizações** -- Liste suas contas, crie e gerencie organizações, convide membros e controle o acesso. Agentes podem configurar toda a estrutura de equipe por meio de conversa.

**Configuração de voz** -- Leia e atualize configurações de voz que controlam como a Glossia gera e revisa conteúdo. Ajuste tom, formalidade, público-alvo e sobrescritas por localidade sem sair do seu editor.

**Gerenciamento de glossário** -- Mantenha a consistência do glossário em todo o seu conteúdo. Adicione, atualize e version as entradas do glossário para que os agentes sempre usem os termos corretos.

**Projetos** -- Liste e inspecione projetos em todas as organizações.

## Como funciona

Aponte seu cliente MCP para `https://your-glossia-instance/mcp` e autentique-se com um token OAuth de autenticação. O [guia de configuração do MCP](/docs/reference/mcp/overview) percorre o fluxo completo de conexão, incluindo registro dinâmico do cliente e PKCE. O servidor usa o mesmo sistema de autenticação e autorização que a [REST API](/features/rest-api), então qualquer token que funcione para a API funciona para o MCP.

Daí, seu assistente de IA pode chamar qualquer uma das 16 ferramentas. Peça para que "crie uma organização chamada Acme" ou "atualize o tom de voz para profissional" e o agente traduzirá sua intenção na chamada de ferramenta correta.

## Criado para fluxos de trabalho de agentes

O MCP não é apenas uma camada de conveniência. É a base para compor a Glossia em pipelines de agentes maiores. Um assistente de código pode ler seu código, detectar conteúdo não localizado, atualizar o glossário com novos termos, ajustar configurações de voz para um local específico e acionar uma execução de localização, tudo em uma única conversa.

Como o protocolo é padronizado, você não fica preso a nenhum cliente específico. Troque entre Claude, Cursor ou seu próprio agente personalizado sem alterar uma única linha de configuração.
