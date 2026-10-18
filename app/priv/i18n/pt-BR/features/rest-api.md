%{
  title: "API REST",
  summary:
    "Uma API REST com foco no desenvolvedor, documentação OpenAPI, autenticação OAuth 2.1 e autorização granular. Tudo o que você pode fazer no painel pode ser feito via API.",
  order: 4,
  icon: "Terminal",
  hero_cta_text: "Comece agora",
  hero_cta_url: "/signup",
  highlights: [
    %{
      title: "Documentado com OpenAPI",
      description:
        "Uma especificação OpenAPI 3.1 completa habilita a documentação interativa via Scalar. Explore endpoints, teste requisições e gere o código do cliente a partir de um único arquivo de especificação.",
      icon: "book-open"
    },
    %{
      title: "OAuth 2.1 com PKCE",
      description:
        "Registro dinâmico de cliente, fluxo de código de autorização com PKCE, inspeção de token e revogação. Clientes de terceiros autenticam-se com segurança sem compartilhamento de segredos.",
      icon: "key-round"
    },
    %{
      title: "Paginação e filtragem",
      description:
        "Todos os endpoints de lista suportam paginação por página, filtragem de campos e ordenação nativa. Metadados de resposta previsíveis tornam a criação de clientes direta.",
      icon: "Código"
    }
  ]
}
---

## ## O desenvolvedor em primeiro lugar

A API REST é o alicerce do Glossia. O painel, o CLI e o [servidor MCP](/features/mcp-server) consomem os mesmos endpoints. Quando adicionamos um recurso, ele chega à API primeiro e se torna visível em todos os outros lugares a partir daí.

Isso significa que você nunca fica limitado pela interface. Qualquer fluxo de trabalho que você possa imaginar, desde integrações CI/CD até painéis personalizados, pode ser construído por cima da mesma interface estável e documentada.

## ## Autenticação

O Glossia utiliza OAuth 2.1 com PKCE para toda autenticação de API. O fluxo suporta tanto clientes de primeira quanto de terceiros partes. Consulte os [documentos de autenticação e autorização](/docs/reference/apis/authentication) para o walkthrough completo.

**Registro dinâmico de clientes** -- Os clientes se registram programaticamente em `/oauth/register` com seus URIs de redirecionamento e tipos de concessão. Sem etapa manual de aprovação, sem portal para interagir.

**Código de autorização com PKCE** -- Os usuários autorizam clientes por meio de uma tela de consentimento baseada no navegador. A extensão PKCE garante que os tokens permaneçam seguros, mesmo para clientes públicos que não podem armazenar um segredo.

**Ciclo de vida do token** -- Os tokens de acesso podem ser trocados, inspecionados e revogados por meio de endpoints OAuth padrão. A limitação de taxas nos endpoints de tokens protege contra brutas.

## ## Autorização

O controle de acesso utiliza duas camadas. Os [documentos de autenticação](/docs/reference/apis/authentication) cobrem escopos, papéis e a matriz completa de permissões em detalhes.

**Escopos** definem quais categorias de recursos um token pode acessar. Um token com `voice:read` pode ler configurações de voz, mas não pode alterá-las. Os escopos seguem o `resource:action` padrão: `account:read`, `organization:write`, `glossary:admin` para administração de glossário e assim por diante.

**Políticas** verificam a relação entre o usuário e o recurso específico. Um token válido com o escopo correto ainda não pode acessar uma organização da qual o usuário não faz parte. Todas as solicitações são verificadas contra ambas as camadas.

## ## Paginação, filtragem e ordenação

Todos os endpoints de lista retornam resultados paginados com metadados consistentes:

Cada resposta inclui `total_count`, `total_pages`, `current_page`, `page_size`, `has_next_page?`, e `has_previous_page?` para que os clientes possam construir controles de paginação sem adivinhar.

Filtre por qualquer campo indexado usando `filters[field]=value` parâmetros de consulta. Ordene de forma ascendente ou descendente com `order_by[]` parâmetros. A interface é a mesma em todos os recursos.

## ## OpenAPI e documentação interativa

A especificação completa da OpenAPI 3.1 está disponível em `/api/openapi.json`. A [referência de API interativa](/docs/reference/apis/rest) é alimentada pelo Scalar e permite explorar endpoints, inspecionar esquemas e fazer solicitações de teste diretamente do navegador.

Bibliotecas de cliente em qualquer linguagem podem ser geradas a partir da especificação. O contrato é versionado e estável, então suas integrações não quebram quando lançamos novos recursos.
