%{
  title: "Aperçu",
  summary:
    "Connectez les agents de codage à vos projets Glossia via le protocole de contexte de modèle.",
  category: "Référence",
  subcategory: "mcp",
  order: 1
}
---
Glossia expose un [Model Context Protocol](https://modelcontextprotocol.io) (MCP) serveur qui permet aux agents de codage d'interagir avec vos projets de localisation. Le serveur met en œuvre OAuth 2.1 avec PKCE et enregistrement de client dynamique ([RFC 7591](https://datatracker.ietf.org/doc/html/rfc7591)), afin que tout client compatible MCP puisse s'authentifier sans configuration manuelle des identifiants.

## Ce que fournit le serveur MCP

Une fois connecté, un agent de codage peut lister les comptes et les projets, créer des projets, gérer les membres et les invitations de l'organisation, lire ou mettre à jour les paramètres de voix et de glossaire, et gérer les modèles et jetons de compte, selon ses autorisations.

Le serveur n'expose actuellement aucun outil pour lancer des traductions ou des révisions, ni pour inspecter l'état de traduction par fichier. Voir le [référence des outils](/docs/reference/mcp) pour les outils disponibles.

## URL du serveur

Connectez-vous au service hébergé de Glossia à `https://glossia.ai/mcp`. Glossia exécute et gère ce point de terminaison ; vous configurez uniquement la connexion dans votre agent de codage.

## Flux d'authentification

Le serveur MCP utilise le flux d'autorisation standard OAuth 2.1 avec PKCE. Vous n'avez pas besoin de créer manuellement des clients OAuth. Le flux fonctionne ainsi :

1. L'agent découvre Glossia via `https://glossia.ai/.well-known/oauth-authorization-server`
2. Il s'enregistre en tant que client OAuth via l'endpoint d'enregistrement dynamique
3. Il ouvre votre navigateur pour la connexion et votre consentement
4. Après votre approbation, l'agent reçoit un jeton d'accès et l'attache à toutes les requêtes MCP

## Ajout de Glossia à un agent de codage

### OpenAI Codex

En suivant le [guide de connexion Codex](https://developers.openai.com/codex/mcp), ajoutez le serveur dans votre fichier de configuration Codex à l'adresse `~/.codex/config.toml`:

```toml
[mcp_servers.glossia]
url = "https://glossia.ai/mcp"
```

Ensuite, exécutez la connexion OAuth :

```bash
codex mcp login glossia
```

Votre navigateur s'ouvrira pour l'authentification. Après validation, Codex stocke le jeton localement et l'utilise pour les sessions futures.

Pour vérifier la connexion :

```bash
codex mcp list
```

### Claude Code

Ajoutez le serveur hébergé avec la commande documentée dans [le guide de connexion de Claude Code](https://code.claude.com/docs/en/mcp):

```bash
claude mcp add --transport http glossia https://glossia.ai/mcp
```

Exécuter `/mcp` dans Claude Code et suivez le flux d'authentification du navigateur.

### Autres clients MCP

Un client doit prendre en charge le [flux d'autorisation du protocole de contexte du modèle](https://modelcontextprotocol.io/specification/2025-11-25/basic/authorization) implémenté par Glossia. La connexion nécessite:

- **Transport**: Streamable HTTP
- **Découverte**: Le client doit prendre en charge OAuth 2.0 métadonnées de ressource protégée ([RFC 9728](https://datatracker.ietf.org/doc/html/rfc9728))
- **Enregistrement**: Enregistrement dynamique du client ([RFC 7591](https://datatracker.ietf.org/doc/html/rfc7591))
- **Flux d'authentification**: Code d'autorisation avec PKCE (S256)

Pointez le client vers `https://glossia.ai/mcp` et laissez-le gérer la découverte et l'enregistrement automatiquement.

## Points de terminaison de découverte

Le serveur publie deux documents de métadonnées que les clients MCP utilisent pour initialiser le flux OAuth :

| Point de terminaison | Description |
|---|---|
| `/.well-known/oauth-authorization-server` | Métadonnées du serveur d'autorisation (points de terminaison, types d'octroi pris en charge, méthodes PKCE) |
| `/.well-known/oauth-protected-resource` | Métadonnées de la ressource protégée (portées, serveurs d'autorisation) |

## Limites de débit

Les points de terminaison OAuth imposent des limites de débit pour prévenir les abus :

| Point de terminaison | Limite |
|---|---|
| `POST /oauth/register` | 5 requêtes par minute |
| `POST /oauth/token` | 30 requêtes par minute |
| `POST /oauth/introspect` | 30 requêtes par minute |
| `POST /oauth/revoke` | 30 requêtes par minute |

Lorsqu'une limite de débit est dépassée, le serveur renvoie HTTP 429 avec un `Retry-After` en-tête.

## Dépannage

### L'inscription échoue avec "invalid\_client\_metadata"

Le point d'enregistrement dynamique n'accepte que des `token_endpoint_auth_method` valeurs. Les clients publics (la plupart des agents de codage) doivent envoyer `"none"`, ce que Glossia gère automatiquement en recourant aux méthodes d'authentification par défaut avec PKCE obligatoire.

### "Appel OAuth invalide" après avoir approuvé

Vérifiez que votre agent de codage peut atteindre `https://glossia.ai`. L'appel de retour se produit sur un port local que l'agent de codage ouvre temporairement sur votre ordinateur. Glossia reste hébergé ; cet écouteur local appartient à votre agent. Les pare-feu ou les réseaux privés virtuels peuvent parfois bloquer l'appel.

### L'échange de jetons échoue

Vérifiez que le `code_challenge_methods_supported` Le champ est présent dans les métadonnées du serveur d'autorisation. Le serveur doit annoncer la prise en charge S256 pour que le PKCE fonctionne. Glossia inclut cela par défaut.

### L'agent ne peut pas atteindre le serveur

Vérifiez que le point de terminaison configuré est `https://glossia.ai/mcp` et que votre réseau autorise votre agent de codage à y accéder. Si le service hébergé reste indisponible, contactez le support Glossia.