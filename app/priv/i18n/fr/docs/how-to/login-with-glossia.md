%{
  title: "Se connecter avec Glossia",
  summary: "Permettez aux utilisateurs de se connecter à votre application avec leur compte Glossia à l’aide d’OAuth 2.1.",
  category: "how-to",
  order: 2
}
---
Ce guide vous explique comment ajouter « Se connecter avec Glossia » à votre application. À la fin, vos utilisateurs pourront se connecter avec leur compte Glossia et votre application disposera d’un jeton d’accès lui permettant d’appeler l’API Glossia en leur nom.

Glossia utilise **OAuth 2.1 avec PKCE** (Proof Key for Code Exchange). PKCE est obligatoire pour tous les clients, y compris les applications côté serveur.

## 1. Enregistrer votre application OAuth

Deux options permettent d’enregistrer votre application :

### Option A : depuis le tableau de bord (recommandé)

1. Connectez-vous à Glossia et accédez au tableau de bord de votre compte.
2. Ouvrez la section **API** dans la barre latérale, puis cliquez sur **Applications OAuth**.
3. Cliquez sur **Nouvelle application**.
4. Renseignez le **nom** de l’application et l’**URL de rappel** (également appelée URI de redirection).
5. Cliquez sur **Créer l’application**.

Après la création, notez l’**ID client** et le **secret client**. Le secret n’est affiché qu’une seule fois. Conservez-le donc en lieu sûr.

### Option B : enregistrement dynamique du client

Envoyez une requête `POST` à `/oauth/register` :

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

## 2. Générer une clé de vérification PKCE

Avant de rediriger l’utilisateur, générez un vérificateur de code PKCE et sa clé de vérification :

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

## 3. Rediriger l’utilisateur vers Glossia

Construisez l’URL d’autorisation et redirigez le navigateur de l’utilisateur :

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
|-----------|-------------|-------------|
| `response_type` | Oui | Toujours `code` |
| `client_id` | Oui | L’ID client de votre application |
| `redirect_uri` | Oui | Doit correspondre à une URL de rappel enregistrée |
| `code_challenge` | Oui | La clé de vérification PKCE (S256) |
| `code_challenge_method` | Oui | Toujours `S256` |
| `scope` | Non | Liste de [portées](/docs/reference/apis/authentication) séparées par des espaces. Si ce paramètre est omis, l’accès minimal est appliqué par défaut |
| `state` | Recommandé | Chaîne aléatoire permettant d’empêcher les attaques CSRF. Vérifiez qu’elle correspond à la valeur initiale au retour de l’utilisateur |

L’utilisateur verra un écran de consentement indiquant le nom de votre application et les portées demandées. Après son approbation, Glossia le redirige vers votre URL de rappel avec un code d’autorisation.

## 4. Échanger le code contre des jetons

Lorsque l’utilisateur est redirigé vers votre URL de rappel, celle-ci contient un paramètre `code` :

```
https://myapp.com/auth/callback?code=AUTHORIZATION_CODE&state=RANDOM_STATE_VALUE
```

Vérifiez d’abord que `state` correspond à la valeur envoyée à l’étape 3. Échangez ensuite le code contre des jetons :

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

Réponse :

```json
{
  "access_token": "eyJhbGciOiJSUzI1...",
  "token_type": "bearer",
  "expires_in": 3600,
  "refresh_token": "dGhpcyBpcyBhIHJl..."
}
```

Conservez les deux jetons en lieu sûr. Le jeton d’accès sert à effectuer des requêtes auprès de l’API. Le jeton d’actualisation sert à obtenir un nouveau jeton d’accès lorsque le jeton actuel expire.

## 5. Appeler l’API au nom de l’utilisateur

Utilisez le jeton d’accès pour effectuer des requêtes API authentifiées :

```bash
curl -H "Authorization: Bearer eyJhbGciOiJSUzI1..." \
  https://glossia.ai/api/projects
```

