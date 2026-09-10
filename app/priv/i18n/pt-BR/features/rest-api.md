%{
  title: "API REST",
  summary:
    "Uma API REST voltada para desenvolvedores com documentação OpenAPI, autenticação OAuth 2.1 e autorização de granulação fina. Tudo o que você pode fazer no painel, você pode fazer através da API.",
  order: 4,
  icon: "terminal",
  hero_cta_text: "Começar",
  hero_cta_url: "/signup",
  highlights: [
    %{
      title: "Documentação OpenAPI",
      description:
        "Uma especificação completa OpenAPI 3.1 impulsiona a documentação interativa via Scalar. Explore endpoints, teste requisições e gere código de cliente a partir de um único arquivo de especificação.",
      icon: "book-open"
    },
    %{
      title: "OAuth 2.1 com PKCE",
      description:
        "Registro de cliente dinâmico, fluxo de código de autorização com PKCE, introspecção de token e revogação. Clientes de terceiros se autenticam de forma segura sem compartilhar segredos.",
      icon: "key-round"
    },
    %{
      title: "Paginação e filtragem",
      description:
        "Cada endpoint de lista suporta paginação baseada em página, filtragem de campo e ordenação nativamente. Metadados de resposta previsíveis tornam a criação de clientes simples.",
      icon: "code"
    }
  ]
}
---
## Desenvolvedores em primeiro lugar

A REST API é o alicerce do Glossia. O Dashboard, o CLI e o [MCP server](/features/mcp-server) consomem os mesmos endpoints. Quando adicionamos um recurso, ele aterrissa na API primeiro e reflete em todos os outros locais a partir dali.

Isso significa que você nunca é limitado pela interface. Qualquer fluxo de trabalho que você possa imaginar, desde integrações com CI/CD até dashboards personalizados, pode ser construído sobre a mesma interface estável e documentada.

## Autenticação

O Glossia usa OAuth 2.1 com PKCE para autenticação de API. O fluxo suporta tanto clientes de primeira parte quanto de terceiros. Veja a [documentação de autenticação e autorização](/docs/reference/apis/authentication) para o walkthrough completo.

**Registro dinâmico de cliente** -- Os clientes registram-se programaticamente em `/oauth/register` com seus URIs de redirecionamento e tipos de concessão. Sem etapa de aprovação manual, sem portal para clicar.

**Código de autorização com PKCE** -- Os usuários autorizam clientes através de uma tela de consentimento baseada em navegador. A extensão PKCE garante que os tokens permaneçam seguros mesmo para clientes públicos que não podem armazenar um segredo.

**Ciclo de vida do token** -- Tokens de acesso podem ser trocados, introspectados e revogados através de endpoints padrão OAuth. Limitação de taxa nos endpoints de token protege contra força bruta.

## Autorização

O controle de acesso utiliza duas camadas. Os [docs de autenticação e autorização](/docs/reference/apis/authentication) cobrem escopos, papéis e a matriz de permissões completa em detalhe.

**Escopos** definem quais categorias de recursos um token pode acessar. Um token com `voice:read` pode ler configurações de voz, mas não pode alterá-las. Os escopos seguem o padrão `resource:action`: `account:read`, `organization:write`, `glossary:admin` para administração de terminologia e assim por diante.

**Políticas** verificam a relação entre o usuário e o recurso específico. Um token válido com o escopo correto ainda não pode acessar uma organização à qual o usuário não pertence. Cada solicitação é verificada contra ambas as camadas.

## Paginação, filtragem e ordenação

Todos os endpoints de lista retornam resultados paginados com metadados consistentes:

Cada resposta inclui `total_count`, `total_pages`, `current_page`, `page_size`, `has_next_page?` e `has_previous_page?` para que os clientes construam controles de paginação sem precisar adivinhar.

Filtre por qualquer campo indexado usando parâmetros de consulta `filters[field]=value`. Ordene em ordem ascendente ou descendente usando paramètres `order_by[]`. A interface é a mesma em todos os recursos.

## OpenAPI e documentação interativa

A especificação completa OpenAPI 3.1 está disponível em `/api/openapi.json`. A [referência API interativa](/docs/reference/apis/rest) é alimentada pelo Scalar e permite explorar endpoints, inspecionar esquemas e fazer requisições de teste diretamente do navegador.

Bibliotecas de cliente em qualquer linguagem podem ser geradas a partir da especificação. O contrato é versionado e estável, para que suas integrações não sejam quebradas quando lançarmos novos recursos.