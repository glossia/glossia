%{
  title: "Authentification",
  summary:
    "Connexion par navigateur, jetons d'accès et points de terminaison d'authentification.",
  category: "Référence",
  subcategory: "APIs",
  order: 1
}
---

Cette page décrit [Autorisation Ouverte](https://oauth.net/2.1/) (OAuth), [Preuve de clé pour l'échange de code](https://datatracker.ietf.org/doc/html/rfc7636) (PKCE), ainsi que l'[interface de programmation d'application](https://developer.mozilla.org/en-US/docs/Glossary/API) (API). Les spécifications de protocole liées ci-dessous sont publiées sous forme de Demandes de commentaires (RFCs).

## Méthodes d'authentification

Glossia prend en charge les sessions de navigateur et les jetons Bearer. Les jetons Bearer peuvent être émis via le flux d'autorisation ci-dessous ou créés comme [jetons de compte](/docs/reference/apis/account-tokens).

### Sessions de navigateur

Lorsque vous vous connectez via l'interface web, Glossia utilise une authentification par session. Vous vous authentifiez via GitHub, GitLab, Google ou un fournisseur d'identité organisation configuré en utilisant la bibliothèque [Assent](https://github.com/pow-auth/assent). Après une connexion réussie, un cookie de session est défini et utilisé pour les requêtes ultérieures.

Les organisations peuvent configurer Google Workspace ou Okta et vérifier leur domaine de courriel de travail avant d'accorder l'inscription automatique. Consultez [Configurer la connexion organisation](/docs/how-to/organization-sign-in) pour les exigences de configuration et de liaison de compte.

### Jetons Bearer (OAuth 2.1)

Pour l'accès API (tel que depuis l'invite de commande CLI ou d'autres outils), Glossia implémente OAuth 2.1 avec le flux de code d'autorisation et PKCE. Les clients obtiennent un jeton Bearer et l'incluent dans l'`Authorization` en-tête :

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

Glossia renvoie `client_id` et `client_secret`. La `localhost` dans cet exemple appartient à votre application en cours de développement. Les applications de production doivent enregistrer leur propre adresse de rappel sécurisée.

### 2. Requête d'autorisation

Le client redirige l'utilisateur vers `/oauth/authorize` avec les paramètres PKCE :

```
GET /oauth/authorize?response_type=code&client_id=<id>&redirect_uri=<uri>&code_challenge=<challenge>&code_challenge_method=S256&state=<state>
```

**PKCE est requis pour tous les clients.** Seule la méthode de défi `S256` est prise en charge.

### 3. Échange de jeton

Après que l'utilisateur a approuvé, le client échange le code d'autorisation contre des jetons à `POST /oauth/token` :

```
POST /oauth/token
Content-Type: application/x-www-form-urlencoded

grant_type=authorization_code&code=<code>&redirect_uri=<uri>&client_id=<id>&client_secret=<secret>&code_verifier=<verifier>
```

La réponse inclut un jeton d'accès et éventuellement un jeton de rafraîchissement.

### 4. Rafraîchissement de jeton

Lorsqu'un jeton d'accès expire, utilisez le jeton de rafraîchissement :

```
POST /oauth/token
Content-Type: application/x-www-form-urlencoded

grant_type=refresh_token&refresh_token=<token>&client_id=<id>&client_secret=<secret>
```

Consultez [Autorisation](/docs/reference/apis/authorization) pour les portées d'autorisation, l'accès des membres et les vérifications au niveau des ressources.

## Points de terminaison de découverte

Glossia publie des métadonnées sur des URL bien connues standard afin que les clients puissent découvrir automatiquement les points de terminaison.

### Métadonnées du serveur d'autorisation OAuth (RFC 8414)

```
GET /.well-known/oauth-authorization-server
```

Retourne l'émetteur, les points de terminaison, les portées supportées, les types de don de concession, et les méthodes de défi de code.

### Métadonnées de Ressource Protégée (RFC 9728)

```
GET /.well-known/oauth-protected-resource
```

Retourne l'identifiant de la ressource, les serveurs d'autorisation, les portées supportées, et les méthodes Bearer.

## Limitation du débit

L'enregistrement est limité par l'adresse client. Les requêtes de jeton, de révocation et d'introspection sont limitées à la fois par l'adresse client et l'identifiant client :

| Terminaison | Limite |
|----------|-------|
| `POST /oauth/register` | 5 requêtes par minute |
| `POST /oauth/token` | 30 requêtes par minute |
| `POST /oauth/revoke` | 30 requêtes par minute |
| `POST /oauth/introspect` | 30 requêtes par minute |

Lorsqu'en limite de débit, le serveur renvoie HTTP 429 (Trop de requêtes).
