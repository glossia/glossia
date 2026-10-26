%{
  title: "REST API",
  summary:
    "Uma API REST com documentação OpenAPI, autenticação OAuth 2.1 e autorização de granularidade fina. Tudo o que você pode fazer no painel, você pode fazer através da API.",
  order: 4,
  icon: "terminal",
  hero_cta_text: "Get started",
  hero_cta_url: "/signup",
  highlights: [
    %{
      title: "Documentado em OpenAPI",
      description:
        "Uma especificação completa OpenAPI 3.1 habilita a documentação interativa via Scalar. Explore endpoints, teste requisições e gere código do cliente a partir de um único arquivo de especificação.",
      icon: "book-open"
    },
    %{
      title: "OAuth 2.1 com PKCE",
      description:
        "Registro dinâmico de clientes, fluxo de autorização por código com PKCE, introspecção de tokens e revogação. Clientes de terceiros se autenticam com segurança sem compartilhar segredos.",
      icon: "key-round"
    },
    %{
      title: "Paginação e filtragem",
      description:
        "Todos os endpoints de lista suportam paginação baseada em página, filtragem por campo e ordenação pronta para uso. Metadados de resposta previsíveis facilitam a criação de clientes.",
      icon: "code"
    }
  ]
}
---

## ## Desenvolvedor primeiro

A API REST é a espinha dorsal do Glossia. O painel, a CLI e o [servidor MCP](/features/mcp-server) consomem os mesma endpoints. Quando adicionamos um recurso, ele aterrissa na API primeiro e surge em todos os outros lugares a partir daí.

Isso significa que você nunca é limitado pela interface. Qualquer fluxo de trabalho que você possa imaginar, desde integrações CI/CD até painéis personalizados, pode ser construído sobre a mesma interface estável e documentada.

## ## Autenticação

O Glossia usa OAuth 2.1 com PKCE para toda a autenticação da API. O fluxo suporta tanto clientes de primeira quanto de terceiros. Confira a [documentação de autenticação e autorização](/docs/reference/apis/authentication) para o guia completo.

**Registro de cliente dinâmico** -- Os clientes se registram programaticamente em `/oauth/register` com suas URIs de redirecionamento e tipos de concessão. Sem etapa manual de aprovação, sem portal para clicar.

**Código de autorização com PKCE** -- Os usuários autorizam os clientes por meio de uma tela de consentimento baseada no navegador. A extensão PKCE garante que os tokens permaneçam seguros mesmo para clientes públicos que não podem armazenar um segredo.

**Ciclo de vida do token** -- Tokens de acesso podem ser trocados, introspecionados e revogados por meio de endpoints OAuth padrão. Limitação de taxa nos endpoints de token protege contra força bruta.

## ## Autorização

O controle de acesso utiliza duas camadas. A [documentação de autenticação](/docs/reference/apis/authentication) cobre escopos, funções e a matriz completa de permissões em detalhes.

**Escopos** definem quais categorias de recursos que um token pode acessar. Um token com `voice:read` pode ler configurações de voz, mas não pode modificá-las. Escopos seguem o `resource:action` padrão: `account:read`, `organization:write`, `glossary:admin` para administração de glossário, e assim por diante.

**Políticas** verificam a relação entre o usuário e o recurso específico. Um token válido com o escopo correto ainda não pode acessar uma organização à qual o usuário não pertence. Todas as solicitações são verificadas contra ambas as camadas.

## ## Paginação, filtragem e ordenação

Todos os endpoints de lista retornam resultados paginados com metadados consistentes:

Cada resposta inclui `total_count`, `total_pages`, `current_page`, `page_size`, `has_next_page?` e `has_previous_page?` para que os clientes possam construir controles de paginação sem adivinhar.

Filtre qualquer campo indexado usando parâmetros de consulta `filters[field]=value`. Ordene em ordem crescente ou decrescente com parâmetros `order_by[]`. A interface é a mesma em todos os recursos.

## ## OpenAPI e documentação interativa

A especificação completa OpenAPI 3.1 está disponível em `/api/openapi.json`. A [referência interativa da API](/docs/reference/apis/rest) é impulsionada pelo Scalar e permite que você explore endpoints, inspecione esquemas e faça solicitações de teste diretamente do navegador.

Bibliotecas de cliente em qualquer linguagem podem ser geradas a partir da especificação. O contrato é versionado e estável, portanto suas integrações não serão interrompidas quando lançarmos novos recursos.
