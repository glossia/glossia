%{
  title: "Authentification et autorisation",
  summary: "Comment Glossia authentifie les utilisateurs et autorise l'accès à l'API.",
  category: "reference",
  subcategory: "apis",
  order: 1
}
---
## Méthodes d'authentification

Glossia prend en charge deux méthodes d'authentification selon le contexte.

### Sessions de navigateur

Lorsque vous vous connectez depuis l'interface web, Glossia utilise une authentification basée sur les sessions. Vous vous authentifiez auprès d'un fournisseur tiers (GitHub ou GitLab) à l'aide de la bibliothèque [Assent](https://github.com/pow-auth/assent). Une fois la connexion réussie, un cookie de session est défini et utilisé pour les requêtes suivantes.

### Jetons Bearer (OAuth 2.1)

Pour accéder à l'API, notamment depuis l'interface en ligne de commande ou d'autres outils, Glossia implémente OAuth 2.1 avec le flux de code d'autorisation et PKCE. Les clients obtiennent un jeton Bearer et l'incluent dans l'en-tête `Authorization` :

```
Authorization: Bearer <access_token>
```

## Flux OAuth 2.1

### 1. Enregistrement dynamique du client

Les clients s'enregistrent eux-mêmes en appelant `POST /oauth/register` avec leurs métadonnées. Cette procédure respecte la [RFC 7591](https://datatracker.ietf.org/doc/html/rfc7591).

```json
{
  "client_name": "My Tool",
  "redirect_uris": ["http://localhost:8080/callback"],
  "grant_types": ["authorization_code"]
}
```

Le serveur renvoie `client_id` et `client_secret`.

### 2. Requête d'autorisation

Le client redirige l'utilisateur vers `/oauth/authorize` avec les paramètres PKCE :

```
GET /oauth/authorize?response_type=code&client_id=<id>&redirect_uri=<uri>&code_challenge=<challenge>&code_challenge_method=S256&state=<state>
```

**PKCE est requis pour tous les clients.** Seule la méthode de challenge `S256` est prise en charge.

### 3. Échange de jetons

Une fois l'autorisation accordée par l'utilisateur, le client échange le code d'autorisation contre des jetons auprès de `POST /oauth/token` :

```
POST /oauth/token
Content-Type: application/x-www-form-urlencoded

grant_type=authorization_code&code=<code>&redirect_uri=<uri>&client_id=<id>&code_verifier=<verifier>
```

La réponse contient un jeton d'accès et, éventuellement, un jeton d'actualisation.

### 4. Actualisation du jeton

Lorsqu'un jeton d'accès expire, utilisez le jeton d'actualisation :

```
POST /oauth/token
Content-Type: application/x-www-form-urlencoded

grant_type=refresh_token&refresh_token=<token>&client_id=<id>&client_secret=<secret>
```

## Portées

Les portées déterminent les actions qu'un jeton peut effectuer. Elles suivent le modèle `object:action`.

| Portée | Description |
|-------|-------------|
| `user:read` | Lire les informations du profil utilisateur |
| `user:write` | Mettre à jour le profil utilisateur |
| `account:read` | Répertorier les comptes d'organisation auxquels vous avez accès |
| `organization:read` | Lire les informations des organisations et répertorier vos organisations |
| `organization:write` | Créer ou mettre à jour des organisations |
| `organization:delete` | Supprimer des organisations |
| `organization:admin` | Effectuer des actions administratives sur les organisations |
| `members:read` | Lire les membres et les invitations des organisations |
| `members:write` | Gérer les membres et les invitations des organisations |
| `project:read` | Lire les projets |
| `project:write` | Créer ou mettre à jour des projets |
| `project:admin` | Effectuer des actions administratives sur les projets |
| `project:delete` | Supprimer des projets |
| `voice:read` | Lire la configuration de la voix |
| `voice:write` | Créer ou mettre à jour la configuration de la voix |
| `voice:admin` | Effectuer des actions administratives sur la voix |
| `glossary:read` | Lire les entrées de terminologie |
| `glossary:write` | Créer ou mettre à jour les entrées de terminologie |
| `glossary:admin` | Gérer les paramètres de terminologie |

## Modèle d'autorisation

Glossia applique **deux niveaux** de contrôle à l'API REST et au serveur MCP :

1. **Vérification de la portée** : le jeton d'accès doit inclure la portée `object:action` requise.
2. **Politique au niveau de la ressource** : l'utilisateur actuel doit être autorisé à accéder à la ressource concernée via `Glossia.Policy`.

Les portées représentent la capacité *maximale* d'un jeton. Le système de politiques applique l'autorisation *effective* pour une ressource donnée.

### Rôles

| Rôle | Description |
|------|-------------|
| `self` | L’utilisateur accédant à ses propres ressources |
| `organization_member` | Un membre de l’organisation propriétaire de la ressource |
| `organization_admin` | Un administrateur de l’organisation propriétaire de la ressource |
| `public_account` | Le compte est public (lecture seule) |

### Autorisations des rôles

| Portée | self | organization_member | organization_admin | public_account |
|-------|------|----------------------|--------------------|----------------|
| `user:read` | Oui | Oui | | |
| `user:write` | Oui | | | |
| `account:read` | | Oui | Oui | Oui |
| `organization:read` | | Oui | Oui | |
| `organization:write` | | | Oui | |
| `organization:delete` | | | Oui | |
| `organization:admin` | | | Oui | |
| `members:read` | | Oui | Oui | |
| `members:write` | | | Oui | |
| `project:read` | | Oui | Oui | Oui |
| `project:write` | | | Oui | |
| `project:admin` | | | Oui | |
| `project:delete` | | | Oui | |
| `voice:read` | | Oui | Oui | Oui |
| `voice:write` | | | Oui | |
| `voice:admin` | | | Oui | |
| `glossary:read` | | Oui | Oui | |
| `glossary:write` | | | Oui | |
| `glossary:admin` | | | Oui | |

## Points de terminaison de découverte

Glossia publie des métadonnées à des URLs standard bien connues afin que les clients puissent découvrir automatiquement les points de terminaison.

### Métadonnées du serveur d’autorisation OAuth (RFC 8414)

```
GET /.well-known/oauth-authorization-server
```

Renvoie l’émetteur, les points de terminaison, les portées prises en charge, les types d’autorisation et les méthodes de vérification du code.

### Métadonnées de la ressource protégée (RFC 9728)

```
GET /.well-known/oauth-protected-resource
```

Renvoie l’identifiant de la ressource, les serveurs d’autorisation, les portées prises en charge et les méthodes d’utilisation des jetons au porteur.

## Limitation du débit

Le débit des points de terminaison OAuth est limité par adresse IP :

| Point de terminaison | Limite |
|----------|-------|
| `POST /oauth/register` | 5 requêtes par minute |
| `POST /oauth/token` | 30 requêtes par minute |
| `POST /oauth/revoke` | 30 requêtes par minute |
| `POST /oauth/introspect` | 30 requêtes par minute |

Lorsque la limite de débit est atteinte, le serveur renvoie le code HTTP 429 (Trop de requêtes).