%{
  title: "Autorisation",
  summary:
    "Portées d'autorisation, rôles d'organisation et vérifications d'accès au niveau des ressources.",
  category: "Référence",
  subcategory: "APIs",
  order: 2
}
---

L'authentification établit une identité ; l'autorisation détermine les actions que cette identité peut exécuter. Voir [Authentification](/docs/reference/apis/authentication) pour les flux de connexion et de jeton.

## Portées

Les portées contrôlent les actions qu'un jeton peut exécuter. Elles suivent le modèle `object:action`.

| Portée | Description |
|-------|-------------|
| `admin:read` | Lire les données d'administration de la plateforme (administrateurs plateforme uniquement) |
| `admin:write` | Mettre à jour les données d'administration de la plateforme (administrateurs plateforme uniquement) |
| `ops:read` | Lire les données d'exploitation de la plateforme (administrateurs plateforme uniquement) |
| `user:read` | Lire les informations de profil utilisateur |
| `user:write` | Mettre à jour le profil utilisateur |
| `account:read` | Lister les comptes d'organisation auxquels vous avez accès |
| `organization:read` | Lire les détails d'organisation (et lister vos organisations) |
| `organization:write` | Créer ou mettre à jour les organisations |
| `organization:claim` | Réclamer une organisation |
| `organization:delete` | Supprimer les organisations |
| `organization:admin` | Actions administratives d'organisation |
| `members:read` | Lire les membres de l'organisation et les invitations |
| `members:write` | Gérer les membres de l'organisation et les invitations |
| `project:read` | Lire les projets |
| `project:write` | Créer ou mettre à jour les projets |
| `project:admin` | Actions administratives de projet |
| `project:delete` | Supprimer les projets |
| `voice:read` | Lire la configuration de la voix |
| `voice:write` | Créer ou mettre à jour la configuration de la voix |
| `voice:admin` | Actions administratives de la voix |
| `glossary:read` | Lire les entrées du glossaire |
| `glossary:write` | Créer ou mettre à jour les entrées du glossaire |
| `glossary:admin` | Gérer les paramètres du glossaire |
| `discussion:read` | Lire les discussions |
| `discussion:write` | Créer ou mettre à jour les discussions |
| `discussion:admin` | Actions administratives de discussion |
| `ticket:read` | Lire les tickets |
| `ticket:write` | Créer ou mettre à jour les tickets |
| `ticket:admin` | Actions administratives de ticket |
| `llm_model:read` | Lire les modèles de langage du compte |
| `llm_model:write` | Gérer les modèles de langage du compte |
| `translation:write` | Écrire les données de traduction |
| `api_credentials:read` | Lire les identifiants d'accès |
| `api_credentials:write` | Gérer les identifiants d'accès |

Les [métadonnées de découverte](/docs/reference/apis/authentication#discovery-endpoints) du serveur d'authentification publient les portées disponibles pour les clients. La disponibilité d'une portée ne confère pas d'accès par elle-même.

## Modèle d'autorisation

Glossia impose **deux couches** pour l'interface de programmation [Representational State Transfer](https://developer.mozilla.org/en-US/docs/Glossary/REST) et le serveur [Model Context Protocol](https://modelcontextprotocol.io) :

1. **Vérification de portée** : le jeton d'accès doit inclure la portée `object:action` requise.
2. **Politique au niveau de la ressource** : l'utilisateur actuel doit être autorisé pour la ressource spécifiée via les permissions de membre explicites ou la politique par rôle.

Les portées représentent la capacité *maximum* d'un jeton. Les contrôles au niveau de la ressource imposent la permission *effectif* pour une ressource spécifique.

### Rôles

| Rôle | Description |
|------|-------------|
| `self` | L'utilisateur accédant à ses propres ressources |
| `organization_member` | Un membre de l'organisation qui possède la ressource |
| `organization_admin` | Un administrateur de l'organisation qui possède la ressource |
| `public_account` | La ressource appartient à un compte public |

### Permissions des membres

Les membres d'organisation non-administrateurs peuvent porter des portées de permission explicites. Les nouveaux membres commencent avec un accès en lecture vers le compte, l'organisation, les projets, la voix, le glossaire, les discussions et les tickets. Un administrateur d'organisation peut remplacer ces portées via [Membres → Permissions](/docs/how-to/member-permissions). Une action demandée doit être incluse dans les portées autorisées du membre ainsi que dans les portées du jeton lors de l'utilisation d'un jeton.

Les administrateurs d'organisation conservent leur rôle d'administrateur. Les membres existants sans portées explicites continuent d'utiliser la politique par rôle ci-dessous tant que les permissions ne sont pas sauvegardées.

### Permissions de rôle

Le tableau ci-dessous montre les règles courantes par rôle pour les membres sans portées explicites. Ce n'est pas la politique complète : les demandes de collection, l'accès temporaire et les administrateurs plateforme ont des règles supplémentaires.

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
