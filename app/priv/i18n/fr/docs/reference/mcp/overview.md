%{
  title: "Vue d'ensemble",
  summary: "Connectez les agents de codage à vos projets Glossia via le Model Context Protocol.",
  category: "Référence",
  subcategory: "mcp",
  order: 1
}
---
Glossia expose un serveur de [Model Context Protocol](https://modelcontextprotocol.io) (MCP) permettant aux agents de codage d'interagir avec vos projets de localisation. Le serveur met en œuvre OAuth 2.1 avec PKCE et l'Enregistrement dynamique de client ([RFC 7591](https://datatracker.ietf.org/doc/html/rfc7591)), de sorte que n'importe quel client compatible MCP peut s'authentifier sans configuration manuelle des identifiants.

## Ce que le serveur MCP fournit

Une fois connecté, un agent de codage peut :

- Interroger le statut des traductions sur vos projets
- Déclencher des traductions et des révisions
- Examiner les configurations et les entrées de contenu
- Accéder au contexte du projet pour des suggestions de code plus intelligentes

## URL du serveur

| Environnement | URL |
|---|---|
| Production | `https://glossia.ai/mcp` |
| Développement local | `http://localhost:4050/mcp` |

## Flux d'authentification

Le serveur MCP utilise le flux standard de code d'autorisation OAuth 2.1 avec PKCE. Vous n'avez pas besoin de créer des clients OAuth manuellement. Le flux fonctionne comme ceci :

1. L'agent découvre votre serveur via `/.well-known/oauth-authorization-server`
2. Il s'enregistre comme client OAuth via le point de terminaison d'enregistrement dynamique
3. Il ouvre votre navigateur pour la connexion et le consentement
4. Après votre approbation, l'agent reçoit un jeton d'accès et l'attache à toutes les requêtes MCP

## Ajout de Glossia à un agent de codage

### OpenAI Codex

Ajoutez le serveur à votre fichier de configuration Codex situé à `~/.codex/config.toml` :

```toml
[mcp_servers.glossia]
url = "https://glossia.ai/mcp"
```

Puis exécutez la connexion OAuth :

```bash
codex mcp login glossia
```

Votre navigateur s'ouvrira pour l'authentification. Après approbation, Codex stocke le jeton localement et l'utilise pour les prochaines sessions.

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

Ajoutez le serveur aux paramètres MCP de Claude Code (`.claude/settings.json` ou le fichier global de configuration) :

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

Claude Code gérera automatiquement le flux OAuth lors de la première connexion.

### Autres clients MCP

Tout client prenant en charge [la spécification d'autorisation MCP](https://modelcontextprotocol.io/specification/2025-11-25/basic/authorization) fonctionnera. Les exigences clés sont :

- **Transport** : HTTP en flux
- **Découverte** : Le client doit prendre en charge la métadonnée de ressource protégée OAuth 2.0 ([RFC 9728](https://datatracker.ietf.org/doc/html/rfc9728))
- **Enregistrement** : Enregistrement dynamique de client ([RFC 7591](https://datatracker.ietf.org/doc/html/rfc7591)) ou Documents de métadonnées de client ID
- **Flux d'auth** : Code d'autorisation avec PKCE (S256)

Pointez le client vers l'URL du serveur MCP Glossia et laissez-le gérer la découverte et l'enregistrement automatiquement.

## Endpoints de découverte

Le serveur publie deux documents de métadonnées que les clients MCP utilisent pour démarrer le flux OAuth :

| Point de terminaison | Description |
|---|---|
| `/.well-known/oauth-authorization-server` | Métadonnées du serveur d'autorisation (endpoints, types de concessions pris en charge, méthodes PKCE) |
| `/.well-known/oauth-protected-resource` | Métadonnées de la ressource protégée (scopes, serveurs d'autorisation) |

## Limites de débit

Les points de terminaison OAuth imposent des limites de débit pour empêcher les abus :

| Endpoint | Limite |
|---|---|
| `POST /oauth/register` | 5 demandes par minute |
| `POST /oauth/token` | 30 demandes par minute |
| `POST /oauth/introspect` | 30 demandes par minute |
| `POST /oauth/revoke` | 30 demandes par minute |

Lorsqu'une limite de débit est dépassée, le serveur retourne HTTP 429 avec un en-tête `Retry-After`.

## Dépannage

### Échec de l'enregistrement avec « invalid\_client\_metadata »

Le point de terminaison d'enregistrement dynamique n'accepte que des valeurs spécifiques pour `token_endpoint_auth_method`. Les clients publics (la plupart des agents de codage) doivent envoyer `"none"`, ce que Glossia gère automatiquement en retombant sur les méthodes d'authentification par défaut avec application de PKCE.

### "Invalid OAuth callback" après l'approbation

Assurez-vous que votre serveur Glossia tourne et est accessible à l'URL configurée. Le callback se produit sur un port local que l'agent de codage ouvre temporairement. Les pare-feux ou les VPNs peuvent parfois bloquer cela.

### L'échange de jetons échoue

Vérifiez que le champ `code_challenge_methods_supported` est présent dans les métadonnées du serveur d'autorisation. Le serveur doit publier le support S256 pour que le PKCE fonctionne. Glossia inclut cela par défaut.

### L'agent ne peut pas atteindre le serveur

Pour le développement local, assurez-vous que le serveur Phoenix tourne (`mix phx.server`) et écoute sur le port attendu (par défaut : 4050). Le point de terminaison MCP doit être accessible depuis le processus de l'agent.