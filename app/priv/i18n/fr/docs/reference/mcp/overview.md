%{
  title: "Vue d’ensemble",
  summary: "Connectez des agents de programmation à vos projets Glossia via le protocole Model Context Protocol.",
  category: "reference",
  subcategory: "mcp",
  order: 1
}
---
Glossia expose un serveur [Model Context Protocol](https://modelcontextprotocol.io) (MCP) qui permet aux agents de programmation d’interagir avec vos projets de localisation. Le serveur implémente OAuth 2.1 avec PKCE et l’enregistrement dynamique des clients ([RFC 7591](https://datatracker.ietf.org/doc/html/rfc7591)). Tout client compatible avec MCP peut ainsi s’authentifier sans configuration manuelle des identifiants.

## Fonctionnalités du serveur MCP

Une fois connecté, un agent de programmation peut :

- Consulter l’état des traductions dans vos projets
- Déclencher des traductions et des révisions
- Examiner la configuration et les entrées de contenu
- Accéder au contexte du projet pour fournir des suggestions de code plus pertinentes

## URL du serveur

| Environnement | URL |
|---|---|
| Production | `https://glossia.ai/mcp` |
| Développement local | `http://localhost:4050/mcp` |

## Flux d’authentification

Le serveur MCP utilise le flux standard de code d’autorisation OAuth 2.1 avec PKCE. Vous n’avez pas besoin de créer manuellement des clients OAuth. Le flux fonctionne comme suit :

1. L’agent découvre votre serveur par l’intermédiaire de `/.well-known/oauth-authorization-server`
2. Il s’enregistre comme client OAuth par l’intermédiaire du point de terminaison d’enregistrement dynamique
3. Il ouvre votre navigateur pour la connexion et le consentement
4. Après votre approbation, l’agent reçoit un jeton d’accès et le joint à toutes les requêtes MCP

## Ajouter Glossia à un agent de programmation

### OpenAI Codex

Ajoutez le serveur à votre fichier de configuration Codex situé à l’emplacement `~/.codex/config.toml` :

```toml
[mcp_servers.glossia]
url = "https://glossia.ai/mcp"
```

Lancez ensuite la connexion OAuth :

```bash
codex mcp login glossia
```

Votre navigateur s’ouvrira pour l’authentification. Après votre approbation, Codex stocke le jeton localement et l’utilise pour les sessions suivantes.

Pour vérifier la connexion :

```bash
codex mcp list
```

Pour le développement local, remplacez l’URL :

```toml
[mcp_servers.glossia-local]
url = "http://localhost:4050/mcp"
```

### Claude Code

Ajoutez le serveur aux paramètres MCP de Claude Code (`.claude/settings.json` ou le fichier de paramètres global) :

```json
{
  "mcpServers": {
    "glossia": {
      "url": "https://glossia.ai/mcp",
      "transport": "streamable-http"
    }
  }
}
```

Claude Code gère automatiquement le flux OAuth lors de sa première connexion.

### Autres clients MCP

Tout client compatible avec la [spécification d’autorisation MCP](https://modelcontextprotocol.io/specification/2025-11-25/basic/authorization) fonctionnera. Les principales exigences sont les suivantes :

- **Transport** : Streamable HTTP
- **Découverte** : le client doit prendre en charge les métadonnées de ressource protégée OAuth 2.0 ([RFC 9728](https://datatracker.ietf.org/doc/html/rfc9728))
- **Enregistrement** : enregistrement dynamique des clients ([RFC 7591](https://datatracker.ietf.org/doc/html/rfc7591)) ou documents de métadonnées d’identifiant client
- **Flux d’authentification** : code d’autorisation avec PKCE (S256)

Indiquez au client l’URL de votre serveur MCP Glossia et laissez-le gérer automatiquement la découverte et l’enregistrement.

## Points de terminaison de découverte

Le serveur publie deux documents de métadonnées que les clients MCP utilisent pour initialiser le flux OAuth :

| Point de terminaison | Description |
|---|---|
| `/.well-known/oauth-authorization-server` | Métadonnées du serveur d’autorisation (points de terminaison, types d’autorisation pris en charge, méthodes PKCE) |
| `/.well-known/oauth-protected-resource` | Métadonnées de la ressource protégée (portées, serveurs d’autorisation) |

## Limites de débit

Les points de terminaison OAuth appliquent des limites de débit afin d’éviter les abus :

| Point de terminaison | Limite |
|---|---|
| `POST /oauth/register` | 5 requêtes par minute |
| `POST /oauth/token` | 30 requêtes par minute |
| `POST /oauth/introspect` | 30 requêtes par minute |
| `POST /oauth/revoke` | 30 requêtes par minute |

Lorsqu’une limite de débit est dépassée, le serveur renvoie le statut HTTP 429 avec un en-tête `Retry-After`.

## Résolution des problèmes

### L’enregistrement échoue avec « invalid_client_metadata »

Le point de terminaison d’enregistrement dynamique n’accepte que certaines valeurs `token_endpoint_auth_method`. Les clients publics (la plupart des agents de programmation) doivent envoyer `"none"`. Glossia les gère automatiquement en revenant aux méthodes d’authentification par défaut avec application de PKCE.

### « Rappel OAuth non valide » après approbation

Assurez-vous que votre serveur Glossia fonctionne et qu’il est accessible à l’URL configurée. Le rappel s’effectue sur un port local que l’agent de programmation ouvre temporairement. Les pare-feu ou les réseaux privés virtuels peuvent parfois le bloquer.

### Échec de l’échange de jetons

Vérifiez que le champ `code_challenge_methods_supported` figure dans les métadonnées du serveur d’autorisation. Le serveur doit annoncer la prise en charge de S256 pour que PKCE fonctionne. Glossia l’inclut par défaut.

### L’agent ne peut pas accéder au serveur

Pour le développement local, assurez-vous que le serveur Phoenix fonctionne (`mix phx.server`) et écoute sur le port attendu (par défaut : 4050). Le point de terminaison MCP doit être accessible depuis le processus de l’agent.