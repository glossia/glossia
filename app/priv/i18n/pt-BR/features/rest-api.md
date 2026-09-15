%{
  title: "REST API",
  summary:
    "Uma REST API voltada para desenvolvedores com documentação OpenAPI, autenticação OAuth 2.1 e autorização granular. Tudo o que você pode fazer no painel pode ser realizado através da API.",
  order: 4,
  icon: "terminal",
  hero_cta_text: "Começar",
  hero_cta_url: "/signup",
  highlights: [
    %{
      title: "Documentado em OpenAPI",
      description:
        "Uma especificação OpenAPI 3.1 completa ativa documentação interativa via Scalar. Explore endpoints, teste requisições e gere código do cliente a partir de um único arquivo de especificação.",
      icon: "book-open"
    },
    %{
      title: "OAuth 2.1 com PKCE",
      description:
        "Registro dinâmico de cliente, fluxo de código de autorização com PKCE, introspecção de tokens e revogação. Clientes de terceiros autenticam-se de forma segura sem compartilhar segredos.",
      icon: "key-round"
    },
    %{
      title: "Paginação e filtragem",
      description:
        "Todos os endpoints de lista suportam paginação baseada em páginas, filtragem por campo e ordenação nativamente. Metadados de resposta previsíveis tornam o desenvolvimento de clientes direto.",
      icon: "code"
    }
  ]
}
---
## Desenvolvedor em primeiro lugar

A REST API é a espinha dorsal do Glossia. O Painel, o CLI e o [servidor MCP](/features/mcp-server) todos consomem os mesmos endpoints. Quando adicionamos uma funcionalidade, ela é implementada na API primeiro e se torna acessível em todos os outros lugares a partir daí.

Isso significa que você nunca fica limitado pela interface. Qualquer fluxo de trabalho que você possa imaginar, desde integrações de CI/CD a dashboards personalizados, pode ser construído sobre a mesma interface estável e documentada.

## Autenticação

O Glossia usa OAuth 2.1 com PKCE para toda autenticação de API. O fluxo suporta clientes de primeira e terceira parte. Veja os [documentos de autenticação e autorização](/docs/reference/apis/authentication) para o tutorial completo.

**Registro dinâmico de clientes** -- Os clientes se registram programaticamente em `/oauth/register` com seus URIs de redirecionamento e tipos de concessão. Sem etapa de aprovação manual, sem portal para acessar.

**Código de autorização com PKCE** -- Usuários autorizam clientes através de uma tela de consentimento baseada em navegador. A extensão PKCE garante que os tokens permaneçam seguros, mesmo para clientes públicos que não possam armazenar um segredo.

**Ciclo de vida do token** -- Tokens de acesso podem ser intercambiados, introspectados e revogados através de endpoints OAuth padrão. Limitação de taxa nos endpoints de token protege contra força bruta.

## Autorização

O controle de acesso utiliza duas camadas. A [documentação de autenticação](/docs/reference/apis/authentication) cobre escopos, papéis e a matriz completa de permissões em detalhes.

**Escopos** definem quais categorias de recursos um token pode acessar. Um token com `voice:read` pode ler configurações de voz, mas não modificá-las. Os escopos seguem o `resource:action` padrão: `account:read`O documento reassemblado falhou anteriormente na validação: a recuperação de texto literal Markdown deve retornar um array de strings JSON de mesmo comprimento. `organization:write`O documento remontado anteriormente falhou na validação: a recuperação de texto\_literal do Markdown deve retornar um array de strings JSON de tamanho correspondente `glossary:admin` para a administração de terminologia, e assim por diante.

**Políticas** Verificar a relação entre o usuário e o recurso específico. Um token válido com o escopo correto ainda não pode acessar uma organização à qual o usuário não pertence. Cada solicitação é verificada em ambas as camadas.

## Paginação, filtragem e ordenação

Todos os endpoints de lista retornam resultados paginados com metadados consistentes:

Cada resposta inclui `total_count`, `total_pages`, `current_page`O documento remontado previamente falhou na validação: a recuperação de literal de texto Markdown deve retornar um array de strings JSON de tamanho correspondente. `page_size`O documento remontado anteriormente falhou na validação: a recuperação de texto-literal do Markdown deve retornar um array de strings JSON de comprimento correspondente `has_next_page?`, e `has_previous_page?` para que os clientes possam criar controles de paginação sem precisar adivinhar.

Filtrar por qualquer campo indexado usando `filters[field]=value` parâmetros de consulta. Ordenar crescente ou decrescente usando `order_by[]` parâmetros. A interface é a mesma em todos os recursos.

## OpenAPI e documentação interativa

A especificação completa OpenAPI 3.1 está disponível em `/api/openapi.json`. O [referência API interativa](/docs/reference/apis/rest) é oferecida por Scalar e permite que você explore endpoints, inspecione esquemas e faça solicitações de teste diretamente do navegador.

As bibliotecas de cliente em qualquer linguagem podem ser geradas a partir da especificação. O contrato está versionado e estável, para que suas integrações não quebrem quando lançamos novos recursos.