%{
  title: "API REST",
  summary:
    "Uma API REST com foco em desenvolvedores, documentação OpenAPI, autenticação OAuth 2.1 e autorização granularizada. Tudo que você pode fazer no painel, você pode fazer através da API.",
  order: 4,
  icon: "terminal",
  hero_cta_text: "Começar",
  hero_cta_url: "/signup",
  highlights: [
    %{
      title: "Documentado em OpenAPI",
      description:
        "Uma especificação completa OpenAPI 3.1 permite documentação interativa via Scalar. Explore endpoints, teste requisições e gere código de cliente a partir de um único arquivo de especificação.",
      icon: "book-open"
    },
    %{
      title: "OAuth 2.1 com PKCE",
      description:
        "Registro dinâmico de clientes, fluxo de código de autorização com PKCE, introspecção de token e revogação. Clientes de terceiros autenticam-se de forma segura sem compartilhar segredos.",
      icon: "key-round"
    },
    %{
      title: "Paginação e filtragem",
      description:
        "Todos os endpoints de lista suportam paginação baseada em página, filtragem de campos e ordenação por padrão. Metadados de resposta previsíveis tornam a construção de clientes direta.",
      icon: "code"
    }
  ]
}
---
## Primeiro para desenvolvedores

A API REST é o coração da Glossia. O painel de controle, a CLI e o [servidor MCP](/features/mcp-server) consomem todos os mesmos endpoints. Quando adicionamos um recurso, ele entra na API primeiro e aparece em todos os outros lugares a partir daí.

Isso significa que você nunca fica limitado pela interface. Qualquer fluxo de trabalho que você possa imaginar, desde integrações de CI/CD até painéis personalizados, pode ser construído sobre o mesmo interface estável e documentado.

## Autenticação

A Glossia usa OAuth 2.1 com PKCE para toda autenticação de API. O fluxo suporta clientes de primeira parte e de terceiros. Veja os [docs de autenticação e autorização](/docs/reference/apis/authentication) para o walkthrough completo.

**Registro dinâmico de clientes** -- Clientes registram-se programaticamente em `/oauth/register` com suas URIs de redirecionamento e tipos de concessão. Sem etapa de aprovação manual, sem portal para clicar.

**Código de autorização com PKCE** -- Usuários autorizam clientes através de uma tela de consentimento baseada em navegador. A extensão PKCE garante que os tokens fiquem seguros mesmo para clientes públicos que não podem armazenar um segredo.

**Ciclo de vida do token** -- Tokens de acesso podem ser trocados, introspectados e revogados através de endpoints de OAuth padrão. Limitação de taxa nos endpoints de tokens protege contra força bruta.

## Autorização

Controle de acesso usa duas camadas. O [docs de autenticação](/docs/reference/apis/authentication) cobrem escopos, papéis e a matriz de permissões completa em detalhe.

**Escopos** definem quais categorias de recursos um token pode acessar. Um token com `voice:read` pode ler configurações de voz mas não pode modificá-las. Escopos seguem o `resource:action` padrão: `account:read`, `organization:write`, `glossary:admin` para administração de terminologia, e assim por diante.

**Políticas** verificam a relação entre o usuário e o recurso específico. Um token válido com o escopo direito ainda não pode acessar uma organização a qual o usuário não pertence. Toda requisição é verificada contra ambas as camadas.

## Paginação, filtragem e ordenação

Todos os endpoints de lista retornam resultados paginados com metadados consistentes:

Toda resposta inclui `total_count`, `total_pages`, `current_page`, `page_size`, `has_next_page?`, e `has_previous_page?` para que clientes controh de paginação sem chutar.

Filtre por qualquer campo indexado usando `filters[field]=value` parâmetros de consulta. Ordene crescente ou decrescente com `order_by[]` parâmetros. A interface é a mesma em todos os recursos.

## OpenAPI e documentos interativos

A especificação completa OpenAPI 3.1 está disponível em `/api/openapi.json`. O [referência da API interativa](/docs/reference/apis/rest) é alimentado pelo Scalar e permite que você explore endpoints, inspecione esquemas e faça requisições de teste diretamente do navegador.

Bibliotecas de clientes em qualquer idioma podem ser geradas a partir da especificação. O contrato é versionado e estável, então suas integrações não quebram quando distribuímos novos recursos.