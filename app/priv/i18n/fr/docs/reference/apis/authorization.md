%{
  title: "Autorisation",
  summary:
    "Portées de permissions, rôles d'organisation et contrôles d'accès au niveau des ressources.",
  category: "Référence",
  subcategory: "APIs",
  order: 2
}
---

L'authentification établit une identité ; l'autorisation détermine les actions que cette identité peut effectuer. Voir [L'authentification](/docs/reference/apis/authentication) pour les flux de connexion et de jeton.

## Portées

Les portées contrôlent les actions qu'un jeton peut effectuer. Elles suivent le `object:action` modèle.

| Portée | Description |
|-------|-------------|
| `admin:read` | Lire les données d'administration de la plateforme (administrateurs plateforme uniquement) |
| `admin:write` | Mettre à jour les données d'administration de la plateforme (administrateurs plateforme uniquement) |
| `ops:read` | Lire les données d'opérations de la plateforme (administrateurs plateforme uniquement) |
| `user:read` | Lire les informations de profil utilisateur |
| `user:write` | Mettre à jour le profil utilisateur |
| `account:read` | Lister les comptes d'organisation auxquels vous avez accès |
| `organization:read` | Lire les détails de l'organisation (et lister vos organisations) |
| `organization:write` | Créer ou mettre à jour les organisations |
| `organization:claim` | Prendre possession d'une organisation |
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
| `glossary:read` | Lire les entrées de glossaire |
| `glossary:write` | Créer ou mettre à jour les entrées de glossaire |
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

Les [métadonnées de découverte](/docs/reference/apis/authentication#discovery-endpoints) du serveur d'authentification publient les portées disponibles pour les clients. La disponibilité d'une portée ne confère pas l'accès par elle-même.

## Modèle d'autorisation

Glossia impose **deux couches** pour l'[Transfert d'état représentatif](https://developer.mozilla.org/en-US/docs/Glossary/REST) interface de programmation et le [Protocole de contexte du modèle](https://modelcontextprotocol.io) serveur :

1. **Vérification de la portée** : le jeton d'accès doit inclure la portée `object:action` requise.
2. **Politique au niveau de la ressource** : l'utilisateur actuel doit être autorisé pour la ressource spécifique via des permissions des membres explicites ou une politique basée sur le rôle.

Les portées représentent la *maximale* capacité du jeton. Les vérifications de niveau de ressource imposent la *réelle* autorisation pour une ressource spécifique.

### Rôles

| Rôle | Description |
|------|-------------|
| `self` | L'utilisateur accédant à ses propres ressources |
| `organization_member` | Un membre de l'organisation qui possède la ressource |
| `organization_admin` | Un administrateur de l'organisation qui possède la ressource |
| `public_account` | La ressource appartient à un compte public |

### Autorisations de membres

Les membres de non-administrateur peuvent porter des portées d'autorisation explicites. Les nouveaux membres commencent par avoir l'accès en lecture au compte, à l'organisation, aux projets, à la voce, au glossaire, aux discussions et aux tickets. Un administrateur d'organisation peut remplacer ces portées à travers [Membres → Autorisations](/docs/how-to/member-permissions). Une action demandée doit être incluse dans les portées autorisées du membre ainsi que dans les portées du jeton lors de l'utilisation d'un jeton.

Les administrateurs d'organisation conservent leur rôle d'administrateur. Les membres existants sans portées explicites continuent d'utiliser la politico basée sur les rôles ci-dessous jusqu'à ce que les autorisations soient sauvegardées.

### Autorisations de rôles

Le tableau ci-dessous montre les règles courantes liées aux rôles pour les membres sans portées explicites. Ce n'est pas la politique complète : les requêtes de collecte, l'accès temporaire et les administrateurs plateforme disposent de règles supplémentaires.

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
