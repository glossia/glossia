%{
  title: "Autorização",
  summary:
    "Escopos de permissão, papéis da organização e verificações de acesso no nível de recurso.",
  category: "Referência",
  subcategory: "APIs",
  order: 2
}
---

A autenticação estabelece uma identidade; a autorização decide quais ações essa identidade pode executar. Consulte [Autenticação](/docs/reference/apis/authentication) para fluxos de login e de token.

## Escopos

Os escopos controlam quais ações um token pode executar. Seguem o `object:action` padrão.

| Escopo | Descrição |
|-------|-------------|
| `admin:read` | Ler dados de administração de plataforma (apenas administradores de plataforma) |
| `admin:write` | Atualizar dados de administração de plataforma (apenas administradores de plataforma) |
| `ops:read` | Ler dados de operação de plataforma (apenas administradores de plataforma) |
| `user:read` | Ler informações de perfil de usuário |
| `user:write` | Atualizar perfil de usuário |
| `account:read` | Listar contas de organização às quais você tem acesso |
| `organization:read` | Ler detalhes da organização (e listar suas organizações) |
| `organization:write` | Criar ou atualizar organizações |
| `organization:claim` | Reivindicar uma organização |
| `organization:delete` | Excluir organizações |
| `organization:admin` | Ações administrativas da organização |
| `members:read` | Ler membros da organização e convites |
| `members:write` | Gerenciar membros da organização e convites |
| `project:read` | Ler projetos |
| `project:write` | Criar ou atualizar projetos |
| `project:admin` | Ações administrativas do projeto |
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
| `ticket:admin` | Ações administrativas de tickets |
| `llm_model:read` | Ler modelos de linguagem de conta |
| `llm_model:write` | Gerenciar modelos de linguagem de conta |
| `translation:write` | Gravar dados de tradução |
| `api_credentials:read` | Ler credenciais de acesso |
| `api_credentials:write` | Gerenciar credenciais de acesso |

Os [metadados de descoberta](/docs/reference/apis/authentication#discovery-endpoints) do servidor de autenticação publicam os escopos disponíveis para os clientes. O simples fato de um escopo estar disponível não concede acesso por si só.

## Modelo de autorização

O Glossia aplica **duas camadas** para a interface de programação de aplicações [Representational State Transfer](https://developer.mozilla.org/en-US/docs/Glossary/REST) e o servidor [Model Context Protocol](https://modelcontextprotocol.io):

1. **Verificação de escopo**: o token de acesso deve incluir o escopo `object:action` necessário.
2. **Política no nível de recurso**: o usuário atual deve ser autorizado para o recurso específico por meio de permissões de membro explícitas ou pela política baseada em funções.

Os escopos representam a *máxima* capacidade de um token. As verificações no nível de recurso impõem a *efetiva* permissão para um recurso específico.

### Funções

| Função | Descrição |
|------|-------------|
| `self` | O usuário acessando seus próprios recursos |
| `organization_member` | Um membro da organização que possui o recurso |
| `organization_admin` | Um administrador da organização que possui o recurso |
| `public_account` | O recurso pertence a uma conta pública |

### Permissões de membro

As associações de organização não-administradoras podem transportar escopos de permissão explícitos. Os novos membros começam com acesso de leitura à conta, organização, projetos, voz, glossário, discussões e tickets. Um administrador de organização pode substituir esses escopos através de [Membros → Permissões](/docs/how-to/member-permissions). Quando usando um token, a ação solicitada deve estar incluída nos escopos permitidos do membro bem como nos escopos do token.

Os administradores de organização mantêm sua função de administrador. As associações existentes sem escopos explícitos continuam a utilizar a política baseada em funções abaixo até que as permissões sejam salvas.

### Permissões por função

A tabela abaixo mostra regras comuns baseadas em função para associações sem escopos explícitos. Esta não é a política completa: solicitações de coleta, acesso temporário e administradores de plataforma têm regras adicionais.

| Escopo | Próprio | Membro da organização | Administrador da organização | Conta pública |
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
