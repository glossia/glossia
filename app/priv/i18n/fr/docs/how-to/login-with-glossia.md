%{
  title: "Se connecter avec Glossia",
  summary:
    "Permettez aux utilisateurs de se connecter à votre application avec leur compte Glossia via OAuth 2.1.",
  category: "Guide pratique",
  section: "platform",
  order: 2
}
---

Ce guide vous accompagne dans l'ajout de "Connexion avec Glossia" à votre application. À la fin, vos utilisateurs pourront se connecter avec leur compte Glossia et votre application disposera d'un jeton d'accès pour appeler l'API Glossia en leur nom.

Glossia utilise **OAuth 2.1 avec PKCE** (Proof Key for Code Exchange). PKCE est requis pour tous les clients, y compris les applications côté serveur.

## 1. Enregister votre application OAuth

Vous avez deux options pour enregister votre application :

### Option A : Par le tableau de bord (recommandé)

1. Connectez-vous à Glossia et allez vers votre tableau de bord de compte.
2. Ouvrez la section **API** depuis la barre latérale et cliquez sur **Applications OAuth**.
3. Cliquez sur **Nouvelle application**.
4. Remplissez le nom de l'application **name** et l'URL de rappel **callback URL** (aussi appelée URI de redirection).
5. Cliquez sur **Créer l'application**.

Après la création, notez le **Client ID** et le **Client secret**. Le secret n'apparaît qu'une seule fois, stockez-le donc en sécurité.

### Option B : Enregistrement dynamique du client

Envoyez une `POST` requête à `/oauth/register` :

```bash
curl -X POST https://glossia.ai/oauth/register \
  -H "Content-Type: application/json" \
  -d '{
    "client_name": "My App",
    "redirect_uris": ["https://myapp.com/auth/callback"],
    "grant_types": ["authorization_code"]
  }'
```

La réponse inclut `client_id` et `client_secret`.

## 2. Générer un défi PKCE

Avant de rediriger l'utilisateur, générez un code vérificateur PKCE et un défi :

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

## 3. Rediriger l'utilisateur vers Glossia

Construisez l'URL d'autorisation et redirigez le navigateur de l'utilisateur :

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

**Paramètres :**

| Paramètre | Obligatoire | Description |
|-----------|----------|-------------|
| `response_type` | Oui | Toujours `code` |
| `client_id` | Votre client ID d'application | Oui |
| `redirect_uri` | Doit correspondre à une URL de callback enregister | Oui |
| `code_challenge` | Le défi PKCE (S256) | Oui |
| `code_challenge_method` | Oui | Toujours `S256` |
| `scope` | Non | Liste [scopes](/docs/reference/apis/authorization) séparée par des espaces. Aucun périmètre d'action n'est accordé s'il est omis |
| `state` | Une chaîne aléatoire pour prévenir les attaques CSRF. Vérifiez qu'elle correspond lorsque l'utilisateur revient | L'utilisateur verra un écran de consentement affichant le nom de votre application et les scopes demandés. Après leur approbation, Glossia redirige vers votre URL de callback avec un code d'autorisation. |

4\. Échanger le code contre des jetons

## 4. Échanger le code contre des jetons

Premièrement, vérifiez que `code` correspond à ce que vous avez envoyé à l'étape 3. Ensuite, échangez le code contre des jetons :

```
https://myapp.com/auth/callback?code=AUTHORIZATION_CODE&state=RANDOM_STATE_VALUE
```

D'abord, vérifier que `state` correspond à ce qui a été envoyé dans l'étape 3. Ensuite, échanger le code contre des jetons :

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

La réponse :

```json
{
  "access_token": "eyJhbGciOiJSUzI1...",
  "token_type": "bearer",
  "expires_in": 3600,
  "refresh_token": "dGhpcyBpcyBhIHJl..."
}
```

Stockez les deux jetons en sécurité. Le jeton d'accès est utilisé pour les requêtes API. Le jeton de renouvellement est utilisé pour obtenir un nouveau jeton d'accès lorsque le jeton actuel expire.

## 5. Appeler l'API au nom de l'utilisateur

Utilisez le jeton d'accès pour créer des requêtes API authentifiées :

