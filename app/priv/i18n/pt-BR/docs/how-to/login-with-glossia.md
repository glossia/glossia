%{
  title: "Entrar com a Glossia",
  summary: "Permita que os usuários entrem no seu aplicativo com a conta da Glossia usando OAuth 2.1.",
  category: "how-to",
  order: 2
}
---
Este guia orienta você na adição de "Login com Glossia" à sua aplicação. Ao final, os usuários poderão entrar com suas contas da Glossia, e a sua aplicação terá um token de acesso para chamar a API da Glossia em nome deles.

A Glossia usa **OAuth 2.1 com PKCE** (Proof Key for Code Exchange, chave de prova para troca de código). O PKCE é obrigatório para todos os clientes, incluindo aplicações executadas no servidor.

## 1. Registre sua aplicação OAuth

Há duas opções para registrar sua aplicação:

### Opção A: Pelo painel (recomendado)

1. Entre na Glossia e acesse o painel da sua conta.
2. Abra a seção **API** na barra lateral e clique em **Aplicativos OAuth**.
3. Clique em **Nova aplicação**.
4. Preencha o **nome** e a **URL de retorno** da aplicação, também chamada de URI de redirecionamento.
5. Clique em **Criar aplicação**.

Após a criação, anote o **ID do cliente** e o **segredo do cliente**. O segredo é exibido apenas uma vez, portanto, armazene-o com segurança.

### Opção B: Registro dinâmico de cliente

Envie uma solicitação `POST` para `/oauth/register`:

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

Antes de redirecionar o usuário, gere um verificador e um desafio de código PKCE:

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

## 3. Redirecione o usuário para a Glossia

Crie a URL de autorização e redirecione o navegador do usuário:

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
|-----------|-------------|-----------|
| `response_type` | Sim | Sempre `code` |
| `client_id` | Sim | O ID de cliente da sua aplicação |
| `redirect_uri` | Sim | Deve corresponder a uma URL de retorno registrada |
| `code_challenge` | Sim | O desafio de código PKCE (S256) |
| `code_challenge_method` | Sim | Sempre `S256` |
| `scope` | Não | Lista de [escopos](/docs/reference/apis/authentication) separados por espaços. Se omitido, usa o acesso mínimo como padrão |
| `state` | Recomendado | Uma string aleatória para evitar ataques de falsificação de solicitação entre sites (CSRF). Verifique se ela corresponde ao valor original quando o usuário retornar |

O usuário verá uma tela de consentimento com o nome da sua aplicação e os escopos solicitados. Após a aprovação, a Glossia redirecionará o usuário de volta para a URL de retorno com um código de autorização.

## 4. Troque o código por tokens

Quando o usuário for redirecionado de volta para a URL de retorno, ela conterá um parâmetro `code`:

```
https://myapp.com/auth/callback?code=AUTHORIZATION_CODE&state=RANDOM_STATE_VALUE
```

Primeiro, verifique se `state` corresponde ao valor enviado na etapa 3. Em seguida, troque o código por tokens:

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

Armazene ambos os tokens com segurança. O token de acesso é usado nas solicitações à API. O token de atualização é usado para obter um novo token de acesso quando o atual expirar.

## 5. Chame a API em nome do usuário

Use o token de acesso para fazer solicitações autenticadas à API:

```bash
curl -H "Authorization: Bearer eyJhbGciOiJSUzI1..." \
  https://glossia.ai/api/projects
```

Os escopos do token limitam quais endpoints podem ser acessados. A autorização no nível do recurso ainda se aplica. Por exemplo, um token com `project:read` só pode ler os projetos aos quais o usuário tem acesso.

## 6. Atualize o token

Quando o token de acesso expirar, use o token de atualização para obter um novo sem enviar o usuário novamente pelo fluxo de consentimento:

```bash
curl -X POST https://glossia.ai/oauth/token \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "grant_type=refresh_token" \
  -d "refresh_token=dGhpcyBpcyBhIHJl..." \
  -d "client_id=YOUR_CLIENT_ID" \
  -d "client_secret=YOUR_CLIENT_SECRET"
```

## 7. Revogue um token

Quando um usuário desconectar sua aplicação ou quando você não precisar mais do acesso, revogue o token:

```bash
curl -X POST https://glossia.ai/oauth/revoke \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "token=eyJhbGciOiJSUzI1..." \
  -d "client_id=YOUR_CLIENT_ID" \
  -d "client_secret=YOUR_CLIENT_SECRET"
```

## Escolha dos escopos

Solicite apenas os escopos necessários para sua aplicação. Estas são algumas combinações comuns:

| Caso de uso | Escopos |
|-------------|---------|
| Ler o perfil do usuário | `user:read` |
| Ler projetos e conteúdo | `user:read project:read voice:read` |
| Gerenciar projetos | `user:read project:read project:write` |
| Acesso completo à organização | `user:read organization:read organization:write members:read members:write project:read project:write` |

Consulte a [referência completa de escopos](/docs/reference/apis/authentication) para conhecer todos os escopos disponíveis.

## Pontos de extremidade de descoberta

Seu aplicativo pode descobrir automaticamente os pontos de extremidade OAuth do Glossia ao buscar os metadados do servidor:

```bash
curl https://glossia.ai/.well-known/oauth-authorization-server
```

Isso retorna um documento JSON com `authorization_endpoint`, `token_endpoint`, `revocation_endpoint` e outros detalhes. O uso da descoberta torna sua integração resiliente a alterações nos pontos de extremidade.

## Tratamento de erros

### Erros de autorização

Se o usuário recusar o consentimento ou ocorrer algum problema durante a autorização, o Glossia redirecionará para sua URL de retorno de chamada com um parâmetro `error`:

```
https://myapp.com/auth/callback?error=access_denied&state=RANDOM_STATE_VALUE
```

Códigos de erro comuns:

| Erro | Significado |
|------|-------------|
| `access_denied` | O usuário recusou a solicitação de autorização |
| `invalid_request` | Falta um parâmetro obrigatório na solicitação |
| `invalid_scope` | Um ou mais escopos solicitados não são válidos |

### Erros de token

O ponto de extremidade de token retorna HTTP 400 com um corpo de erro JSON:

```json
{
  "error": "invalid_grant",
  "error_description": "The authorization code has expired or was already used."
}
```

### Limites de requisições

Os pontos de extremidade OAuth têm limites de requisições por endereço IP. Se você atingir o limite, receberá HTTP 429. Consulte a [referência de limites de requisições](/docs/reference/apis/authentication) para obter detalhes.

## Lista de verificação de segurança

Antes de entrar em produção, verifique se sua implementação segue estas práticas:

- Sempre use HTTPS para URLs de retorno de chamada em produção
- Valide o parâmetro `state` no retorno de chamada para evitar CSRF
- Armazene os tokens criptografados em repouso
- Nunca exponha tokens em JavaScript do lado do cliente ou em URLs do navegador
- Use o conjunto mínimo necessário de escopos
- Trate adequadamente a expiração de tokens usando tokens de atualização
- Revogue os tokens quando os usuários desconectarem ou excluírem suas contas