%{
  title: "Authentification et autorisation",
  summary: "Comment Glossia authentifie les utilisateurs et autorise l'accès API.",
  category: "Référence",
  subcategory: "APIs",
  order: 1
}
---
## Méthodes d'authentification

Glossia prend en charge deux méthodes d'authentification selon le contexte.

### Sessions du navigateur

Lorsque vous vous connectez via l'interface web, Glossia utilise une authentification basée sur des sessions. Vous vous authentifiez via un fournisseur tiers (GitHub ou GitLab) en utilisant la [Assent](https://github.com/pow-auth/assent) bibliothèque. Après une connexion réussie, un cookie de session est défini et utilisé pour les requêtes ultérieures.

### Jetons Bearer (OAuth 2.1)

Pour l'accès API (tel que depuis le CLI ou d'autres outils), Glossia met en œuvre OAuth 2.1 avec le flux d'autorisation et PKCE. Les clients obtiennent un jeton Bearer et l'incluent dans le `Authorization` header:

    Authorization: Bearer <access_token>

## Flux OAuth 2.1

### 1\. Enregistrement dynamique de client

Les clients s'inscrivent eux-mêmes en appelant `POST /oauth/register` avec leurs métadonnées. Cela suit [RFC 7591](https://datatracker.ietf.org/doc/html/rfc7591).

```json
{
  "client_name": "My Tool",
  "redirect_uris": ["http://localhost:8080/callback"],
  "grant_types": ["authorization_code"]
}
```

Le serveur renvoie `client_id` et `client_secret`.

### 2\. Demande d'autorisation

Le client redirige l'utilisateur vers `/oauth/authorize` avec des paramètres PKCE :

    GET /oauth/authorize?response_type=code&client_id=<id>&redirect_uri=<uri>&code_challenge=<challenge>&code_challenge_method=S256&state=<state>

**PKCE est requis pour tous les clients.** Seule la `S256` méthode de challenge est prise en charge.

### 3\. Échange de jeton

Après l'approbation de l'utilisateur, le client échange le code d'autorisation contre des jetons à `POST /oauth/token`:

    POST /oauth/token
    Content-Type: application/x-www-form-urlencoded
    
    grant_type=authorization_code&code=<code>&redirect_uri=<uri>&client_id=<id>&code_verifier=<verifier>

La réponse comprend un jeton d'accès et éventuellement un jeton de rafraîchissement.

### 4\. Rafraîchissement de jeton

Lorsqu'un jeton d'accès expire, utilisez le jeton de rafraîchissement:

    POST /oauth/token
    Content-Type: application/x-www-form-urlencoded
    
    grant_type=refresh_token&refresh_token=<token>&client_id=<id>&client_secret=<secret>

## Portées

Les portées contrôlent les actions qu'un jeton peut effectuer. Elles suivent la `object:action` motif.

| Portée | Description |
|-------|-------------|
| `user:read` | Consulter les informations du profil utilisateur |
| `user:write` | Mettre à jour le profil utilisateur |
| `account:read` | Lister les comptes d'organisation auxquels vous avez accès |
| `organization:read` | Lire les détails des organisations (et lister vos organisations) |
| `organization:write` | Créer ou mettre à jour des organisations |
| `organization:delete` | Supprimer des organisations |
| `organization:admin` | Actions administratives de l'organisation |
| `members:read` | Voir les membres et les invitations de l'organisation |
| `members:write` | Gérer les membres et les invitations de l'organisation |
| `project:read` | Voir les projets |
| `project:write` | Créer ou mettre à jour les projets |
| `project:admin` | Actions administratives des projets |
| `project:delete` | Supprimer les projets |
| `voice:read` | Lire la configuration de la voix |
| `voice:write` | Créer ou mettre à jour la configuration de la voix |
| `voice:admin` | Actions administratives de la voix |
| `glossary:read` | Lire les entrées de terminologie |
| `glossary:write` | Créer ou mettre à jour les entrées de terminologie |
| `glossary:admin` | Gérer les paramètres de terminologie |

## Modèle d'autorisation

Glossia impose **deux couches** pour l'API REST et le serveur MCP:

1. **Vérification de portée**: le jeton d'accès doit comporter le requis `object:action` portée.
2. **Politique de niveau de ressource**: l'utilisateur actuel doit être autorisé pour la ressource spécifique via `Glossia.Policy`.

Les portées représentent la *maximum* capacité d'un jeton. Le système de politique impose la *réel* autorisation pour une ressource spécifique.

### Rôles

| Rôle | Description |
|------|-------------|
| `self` | L'utilisateur accédant à ses propres ressources |
| `organization_member` | Un membre de l'organisation propriétaire de la ressource |
| `organization_admin` | Un administrateur de l'organisation qui possède la ressource |
| `public_account` | Le compte est public (lecture seule) |

### Permissions de rôle

| Périmètre | self | organization\_member | organization\_admin | public\_account |
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

Glossia publie des métadonnées via des URLs standardisées et connues afin que les clients puissent découvrir automatiquement des points de terminaison.

### Métadonnées du serveur d'autorisation OAuth (RFC 8414)

    GET /.well-known/oauth-authorization-server

Retourne l'émetteur, les points de terminaison, les portées prises en charge, les types de demandes d'accès et les méthodes de défi de code.

### Métadonnées des ressources protégées (RFC 9728)

    GET /.well-known/oauth-protected-resource

Retourne l'identifiant de la ressource, les serveurs d'autorisation, les portées prises en charge et les méthodes de porteur.

## Limitation de débit

Les points de terminaison OAuth sont limités par adresse IP :

| Point de terminaison | Limite |
|----------|-------|
| `POST /oauth/register` | 5 requêtes par minute |
| `POST /oauth/token` | 30 requêtes par minute |
| `POST /oauth/revoke` | 30 requêtes par minute |
| `POST /oauth/introspect` | 30 requêtes par minute |

En cas de limitation du débit, le serveur renvoie HTTP 429 (Trop de requêtes).