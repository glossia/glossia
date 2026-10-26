%{
  title: "Autorização",
  summary:
    "Escopos de permissão, papéis organizacionais e verificações de acesso a nível de recurso.",
  category: "referência",
  subcategory: "APIs",
  order: 2
}
---

Autenticação estabelece uma identidade; a autorização determina quais ações essa identidade pode executar. Veja [Autenticação](/docs/reference/apis/authentication) para fluxos de login e tokens.

## Escopos

Os escopos controlam quais ações um token pode executar. Eles seguem o `object:action` padrão.

| Escopo | Descrição |
|-------|-------------|
| `admin:read` | Ler dados de administração da plataforma (apenas administradores da plataforma) |
| `admin:write` | Atualizar dados de administração da plataforma (apenas administradores da plataforma) |
| `ops:read` | Ler dados de operações da plataforma (apenas administradores da plataforma) |
| `user:read` | Ler informações de perfil de usuário |
| `user:write` | Atualizar perfil de usuário |
| `account:read` | Listar contas da organização às quais você tem acesso |
| `organization:read` | Ler detalhes da organização (e listar suas organizações) |
| `organization:write` | Criar ou atualizar organizações |
| `organization:claim` | Reivindicar uma organização |
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
| `glossary:read` | Ler entradas do glosário |
| `glossary:write` | Criar ou atualizar entradas do glosário |
| `glossary:admin` | Gerenciar configurações do glosário |
| `discussion:read` | Ler discussões |
| `discussion:write` | Criar ou atualizar discussões |
| `discussion:admin` | Ações administrativas de discussão |
| `ticket:read` | Ler chamados |
| `ticket:write` | Criar ou atualizar chamados |
| `ticket:admin` | Ações administrativas de chamado |
| `llm_model:read` | Ler modelos de linguagem da conta |
| `llm_model:write` | Gerenciar modelos de linguagem da conta |
| `translation:read` | Ler atividade de tradução do projeto |
| `translation:write` | Gravar dados de tradução |
| `analytics:read` | Ler análises do site do projeto |
| `toki:read` | Ler suas conversas privadas do projeto |
| `toki:write` | Criar conversas privadas e enfileirar respostas do companheiro |
| `api_credentials:read` | Ler credenciais de acesso |
| `api_credentials:write` | Gerenciar credenciais de acesso |

Os metadados de [descoberta](/docs/reference/apis/authentication#discovery-endpoints) do servidor de autenticação publicam os escopos disponíveis aos clientes. O status de um escopo não concede acesso por si só.

## Modelo de autorização

Glossia impõe **duas camadas** para a interface de programação de aplicações [Transferência de Estado Representacional](https://developer.mozilla.org/en-US/docs/Glossary/REST) e para o servidor [Protocolo de Modelo de Contexto](https://modelcontextprotocol.io):

1. **Verificação de escopo**: o token de acesso deve incluir o `object:action` escopo necessário.
2. **Política em nível de recurso**: o usuário atual deve ser autorizado para o recurso específico por meio de permissões de membro explícitas ou da política baseada em papel.

Os escopos representam a capacidade *máxima* de um token. As verificações em nível de recurso impõem a permissão *efetiva* para um recurso específico.

### Papéis

| Papel | Descrição |
|------|-------------|
| `self` | O usuário acessando seus próprios recursos |
| `organization_member` | Um membro da organização que possui o recurso |
| `organization_admin` | Um administrador da organização que possui o recurso |
| `public_account` | O recurso pertence a uma conta pública |

### Permissões de membro

Membros de organização que não são administradores podem ter escopos de permissão explícitos. Novos membros começam com acesso de leitura à conta, organização, projetos, voz, glosário, discussões, chamados, atividade de tradução e análises, além de acesso às suas próprias conversas Toki privadas. Um administrador de organização pode substituir esses escopos através de [Membros → Permissões](/docs/how-to/member-permissions). Uma ação solicitada deve estar incluída nos escopos permitidos do membro, bem como nos escopos do token ao usá-lo.

A propriedade de conversas Toki privadas é verificada antes da sobreescrição de escopo de membro de organização. Nem as afiliações nem os papéis administradores permitem acesso às conversas de outro usuário. A visibilidade do projeto é verificada separadamente. Consulte a [API móvel e de companheiro](/docs/reference/apis/mobile) para os escopos e limites dos endpoints.

Administradores de organização mantêm sua função administrativa. Afiliaturas existentes sem escopos explícitos continuam a usar a política baseada em papel abaixo até que as permissões sejam salvas.

### Permissões de papel

A tabela abaixo mostra regras comuns baseadas em papel para afiliações sem escopos explícitos. Não é a política completa: solicitações de coleção, acesso temporário e administradores da plataforma possuem regras adicionais.

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
