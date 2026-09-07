%{
  title: "Entrar com Glossia",
  summary:
    "Permita que os usuários façam login no seu aplicativo usando sua conta Glossia via OAuth 2.1.",
  category: "Tutorial",
  order: 2
}
---
Este guia o orienta a adicionar "Login com Glossia" ao seu aplicativo. Ao final, seus usuários poderão fazer login com sua conta Glossia e seu aplicativo terá um token de acesso para chamar a API do Glossia em seu nome.

Glossia usa **OAuth 2.1 com PKCE** (Chave de Prova para Troca de Código). O PKCE é obrigatório para todos os clientes, incluindo aplicativos do lado do servidor.

## 1\. Registre seu aplicativo OAuth

Você tem duas opções para registrar seu aplicativo:

### Opção A: Através do painel (recomendado)

1. Faça login no Glossia e vá para seu painel de conta.
2. Abra a **API** seção da barra lateral e clique em **Aplicativos OAuth**.
3. Clique **Novo aplicativo**.
4. Preencha o aplicativo **nome** e **URL de callback** (também chamado URI de redirecionamento).
5. Clique **Criar aplicativo**.

Após a criação, anote o **Client ID** e **Client secret**. O segredo é exibido uma vez, então armazene-o com segurança.

### Opção B: Registro dinâmico de cliente

Envie uma `POST` requisição para `/oauth/register`:

```bash
curl -X POST https://glossia.ai/oauth/register \
  -H "Content-Type: application/json" \
  -d '{
    "client_name": "My App",
    "redirect_uris": ["https://myapp.com/auth/callback"],
    "grant_types": ["authorization_code"]
  }'
```

A resposta inclui `client_id` e `client_secret`.

## 2\. Gerar um desafio de código PKCE

Antes de redirecionar o usuário, gere um verificador e desafio de código PKCE:

```javascript
function generateCodeVerifier() {
  const array = new Uint8Array(32);
  crypto.getRandomValues(array);
  return btoa(String.fromCharCode(...array))
    .replace(/\+/g, "-")
    .replace(/\//g, "_")
    .replace(/=+$/, "");
}

async function generateCodeChallenge(verifier) {
  const encoder = new TextEncoder();
  const data = encoder.encode(verifier);
  const digest = await crypto.subtle.digest("SHA-256", data);
  return btoa(String.fromCharCode(...new Uint8Array(digest)))
    .replace(/\+/g, "-")
    .replace(/\//g, "_")
    .replace(/=+$/, "");
}

const codeVerifier = generateCodeVerifier();
const codeChallenge = await generateCodeChallenge(codeVerifier);
// Store codeVerifier in your session -- you will need it in step 4
```

## 3\. Redirecionar o usuário para Glossia

Crie a URL de autorização e redirecione o navegador do usuário:

    https://glossia.ai/oauth/authorize?
      response_type=code
      &client_id=YOUR_CLIENT_ID
      &redirect_uri=https://myapp.com/auth/callback
      &code_challenge=YOUR_CODE_CHALLENGE
      &code_challenge_method=S256
      &scope=user:read+project:read
      &state=RANDOM_STATE_VALUE

**Parâmetros:**

| Parâmetro | Obrigatório | Descrição |
|-----------|----------|-------------|
| `response_type` | Sim | Sempre `code` |
| `client_id` | Sim | ID do cliente do seu aplicativo |
| `redirect_uri` | Sim | Deve corresponder a uma URL de callback registrada |
| `code_challenge` | Sim | O desafio de código PKCE (S256) |
| `code_challenge_method` | Sim | Sempre `S256` |
| `scope` | Nome | Lista separada por espaços [escopos](/docs/reference/apis/authentication). O padrão é o acesso mínimo se omitido |
| `state` | Recomendado | Uma string aleatória para prevenir ataques CSRF. Verifique se corresponde quando o usuário retorna |

O usuário verá uma tela de consentimento mostrando o nome do seu aplicativo e os escopos solicitados. Após a aprovação, o Glossia redireciona de volta para o URL de callback com um código de autorização.

## 4\. Troque o código pelos tokens

Quando o usuário for redirecionado de volta para o URL de callback, a URL conterá um `code` parâmetro:

    https://myapp.com/auth/callback?code=AUTHORIZATION_CODE&state=RANDOM_STATE_VALUE

Primeiro, verifique que `state` corresponde ao que você enviou no passo 3. Depois, troque o código por tokens:

