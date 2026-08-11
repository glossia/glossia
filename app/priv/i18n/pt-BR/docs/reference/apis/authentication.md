%{
  title: "Autenticação e autorização",
  summary: "Como a Glossia autentica usuários e autoriza o acesso à API.",
  category: "reference",
  subcategory: "apis",
  order: 1
}
---
## Métodos de autenticação

A Glossia oferece dois métodos de autenticação, dependendo do contexto.

### Sessões no navegador

Ao entrar pela interface web, a Glossia usa autenticação baseada em sessão. A autenticação é realizada por meio de um provedor externo (GitHub ou GitLab) usando a biblioteca [Assent](https://github.com/pow-auth/assent). Após uma autenticação bem-sucedida, um cookie de sessão é definido e usado nas solicitações subsequentes.

### Tokens Bearer (OAuth 2.1)

Para acessar a API, como pela CLI ou por outras ferramentas, a Glossia implementa OAuth 2.1 com o fluxo de código de autorização e PKCE. Os clientes obtêm um token Bearer e o incluem no cabeçalho `Authorization`:

```
Authorization: Bearer <access_token>
```

## Fluxo do OAuth 2.1

### 1. Registro dinâmico de clientes

Os clientes se registram chamando `POST /oauth/register` com seus metadados. Esse processo segue a [RFC 7591](https://datatracker.ietf.org/doc/html/rfc7591).

```json
{
  "client_name": "My Tool",
  "redirect_uris": ["http://localhost:8080/callback"],
  "grant_types": ["authorization_code"]
}
```

O servidor retorna `client_id` e `client_secret`.

### 2. Solicitação de autorização

O cliente redireciona o usuário para `/oauth/authorize` com os parâmetros de PKCE:

```
GET /oauth/authorize?response_type=code&client_id=<id>&redirect_uri=<uri>&code_challenge=<challenge>&code_challenge_method=S256&state=<state>
```

**PKCE é obrigatório para todos os clientes.** Somente o método de desafio `S256` é compatível.

### 3. Troca de tokens

Após a aprovação do usuário, o cliente troca o código de autorização por tokens em `POST /oauth/token`:

```
POST /oauth/token
Content-Type: application/x-www-form-urlencoded

grant_type=authorization_code&code=<code>&redirect_uri=<uri>&client_id=<id>&code_verifier=<verifier>
```

A resposta inclui um token de acesso e, opcionalmente, um token de atualização.

### 4. Atualização do token

Quando um token de acesso expirar, use o token de atualização:

```
POST /oauth/token
Content-Type: application/x-www-form-urlencoded

grant_type=refresh_token&refresh_token=<token>&client_id=<id>&client_secret=<secret>
```

## Escopos

Os escopos controlam quais ações um token pode realizar. Eles seguem o padrão `object:action`.

| Escopo | Descrição |
|-------|-------------|
| `user:read` | Ler informações do perfil do usuário |
| `user:write` | Atualizar o perfil do usuário |
| `account:read` | Listar as contas de organizações que você pode acessar |
| `organization:read` | Ler detalhes da organização e listar suas organizações |
| `organization:write` | Criar ou atualizar organizações |
| `organization:delete` | Excluir organizações |
| `organization:admin` | Executar ações administrativas em organizações |
| `members:read` | Ler membros e convites da organização |
| `members:write` | Gerenciar membros e convites da organização |
| `project:read` | Ler projetos |
| `project:write` | Criar ou atualizar projetos |
| `project:admin` | Executar ações administrativas em projetos |
| `project:delete` | Excluir projetos |
| `voice:read` | Ler a configuração de voz |
| `voice:write` | Criar ou atualizar a configuração de voz |
| `voice:admin` | Executar ações administrativas de voz |
| `glossary:read` | Ler entradas de terminologia |
| `glossary:write` | Criar ou atualizar entradas de terminologia |
| `glossary:admin` | Gerenciar configurações de terminologia |

## Modelo de autorização

A Glossia aplica **duas camadas** à API REST e ao servidor MCP:

1. **Verificação de escopo**: o token de acesso deve incluir o escopo `object:action` necessário.
2. **Política no nível do recurso**: o usuário atual deve estar autorizado para o recurso específico por meio de `Glossia.Policy`.

Os escopos representam a capacidade *máxima* de um token. O sistema de políticas aplica a permissão *efetiva* para um recurso específico.

### Funções

| Função | Descrição |
|------|-------------|
| `self` | O usuário que acessa os próprios recursos |
| `organization_member` | Um membro da organização proprietária do recurso |
| `organization_admin` | Um administrador da organização proprietária do recurso |
| `public_account` | A conta é pública (somente leitura) |

### Permissões das funções

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

## Endpoints de descoberta

A Glossia publica metadados em URLs padronizadas e conhecidas para que os clientes possam descobrir os endpoints automaticamente.

### Metadados do servidor de autorização OAuth (RFC 8414)

```
GET /.well-known/oauth-authorization-server
```

Retorna o emissor, os endpoints, os escopos compatíveis, os tipos de concessão e os métodos de desafio de código.

### Metadados do recurso protegido (RFC 9728)

```
GET /.well-known/oauth-protected-resource
```

Retorna o identificador do recurso, os servidores de autorização, os escopos compatíveis e os métodos de autenticação por token portador.

## Limitação de taxa

Os endpoints OAuth têm limitação de taxa por endereço IP:

| Endpoint | Limite |
|----------|-------|
| `POST /oauth/register` | 5 solicitações por minuto |
| `POST /oauth/token` | 30 solicitações por minuto |
| `POST /oauth/revoke` | 30 solicitações por minuto |
| `POST /oauth/introspect` | 30 solicitações por minuto |

Quando o limite de taxa é atingido, o servidor retorna HTTP 429 (Muitas solicitações).