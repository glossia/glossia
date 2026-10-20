%{
  title: "Autenticação",
  summary: "Login no navegador, tokens de acesso e pontos de autenticação.",
  category: "Referência",
  subcategory: "APIs",
  order: 1
}
---

Esta página descreve [Open Authorization](https://oauth.net/2.1/) (OAuth), [Proof Key for Code Exchange](https://datatracker.ietf.org/doc/html/rfc7636) (PKCE) e a [interface de programação de aplicações](https://developer.mozilla.org/en-US/docs/Glossary/API) (API). As especificações de protocolos vinculadas abaixo são publicadas como Requests for Comments (RFCs).

## Métodos de autenticação

O Glossia suporta sessões do navegador e tokens de portador. Tokens de portador podem ser emitidos através do fluxo de autenticação abaixo ou criados como [tokens de conta](/docs/reference/apis/account-tokens).

### Sessões do navegador

Quando você realiza o login através da interface web, o Glossia usa autenticação baseada em sessão. Você autentica via GitHub, GitLab, Google ou um provedor de identidade de organização configurado usando a biblioteca [Assent](https://github.com/pow-auth/assent). Após um login bem-sucedido, um cookie de sessão é definido e usado para solicitações subsequentes.

Organizações podem configurar Google Workspace ou Okta e verificar seu domínio de e-mail corporativo antes de permitir inscrição automática. Veja [Configurar login de organização](/docs/how-to/organization-sign-in) para requisitos de instalação e vinculação de conta.

### Tokens de portador (OAuth 2.1)

Para acesso de API (como do CLI ou outras ferramentas), o Glossia implementa OAuth 2.1 com o fluxo de código de autorização e PKCE. Os clientes obtêm um token de portador e incluem-no no cabeçalho `Authorization`:

```
Authorization: Bearer <access_token>
```

## Fluxo OAuth 2.1

### 1. Registro dinâmico de clientes

Os clientes registram-se chamando `POST /oauth/register` com seus metadados. Isso segue [RFC 7591](https://datatracker.ietf.org/doc/html/rfc7591).

```json
{
  "client_name": "My Tool",
  "redirect_uris": ["http://localhost:8080/callback"],
  "grant_types": ["authorization_code"]
}
```

O Glossia retorna `client_id` e `client_secret`. O redirecionamento `localhost` neste exemplo pertence ao seu aplicativo durante o desenvolvimento. Aplicativos de produção devem registrar seu próprio endereço de callback seguro.

### 2. Solicitação de autorização

O cliente redireciona o usuário para `/oauth/authorize` com parâmetros PKCE:

```
GET /oauth/authorize?response_type=code&client_id=<id>&redirect_uri=<uri>&code_challenge=<challenge>&code_challenge_method=S256&state=<state>
```

**PKCE é requerido para todos os clientes.** Apenas o método de desafio `S256` é suportado.

### 3. Troca de token

Após o usuário aprovar, o cliente troca o código de autorização por tokens em `POST /oauth/token`:

```
POST /oauth/token
Content-Type: application/x-www-form-urlencoded

grant_type=authorization_code&code=<code>&redirect_uri=<uri>&client_id=<id>&client_secret=<secret>&code_verifier=<verifier>
```

A resposta inclui um token de acesso e, opcionalmente, um token de atualização.

### 4. Atualização de token

Quando um token de acesso expira, use o token de atualização:

```
POST /oauth/token
Content-Type: application/x-www-form-urlencoded

grant_type=refresh_token&refresh_token=<token>&client_id=<id>&client_secret=<secret>
```

Veja [Autenticação](/docs/reference/apis/authorization) para escopes de permissão, acesso de membros e verificações do nível de recurso.

## Pontos de descoberta

O Glossia publica metadados em URLs bem conhecidas padrão para que clientes possam descobrir endpoints automaticamente.

### Metadados do Servidor de Autorização OAuth (RFC 8414)

```
GET /.well-known/oauth-authorization-server
```

Retorna o emissor, os endpoints, escopes suportados, tipos de concessão e métodos de desafio de código.

### Metadados de Recurso Protegido (RFC 9728)

```
GET /.well-known/oauth-protected-resource
```

Retorna o identificador do recurso, servidores de autorização, escopes suportados e métodos de portador.

## Limitação de taxa (Rate limiting)

O registro é limitado pelo endereço do cliente. solicitações de token, revogação e introspecção são limitadas tanto pelo endereço quanto pelo identificador do cliente:

| Endpoint | Limite |
|----------|-------|
| `POST /oauth/register` | 5 solicitações por minuto |
| `POST /oauth/token` | 30 solicitações por minuto |
| `POST /oauth/revoke` | 30 solicitações por minuto |
| `POST /oauth/introspect` | 30 solicitações por minuto |

Quando limitado por taxa, o servidor retorna HTTP 429 (Too Many Requests).
