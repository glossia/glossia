%{
  title: "Entrar com Glossia",
  summary:
    "Permita que os usuários façam login no seu aplicativo com sua conta Glossia usando OAuth 2.1.",
  category: "Tutorial",
  order: 2
}
---
Neste guia, você aprenderá a adicionar "Entrar com Glossia" ao seu aplicativo. Ao final, seus usuários poderão fazer login com sua conta Glossia e seu aplicativo terá um token de acesso para chamar a API Glossia em seu nome.

Glossia usa **OAuth 2.1 com PKCE** (Chave de Prova para Troca de Código). O PKCE é obrigatório para todos os clientes, incluindo aplicativos do lado do servidor.

## 1\. Registre seu aplicativo OAuth

Você tem duas opções para registrar seu aplicativo:

### Opção A: Através do painel (recomendado)

1. Faça login na Glossia e vá para o painel da sua conta.
2. Abra a **API** seção na barra lateral e clique **Aplicativos OAuth**.
3. Clique **Novo aplicativo**.
4. Preencha o **nome** e **URL de callback** (também conhecida como URI de redirecionamento).
5. Clique em **Criar aplicativo**.

Após a criação, anote o **ID do cliente** e **segredo do cliente**. O segredo é exibido uma vez, então armazene-o com segurança.

### Opção B: Registro dinâmico do cliente

Envie uma `POST` solicitação para `/oauth/register`：

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

## 2\. Gere um desafio de código PKCE

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

## 3\. Redirecione o usuário para o Glossia

Construa a URL de autorização e redirecione o navegador do usuário:

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
| `scope` | Nome | Lista separada por espaço de [escopos](/docs/reference/apis/authentication). Por padrão, acesso mínimo se omitido |
| `state` | Recomendado | Uma string aleatória para prevenir ataques CSRF. Verifique se corresponde quando o usuário retorna |

O usuário verá uma tela de consentimento mostrando o nome da sua aplicação e os escopos solicitados. Após a aprovação, o Glossia redireciona de volta para o seu URL de callback com um código de autorização.

## 4\. Troque o código por tokens

Quando o usuário for redirecionado de volta para o seu URL de callback, o URL conterá um `code` parâmetro:

    https://myapp.com/auth/callback?code=AUTHORIZATION_CODE&state=RANDOM_STATE_VALUE

Primeiro, verifique que `state` corresponde ao que você enviou no passo 3. Em seguida, troque o código por tokens:

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

Armazene ambos os tokens com segurança. O token de acesso é usado para requisições de API. O token de atualização é usado para obter um novo token de acesso quando o atual expira.

## 5\. Chame a API em nome do usuário

Use o token de acesso para fazer requisições de API autenticadas:

```bash
curl -H "Authorization: Bearer eyJhbGciOiJSUzI1..." \
  https://glossia.ai/api/projects
```

Os escopos do token limitam quais endpoints você pode acessar. A autorização em nível de recurso ainda se aplica -- por exemplo, um token com `project:read` pode ler apenas os projetos a que o usuário tem acesso.

## 6\. Atualize o token

Quando o token de acesso expira, use o token de atualização para obter um novo sem enviar o usuário novamente pelo fluxo de consentimento:

```bash
curl -X POST https://glossia.ai/oauth/token \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "grant_type=refresh_token" \
  -d "refresh_token=dGhpcyBpcyBhIHJl..." \
  -d "client_id=YOUR_CLIENT_ID" \
  -d "client_secret=YOUR_CLIENT_SECRET"
```

## 7\. Revogar um token

Quando um usuário desconecta o seu aplicativo ou você não precisar mais do acesso, revogue o token:

```bash
curl -X POST https://glossia.ai/oauth/revoke \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "token=eyJhbGciOiJSUzI1..." \
  -d "client_id=YOUR_CLIENT_ID" \
  -d "client_secret=YOUR_CLIENT_SECRET"
```

## Escolhendo escopos

Solicite apenas os escopos necessários ao seu aplicativo. Confira as combinações comuns:

| Caso de uso | Escopos |
|----------|--------|
| Ler perfil do usuário | `user:read` |
| Ler projetos e conteúdo | `user:read project:read voice:read` |
| Gerenciar projetos | `user:read project:read project:write` |
| Acesso completo à organização | `user:read organization:read organization:write members:read members:write project:read project:write` |

Veja a [referência completa de escopos](/docs/reference/apis/authentication) para todos os âmbitos disponíveis.

## Endpoints de Descoberta

Seu aplicativo pode descobrir automaticamente os endpoints OAuth do Glossia ao recuperar os metadados do servidor:

```bash
curl https://glossia.ai/.well-known/oauth-authorization-server
```

Isso retorna um documento JSON com o `authorization_endpoint`O documento remontado anteriormente falhou na validação: a recuperação de nó de texto Markdown produziu uma tradução vazia `token_endpoint`O documento remontado anteriormente falhou na validação: a recuperação de nós de texto Markdown resultou em uma tradução vazia. `revocation_endpoint`, e outros detalhes. O uso de descoberta torna sua integração resiliente a mudanças de endpoint.

## Tratamento de erro

### Erros de autorização

Se o usuário negar o consentimento ou algo der errado durante a autorização, Glossia redireciona para sua URL de callback com um `error` parâmetro:

    https://myapp.com/auth/callback?error=access_denied&state=RANDOM_STATE_VALUE

Códigos de erro comuns:

| Erro | Significado |
|-------|---------|
| `access_denied` | O usuário negou a solicitação de autorização |
| `invalid_request` | O parâmetro obrigatório está ausente na solicitação |
| `invalid_scope` | Um ou mais escopos solicitados não são válidos |

### Erros do token

O endpoint de token retorna HTTP 400 com um corpo de erro JSON:

```json
{
  "error": "invalid_grant",
  "error_description": "The authorization code has expired or was already used."
}
```

### Limites de taxa

Os endpoints do OAuth têm limites de taxa por IP. Se você atingir o limite, receberá HTTP 429. Consulte o [referência de limitação de taxa](/docs/reference/apis/authentication) para mais detalhes.

## Lista de verificação de segurança

Antes de ir para a produção, verifique que sua implementação segue essas práticas:

- Sempre use HTTPS para URLs de callback em produção
- Valide o `state` parâmetro no callback para prevenir CSRF
- Armazene os tokens criptografados em repouso
- Nunca exponha os tokens em JavaScript de lado do cliente ou em URLs do navegador
- Use o conjunto mínimo de escopos necessários
- Gerencie a expiração do token adequadamente usando tokens de atualização
- Revogue os tokens quando os usuários desconectarem ou excluírem suas contas