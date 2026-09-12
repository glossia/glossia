%{
  title: "REST API",
  summary:
    "Uma API REST focada em desenvolvedores, com documentação OpenAPI, autenticação OAuth 2.1 e autorização granular. Tudo o que você pode fazer no painel, você pode fazer através da API.",
  order: 4,
  icon: "Terminal",
  hero_cta_text: "Começar",
  hero_cta_url: "/signup",
  highlights: [
    %{
      title: "Documentado com OpenAPI",
      description:
        "Uma especificação completa OpenAPI 3.1 habilita documentação interativa via Scalar. Explore endpoints, tente requisições e gere código de cliente a partir de um único arquivo de especificação.",
      icon: "Documentos"
    },
    %{
      title: "OAuth 2.1 com PKCE",
      description:
        "Registro dinâmico de cliente, fluxo de código de autorização com PKCE, introspecção de tokens e revogação. Clientes de terceiros se autenticam de forma segura sem compartilhar segredos.",
      icon: "Segurança"
    },
    %{
      title: "Paginação e filtragem",
      description:
        "Todos os endpoints de lista suportam paginação baseada em página, filtragem de campos e ordenação prontas para uso. Metadados de resposta previsíveis tornam a construção de clientes simples.",
      icon: "Código"
    }
  ]
}
---
## Primeiro para desenvolvedores

A API REST é a espinha dorsal do Glossia. O painel de controle, o CLI e o [servidor MCP](/features/mcp-server) consomem os mesmos endpoints. Quando adicionamos um recurso, ele chega à API primeiro e é exposto em todos os outros lugares a partir daí.

Isso significa que você nunca fica limitado pela interface. Qualquer fluxo de trabalho que você possa imaginar, desde integrações CI/CD até painéis personalizados, pode ser construído sobre a mesma interface estável e documentada.

## Autenticação

O Glossia usa OAuth 2.1 com PKCE para toda autenticação de API. O fluxo suporta clientes de primeira e terceira parte. Veja a [autenticação e autorização](/docs/reference/apis/authentication) para o guia completo.

**Registro de cliente dinâmico** -- Os clientes se registram programaticamente em `/oauth/register` com seus URIs de redirecionamento e tipos de concessão. Sem etapa manual de aprovação, sem portal para clicar.

**Código de autorização com PKCE** -- Os usuários autorizam clientes através de uma tela de consentimento baseada em navegador. A extensão PKCE garante que os tokens permaneçam seguros, mesmo para clientes públicos que não podem armazenar um segredo.

**Ciclo de vida do token** -- Tokens de acesso podem ser trocados, introspecionados e revogados através de endpoints OAuth padrão. Limitação de taxas nos endpoints de tokens protege contra força bruta.

## Autorização

O controle de acesso usa duas camadas. A [documentação de autenticação](/docs/reference/apis/authentication) cobre escopos, papéis e a matriz de permissões completa em detalhe.

**Escopos** definem quais categorias de recursos um token pode acessar. Um token com `voice:read` pode ler configurações de voz, mas não modificá-las. Os escopos seguem o `resource:action` padrão: `account:read`, `organization:write`, `glossary:admin` para administração de terminologia, e assim por diante.

**Políticas** verificam a relação entre o usuário e o recurso específico. Um token válido com o escopo correto ainda não pode acessar uma organização à qual o usuário não pertence. Cada solicitação é verificada contra ambas as camadas.

## Paginação, filtragem e ordenação

Todos os endpoints de lista retornam resultados paginados com metadados consistentes:

Cada resposta inclui `total_count`, `total_pages`, `current_page`, `page_size`, `has_next_page?`, e `has_previous_page?` para que os clientes possam construir controles de paginação sem adivinhar.

Filtre por qualquer campo indexado usando `filters[field]=value` parâmetros. Ordene de forma ascendente ou descendente com `order_by[]`. A interface é a mesma em todos os recursos.

## OpenAPI e documentação interativa

A especificação completa OpenAPI 3.1 está disponível em `/api/openapi.json`. A [referência da API interativa](/docs/reference/apis/rest) é impulsionada pelo Scalar e permite que você explore endpoints, inspecione esquemas e faça solicitações de teste diretamente do navegador.

Bibliotecas de cliente em qualquer linguagem podem ser geradas a partir da especificação. O contrato é versionado e estável, então suas integrações não quebram quando lançamos novos recursos.