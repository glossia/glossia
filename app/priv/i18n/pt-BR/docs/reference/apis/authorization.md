%{
  title: "Autorização",
  summary:
    "Escopos de permissão, papéis de organização e controles de acesso em nível de recurso.",
  category: "Referência",
  subcategory: "APIs",
  order: 2
}
---
Autenticação estabelece uma identidade; a autorização decide quais ações essa identidade pode executar. Veja [Autenticação](/docs/reference/apis/authentication) para fluxos de login e token.

## Escopos

Escopos controlam o que um token pode executar. Eles seguem o `object:action` padrão.

| Escopo | Descrição |
|-------|-------------|
| `admin:read` | Visualizar dados de administração da plataforma (apenas administradores da plataforma) |
| `admin:write` | Atualizar dados de administração da plataforma (apenas administradores da plataforma) |
| `ops:read` | Visualizar dados operacionais da plataforma (apenas administradores da plataforma) |
| `user:read` | Visualizar informações de perfil do usuário |
| `user:write` | Atualizar perfil do usuário |
| `account:read` | Listar contas de organização às quais você tem acesso |
| `organization:read` | Ler detalhes da organização (e listar suas organizações) |
| `organization:write` | Criar ou atualizar organizações |
| `organization:claim` | Assumir uma organização |
| `organization:delete` | Excluir organizações |
| `organization:admin` | Ações administrativas da organização |
| `members:read` | Visualizar membros e convites da organização |
| `members:write` | Gerenciar membros e convites da organização |
| `project:read` | Ler projetos |
| `project:write` | Criar ou atualizar projetos |
| `project:admin` | Ações administrativas de projetos |
| `project:delete` | Excluir projetos |
| `voice:read` | Ler configuração de voz |
| `voice:write` | Criar ou atualizar configuração de voz |
| `voice:admin` | Ações administrativas de voz |
| `glossary:read` | Ler entradas de glossário |
| `glossary:write` | Criar ou atualizar entradas de glossário |
| `glossary:admin` | Gerenciar configurações de glossário |
| `discussion:read` | Ler discussões |
| `discussion:write` | Criar ou atualizar discussões |
| `discussion:admin` | Ações administrativas de discussões |
| `ticket:read` | Ler chamados |
| `ticket:write` | Criar ou atualizar chamados |
| `ticket:admin` | Ações de ticket administrativo |
| `llm_model:read` | Ler modelos de linguagem da conta |
| `llm_model:write` | Gerenciar modelos de linguagem da conta |
| `translation:write` | Escrever dados de tradução |
| `api_credentials:read` | Credenciais de acesso à leitura |
| `api_credentials:write` | Gerenciar credenciais de acesso |

O servidor de autenticação [de metadados de descoberta](/docs/reference/apis/authentication#discovery-endpoints) publicam os escopos disponíveis para clientes. Um escopo disponível não concede acesso por si só.

## Modelo de autorização

Glossia impõe **duas camadas** para a [Representational State Transfer](https://developer.mozilla.org/en-US/docs/Glossary/REST) interface de programação de aplicações e o [Model Context Protocol](https://modelcontextprotocol.io) servidor:

1. **Verificação de escopo**: o token de acesso deve incluir o necessário `object:action` escopo.
2. **Política de nível de recurso**: o usuário atual deve estar autorizado para o recurso específico por meio de permissões explícitas de membro ou da política baseada em papel.

Escopos representam o *máxima* capacidade de um token. As verificações de nível de recurso garantem o *efetivo* permissão para um recurso específico.

### Papéis

| Papel | Descrição |
|------|-------------|
| `self` | O usuário acessando seus próprios recursos |
| `organization_member` | Um membro da organização que possui o recurso |
| `organization_admin` | Um administrador da organização que possui o recurso |
| `public_account` | O recurso pertence a uma conta pública |

### Permissões de membros

Os membros que não são administradores da organização podem ter escopos de permissão explícitos. Novos membros começam com acesso de leitura à conta, organização, projetos, voz, glossário, discussões e tickets. Um administrador da organização pode substituir esses escopos através de [Membros → Permissões](/docs/how-to/member-permissions). A ação solicitada deve estar incluída nos escopos permitidos do membro, bem como nos escopos do token ao usar um token.

Administradores da organização mantêm o papel de administrador. Membros existentes sem escopos explícitos continuam usando a política baseada em papéis abaixo até que as permissões sejam salvas.

### Permissões de papel

A tabela abaixo mostra as regras baseadas em papéis comuns para membros sem escopos explícitos. Ela não é a política completa: solicitações de coleção, acesso temporário e administradores da plataforma têm regras adicionais.

| Escopo | self | organization\_member | organization\_admin | public\_account |
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