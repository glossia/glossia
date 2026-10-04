%{
  title: "Authentification",
  summary:
    "Connexion via navigateur, jetons d'accès et points de terminaison d'authentification.",
  category: "Référence",
  subcategory: "APIs",
  order: 1
}
---
Cette page décrit [Open Authorization](https://oauth.net/2.1/) (OAuth), [Proof Key for Code Exchange](https://datatracker.ietf.org/doc/html/rfc7636) (PKCE), et l' [interface de programmation](https://developer.mozilla.org/en-US/docs/Glossary/API) (API). Les spécifications de protocole ci-dessous sont publiées sous forme de Requests for Comments (RFCs).

## Méthodes d'authentification

Glossia prend en charge les sessions de navigateur et les jetons Bearer. Les jetons Bearer peuvent être émis à travers le flux d'autorisation ci-dessous ou créés en tant que [jetons de compte](/docs/reference/apis/account-tokens).

### Sessions de navigateur

Lorsque vous vous connectez via l'interface web, Glossia utilise une authentification basée sur les sessions. Vous vous authentifiez via GitHub, GitLab, Google ou un fournisseur d'identité d'organisation configuré en utilisant la [Assent](https://github.com/pow-auth/assent) bibliothèque. Après une connexion réussie, un cookie de session est défini et utilisé pour les requêtes subséquentes.

Les organisations peuvent configurer Google Workspace ou Okta et vérifier leur domaine d'e-mail professionnel avant d'autoriser l'inscription automatique. Voir [Configurer la connexion de l'organisation](/docs/how-to/organization-sign-in) pour les exigences de configuration et de liaison de comptes.

### Jetons Bearer (OAuth 2.1)

Pour l'accès API (tels que depuis le CLI ou d'autres outils), Glossia implémente OAuth 2.1 avec le flux d'autorisation par code et PKCE. Les clients obtiennent un jeton Bearer et l'incluent dans le `Authorization` en-tête :

    Authorization: Bearer <access_token>

## flux OAuth 2.1

### 1\. Inscription dynamique des clients

Les clients s'inscrivent en appelant `POST /oauth/register` avec leurs métadonnées. Ceci suit [RFC 7591](https://datatracker.ietf.org/doc/html/rfc7591).

```json
{
  "client_name": "My Tool",
  "redirect_uris": ["http://localhost:8080/callback"],
  "grant_types": ["authorization_code"]
}
```

Glossia renvoie `client_id` et `client_secret`. Le `localhost` La redirection dans cet exemple appartient à votre application en cours de développement. Les applications de production doivent enregistrer leur propre adresse de rappel sécurisée.

### 2\. Demande d'autorisation

Le client redirige l'utilisateur vers `/oauth/authorize` avec les paramètres PKCE :

    GET /oauth/authorize?response_type=code&client_id=<id>&redirect_uri=<uri>&code_challenge=<challenge>&code_challenge_method=S256&state=<state>

**PKCE est requis pour tous les clients.** Seule la `S256` méthode challenge est prise en charge.

### 3\. Échange de jetons

Après l'approbation de l'utilisateur, le client échange le code d'autorisation contre des jetons à `POST /oauth/token`:

    POST /oauth/token
    Content-Type: application/x-www-form-urlencoded
    
    grant_type=authorization_code&code=<code>&redirect_uri=<uri>&client_id=<id>&client_secret=<secret>&code_verifier=<verifier>

La réponse inclut un jeton d'accès et, éventuellement, un jeton de rafraîchissement.

### 4\. Rafraîchissement du jeton

Lorsqu'un jeton d'accès expire, utilisez le jeton de rafraîchissement :

    POST /oauth/token
    Content-Type: application/x-www-form-urlencoded
    
    grant_type=refresh_token&refresh_token=<token>&client_id=<id>&client_secret=<secret>

Voir [Autorisation](/docs/reference/apis/authorization) pour les portées de permissions, l'accès des membres et les contrôles de niveau de ressource.

## Points de découverte

Glossia publie des métadonnées via des URLs standards bien connues afin que les clients puissent découvrir les points d'accès automatiquement.

### Métadonnées du serveur d'autorisation OAuth (RFC 8414)

    GET /.well-known/oauth-authorization-server

Retourne l'émetteur, les endpoints, les scopes pris en charge, les types de concession et les méthodes de défi de code.

### Métadonnées de la ressource protégée (RFC 9728)

    GET /.well-known/oauth-protected-resource

Retourne l'identifiant de la ressource, les serveurs d'autorisation, les scopes pris en charge et les méthodes Bearer.

## Limitation du débit

L'inscription est limitée par l'adresse du client. Les jetons, les révocations et les demandes d'introspection sont limitées par l'adresse du client et l'identifiant du client :

| Point de terminaison | Limite |
|----------|-------|
| `POST /oauth/register` | 5 requêtes par minute |
| `POST /oauth/token` | 30 requêtes par minute |
| `POST /oauth/revoke` | 30 requêtes par minute |
| `POST /oauth/introspect` | 30 requêtes par minute |

En cas de limitation du débit, le serveur renvoie HTTP 429 (Trop de requêtes).