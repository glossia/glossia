%{
  title: "Entrar com o Glossia",
  summary:
    "Permita que os usuários façam login no seu aplicativo com a conta Glossia usando OAuth 2.1.",
  category: "Tutorial",
  section: "platform",
  order: 2
}
---

Este guia o ajuda a adicionar "Login com Glossia" ao seu aplicativo. Ao final, seus usuários poderão fazer login com sua conta Glossia e seu aplicativo terá um token de acesso para executar chamadas à API Glossia em seu nome.

Glossia usa **OAuth 2.1 com PKCE** (Proof Key for Code Exchange). PKCE é obrigatório para todos os clientes, incluindo aplicações de lado do servidor.

## 1. Registre seu aplicativo OAuth

Você tem duas opções para registrar seu aplicativo:

### Opção A: Pelo painel (recomendado)

1. Faça login no Glossia e vá para o seu painel de conta.
2. Abra a seção **API** na barra lateral e clique em **Aplicativos OAuth**.
3. Clique em **Novo aplicativo**.
4. Preencha o **nome** e **URL de callback** do aplicativo (também chamada de URI de redirecionamento).
5. Clique em **Criar aplicativo**.

Após a criação, anote o **ID do cliente** e o **segredo do cliente**. O segredo é exibido uma única vez, então guarde-o com segurança.

### Opção B: Registro dinâmico do cliente

Envie `POST` para `/oauth/register`:

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

## 2. Gere um desafio de código PKCE

Antes de redirecionar o usuário, gere um verificador de código PKCE e um desafio:

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

## 3. Redirecione o usuário para o Glossia

Construa a URL de autorização e redirecione o navegador do usuário:

```
https://glossia.ai/oauth/authorize?
  response_type=code
  &client_id=YOUR_CLIENT_ID
  &redirect_uri=https://myapp.com/auth/callback
  &code_challenge=YOUR_CODE_CHALLENGE
  &code_challenge_method=S256
  &scope=user:read+project:read
  &state=RANDOM_STATE_VALUE
```

**Parâmetros:**

| Parâmetro | Obrigatório | Descrição |
|-----------|----------|-------------|
| `response_type` | Sim | Sempre `code` |
| `client_id` | Sim | ID do cliente do seu aplicativo |
| `redirect_uri` | Sim | Deve corresponder a uma URL de callback registrada |
| `code_challenge` | Sim | O desafio de código PKCE (S256) |
| `code_challenge_method` | Sim | Sempre `S256` |
| `scope` | Não | Lista separada por espaços de [escopos](/docs/reference/apis/authorization). Nenhum escopo de ação é concedido se omitido |
| `state` | Recomendado | Uma string aleatória para prevenir ataques CSRF. Verifique se corresponde quando o usuário retorna |

O usuário verá uma tela de consentimento mostrando o nome do seu aplicativo e os escopos solicitados. Após a aprovação, o Glossia redireciona de volta para sua URL de callback com um código de autorização.

## 4. Troque o código por tokens

Quando o usuário for redirecionado de volta para sua URL de callback, a URL conterá um parâmetro `code`:

```
https://myapp.com/auth/callback?code=AUTHORIZATION_CODE&state=RANDOM_STATE_VALUE
```

Primeiro, verifique se `state` corresponde ao que você enviou no passo 3. Depois, troque o código por tokens:

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

Armazene ambos os tokens com segurança. O token de acesso é utilizado para solicitações de API. O token de atualização é utilizado para obter um novo token de acesso quando o atual expira.

## 5. Chame a API em nome do usuário

Use o token de acesso para fazer solicitações de API autenticadas:

```bash
curl -H "Authorization: Bearer eyJhbGciOiJSUzI1..." \
  https://glossia.ai/api/projects
```

Os escopos do token limitam quais endpoints você pode acessar. A autorização de nível de recursos ainda se aplica -- por exemplo, um token com `project:read` pode apenas ler projetos aos quais o usuário tem acesso.

## 6. Atualize o token

Quando o token de acesso expirar, use o token de atualização para obter um novo sem enviar o usuário pelo fluxo de consentimento novamente:

```bash
curl -X POST https://glossia.ai/oauth/token \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "grant_type=refresh_token" \
  -d "refresh_token=dGhpcyBpcyBhIHJl..." \
  -d "client_id=YOUR_CLIENT_ID" \
  -d "client_secret=YOUR_CLIENT_SECRET"
```

## 7. Revogue um token

Quando um usuário desconectar seu aplicativo ou você não precisar mais do acesso, revogue o token:

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
| Gerenciar recursos da organização | `user:read organization:read organization:write members:read members:write project:read project:write` |

Veja a [referência de escopos](/docs/reference/apis/authorization) para todos os escopos disponíveis.

## Pontos finais de descoberta

Seu aplicativo pode descobrir automaticamente os pontos finais OAuth do Glossia buscando o metadados do servidor:

```bash
curl https://glossia.ai/.well-known/oauth-authorization-server
```

Isso retorna um documento JSON com `authorization_endpoint`, `token_endpoint`, `revocation_endpoint` e outros detalhes. Usar a descoberta torna sua integração resiliente a alterações de endpoints.

## Tratamento de erros

### Erros de autorização

Se o usuário negar o consentimento ou algo der errado durante a autorização, o Glossia redireciona para sua URL de callback com um parâmetro `error`:

```
https://myapp.com/auth/callback?error=access_denied&state=RANDOM_STATE_VALUE
```

Códigos de erro comuns:

| Erro | Significado |
|-------|---------|
| `access_denied` | O usuário negou o pedido de autorização |
| `invalid_request` | O pedido está faltando um parâmetro obrigatório |
| `invalid_scope` | Um ou mais escopos solicitados não são válidos |

### Erros de token

O ponto final de token retorna HTTP 400 com um corpo de erro JSON:

```json
{
  "error": "invalid_grant",
  "error_description": "The authorization code has expired or was already used."
}
```

### Limites de taxa

Os pontos finais OAuth são limitados por taxa por IP. Se você atingir o limite, receberá HTTP 429. Veja a [referência de limitação de taxa](/docs/reference/apis/authentication) para detalhes.

## Lista de verificação de segurança

Antes de ir para a produção, verifique se sua implementação segue essas práticas:

- Sempre use HTTPS para URLs de callback na produção
- Valide o parâmetro `state` no callback para prevenir CSRF
- Armazene os tokens criptografados em repouso
- Nunca exponha os tokens em JavaScript de lado do cliente ou URLs de navegador
- Use o conjunto mínimo de escopos necessários.
- Gerencie a expiração do token com elegância usando tokens de atualização.
- Revogue os tokens quando os usuários se desconectarem ou excluir a conta deles.
