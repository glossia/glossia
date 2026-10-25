%{
  title: "Autorização",
  summary:
    "Escopos de permissão, papéis de organização e verificações de acesso no nível do recurso.",
  category: "Referência",
  subcategory: "APIs",
  order: 2
}
---

Autenticação estabelece uma identidade; autorização decide quais ações essa identidade pode executar. Consulte [Autenticação](/docs/reference/apis/authentication) para os fluxos de login e token.

## Escopos

Escopos controlam quais ações um token pode executar. Eles seguem o `object:action` padrão.

| Escopo | Descrição |
|-------|-------------|
| `admin:read` | Ler dados de administração da plataforma (administradores da plataforma apenas) |
| `admin:write` | Atualizar dados de administração da plataforma (administradores da plataforma apenas) |
| `ops:read` | Ler dados de operações da plataforma (administradores da plataforma apenas) |
| `user:read` | Ler informações do perfil do usuário |
| `user:write` | Atualizar perfil do usuário |
| `account:read` | Listar contas de organização às quais você tem acesso |
| `organization:read` | Ler detalhes da organização (e listar suas organizações) |
| `organization:write` | Criar ou atualizar organizações |
| `organization:claim` | Assumir uma organização |
| `organization:delete` | Excluir organizações |
| `organization:admin` | Ações administrativas de organização |
| `members:read` | Ler membros da organização e convites |
| `members:write` | Gerenciar membros da organização e convites |
| `project:read` | Ler projetos |
| `project:write` | Criar ou atualizar projetos |
| `project:admin` | Ações administrativas de projeto |
| `project:delete` | Excluir projetos |
| `voice:read` | Ler configuração de voz |
| `voice:write` | Criar ou atualizar configuração de voz |
| `voice:admin` | Ações administrativas de voz |
| `glossary:read` | Ler entradas de glossário |
| `glossary:write` | Criar ou atualizar entradas de glossário |
| `glossary:admin` | Gerenciar configurações de glossário |
| `discussion:read` | Ler discussões |
| `discussion:write` | Criar ou atualizar discussões |
| `discussion:admin` | Ações administrativas de discussão |
| `ticket:read` | Ler tickets |
| `ticket:write` | Criar ou atualizar tickets |
| `ticket:admin` | Ações administrativas de ticket |
| `llm_model:read` | Ler modelos de linguagem da conta |
| `llm_model:write` | Gerenciar modelos de linguagem da conta |
| `translation:read` | Ler atividade de tradução do projeto |
| `translation:write` | Escrever dados de tradução |
| `analytics:read` | Ler análises do site do projeto |
| `toki:read` | Ler suas conversas privadas do projeto |
| `toki:write` | Criar conversas privadas e enfileirar respostas do companheiro |
| `api_credentials:read` | Ler credenciais de acesso |
| `api_credentials:write` | Gerenciar credenciais de acesso |

Os [metadados de descoberta](/docs/reference/apis/authentication#discovery-endpoints) do servidor de autenticação publicam os escopos disponíveis para clientes. A disponibilidade de um escopo não concede acesso por si só.

## Modelo de autorização

A Glossia impõe **dois níveis** para a interface de programação de aplicação [Representational State Transfer](https://developer.mozilla.org/en-US/docs/Glossary/REST) e o servidor [Model Context Protocol](https://modelcontextprotocol.io):

1. **Verificação de escopo**: o token de acesso deve incluir o escopo `object:action` necessário.
2. **Política em nível de recurso**: o usuário atual deve estar autorizado para o recurso específico por meio de permissões de membro explícitas ou da política baseada em papéis.

Os escopos representam a capacidade *máxima* de um token. As verificações em nível de recurso impõem a permissão *real* para um recurso específico.

### Papéis

| Papel | Descrição |
|------|-------------|
| `self` | O usuário que acessa seus próprios recursos |
| `organization_member` | Um membro da organização que possui o recurso |
| `organization_admin` | Um administrador da organização que possui o recurso |
| `public_account` | O recurso pertence a uma conta pública |

### Permissões de membro

As filiaturas de organização não-administrador podem ter escopos de permissão explícitos. Novos membros começam com acesso de leitura à conta, organização, projetos, voz, glossário, discussões, tickets, atividade de tradução e análises, além de acesso às próprias conversas privadas Toki. Um administrador de organização pode substituir esses escopos por meio de [Membros → Permissões](/docs/how-to/member-permissions). Uma ação solicitada deve estar incluída nos escopos permitidos do membro, além dos escopos do token ao usar um token.

A posse privada Toki é verificada antes das substituições de escopo de membro da organização. Nem a filiação nem os papéis de administrador permitem acesso à conversa de outro usuário. A visibilidade do projeto é verificada separadamente. Consulte a [API móvel e companion](/docs/reference/apis/mobile) para escopos de endpoint e limites.

Administradores de organização mantêm seu papel de administrador. Filiações existentes sem escopos explícitos continuam usando o modelo de autorização abaixo até que as permissões sejam salvas.

### Permissões de papel

A tabela abaixo mostra regras baseadas em papel comuns para filiações sem escopos explícitos. Não é a política completa: solicitações de coleta, acesso temporário e administradores da plataforma têm regras adicionais.

| Escopo | self | organization_member | organization_admin | public_account |
|-------|------|----------------------|--------------------|----------------|
| `user:read` | Sim | Sim | | |
| `user:write` | Sim | | | |
| `account:read` | | Sim | Sim | Sim |
| `organization:read` | | Sim | Sim | |
| `organization:write` | | | Sim | |
| `organization:delete` | | | Sim | |
| `organization:admin` | | | Sim | |
| `members:read` | | Sim | Sim | |
| `members:write` | | | Sim | |
| `project:read` | | Sim | Sim | Sim |
| `project:write` | | | Sim | |
| `project:admin` | | | Sim | |
| `project:delete` | | | Sim | |
| `voice:read` | | Sim | Sim | Sim |
| `voice:write` | | | Sim | |
| `voice:admin` | | | Sim | |
| `glossary:read` | | Sim | Sim | |
| `glossary:write` | | | Sim | |
| `glossary:admin` | | | Sim | |
