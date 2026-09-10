%{
  title: "Autenticação e autorização",
  summary: "Como o Glossia autentica usuários e autoriza o acesso à API.",
  category: "Referência",
  subcategory: "APIs",
  order: 1
}
---
## Métodos de autenticação

A Glossia suporta dois métodos de autenticação dependendo do contexto.

### Sessões de navegador

Ao fazer login através da interface web, a Glossia usa autenticação baseada em sessão. Você autentica-se via um provedor de terceiros (GitHub ou GitLab) usando a [Assent](https://github.com/pow-auth/assent) biblioteca. Após um login bem-sucedido, um cookie de sessão é definido e usado para requisições subsequentes.

### Tokens Bearer (OAuth 2.1)

Para acesso à API (seja da CLI ou outras ferramentas), a Glossia implementa OAuth 2.1 com fluxo de código de autorização e PKCE. Os clientes obtêm um token Bearer e o incluem no `Authorization` header:

    Authorization: Bearer <access_token>

## Fluxo OAuth 2.1

### 1\. Registro dinâmico de clientes

Os clientes se registram chamando `POST /oauth/register` com seus metadados. Isso segue [RFC 7591](https://datatracker.ietf.org/doc/html/rfc7591).

```json
{
  "client_name": "My Tool",
  "redirect_uris": ["http://localhost:8080/callback"],
  "grant_types": ["authorization_code"]
}
```

O servidor retorna `client_id` e `client_secret`.

### 2\. Solicitação de autorização

O cliente redireciona o usuário para `/oauth/authorize` com os parâmetros PKCE:

    GET /oauth/authorize?response_type=code&client_id=<id>&redirect_uri=<uri>&code_challenge=<challenge>&code_challenge_method=S256&state=<state>

**PKCE é obrigatório para todos os clientes.** Apenas o `S256` método de desafio é suportado.

### 3\. Troca de token

Após o usuário aprovar, o cliente troca o código de autorização por tokens em `POST /oauth/token`:

    POST /oauth/token
    Content-Type: application/x-www-form-urlencoded
    
    grant_type=authorization_code&code=<code>&redirect_uri=<uri>&client_id=<id>&code_verifier=<verifier>

A resposta inclui um token de acesso e, opcionalmente, um token de atualização.

### 4\. Atualização de token

Quando um token de acesso expira, use o token de atualização:

    POST /oauth/token
    Content-Type: application/x-www-form-urlencoded
    
    grant_type=refresh_token&refresh_token=<token>&client_id=<id>&client_secret=<secret>

## Escopos

Escopos controlam quais ações um token pode realizar. Eles seguem o `object:action` padrão.

| Escopo | Descrição |
|-------|-------------|
| `user:read` | Ler informações de perfil do usuário |
| `user:write` | Atualizar perfil do usuário |
| `account:read` | Listar contas de organização às quais você tem acesso |
| `organization:read` | Ler detalhes da organização (e listar suas organizações) |
| `organization:write` | Criar ou atualizar organizações |
| `organization:delete` | Excluir organizações |
| `organization:admin` | Ações administrativas da organização |
| `members:read` | Ler membros e convites da organização |
| `members:write` | Gerenciar membros e convites da organização |
| `project:read` | Ler projetos |
| `project:write` | Criar ou atualizar projetos |
| `project:admin` | Ações administrativas do projeto |
| `project:delete` | Excluir projetos |
| `voice:read` | Ler configuração de voz |
| `voice:write` | Crie ou atualize a configuração de voz |
| `voice:admin` | Ações administrativas de voz |
| `glossary:read` | Ler as entradas de terminologia |
| `glossary:write` | Crie ou atualize as entradas de terminologia |
| `glossary:admin` | Gerenciar configurações de terminologia |

## Modelo de autorização

Glossia impõe **duas camadas** para a REST API e servidor MCP:

1. **Verificação de escopo**: o token de acesso deve incluir o necessário `object:action` escopo.
2. **Política de nível de recurso**: o usuário atual deve ser autorizado para o recurso específico através `Glossia.Policy`.

Escopos representam a *máxima* capacidade de um token. O sistema de política garante a *real* permissão para um recurso específico.

### Papéis

| Papel | Descrição |
|------|-------------|
| `self` | O usuário que acessa seus próprios recursos |
| `organization_member` | Um membro da organização que possui o recurso |
| `organization_admin` | Um administrador da organização que possui o recurso |
| `public_account` | A conta é pública (somente leitura) |

### Permissões de função

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

## Endpoints de descoberta

O Glossia publica metadados em URLs padrão e bem conhecidas para que os clientes possam descobrir endpoints automaticamente.

### Metadados do Servidor de Autorização OAuth (RFC 8414)

    GET /.well-known/oauth-authorization-server

Retorna o emissor, endpoints, escopos suportados, tipos de concessão e métodos de desafio de código.

### Metadados de Recursos Protegidos (RFC 9728)

    GET /.well-known/oauth-protected-resource

Retorna o identificador de recurso, servidores de autorização, escopos suportados e métodos de portador.

## Limitação de taxa

Os endpoints OAuth são limitados por taxa por endereço IP:

| Endpoint | Limite |
|----------|-------|
| `POST /oauth/register` | 5 requisições por minuto |
| `POST /oauth/token` | 30 requisições por minuto |
| `POST /oauth/revoke` | 30 solicitações por minuto |
| `POST /oauth/introspect` | 30 solicitações por minuto |

Quando limitado por taxa, o servidor retorna HTTP 429 (Muitas Solicitações).