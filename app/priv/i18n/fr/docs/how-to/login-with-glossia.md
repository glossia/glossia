%{
  title: "Se connecter avec Glossia",
  summary:
    "Permettez aux utilisateurs de se connecter à votre application avec leur compte Glossia en utilisant OAuth 2.1.",
  category: "guide",
  section: "platform",
  order: 2
}
---

Ce guide vous accompagne dans l'ajout de « Connexion avec Glossia » à votre application. À la fin, vos utilisateurs pourront se connecter avec leur compte Glossia et votre application disposera d'un jeton d'accès pour appeler l'API Glossia en leur nom.

Glossia utilise **OAuth 2.1 avec PKCE** (Preuve de clé pour échange de code). PKCE est requis pour tous les clients, incluant les applications côté serveur.

## 1. Enregistrez votre application OAuth

Vous avez deux options pour enregistrer votre application :

### Option A : Par le tableau de bord (recommandé)

1. Connectez-vous à Glossia et accédez à votre tableau de bord de compte.
2. Ouvrez la section **API** dans la barre latérale et cliquez sur **Applications OAuth**.
3. Cliquez sur **Nouvelle application**.
4. Remplissez le **nom** de l'application et l'**URL de rappel** (également appelée URI de redirection).
5. Cliquez sur **Créer une application**.

Après la création, notez l'**ID client** et le **Secret client**. Ce secret n'est affiché qu'une fois, donc stockez-le en sécurité.

### Option B : Inscription dynamique du client

Envoyez `POST` une requête à `/oauth/register` :

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

## 2. Générer un défi de code PKCE

Avant de rediriger l'utilisateur, générez un vérificateur de code PKCE et un défi :

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
| `client_id` | Oui | L'ID client de votre application |
| `redirect_uri` | Oui | Doit correspondre à l'URL de rappel enregistrée |
| `code_challenge` | Oui | Le défi de code PKCE (S256) |
| `code_challenge_method` | Oui | Toujours `S256` |
| `scope` | Non | Liste séparée par des espaces de [portées](/docs/reference/apis/authorization). Aucune portée d'action n'est accordée si elle est omise |
| `state` | Recommandé | Une chaîne aléatoire pour éviter les attaques CSRF. Vérifiez qu'elle correspond lors du retour de l'utilisateur. |

L'utilisateur verra une fenêtre de consentement affichant le nom de votre application et les portées demandées. Une fois approuvé, Glossia redirige vers votre URL de rappel avec un code d'autorisation.

## 4. Échanger le code contre des jetons

Lorsque l'utilisateur est redirigé vers votre URL de rappel, l'URL contiendra un paramètre `code` :

```
https://myapp.com/auth/callback?code=AUTHORIZATION_CODE&state=RANDOM_STATE_VALUE
```

Vérifiez d'abord que `state` correspond à ce qui a été envoyé à l'étape 3. Ensuite, échangez le code contre des jetons :

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

La réponse:

```json
{
  "access_token": "eyJhbGciOiJSUzI1...",
  "token_type": "bearer",
  "expires_in": 3600,
  "refresh_token": "dGhpcyBpcyBhIHJl..."
}
```

Stockez les deux jetons en sécurité. Le jeton d'accès est utilisé pour les requêtes API. Le jeton de rafraîchissement est utilisé pour obtenir un nouveau jeton d'accès lorsque celui-ci expire.

## 5. Appelez l'API au nom de l'utilisateur

Utilisez le jeton d'accès pour envoyer des requêtes API authentifiées :

```bash
curl -H "Authorization: Bearer eyJhbGciOiJSUzI1..." \
  https://glossia.ai/api/projects
```

Les portées du jeton limitent les points d'aboutissement auxquels vous avez accès. La validation d'autorisation au niveau des ressources s'applique toujours - par exemple, un jeton `project:read` peut uniquement lire les projets auxquels l'utilisateur a accès.

## 6. Rafraîchir le jeton

Lorsque le jeton d'accès expire, utilisez le jeton de rafraîchissement pour en obtenir un nouveau sans envoyer l'utilisateur à travers le flux de consentement à nouveau :

```bash
curl -X POST https://glossia.ai/oauth/token \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "grant_type=refresh_token" \
  -d "refresh_token=dGhpcyBpcyBhIHJl..." \
  -d "client_id=YOUR_CLIENT_ID" \
  -d "client_secret=YOUR_CLIENT_SECRET"
```

## 7. Révoquer un jeton

Lorsqu'un utilisateur se déconnecte de votre application ou lorsque vous n'avez plus besoin d'accès, révoquez le jeton :

```bash
curl -X POST https://glossia.ai/oauth/revoke \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "token=eyJhbGciOiJSUzI1..." \
  -d "client_id=YOUR_CLIENT_ID" \
  -d "client_secret=YOUR_CLIENT_SECRET"
```

## Choix des portées

Demandez uniquement les portées nécessaires à votre application. Voici quelques combinaisons courantes :

| Cas d'usage | Portées |
|----------|--------|
| Lire le profil utilisateur | `user:read` |
| Lire les projets et le contenu | `user:read project:read voice:read` |
| Gérer les projets | `user:read project:read project:write` |
| Gérer les ressources de l'organisation | `user:read organization:read organization:write members:read members:write project:read project:write` |

Consultez la [référence des portées](/docs/reference/apis/authorization) pour toutes les portées disponibles.

## Découverte des points d'aboutissement

Votre application peut découvrir automatiquement les points d'aboutissement OAuth de Glossia en récupérant les métadonnées du serveur :

```bash
curl https://glossia.ai/.well-known/oauth-authorization-server
```

Cela retourne un document JSON avec les `authorization_endpoint`, `token_endpoint`, `revocation_endpoint` et autres détails. La découverte permet à votre intégration de résister aux changements de points d'aboutissement.

## Gestion des erreurs

### Erreurs d'autorisation

Si l'utilisateur refuse le consentement ou si un problème survient lors de l'autorisation, Glossia redirige vers votre URL de rappel avec un paramètre `error` :

```
https://myapp.com/auth/callback?error=access_denied&state=RANDOM_STATE_VALUE
```

Codes d'erreur courants :

| Erreur | Signification |
|-------|---------|
| `access_denied` | L'utilisateur a refusé la demande d'autorisation |
| `invalid_request` | La requête manque un paramètre obligatoire |
| `invalid_scope` | Une ou plusieurs portées demandées ne sont pas valides |

### Erreurs de jetons

Le point d'aboutissement du jeton retourne une réponse HTTP 400 avec un corps JSON d'erreur :

```json
{
  "error": "invalid_grant",
  "error_description": "The authorization code has expired or was already used."
}
```

### Limitations de vitesse

Les points d'aboutissement OAuth sont limités par adresse IP. Si vous atteignez la limite, vous recevrez une réponse HTTP 429. Consultez la [référence relative à la limitation du débit](/docs/reference/apis/authentication) pour plus de détails.

## Checklist de sécurité

Avant de passer en production, vérifiez que votre implémentation suit ces pratiques :

- Utilisez toujours HTTPS pour les URL de rappel en production
- Validez le paramètre `state` lors du rappel pour prévenir les attaques CSRF
- Stockez les jetons chiffrés au repos
- N'exposez jamais les jetons dans les scripts JavaScript côté client ou dans les URLs du navigateur
- Utilisez un ensemble minimum de portées nécessaires.
- Gérez l'expiration du jeton de manière fluide avec les jetons de rafraîchissement.
- Révoquez les jetons lorsque les utilisateurs se déconnectent ou suppriment leur compte.
