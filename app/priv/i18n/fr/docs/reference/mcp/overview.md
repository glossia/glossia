%{
  title: "Aperçu",
  summary:
    "Connectez les agents de codage à vos projets Glossia via le protocole de contexte du modèle.",
  category: "Référence",
  subcategory: "mcp",
  order: 1
}
---

Glossia expose un [Protocole de contexte du modèle](https://modelcontextprotocol.io) (MCP) qui permet aux agents de codage d'interagir avec vos projets de localisation. Le serveur implémente OAuth 2.1 avec PKCE et l'inscription dynamique du client ([RFC 7591](https://datatracker.ietf.org/doc/html/rfc7591)), de sorte que tout client compatible MCP peut s'authentiquer sans configuration manuelle des identifiants.

## Ce que fournit le serveur MCP

Une fois connecté, un agent de codage peut lister les comptes et projets, créer des projets, gérer les membres et invitations de l'organisation, lire ou mettre à jour les paramètres voix et glossaire, et gérer les modèles et jetons de compte, sous réserve de ses permissions.

Le serveur ne expose pas actuellement d'outils pour démarrer des traductions ou des révisions, ni pour inspecter l'état de traduction par fichier. Consultez la [référence des outils](/docs/reference/mcp) pour les outils disponibles.

## Adresse du serveur

Connectez-vous au service hébergé de Glossia à `https://glossia.ai/mcp`. Glossia exécute et maintient ce point de terminaison; vous configurez uniquement la connexion dans votre agent de codage.

## Flux d'authentification

Le serveur MCP utilise le flux standard de code d'autorisation d'OAuth 2.1 avec PKCE. Vous n'avez pas besoin de créer manuellement des clients OAuth. Le flux fonctionne comme ceci :

1. L'agent découvre Glossia via `https://glossia.ai/.well-known/oauth-authorization-server`
2. Il s'enregistre en tant que client OAuth via le point de terminaison d'inscription dynamique.
3. Il ouvre votre navigateur pour l'authentification et la validation.
4. Après votre approbation, l'agent reçoit un jeton d'accès et l'attache à toutes les requêtes MCP.

## Ajout de Glossia à un agent de codage

### OpenAI Codex

En suivant le [guide de connexion de Codex](https://developers.openai.com/codex/mcp), ajoutez le serveur à votre fichier de configuration Codex à `~/.codex/config.toml` :

```toml
[mcp_servers.glossia]
url = "https://glossia.ai/mcp"
```

Exécutez ensuite la connexion OAuth :

```bash
codex mcp login glossia
```

Votre navigateur s'ouvrira pour l'authentification. Après votre approbation, Codex stocke le jeton localement et l'utilise pour les futures sessions.

Pour vérifier la connexion :

```bash
codex mcp list
```

### Claude Code

Ajoutez le serveur hébergé avec la commande documentée dans [le guide de connexion de Claude Code](https://code.claude.com/docs/en/mcp) :

```bash
claude mcp add --transport http glossia https://glossia.ai/mcp
```

Exécutez `/mcp` à l'intérieur de Claude Code et suivez le flux d'authentification du navigateur.

### Autres clients MCP

Un client doit prendre en charge le [flux d'autorisation du Protocole de contexte du modèle](https://modelcontextprotocol.io/specification/2025-11-25/basic/authorization) implémenté par Glossia. La connexion requiert :

- **Transport**: HTTP en flux
- **Découverte**: Le client doit prendre en charge les métadonnées de la ressource protégée OAuth 2.0 ([RFC 9728](https://datatracker.ietf.org/doc/html/rfc9728))
- **Inscription**: Inscription dynamique du client ([RFC 7591](https://datatracker.ietf.org/doc/html/rfc7591))
- **Flux d'authentification**: Code d'autorisation avec PKCE (S256)

Orientez le client vers `https://glossia.ai/mcp` et laissez-le gérer la découverte et l'inscription automatiquement.

## Points de terminaison de découverte

Le serveur publie deux documents de métadonnées que les clients MCP utilisent pour initialiser le flux d'OAuth :

| Point de terminaison | Description |
|---|---|
| `/.well-known/oauth-authorization-server` | Métadonnées du serveur d'autorisation (points de terminaison, types de demande pris en charge, méthodes PKCE) |
| `/.well-known/oauth-protected-resource` | Métadonnées de la ressource protégée (étendues, serveurs d'autorisation) |

## Limites de débit

Les points de terminaison OAuth imposent des limites de débit pour prévenir tout abus :

| Point de terminaison | Limite |
|---|---|
| `POST /oauth/register` | 5 requêtes par minute |
| `POST /oauth/token` | 30 requêtes par minute |
| `POST /oauth/introspect` | 30 requêtes par minute |
| `POST /oauth/revoke` | 30 requêtes par minute |

Lorsque la limite de débit est dépassée, le serveur retourne HTTP 429 avec un en-tête `Retry-After`.

## Dépannage

### L'inscription échoue avec "invalid_client_metadata"

Le point de terminaison d'inscription dynamique n'accepte que des valeurs `token_endpoint_auth_method` spécifiques. Les clients publics (la plupart des agents de codage) doivent envoyer `"none"`, ce que Glossia gère automatiquement en recourant aux méthodes d'authentification par défaut avec PKCE imposé.

### "Callback OAuth non valide" après approbation

Confirmez que votre agent de codage peut accéder à `https://glossia.ai`. Le callback a lieu sur un port local que l'agent de codage ouvre temporairement sur votre ordinateur. Glossia reste hébergé ; ce jeton d'écoute local appartient à votre agent. Les pare-feu ou les réseaux privés virtuels peuvent parfois bloquer le callback.

### L'échange de jeton échoue

Vérifiez que le champ `code_challenge_methods_supported` est présent dans les métadonnées du serveur d'autorisation. Le serveur doit annoncer la prise en charge de S256 pour que PKCE fonctionne. Glossia inclut cela par défaut.

### L'agent ne peut pas accéder au serveur

Vérifiez que le point de terminaison configuré est `https://glossia.ai/mcp` et que votre réseau autorise votre agent de codage à y accéder. Si le service hébergé reste indisponible, contactez le support Glossia.
