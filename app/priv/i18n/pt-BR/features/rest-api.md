%{
  title: "REST API",
  summary:
    "Uma REST API centrada no desenvolvedor com documentação OpenAPI, autenticação OAuth 2.1 e autorização granular. Tudo o que você pode fazer no dashboard também pode ser feito via API.",
  order: 4,
  icon: "terminal",
  hero_cta_text: "Começar",
  hero_cta_url: "/signup",
  highlights: [
    %{
      title: "Documentado em OpenAPI",
      description:
        "Uma especificação completa OpenAPI 3.1 impulsiona a documentação interativa via Scalar. Explore endpoints, experimente solicitações e gere código do cliente a partir de um único arquivo de especificação.",
      icon: "book-open"
    },
    %{
      title: "OAuth 2.1 com PKCE",
      description:
        "Registro dinâmico de cliente, fluxo de código de autorização com PKCE, inspeção de token e revogação. Clientes de terceiros autenticam-se com segurança sem compartilhar segredos.",
      icon: "key-round"
    },
    %{
      title: "Paginação e Filtragem",
      description:
        "Todos os endpoints de lista suportam paginação baseada em página, filtragem de campo e ordenação nativa. Metadados de resposta previsíveis tornam a construção de clientes simples.",
      icon: "código"
    }
  ]
}
---
## Desenvolvedores em primeiro lugar

A API REST é a espinha dorsal do Glossia. O Dashboard, o CLI e o [MCP server](/features/mcp-server) consomem todos os mesmos endpoints. Quando adicionamos um recurso, ele é incorporado à API primeiro e disponibilizado em todos os outros locais a partir daí.

Isso significa que você nunca será limitado pela interface. Qualquer fluxo de trabalho que você possa imaginar, desde integrações de CI/CD até painéis personalizados, pode ser construído sobre a mesma interface estável e documentada.

## Autenticação

O Glossia usa OAuth 2.1 com PKCE para todas as autenticações da API. O fluxo suporta tanto clientes de primeira quanto de terceiros. Veja a [documentação de autenticação e autorização](/docs/reference/apis/authentication) para o guia completo.

**Registro dinâmico de clientes** -- Os clientes se registram programaticamente em `/oauth/register` com seus URIs de redirecionamento e tipos de concessão. Sem etapa manual de aprovação, nem necessidade de navegar por um portal.

**Código de autorização com PKCE** -- Os usuários autorizam clientes por meio de uma tela de consentimento baseada em navegador. A extensão PKCE garante que os tokens permaneçam seguros, mesmo para clientes públicos que não podem armazenar um segredo.

**Ciclo de vida do token** -- Tokens de acesso podem ser trocados, introspecionados e revogados por meio de endpoints OAuth padrão. A limitação de taxa nos endpoints de token protege contra força bruta.

## Autorização

O controle de acesso usa duas camadas. A [documentação de autenticação](/docs/reference/apis/authentication) cobre escopos, papéis e a matriz de permissões completa em detalhes.

**Escopos** definem quais categorias de recursos um token pode acessar. Um token com `voice:read` pode ler configurações de voz, mas não modificá-las. Os escopos seguem o padrão `resource:action`: `account:read`, `organization:write`, `glossary:admin` para administração de terminologia e assim por diante.

**Políticas** verificam a relação entre o usuário e o recurso específico. Um token válido com o escopo correto ainda não pode acessar uma organização à qual o usuário não pertence. Cada requisição é verificada contra ambas as camadas.

## Paginação, filtragem e ordenação

Todos os endpoints de lista retornam resultados paginados com metadados consistentes:

Todas as respostas incluem `total_count`, `total_pages`, `current_page`, `page_size`, `has_next_page?` e `has_previous_page?`, permitindo que os clientes construam controles de paginação sem adivinhar.

Filtre por qualquer campo indexado usando os parâmetros de consulta `filters[field]=value`. Ordene em ordem crescente ou decrescente com os parâmetros `order_by[]`. A interface é a mesma em todos os recursos.

## OpenAPI e documentação interativa

A especificação completa OpenAPI 3.1 está disponível em `/api/openapi.json`. A [referência de API interativa](/docs/reference/apis/rest) é alimentada pelo Scalar e permite que você explore endpoints, examine esquemas e realize requisições de teste diretamente do navegador.

Bibliotecas de clientes em qualquer linguagem podem ser geradas a partir da especificação. O contrato é versionado e estável, então suas integrações não quebram quando lançamos novos recursos.