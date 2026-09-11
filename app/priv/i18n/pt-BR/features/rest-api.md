%{
  title: "REST API",
  summary:
    "Uma API REST voltada para desenvolvedores com documentação OpenAPI, autenticação OAuth 2.1 e autorização de granularidade fina. Tudo o que você pode fazer no painel também é possível através da API.",
  order: 4,
  icon: "terminal",
  hero_cta_text: "Começar",
  hero_cta_url: "/signup",
  highlights: [
    %{
      title: "Documentado com OpenAPI",
      description:
        "Uma especificação OpenAPI 3.1 completa habilita documentação interativa via Scalar. Explore endpoints, teste solicitações e gere código cliente a partir de um único arquivo de especificação.",
      icon: "book-open"
    },
    %{
      title: "OAuth 2.1 com PKCE",
      description:
        "Registro dinâmico de clientes, fluxo de autorização por código com PKCE, introspeção de tokens e revogação. Clientes de terceiros autenticam-se com segurança sem compartilhar segredos.",
      icon: "key-round"
    },
    %{
      title: "Paginação e filtragem",
      description:
        "Todos os endpoints de lista suportam paginação por página, filtragem de campo e ordenação nativamente. Metadados de resposta previsíveis facilitam a criação de clientes.",
      icon: "code"
    }
  ]
}
---
## Primeiro o desenvolvedor

A REST API é a espinha dorsal do Glossia. O painel, o CLI e o [servidor MCP](/features/mcp-server) todos consomem os mesmos endpoints. Quando adicionamos uma funcionalidade, ela é implementada na API primeiro e se torna disponível em todos os outros lugares a partir daí.

Isso significa que você nunca está limitado pela interface. Qualquer fluxo de trabalho que você possa imaginar, desde integrações CI/CD até painéis personalizados, pode ser construído sobre a mesma interface estável e documentada.

## Autenticação

O Glossia usa OAuth 2.1 com PKCE para toda autenticação de API. O fluxo suporta tanto clientes de primeira quanto de terceira parte. Veja os [documentos de autenticação e autorização](/docs/reference/apis/authentication) para o guia completo.

**Registro dinâmico de clientes** -- Os clientes se registram programaticamente em `/oauth/register` com suas URIs de redirecionamento e tipos de concessão. Sem etapa manual de aprovação, sem portal para navegar.

**Código de autorização com PKCE** -- Os usuários autorizam clientes por meio de uma tela de consentimento baseada em navegador. A extensão PKCE garante que os tokens permaneçam seguros, mesmo para clientes públicos que não podem armazenar um segredo.

**Ciclo de vida do token** -- Os tokens de acesso podem ser trocados, introspectados e revogados através de endpoints OAuth padrão. A limitação de taxa nos endpoints de token protege contra força bruta.

## Autorização

O controle de acesso utiliza duas camadas. A [documentação de autenticação](/docs/reference/apis/authentication) abrange escopos, papéis e a matriz de permissões completa em detalhes.

**Escopos** define quais categorias de recursos um token pode acessar. Um token com `voice:read` pode ler configurações de voz, mas não pode modificá-las. Escopos seguem o `resource:action` padrão: `account:read`, `organization:write`, `glossary:admin` para administração de terminologia, e assim por diante.

**Políticas** Verifique a relação entre o usuário e o recurso específico. Um token válido com o escopo correto ainda não pode acessar uma organização à qual o usuário não pertence. Cada solicitação é verificada contra ambas as camadas.

## Paginação, filtragem e ordenação

Todos os endpoints de lista retornam resultados paginados com metadados consistentes:

Cada resposta inclui `total_count`, `total_pages`, `current_page`O documento remontado anteriormente falhou na validação: a recuperação de texto literal do Markdown deve retornar um array de strings JSON de comprimento correspondente `page_size`, `has_next_page?`e `has_previous_page?` assim os clientes podem criar controles de paginação sem precisar adivinhar.

Filtrar por qualquer campo indexado usando `filters[field]=value` parâmetros de consulta. Ordenar ascendente ou descendente com `order_by[]` parâmetros. A interface é a mesma em todos os recursos.

## OpenAPI e documentações interativas

A especificação completa OpenAPI 3.1 está disponível em `/api/openapi.json`. A [referência interativa da API](/docs/reference/apis/rest) é impulsionada por Scalar e permite que você explore endpoints, inspecione esquemas e faça solicitações de teste diretamente do navegador.

Bibliotecas de cliente em qualquer linguagem podem ser geradas a partir da especificação. O contrato é versionado e estável, de modo que suas integrações não se rompem quando lançamos novos recursos.