```bash
curl -X POST https://glossia.ai/oauth/token \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "grant_type=authorization_code" \
  -d "code=AUTHORIZATION_CODE" \
  -d "redirect_uri=https://myapp.com/auth/callback" \
  -d "client_id=YOUR_CLIENT_ID" \
  -d "client_secret=YOUR_CLIENT_SECRET" \
  -d "code_verifier=YOUR_CODE_VERIFIER"
```

A resposta:

```json
{
  "access_token": "eyJhbGciOiJSUzI1...",
  "token_type": "bearer",
  "expires_in": 3600,
  "refresh_token": "dGhpcyBpcyBhIHJl..."
}
```

Armazene ambos os tokens com segurança. O token de acesso é usado para requisições de API. O token de atualização é usado para obter um novo token de acesso quando o atual expirar.

## 5\. Chamar a API em nome do usuário

Use o token de acesso para fazer requisições de API autenticadas:

```bash
curl -H "Authorization: Bearer eyJhbGciOiJSUzI1..." \
  https://glossia.ai/api/projects
```

Os escopos do token limitam quais endpoints você pode acessar. A autorização em nível de recurso ainda se aplica -- por exemplo, um token que `project:read` apenas pode ler os projetos aos quais o usuário tem acesso.

## 6\. Atualizar o token

Quando o token de acesso expirar, use o token de atualização para obter um novo sem enviar o usuário pelo fluxo de consentimento novamente:

```bash
curl -X POST https://glossia.ai/oauth/token \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "grant_type=refresh_token" \
  -d "refresh_token=dGhpcyBpcyBhIHJl..." \
  -d "client_id=YOUR_CLIENT_ID" \
  -d "client_secret=YOUR_CLIENT_SECRET"
```

## 7\. Revogar um token

Quando um usuário desconecta seu aplicativo ou você não precisa mais do acesso, revogue o token:

```bash
curl -X POST https://glossia.ai/oauth/revoke \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "token=eyJhbGciOiJSUzI1..." \
  -d "client_id=YOUR_CLIENT_ID" \
  -d "client_secret=YOUR_CLIENT_SECRET"
```

## Escolhendo escopos

Solicite apenas os escopos que seu aplicativo precisa. Aqui estão algumas combinações comuns:

| Caso de uso | Escopos |
|----------|--------|
| Ler perfil do usuário | `user:read` |
| Ler projetos e conteúdo | `user:read project:read voice:read` |
| Gerenciar projetos | `user:read project:read project:write` |
| Acesso completo à organização | `user:read organization:read organization:write members:read members:write project:read project:write` |

Veja a [referência completa de escopos](/docs/reference/apis/authentication) para todos os escopos disponíveis.

## Endpoints de descoberta

Seu aplicativo pode descobrir automaticamente os endpoints OAuth do Glossia consultando o metadado do servidor:

```bash
curl https://glossia.ai/.well-known/oauth-authorization-server
```

Isso retorna um documento JSON com `authorization_endpoint`, `token_endpoint`, `revocation_endpoint`e outros detalhes. Usar a descoberta torna sua integração resiliente a alterações nos endpoints.

## Tratamento de erros

### Erros de autorização

Se o usuário negar o consentimento ou algo der errado durante a autorização, o Glossia redireciona para a sua URL de callback com um `error` parâmetro:

    https://myapp.com/auth/callback?error=access_denied&state=RANDOM_STATE_VALUE

Códigos de erro comuns:

| Erro | Significado |
|-------|---------|
| `access_denied` | O usuário negou a solicitação de autorização |
| `invalid_request` | A requisição falta um parâmetro obrigatório |
| `invalid_scope` | Um ou mais escopos solicitados não são válidos |

### Erros de token

O endpoint de token retorna HTTP 400 com um corpo de erro JSON:

```json
{
  "error": "invalid_grant",
  "error_description": "The authorization code has expired or was already used."
}
```

### Limites de taxa

Os endpoints OAuth são limitados por taxa por IP. Se você atingir o limite, receberá HTTP 429. Veja o [referência de limitação de taxa](/docs/reference/apis/authentication) para mais detalhes.

## Lista de verificação de segurança

Antes de ir para produção, verifique que sua implementação segue essas práticas:

- Sempre use HTTPS para URLs de callback em produção
- Validar o `state` parâmetro no callback para prevenir CSRF
- Armazene tokens criptografados em repouso
- Nunca exponha tokens em JavaScript do lado do cliente ou em URLs do navegador
- Utilize o conjunto mínimo de escopos necessários
- Gerencie a expiração de tokens adequadamente com tokens de atualização
- Revogue tokens quando os usuários se desconectarem ou excluam suas contas