%{
  title: "Vue d'ensemble",
  summary:
    "Connectez les agents de codage à vos projets Glossia via le protocole Model Context Protocol.",
  category: "référence",
  subcategory: "mcp",
  order: 1
}
---
Glossia expose un [Model Context Protocol](https://modelcontextprotocol.io) (serveur MCP) qui permet aux agents de codage d'interagir avec vos projets de localisation. Le serveur implémente OAuth 2.1 avec PKCE et l'Enregistrement dynamique du client ([RFC 7591](https://datatracker.ietf.org/doc/html/rfc7591)), donc tout client compatible MCP peut s'authentifier sans configuration manuelle des identifiants.

## Ce que fournit le serveur MCP

Une fois connecté, un agent de codage peut :

- Vérifier le statut de traduction dans vos projets
- Déclencher des traductions et des révisions
- Inspecter les entrées de configuration et de contenu
- Accéder au contexte du projet pour des suggestions de code plus intelligentes

## URL du serveur

| Environnement | URL |
|---|---|
| Production | `https://glossia.ai/mcp` |
| Développement local | `http://localhost:4050/mcp` |

## Flux d'authentification

Le serveur MCP utilise le flux standard d'autorisation de code OAuth 2.1 avec PKCE. Vous n'avez pas besoin de créer manuellement de clients OAuth. Le flux fonctionne comme ceci :

1. L'agent découvre votre serveur via `/.well-known/oauth-authorization-server`
2. Il s'enregistre en tant que client OAuth via le point de terminaison d'enregistrement dynamique
3. Il ouvre votre navigateur pour la connexion et le consentement
4. Après votre validation, l'agent reçoit un jeton d'accès et l'attache à toutes les requêtes MCP

## Ajout de Glossia à un agent de codage

### OpenAI Codex

Ajoutez le serveur à votre fichier de configuration Codex à `~/.codex/config.toml`:

```toml
[mcp_servers.glossia]
url = "https://glossia.ai/mcp"
```

Exécutez ensuite la connexion OAuth :

```bash
codex mcp login glossia
```

Votre navigateur s’ouvrira pour l’authentification. Après avoir approuvé, Codex stocke le jeton localement et l'utilise pour les sessions futures.

Pour vérifier la connexion :

```bash
codex mcp list
```

Pour le développement local, remplacez l'URL :

```toml
[mcp_servers.glossia-local]
url = "http://localhost:4050/mcp"
```

### Claude Code

Ajoutez le serveur à vos paramètres MCP Claude Code (`.claude/settings.json` ou le fichier de paramètres global)

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

Claude Code gérera automatiquement le flux OAuth lors de sa première connexion.

### Autres clients MCP

Tout client qui prend en charge la [spécification d'autorisation MCP](https://modelcontextprotocol.io/specification/2025-11-25/basic/authorization) fonctionnera. Les exigences clés sont :

- **Transport**: Flux HTTP
- **Découverte**: Le client doit prendre en charge les métadonnées des ressources protégées OAuth 2.0 ([RFC 9728](https://datatracker.ietf.org/doc/html/rfc9728))
- **Enregistrement**: Enregistrement dynamique du client ([RFC 7591](https://datatracker.ietf.org/doc/html/rfc7591)) ou documents de métadonnées Client ID
- **Flux d'authentification**: Code d'autorisation avec PKCE (S256)

Pointez le client vers l'URL de votre serveur MCP Glossia et laissez-le gérer la découverte et l'enregistrement automatiquement.

## Points de terminaison de découverte

Le serveur publie deux documents de métadonnées que les clients MCP utilisent pour initialiser le flux OAuth :

| Point de terminaison | Description |
|---|---|
| `/.well-known/oauth-authorization-server` | Métadonnées du serveur d'autorisation (points de terminaison, types d'octroi pris en charge, méthodes PKCE) |
| `/.well-known/oauth-protected-resource` | Métadonnées de la ressource protégée (portées, serveurs d'autorisation) |

## Limites de débit

Les points de terminaison OAuth appliquent des limites de débit pour prévenir les abus :

| Point de terminaison | Limite |
|---|---|
| `POST /oauth/register` | 5 requêtes par minute |
| `POST /oauth/token` | 30 requêtes par minute |
| `POST /oauth/introspect` | 30 requêtes par minute |
| `POST /oauth/revoke` | 30 demandes par minute |

Lorsqu'une limite de débit est dépassée, le serveur renvoie HTTP 429 avec un `Retry-After` en-tête.

## Dépannage

### L'inscription échoue avec \\"invalid\_client\_metadata\\"

Le point de terminaison d'inscription dynamique n'accepte que des spécifiques `token_endpoint_auth_method` valeurs. Les clients publics (la plupart des agents de codage) doivent envoyer `"none"`, que Glossia gère automatiquement en recourant aux méthodes d'authentification par défaut avec PKCE enforcement.

### "Rappel OAuth invalide" après approbation

Assurez-vous que votre serveur Glossia est en cours d'exécution et accessible à l'URL configurée. Le callback se déclenche sur un port local que l'agent de codage ouvre temporairement. Les pare-feux ou les VPN peuvent parfois bloquer cela.

### L'échange de jetons échoue

Vérifiez que le champ `code_challenge_methods_supported` est présent dans les métadonnées du serveur d'autorisation. Le serveur doit indiquer le support de S256 pour que PKCE fonctionne. Glossia inclut cela par défaut.

### L'agent ne peut pas atteindre le serveur

Pour le développement local, assurez-vous que le serveur Phoenix est en cours d'exécution (`mix phx.server`) et écoute sur le port attendu (par défaut : 4050). Le point de terminaison MCP doit être accessible depuis le processus de l'agent.