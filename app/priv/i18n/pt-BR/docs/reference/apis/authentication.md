%{
  title: "Autenticação",
  summary: "Login no navegador, tokens de acesso e endpoints de autenticação.",
  category: "referência",
  subcategory: "apis",
  order: 1
}
---
Esta página descreve [Autorização Aberta](https://oauth.net/2.1/) (OAuth), [Chave de Prova para Troca de Código](https://datatracker.ietf.org/doc/html/rfc7636) (PKCE), e a [interface de programação de aplicações](https://developer.mozilla.org/en-US/docs/Glossary/API) (API). As especificações do protocolo vinculadas abaixo são publicadas como Solicitações de Comentários (RFCs).

## Métodos de autenticação

O Glossia suporta sessões de navegador e tokens Bearer. Os tokens Bearer podem ser emitidos através do fluxo de autorização abaixo ou criados como [tokens de conta](/docs/reference/apis/account-tokens).

### Sessões de navegador

Ao fazer login na interface web, o Glossia usa autenticação baseada em sessão. Você se autentica via GitHub, GitLab, Google ou um provedor de identidade de organização configurado usando o [Assent](https://github.com/pow-auth/assent) biblioteca. Após um login bem-sucedido, um cookie de sessão é definido e usado para solicitações subsequentes.

Organizações podem configurar Google Workspace ou Okta e verificar seu domínio de e-mail corporativo antes de permitir inscrição automática. Veja [Configurar login da organização](/docs/how-to/organization-sign-in) para requisitos de configuração e vinculação de contas.

### Tokens Bearer (OAuth 2.1)

Para acesso à API (como do CLI ou outras ferramentas), a Glossia implementa OAuth 2.1 com o fluxo de código de autorização e PKCE. Os clientes obtêm um Token Bearer e o incluem no `Authorization` cabeçalho:

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

Glossia retorna `client_id` e `client_secret`. O `localhost` redirecionamento neste exemplo pertence à sua aplicação durante o desenvolvimento. Aplicações de produção devem registrar o seu próprio endereço de callback seguro.

### 2\. Solicitação de autorização

O cliente redireciona o usuário para `/oauth/authorize` com os parâmetros PKCE:

    GET /oauth/authorize?response_type=code&client_id=<id>&redirect_uri=<uri>&code_challenge=<challenge>&code_challenge_method=S256&state=<state>

**PKCE é obrigatório para todos os clientes.** Apenas o `S256` método de desafio é suportado.

### 3\. Troca de tokens

Após a aprovação do usuário, o cliente troca o código de autorização por tokens em `POST /oauth/token`:

    POST /oauth/token
    Content-Type: application/x-www-form-urlencoded
    
    grant_type=authorization_code&code=<code>&redirect_uri=<uri>&client_id=<id>&client_secret=<secret>&code_verifier=<verifier>

A resposta inclui um token de acesso e opcionalmente um token de atualização.

### 4\. Atualização do token

Quando um token de acesso expirar, use o token de atualização:

    POST /oauth/token
    Content-Type: application/x-www-form-urlencoded
    
    grant_type=refresh_token&refresh_token=<token>&client_id=<id>&client_secret=<secret>

Veja [Autorização](/docs/reference/apis/authorization) para escopos de permissão, acesso de membros e verificações em nível de recurso.

## Pontos finais de descoberta

O Glossia publica metadados em URLs padrão bem conhecidas para que os clientes possam descobrir pontos finais automaticamente.

### Metadados do Servidor de Autorização OAuth (RFC 8414)

    GET /.well-known/oauth-authorization-server

Retorna o emissor, endpoints, escopos suportados, tipos de concessão e métodos de desafio de código.

### Metadados de Recursos Protegidos (RFC 9728)

    GET /.well-known/oauth-protected-resource

Retorna o identificador de recurso, servidores de autorização, escopos suportados e métodos de portador.

## Limitação de taxa

O registro é limitado pelo endereço do cliente. Solicitações de token, revogação e introspecção são limitadas tanto pelo endereço quanto pelo identificador do cliente:

| Endpoint | Limite |
|----------|--------|
| `POST /oauth/register` | 5 solicitações por minuto |
| `POST /oauth/token` | 30 solicitações por minuto |
| `POST /oauth/revoke` | 30 solicitações por minuto |
| `POST /oauth/introspect` | 30 solicitações por minuto |

Em caso de limitação de taxa, o servidor retorna HTTP 429 (Muitas solicitações).