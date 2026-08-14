%{
  title: "API REST",
  summary: "Uma API REST voltada para desenvolvedores, com documentação OpenAPI, autenticação OAuth 2.1 e autorização granular. Tudo o que pode ser feito no painel também pode ser feito por meio da API.",
  order: 4,
  icon: "terminal",
  hero_cta_text: "Começar",
  hero_cta_url: "/signup",
  highlights: [
    %{title: "Documentada com OpenAPI", description: "Uma especificação OpenAPI 3.1 completa fornece documentação interativa por meio do Scalar. Explore endpoints, teste solicitações e gere código de cliente a partir de um único arquivo de especificação.", icon: "book-open"},
    %{title: "OAuth 2.1 com PKCE", description: "Registro dinâmico de clientes, fluxo de código de autorização com PKCE, introspecção de tokens e revogação. Clientes de terceiros se autenticam com segurança sem compartilhar segredos.", icon: "key-round"},
    %{title: "Paginação e filtragem", description: "Todos os endpoints de listagem oferecem, por padrão, paginação baseada em páginas, filtragem por campos e ordenação. Metadados de resposta previsíveis simplificam o desenvolvimento de clientes.", icon: "code"}
  ]
}
---
## Desenvolvedores em primeiro lugar

A API REST é a base do Glossia. O painel, a CLI e o [servidor MCP](/features/mcp-server) consomem os mesmos endpoints. Quando adicionamos uma funcionalidade, ela é implementada primeiro na API e, a partir dela, disponibilizada em todos os outros lugares.

Isso significa que você nunca fica limitado pela interface do usuário. Qualquer fluxo de trabalho que possa imaginar, desde integrações de CI/CD até painéis personalizados, pode ser desenvolvido sobre a mesma interface estável e documentada.

## Autenticação

O Glossia usa OAuth 2.1 com PKCE para toda a autenticação da API. O fluxo oferece suporte a clientes próprios e de terceiros. Consulte a [documentação de autenticação e autorização](/docs/reference/apis/authentication) para ver o passo a passo completo.

**Registro dinâmico de clientes** - Os clientes são registrados programaticamente em `/oauth/register` com seus URIs de redirecionamento e tipos de concessão. Não há etapa de aprovação manual nem portal pelo qual navegar.

**Código de autorização com PKCE** - Os usuários autorizam os clientes por meio de uma tela de consentimento no navegador. A extensão PKCE garante que os tokens permaneçam seguros, mesmo para clientes públicos que não podem armazenar um segredo.

**Ciclo de vida dos tokens** - Os tokens de acesso podem ser trocados, inspecionados e revogados por meio de endpoints OAuth padrão. A limitação de taxa nos endpoints de token oferece proteção contra ataques de força bruta.

## Autorização

O controle de acesso usa duas camadas. A [documentação de autenticação](/docs/reference/apis/authentication) aborda detalhadamente os escopos, as funções e a matriz completa de permissões.

**Escopos** definem quais categorias de recursos um token pode acessar. Um token com `voice:read` pode ler configurações de voz, mas não pode modificá-las. Os escopos seguem o padrão `resource:action`: `account:read`, `organization:write`, `glossary:admin` para administração de terminologia e assim por diante.

**Políticas** verificam a relação entre o usuário e o recurso específico. Mesmo um token válido com o escopo correto não pode acessar uma organização à qual o usuário não pertence. Cada solicitação é verificada nas duas camadas.

## Paginação, filtragem e ordenação

Todos os endpoints de listagem retornam resultados paginados com metadados consistentes:

Cada resposta inclui `total_count`, `total_pages`, `current_page`, `page_size`, `has_next_page?` e `has_previous_page?`, permitindo que os clientes criem controles de paginação sem suposições.

Filtre por qualquer campo indexado usando parâmetros de consulta `filters[field]=value`. Ordene em ordem crescente ou decrescente com parâmetros `order_by[]`. A interface é a mesma para todos os recursos.

## OpenAPI e documentação interativa

A especificação OpenAPI 3.1 completa está disponível em `/api/openapi.json`. A [referência interativa da API](/docs/reference/apis/rest) utiliza Scalar e permite explorar endpoints, inspecionar esquemas e fazer solicitações de teste diretamente no navegador.

Bibliotecas de cliente em qualquer linguagem podem ser geradas com base na especificação. O contrato é versionado e estável, portanto suas integrações não deixam de funcionar quando lançamos novas funcionalidades.