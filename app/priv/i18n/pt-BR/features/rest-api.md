%{
  title: "REST API",
  summary:
    "Uma REST API voltada para desenvolvedores, com documentação OpenAPI, autenticação OAuth 2.1 e autorização granular. Tudo o que você pode fazer no dashboard também pode ser feito via API.",
  order: 4,
  icon: "Terminal",
  hero_cta_text: "Começar",
  hero_cta_url: "/signup",
  highlights: [
    %{
      title: "Documentação OpenAPI",
      description:
        "Especificação OpenAPI 3.1 completa que habilita documentação interativa via Scalar. Explore endpoints, teste requisições e gere o código do cliente a partir de um único arquivo de especificação.",
      icon: "book-open"
    },
    %{
      title: "OAuth 2.1 com PKCE",
      description:
        "Registro dinâmico de cliente, fluxo de código de autorização com PKCE, introspecção de token e revogação. Clientes de terceiros autenticam-se com segurança sem compartilhar segredos.",
      icon: "key-round"
    },
    %{
      title: "Paginação e filtragem",
      description:
        "Todos os endpoints de lista suportam paginação por página, filtragem de campos e ordenação nativa. Metadados de resposta previsíveis facilitam a construção de clientes.",
      icon: "code"
    }
  ]
}
---
## Desenvolvedor primeiro

A REST API é a espinha dorsal do Glossia. O dashboard, o CLI e o [Servidor MCP](/features/mcp-server) todos consomem os mesmos endpoints. Quando adicionamos um recurso, ele chega na API primeiro e se torna disponível em todos os outros locais a partir dali.

Isso significa que você nunca é limitado pela interface do usuário. Qualquer fluxo de trabalho que você possa imaginar, desde integrações CI/CD até dashboards personalizados, pode ser construído sobre a mesma interface estável e documentada.

## Autenticação

O Glossia usa OAuth 2.1 com PKCE para autenticação de API. O fluxo suporta clientes de primeira e de terceira parte. Veja a [documentação de autenticação e autorização](/docs/reference/apis/authentication) para o tutorial completo.

**Registro dinâmico de clientes** -- Os clientes se registram programaticamente em `/oauth/register` com seus URIs de redirecionamento e tipos de concessão. Sem etapa de aprovação manual, sem portal para navegar.

**Código de autorização com PKCE** -- Os usuários autorizam clientes por meio de uma tela de consentimento baseada em navegador. A extensão PKCE garante que os tokens permaneçam seguros mesmo para clientes públicos que não podem armazenar um segredo.

**Ciclo de vida do token** -- Os tokens de acesso podem ser trocados, introspecionados e revogados por meio de endpoints OAuth padrão. A limitação de taxa nos endpoints de token protege contra ataques de força bruta.

## Autorização

O controle de acesso utiliza duas camadas. A [documentação de autenticação](/docs/reference/apis/authentication) aborda escopos, funções e a matriz completa de permissões em detalhes.

**Escopos** definem quais categorias de recursos um token pode acessar. Um token com `voice:read` pode ler configurações de voz, mas não pode modificá-las. Os escopos seguem o `resource:action` padrão: `account:read`( `organization:write`And `glossary:admin` Para administração de terminologia, e assim por diante.

**Políticas** Verifique a relação entre o usuário e o recurso específico. Um token válido com o escopo correto ainda não pode acessar uma organização à qual o usuário não pertence. Cada solicitação é verificada em ambas as camadas.

## Paginação, filtragem e ordenação

Todos os endpoints de lista retornam resultados paginados com metadados consistentes:

Cada resposta inclui `total_count`, `total_pages`, `current_page`, `page_size`, `has_next_page?`e ago `has_previous_page?` assim, os clientes podem criar controles de paginação sem ter que adivinhar.

Filtrar por qualquer campo indexado usando `filters[field]=value` parâmetros de consulta. Ordenar em ordem crescente ou decrescente com `order_by[]` Parâmetros. A interface é a mesma em todos os recursos.

## OpenAPI e documentação interativa

A especificação completa do OpenAPI 3.1 está disponível em `/api/openapi.json`. A [referência de API interativa](/docs/reference/apis/rest) é impulsionada pelo Scalar e permite que você explore endpoints, examine esquemas e realize solicitações de teste diretamente do navegador.

Bibliotecas de cliente em qualquer linguagem podem ser geradas a partir da especificação. O contrato é versionado e estável, de modo que suas integrações não quebram quando lançamos novas funcionalidades.