%{
  title: "Authentification",
  summary:
    "Connexion par navigateur, jetons d'accès et points de terminaison d'authentification.",
  category: "référence",
  subcategory: "APIs",
  order: 1
}
---

Cette page décrit [Authentification Ouverte](https://oauth.net/2.1/) (OAuth), [Echange de clé de preuve](https://datatracker.ietf.org/doc/html/rfc7636) (PKCE) et la [interface de programmation applicative](https://developer.mozilla.org/en-US/docs/Glossary/API) (API). Les spécifications de protocole liées ci-dessous sont publiées sous forme de Requests for Comments (RFCs).

## Méthodes d'authentification

Glossia supporte les sessions de navigateur et les jetons porteurs. Les jetons porteurs peuvent être émis via le flux d'autorisation ci-dessous ou créés en tant que [jets de compte](/docs/reference/apis/account-tokens).

### Sessions de navigateur

Lors de votre connexion via l'interface web, Glossia utilise l'authentification par session. Vous vous authentifiez via GitHub, GitLab, Google ou un fournisseur d'identité configuré pour l'organisation en utilisant la bibliothèque [Assent](https://github.com/pow-auth/assent). Après une connexion réussie, un cookie de session est défini et utilisé pour les requêtes ultérieures.

Les organisations peuvent configurer Google Workspace ou Okta et vérifier leur domaine d'e-mail professionnel avant d'autoriser l'inscription automatique. Voir [Configurer la connexion de l'organisation](/docs/how-to/organization-sign-in) pour les exigences de configuration et de liaison de compte.

### Jetons porteurs (OAuth 2.1)

Pour l'accès API (tel que depuis l'outil CLI ou d'autres outils), Glossia implémente OAuth 2.1 avec le flux de code d'autorisation et le PKCE. Les clients obtiennent un jeton porteur et l'incluent dans le `Authorization` en-tête :

```
Authorization: Bearer <access_token>
```

## Flux OAuth 2.1

### 1. Enregistrement dynamique du client

Les clients s'enregistrent eux-mêmes en appelant `POST /oauth/register` avec leurs métadonnées. Cela suit [RFC 7591](https://datatracker.ietf.org/doc/html/rfc7591).

```json
{
  "client_name": "My Tool",
  "redirect_uris": ["http://localhost:8080/callback"],
  "grant_types": ["authorization_code"]
}
```

Glossia renvoie `client_id` et `client_secret`. La `localhost` redirection dans cet exemple appartient à votre application en cours de développement. Les applications de production doivent enregistrer leur propre adresse de rappel sécurisée.

### 2. Demande d'autorisation

Le client redirige l'utilisateur vers `/oauth/authorize` avec les paramètres PKCE :

```
GET /oauth/authorize?response_type=code&client_id=<id>&redirect_uri=<uri>&code_challenge=<challenge>&code_challenge_method=S256&state=<state>
```

**Le PKCE est requis pour tous les clients.** Seule la méthode de défi `S256` est prise en charge.

### 3. Échange de jetons

Après l'approbation de l'utilisateur, le client échange le code d'autorisation contre des jetons à `POST /oauth/token` :

```
POST /oauth/token
Content-Type: application/x-www-form-urlencoded

grant_type=authorization_code&code=<code>&redirect_uri=<uri>&client_id=<id>&client_secret=<secret>&code_verifier=<verifier>
```

La réponse inclut un jeton d'accès et éventuellement un jeton de rafraîchissement.

### 4. Rafraîchissement des jetons

Lorsqu'un jeton d'accès expire, utilisez le jeton de rafraîchissement :

```
POST /oauth/token
Content-Type: application/x-www-form-urlencoded

grant_type=refresh_token&refresh_token=<token>&client_id=<id>&client_secret=<secret>
```

Voir [Autorisation](/docs/reference/apis/authorization) pour les étendues de permission, l'accès des membres et les vérifications au niveau des ressources.

## Endpoints de découverte

Glossia publie des métadonnées sur des URLs bien connues afin que les clients puissent découvrir automatiquement les endpoints.

### Métadonnées du serveur d'autorisation OAuth (RFC 8414)

```
GET /.well-known/oauth-authorization-server
```

Retourne l'émetteur, les endpoints, les étendues prises en charge, les types de concession et les méthodes de défi de code.

### Métadonnées de la ressource protégée (RFC 9728)

```
GET /.well-known/oauth-protected-resource
```

Retourne l'identifiant de la ressource, les serveurs d'autorisation, les étendues prises en charge et les méthodes de jeton porteur.

## Limitation par débit

L'enregistrement est limité par l'adresse du client. Les requêtes de jeton, de révocation et d'inspection sont limitées par l'adresse du client et l'identifiant du client :

| Endpoint | Limite |
|----------|-------|
| `POST /oauth/register` | 5 requêtes par minute |
| `POST /oauth/token` | 30 requêtes par minute |
| `POST /oauth/revoke` | 30 requêtes par minute |
| `POST /oauth/introspect` | 30 requêtes par minute |

Lorsque limité par débit, le serveur renvoie HTTP 429 (Trop de requêtes).