Les portées du jeton limitent les points de terminaison auxquels vous pouvez accéder. L’autorisation au niveau des ressources continue de s’appliquer. Par exemple, un jeton doté de `project:read` peut uniquement lire les projets auxquels l’utilisateur a accès.

## 6. Actualiser le jeton

Lorsque le jeton d’accès expire, utilisez le jeton d’actualisation pour en obtenir un nouveau sans soumettre à nouveau l’utilisateur au processus de consentement :

```bash
curl -X POST https://glossia.ai/oauth/token \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "grant_type=refresh_token" \
  -d "refresh_token=dGhpcyBpcyBhIHJl..." \
  -d "client_id=YOUR_CLIENT_ID" \
  -d "client_secret=YOUR_CLIENT_SECRET"
```

## 7. Révoquer un jeton

Lorsqu’un utilisateur déconnecte votre application ou que vous n’avez plus besoin de l’accès, révoquez le jeton :

```bash
curl -X POST https://glossia.ai/oauth/revoke \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "token=eyJhbGciOiJSUzI1..." \
  -d "client_id=YOUR_CLIENT_ID" \
  -d "client_secret=YOUR_CLIENT_SECRET"
```

## Choisir les portées

Demandez uniquement les portées nécessaires à votre application. Voici quelques combinaisons courantes :

| Cas d’utilisation | Portées |
|----------|--------|
| Lire le profil utilisateur | `user:read` |
| Lire les projets et le contenu | `user:read project:read voice:read` |
| Gérer les projets | `user:read project:read project:write` |
| Accès complet à l’organisation | `user:read organization:read organization:write members:read members:write project:read project:write` |

Consultez la [référence complète des portées](/docs/reference/apis/authentication) pour connaître toutes les portées disponibles.

## Points de terminaison de découverte

Votre application peut découvrir automatiquement les points de terminaison OAuth de Glossia en récupérant les métadonnées du serveur :

```bash
curl https://glossia.ai/.well-known/oauth-authorization-server
```

Cette requête renvoie un document JSON contenant `authorization_endpoint`, `token_endpoint`, `revocation_endpoint` et d’autres informations. L’utilisation de la découverte rend votre intégration résistante aux changements de points de terminaison.

## Gestion des erreurs

### Erreurs d’autorisation

Si l’utilisateur refuse son consentement ou si une erreur survient pendant l’autorisation, Glossia redirige vers votre URL de rappel avec un paramètre `error` :

```
https://myapp.com/auth/callback?error=access_denied&state=RANDOM_STATE_VALUE
```

Codes d’erreur courants :

| Erreur | Signification |
|-------|---------|
| `access_denied` | L’utilisateur a refusé la demande d’autorisation |
| `invalid_request` | Un paramètre obligatoire est absent de la requête |
| `invalid_scope` | Une ou plusieurs portées demandées ne sont pas valides |

### Erreurs de jeton

Le point de terminaison de jeton renvoie une réponse HTTP 400 avec un corps d’erreur JSON :

```json
{
  "error": "invalid_grant",
  "error_description": "The authorization code has expired or was already used."
}
```

### Limites de débit

Les points de terminaison OAuth sont soumis à une limitation de débit par adresse IP. Si vous atteignez la limite, vous recevrez une réponse HTTP 429. Consultez la [référence sur la limitation de débit](/docs/reference/apis/authentication) pour plus d’informations.

## Liste de contrôle de sécurité

Avant la mise en production, vérifiez que votre implémentation respecte les pratiques suivantes :

- Toujours utiliser HTTPS pour les URL de rappel en production
- Valider le paramètre `state` lors du rappel afin d’empêcher la falsification de requête intersites (CSRF)
- Stocker les jetons chiffrés au repos
- Ne jamais exposer les jetons dans le code JavaScript côté client ni dans les URL du navigateur
- Utiliser l’ensemble minimal de portées nécessaires
- Gérer correctement l’expiration des jetons à l’aide de jetons d’actualisation
- Révoquer les jetons lorsque les utilisateurs se déconnectent ou suppriment leur compte