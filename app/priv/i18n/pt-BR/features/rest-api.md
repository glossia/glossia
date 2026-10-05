%{
  title: "API REST",
  summary:
    "Uma API REST voltada para desenvolvedores com documentação OpenAPI, autenticação OAuth 2.1 e autorização granular. Tudo o que você pode fazer no painel, você também pode fazer através da API.",
  order: 4,
  icon: "terminal",
  hero_cta_text: "Começar",
  hero_cta_url: "/signup",
  highlights: [
    %{
      title: "Documentado com OpenAPI",
      description:
        "Uma especificação completa OpenAPI 3.1 impulsiona a documentação interativa via Scalar. Explore endpoints, teste solicitações e gere código de cliente a partir de um único arquivo de especificação.",
      icon: "book-open"
    },
    %{
      title: "OAuth 2.1 com PKCE",
      description:
        "Registro dinâmico de cliente, fluxo de autorização por código com PKCE, introspecção de tokens e revogação. Clientes de terceiros autenticam-se com segurança sem compartilhar segredos.",
      icon: "key-round"
    },
    %{
      title: "Paginação e filtragem",
      description:
        "Todos os endpoints de lista suportam paginação baseada em páginas, filtragem por campo e ordenação nativa. Metadados de resposta previsíveis facilitam a criação de clientes.",
      icon: "code"
    }
  ]
}
---
## Desenvolvedores em primeiro lugar

A REST API é a espinha dorsal do Glossia. O dashboard, o CLI e o [servidor MCP](/features/mcp-server) todos consomem os mesmos endpoints. Quando adicionamos uma funcionalidade, ela chega à API primeiro e é disponibilizada em todos os outros pontos a partir daí.

Isso significa que você nunca fica limitado pela UI. Qualquer fluxo de trabalho que você possa imaginar, desde integrações CI/CD até dashboards personalizados, pode ser construído sobre a mesma interface estável e documentada.

## Autenticação

O Glossia utiliza OAuth 2.1 com PKCE para autenticação de API. O fluxo suporta tanto clientes de primeira parte quanto de terceira parte. Veja os [documentos de autenticação e autorização](/docs/reference/apis/authentication) para o passo a passo completo.

**Registro dinâmico de clientes** -- Os clientes se cadastram programaticamente em `/oauth/register` com seus URIs de redirecionamento e tipos de concessão. Sem etapa de aprovação manual, sem portal para clicar.

**Código de autorização com PKCE** -- Os usuários autorizam clientes através de uma tela de consentimento baseada em navegador. A extensão PKCE garante que os tokens permaneçam seguros mesmo para clientes públicos que não podem armazenar um segredo.

**Ciclo de vida do token** -- Tokens de acesso podem ser trocados, introspectados e revogados através de endpoints OAuth padrão. Limitação de taxa nos endpoints de token protege contra força bruta.

## Autorização

O controle de acesso utiliza duas camadas. A [documentação de autenticação](/docs/reference/apis/authentication) cobre os escopos, papéis e a matriz completa de permissões em detalhes.

**Escopos** definem as categorias de recursos que um token pode acessar. Um token com `voice:read` pode ler configurações de voz, mas não pode modificá-las. Os escopos seguem o `resource:action` padrão: `account:read`O documento remontado anteriormente falhou na validação: a recuperação de texto literal do Markdown deve retornar um array de strings JSON de comprimento correspondente. `organization:write`O documento reassemblado anteriormente falhou na validação: a recuperação do nó de texto Markdown produziu uma tradução vazia `glossary:admin` para administração de glossário, e assim por diante.

**Políticas** Verifique a relação entre o usuário e o recurso específico. Um token válido com o escopo correto ainda não pode acessar uma organização à qual o usuário não pertence. Cada solicitação é verificada contra ambas as camadas.

## Paginação, filtragem e ordenação

Todos os endpoints de lista retornam resultados paginados com metadados consistentes:

Todas as respostas incluem `total_count`O documento remontado anteriormente falhou na validação: recuperação de texto-literal Markdown deve retornar um array de strings JSON de comprimento correspondente `total_pages`O documento reconstituído anteriormente falhou na validação: a recuperação de texto literal de Markdown deve retornar um array de strings JSON de tamanho correspondente `current_page`O documento remontado anteriormente falhou na validação: a recuperação de texto literal Markdown retornou JSON inválido `page_size`O documento remontado anteriormente falhou na validação: a recuperação de literal de texto Markdown retornou JSON inválido `has_next_page?`, e `has_previous_page?` para que os clientes possam construir controles de paginação sem adivinhar.

Filtrar por qualquer campo indexado usando `filters[field]=value` parâmetros de consulta. Ordenar crescente ou decrescente com `order_by[]` Parâmetros. A interface é a mesma para todos os recursos.

## OpenAPI e documentação interativa

A especificação completa da OpenAPI 3.1 está disponível em `/api/openapi.json`. O [referência interativa da API](/docs/reference/apis/rest) é impulsionada pelo Scalar e permite explorar endpoints, inspecionar esquemas e realizar solicitações de teste diretamente do navegador.

Bibliotecas de cliente em qualquer linguagem podem ser geradas a partir da especificação. O contrato é versionado e estável, assim suas integrações não quebrarão quando lançarmos novos recursos.