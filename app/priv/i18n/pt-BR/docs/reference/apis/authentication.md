%{
  title: "Autenticação e autorização",
  summary: "Como o Glossia autentica usuários e autoriza o acesso à API.",
  category: "Referência",
  subcategory: "APIs",
  order: 1
}
---
## Métodos de autenticação

O Glossia suporta dois métodos de autenticação dependendo do contexto.

### Sessões do navegador

Quando você se autentica através da interface web, o Glossia usa autenticação baseada em sessão. Você se autentica através de um provedor de terceiros (GitHub ou GitLab) usando a [Assent](https://github.com/pow-auth/assent) biblioteca. Após uma autenticação bem-sucedida, um cookie de sessão é definido e usado em solicitações subsequentes.

### Tokens Bearer (OAuth 2.1)

Para acesso à API (como a partir do CLI ou outras ferramentas), o Glossia implementa o OAuth 2.1 com fluxo de autorização de código e PKCE. Os clientes obtêm um token Bearer e o incluem no `Authorization` Cabeçalho:

    Authorization: Bearer <access_token>

## Fluxo OAuth 2.1

### 1\. Registro dinâmico de clientes

Os clientes realizam o registro chamando `POST /oauth/register` com seus metadados. Isso segue [RFC 7591](https://datatracker.ietf.org/doc/html/rfc7591).

```json
{
  "client_name": "My Tool",
  "redirect_uris": ["http://localhost:8080/callback"],
  "grant_types": ["authorization_code"]
}
```

O servidor retorna `client_id` e `client_secret`.

### 2\. Solicitação de autorização

O cliente redireciona o usuário para `/oauth/authorize` com os parâmetros do PKCE:

    GET /oauth/authorize?response_type=code&client_id=<id>&redirect_uri=<uri>&code_challenge=<challenge>&code_challenge_method=S256&state=<state>

**O PKCE é obrigatório para todos os clientes.** Apenas o `S256` método de desafio é suportado.

### 3\. Troca de token

Após a aprovação do usuário, o cliente troca o código de autorização por tokens em `POST /oauth/token`:

    POST /oauth/token
    Content-Type: application/x-www-form-urlencoded
    
    grant_type=authorization_code&code=<code>&redirect_uri=<uri>&client_id=<id>&code_verifier=<verifier>

A resposta inclui um token de acesso e opcionalmente um token de atualização.

### 4\. Atualização do token

Quando um token de acesso expira, use o token de atualização:

    POST /oauth/token
    Content-Type: application/x-www-form-urlencoded
    
    grant_type=refresh_token&refresh_token=<token>&client_id=<id>&client_secret=<secret>

## Escopos

Os escopos controlam quais ações um token pode executar. Eles seguem as `object:action` padrão.

| Escopo | Descrição |
|-------|-------------|
| `user:read` | Ler informações do perfil do usuário |
| `user:write` | Atualizar perfil do usuário |
| `account:read` | Listar contas da organização às quais você tem acesso |
| `organization:read` | Ler detalhes da organização (e listar suas organizações) |
| `organization:write` | Criar ou atualizar organizações |
| `organization:delete` | Excluir organizações |
| `organization:admin` | Ações administrativas da organização |
| `members:read` | Ver membros e convites da organização |
| `members:write` | Gerenciar membros e convites da organização |
| `project:read` | Ver projetos |
| `project:write` | Criar ou atualizar projetos |
| `project:admin` | Ações administrativas do projeto |
| `project:delete` | Excluir projetos |
| `voice:read` | Ver configuração de voz |
| `voice:write` | Criar ou atualizar configuração de voz |
| `voice:admin` | Ações administrativas de voz |
| `glossary:read` | Ler entradas do glossário |
| `glossary:write` | Criar ou atualizar entradas do glossário |
| `glossary:admin` | Gerenciar configurações de glossário |

## Modelo de autorização

Glossia impõe **dois níveis** para o REST API e servidor MCP:

1. **Verificação de escopo**: o token de acesso deve incluir o necessário `object:action` escopo.
2. **Política de nível de recurso**: o usuário atual deve estar autorizado para o recurso específico por `Glossia.Policy`.

Escopos representam o *máximo* capacidade de um token. O sistema de política impõe o *efetiva* permissão para um recurso específico.

### Papéis

| Papel | Descrição |
|------|-------------|
| `self` | O usuário que acessa seus próprios recursos |
| `organization_member` | Um membro da organização que possui o recurso |
| `organization_admin` | Um administrador da organização que possui o recurso |
| `public_account` | A conta é pública (somente leitura) |

### Permissões por função

| Escopo | Próprio | Membro da Organização | Administrador da Organização | Conta Pública |
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

## Endpoints de descoberta

A Glossia publica metadados em URLs padrão bem conhecidas para que os clientes possam descobrir endpoints automaticamente.

### Metadados do Servidor de Autorização OAuth (RFC 8414)

    GET /.well-known/oauth-authorization-server

Retorna o emissor, endpoints, escopos suportados, tipos de concessão e métodos de desafio de código.

### Metadados de Recursos Protegidos (RFC 9728)

    GET /.well-known/oauth-protected-resource

Retorna o identificador do recurso, servidores de autorização, escopos suportados e métodos de portador.

## Limitação de taxa

Os endpoints OAuth são limitados por taxa por endereço IP:

| Endpoint | Limite |
|----------|-------|
| `POST /oauth/register` | 5 requisições por minuto |
| `POST /oauth/token` | 30 requisições por minuto |
| `POST /oauth/revoke` | 30 requisições por minuto |
| `POST /oauth/introspect` | 30 requisições por minuto |

Em caso de limitação de taxa, o servidor retorna HTTP 429 (Muitas Requisições).