```bash
curl -H "Authorization: Bearer eyJhbGciOiJSUzI1..." \
  https://glossia.ai/api/projects
```

Les périmètres du jeton déterminent quelles terminaisons vous pouvez accéder. L'autorisation au niveau des ressources s'applique toujours -- par exemple, un jeton avec `project:read` ne peut lire que les projets auxquels l'utilisateur a accès.

## 6. Renouveler le jeton

Lorsque le jeton d'accès expire, utilisez le jeton de renouvellement pour en obtenir un nouveau sans passer l'utilisateur à nouveau par le flux de consentement :

```bash
curl -X POST https://glossia.ai/oauth/token \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "grant_type=refresh_token" \
  -d "refresh_token=dGhpcyBpcyBhIHJl..." \
  -d "client_id=YOUR_CLIENT_ID" \
  -d "client_secret=YOUR_CLIENT_SECRET"
```

## 7. Révoquer un jeton

Lorsqu'un utilisateur désconnecte votre application ou que vous n'avez plus besoin d'accès, révoquez le jeton :

```bash
curl -X POST https://glossia.ai/oauth/revoke \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "token=eyJhbGciOiJSUzI1..." \
  -d "client_id=YOUR_CLIENT_ID" \
  -d "client_secret=YOUR_CLIENT_SECRET"
```

## Choisir les périmètres

Demander uniquement les périmètres dont votre application a besoin. Voici quelques combinaisons courantes :

| Cas d'utilisation | Périmètres |
|----------|--------|
| Lire le profil utilisateur | `user:read` |
| Lire les projets et le contenu | `user:read project:read voice:read` |
| Gérer les projets | `user:read project:read project:write` |
| Gérer les ressources de l'organisation | `user:read organization:read organization:write members:read members:write project:read project:write` |

Voir la [référence des périmètres](/docs/reference/apis/authorization) pour tous les périmètres disponibles.

## Points de terminaison de découverte

Votre application peut découvrir automatiquement les points de terminaison OAuth de Glossia en récupérant les métadonnées du serveur :

```bash
curl https://glossia.ai/.well-known/oauth-authorization-server
```

Ceci renvoie un document JSON contenant `authorization_endpoint`, `token_endpoint`, `revocation_endpoint` et d'autres détails. L'utilisation de la découverte rend votre intégration résiliente aux changements de terminaisons.

## Gestion des erreurs

### Erreurs d'autorisation

Si l'utilisateur refuse le consentement ou si quelque chose se passe mal pendant l'autorisation, Glossia redirige vers votre URL de rappel avec un paramètre `error` :

```
https://myapp.com/auth/callback?error=access_denied&state=RANDOM_STATE_VALUE
```

Codes d'erreur courants :

| Erreur | Signification |
|-------|---------|
| `access_denied` | L'utilisateur a rejeté la demande d'autorisation |
| `invalid_request` | La requête manque d'un paramètre obligatoire |
| `invalid_scope` | Un ou plusieurs périmètres demandés sont invalides |

### Erreurs de jeton

Le point de terminaison du jeton renvoie un code HTTP 400 avec un corps d'erreur JSON :

```json
{
  "error": "invalid_grant",
  "error_description": "The authorization code has expired or was already used."
}
```

### Limites de débit

Les points de terminaison OAuth sont limités en débit par IP. Si vous atteignez la limite, vous recevrez un HTTP 429. Consultez la [référence de limitation du débit](/docs/reference/apis/authentication) pour plus de détails.

## Liste de contrôle de sécurité

Avant le déploiement en production, vérifiez que votre implémentation suit ces pratiques :

- Utilisez toujours HTTPS pour les URL de rappel en production
- Validez le `state` paramètre sur le rappel pour prévenir les attaques CSRF
- Stockez les jetons cryptés au repos
- Ne jamais exposer des jetons dans le JavaScript côté client ou les URL du navigateur
- Utilisez l'ensemble minimal de périmètres nécessaires.
- Gérez l'expiration des jetons proprement avec les jetons de renouvellement.
- Révoquez les jetons lorsque les utilisateurs se désconnectent ou suppriment leur compte.
