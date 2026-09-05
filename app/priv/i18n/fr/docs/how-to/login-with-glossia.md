%{
  title: "Se connecter avec Glossia",
  summary:
    "Permettez à vos utilisateurs de se connecter à votre application avec leur compte Glossia en utilisant OAuth 2.1.",
  category: "how-to",
  order: 2
}
---
Ce guide vous accompagne dans l'ajout de "Connexion avec Glossia" à votre application. À la fin, vos utilisateurs pourront se connecter avec leur compte Glossia et votre application disposera d'un jeton d'accès pour appeler l'API Glossia à leur place.

Glossia utilise **OAuth 2.1 avec PKCE** (Clé de preuve pour l'échange de code). PKCE est requis pour tous les clients, y compris les applications côté serveur.

## 1\. Enregistrer votre application OAuth

Vous avez deux options pour enregistrer votre application :

### Option A : Par le tableau de bord (recommandé)

1. Connectez-vous à Glossia et accédez à votre tableau de bord de compte.
2. Ouvrez la **API** section de la barre latérale et cliquez **Applications OAuth**.
3. Cliquez **Nouvelle application**.
4. Remplissez l'application **nom** et **URL de rappel** (aussi appelé URI de redirection).
5. Cliquez sur **Créer une application**.

Après la création, notez **ID client** et **Secret client**. Le secret n'est affiché qu'une fois, stockez-le en toute sécurité.

### Option B : Enregistrement dynamique du client

Envoyez une `POST` demande à `/oauth/register`:

```bash
curl -X POST https://glossia.ai/oauth/register \
  -H "Content-Type: application/json" \
  -d '{
    "client_name": "My App",
    "redirect_uris": ["https://myapp.com/auth/callback"],
    "grant_types": ["authorization_code"]
  }'
```

La réponse contient `client_id` et `client_secret`.

## 2\. Générer un défi de code PKCE

Avant de rediriger l'utilisateur, générez un vérificateur de code PKCE et un défi de code PKCE:

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

## 3\. Rediriger l'utilisateur vers Glossia

Construire l'URL d'autorisation et rediriger le navigateur de l'utilisateur:

    https://glossia.ai/oauth/authorize?
      response_type=code
      &client_id=YOUR_CLIENT_ID
      &redirect_uri=https://myapp.com/auth/callback
      &code_challenge=YOUR_CODE_CHALLENGE
      &code_challenge_method=S256
      &scope=user:read+project:read
      &state=RANDOM_STATE_VALUE

**Paramètres:**

| Paramètre | Requis | Description |
|-----------|----------|-------------|
| `response_type` | Oui | Toujours `code` |
| `client_id` | Oui | L'identifiant client de votre application |
| `redirect_uri` | Oui | Doit correspondre à une URL de rappel enregistrée |
| `code_challenge` | Oui | Le défi PKCE (S256) |
| `code_challenge_method` | Oui | Toujours `S256` |
| `scope` | Nom | Liste séparée par des espaces de [portées](/docs/reference/apis/authentication). Par défaut, accès minimum si omis |
| `state` | Recommandé | Une chaîne aléatoire pour prévenir les attaques CSRF. Vérifiez qu'elle correspond lorsque l'utilisateur revient |

L'utilisateur verra un écran de consentement affichant le nom de votre application et les portées demandées. Après son approbation, Glossia redirige vers votre URL de rappel avec un code d'autorisation.

## 4\. Échangez le code contre des jetons

Lorsque l'utilisateur est redirigé vers votre URL de rappel, l'URL contiendra un `code` paramètre:

    https://myapp.com/auth/callback?code=AUTHORIZATION_CODE&state=RANDOM_STATE_VALUE

D'abord, vérifiez que `state` correspond à ce que vous avez envoyé à l'étape 3. Ensuite, échangez le code contre des jetons:

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

Stockez les deux jetons en toute sécurité. Le jeton d'accès est utilisé pour les requêtes API. Le jeton de rafraîchissement est utilisé pour obtenir un nouveau jeton d'accès lorsque celui-ci expire.

## 5\. Appeler l'API au nom de l'utilisateur

Utilisez le jeton d'accès pour effectuer des requêtes API authentifiées :

```bash
curl -H "Authorization: Bearer eyJhbGciOiJSUzI1..." \
  https://glossia.ai/api/projects
```

Les portées du jeton limitent les endpoints que vous pouvez accéder. L'autorisation au niveau des ressources s'applique toujours - par exemple, un jeton avec `project:read` ne peut lire que les projets auxquels l'utilisateur a accès.

## 6\. Rafraîchir le jeton

Lorsque le jeton d'accès expire, utilisez le jeton de rafraîchissement pour obtenir un nouveau sans renvoyer l'utilisateur à nouveau dans le flux de consentement :

```bash
curl -X POST https://glossia.ai/oauth/token \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "grant_type=refresh_token" \
  -d "refresh_token=dGhpcyBpcyBhIHJl..." \
  -d "client_id=YOUR_CLIENT_ID" \
  -d "client_secret=YOUR_CLIENT_SECRET"
```

## 7\. Révoquer un jeton

Lorsqu'un utilisateur se déconnecte de votre application ou que vous n'avez plus besoin d'accès, révoquez le jeton :

```bash
curl -X POST https://glossia.ai/oauth/revoke \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "token=eyJhbGciOiJSUzI1..." \
  -d "client_id=YOUR_CLIENT_ID" \
  -d "client_secret=YOUR_CLIENT_SECRET"
```

## Choix des portées

Demandez uniquement les portées dont votre application a besoin. Voici quelques combinaisons courantes :

| Cas d'usage | Portées |
|----------|--------|
| Lecture du profil utilisateur | `user:read` |
| Lire les projets et le contenu | `user:read project:read voice:read` |
| Gérer les projets | `user:read project:read project:write` |
| Accès complet à l'organisation | `user:read organization:read organization:write members:read members:write project:read project:write` |

Voir la [référence complète des périmètres](/docs/reference/apis/authentication) pour toutes les portées disponibles.

## Points de terminaison de découverte

Votre application peut découvrir automatiquement les points de terminaison OAuth de Glossia en récupérant les métadonnées du serveur :

```bash
curl https://glossia.ai/.well-known/oauth-authorization-server
```

Cela renvoie un document JSON avec les `authorization_endpoint`, `token_endpoint`, `revocation_endpoint`et d'autres détails. L'utilisation de la découverte rend votre intégration résiliente aux changements de points de terminaison.

## Gestion des erreurs

### Erreurs d'autorisation

Si l'utilisateur refuse le consentement ou si quelque chose ne va pas pendant l'autorisation, Glossia redirige vers votre URL de rappel avec un `error` paramètre :

    https://myapp.com/auth/callback?error=access_denied&state=RANDOM_STATE_VALUE

Codes d'erreur courants :

| Erreur | Signification |
|-------|---------|
| `access_denied` | L'utilisateur a refusé la demande d'autorisation |
| `invalid_request` | Le message de la demande manque un paramètre obligatoire |
| `invalid_scope` | Un ou plusieurs domaines demandées ne sont pas valides |

### Erreurs de jeton

L'endpoint du jeton retourne un HTTP 400 avec un corps d'erreur JSON :

```json
{
  "error": "invalid_grant",
  "error_description": "The authorization code has expired or was already used."
}
```

### Limites de débit

Les endpoints OAuth ont une limite de débit par IP. Si vous atteignez la limite, vous recevrez un HTTP 429. Voir le [référence de limitation du débit](/docs/reference/apis/authentication) pour plus de détails.

## Checklist de sécurité

Avant de passer en production, vérifiez que votre implémentation suit ces pratiques :

- Utilisez toujours HTTPS pour les URL de rappel en production
- Validez le `state` paramètre du rappel pour prévenir le CSRF
- Stockez les jetons chiffrés au repos
- Ne jamais exposer les jetons dans le JavaScript côté client ou les URLs du navigateur
- Utilisez l'ensemble minimum de portées nécessaire
- Gérez l'expiration des jetons sans interruption grâce aux jetons de rafraîchissement
- Révoquez les jetons lorsque les utilisateurs se déconnectent ou suppriment leur compte
