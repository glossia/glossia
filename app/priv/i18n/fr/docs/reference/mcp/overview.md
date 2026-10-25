%{
  title: "Vue d'ensemble",
  summary: "Connectez les agents de codage à vos projets Glossia via le Model Context Protocol.",
  category: "référence",
  subcategory: "mcp",
  order: 1
}
---

Glossia expose un serveur [Protocole de contexte modèle](https://modelcontextprotocol.io) (MCP) qui permet aux agents de codage d'interagir avec vos projets de localisation. Le serveur implémente OAuth 2.1 avec PKCE et l'enregistrement dynamique des clients ([RFC 7591](https://datatracker.ietf.org/doc/html/rfc7591)), de sorte que tout client compatible MCP peut s'authentifier sans configuration manuelle des identifiants.

## Ce que fournit le serveur MCP

Une fois connecté, un agent de codage peut lister les comptes et projets, créer des projets, gérer les membres et invitations de l'organisation, lire ou mettre à jour les paramètres de voix et de glossaire, et gérer les modèles de compte et jetons, selon ses permissions.

Le serveur n'expose pas actuellement d'outils pour démarrer les traductions ou les révisions, ou pour inspecter l'état de traduction par fichier. Consultez la [référence des outils](/docs/reference/mcp) pour les outils disponibles.

## URL du serveur

Connectez-vous au service hébergé de Glossia à `https://glossia.ai/mcp`. Glossia exécute et maintient cet endpoint ; vous configurez uniquement la connexion dans votre agent de codage.

## Flux d'authentification

Le serveur MCP utilise le flux standard d'autorisation OAuth 2.1 avec PKCE. Vous n'avez pas besoin de créer manuellement des clients OAuth. Le flux fonctionne comme ceci :

1. L'agent découvre Glossia via `https://glossia.ai/.well-known/oauth-authorization-server`
2. Il s'enregistre lui-même en tant que client OAuth via l'endpoint d'enregistrement dynamique
3. Il ouvre votre navigateur pour la connexion et le consentement
4. Après votre approbation, l'agent reçoit un token d'accès et l'attache à toutes les requêtes MCP

## Ajout de Glossia à un agent de codage

### OpenAI Codex

En suivant le [guide de connexion Codex](https://developers.openai.com/codex/mcp), ajoutez le serveur à votre fichier de configuration Codex à `~/.codex/config.toml` :

```toml
[mcp_servers.glossia]
url = "https://glossia.ai/mcp"
```

Ensuite, exécutez la connexion OAuth :

```bash
codex mcp login glossia
```

Votre navigateur s'ouvrira pour l'authentification. Après approbation, Codex stocke le token localement et l'utilise pour les sessions futures.

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

Un client doit prendre en charge le [flux d'autorisation du Protocole Contexte Modèle](https://modelcontextprotocol.io/specification/2025-11-25/basic/authorization) implémenté par Glossia. La connexion nécessite :

- **Transport** : HTTP streaming
- **Découverte** : Le client doit prendre en charge les métadonnées de ressources protégées OAuth 2.0 ([RFC 9728](https://datatracker.ietf.org/doc/html/rfc9728))
- **Enregistrement** : Enregistrement dynamique des clients ([RFC 7591](https://datatracker.ietf.org/doc/html/rfc7591))
- **Flux d'authentification** : Code d'autorisation avec PKCE (S256)

Orientez le client vers `https://glossia.ai/mcp` et laissez-le gérer la découverte et l'enregistrement automatiquement.

## Endpoints de découverte

Le serveur publie deux documents d'information que les clients MCP utilisent pour initialiser le flux OAuth :

| Endpoint | Description |
|---|---|
| `/.well-known/oauth-authorization-server` | Métadonnées du serveur d'autorisation (endpoints, types de concession pris en charge, méthodes PKCE) |
| `/.well-known/oauth-protected-resource` | Métadonnées de la ressource protégée (portées, serveurs d'autorisation) |

## Limites de débit

Les endpoints OAuth imposent des limites de débit pour prévenir les abus :

| Endpoint | Limite |
|---|---|
| `POST /oauth/register` | 5 requêtes par minute |
| `POST /oauth/token` | 30 requêtes par minute |
| `POST /oauth/introspect` | 30 requêtes par minute |
| `POST /oauth/revoke` | 30 requêtes par minute |

Lorsqu'une limite de débit est dépassée, le serveur renvoie HTTP 429 avec un en-tête `Retry-After`.

## Dépannage

### L'enregistrement échoue avec «invalid_client_metadata»

L'endpoint d'enregistrement dynamique n'accepte que des valeurs déterminées `token_endpoint_auth_method`. Les clients publics (la plupart des agents de codage) doivent envoyer `"none"`, ce que Glossia gère automatiquement en recourant aux méthodes d'authentification par défaut avec application PKCE.

### "Invalid OAuth callback" après approbation

Vérifiez que votre agent de codage peut atteindre `https://glossia.ai`. La callback intervient sur un port local que l'agent de codage ouvre temporairement sur votre ordinateur. Glossia reste hébergé ; cet écouteur local appartient à votre agent. Des pare-feu ou des réseaux privés virtuels peuvent parfois bloquer la callback.

### L'échange de token échoue

Vérifiez que le champ `code_challenge_methods_supported` est présent dans les métadonnées du serveur d'autorisation. Le serveur doit annoncer une prise en charge S256 pour que PKCE fonctionne. Glossia inclut cela par défaut.

### L'agent ne peut pas atteindre le serveur

Vérifiez que l'endpoint configuré est `https://glossia.ai/mcp` et que votre réseau permet à votre agent de codage d'y accéder. Si le service hébergé reste indisponible, contactez le support Glossia.
