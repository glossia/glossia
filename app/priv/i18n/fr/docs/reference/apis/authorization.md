%{
  title: "Autorisation",
  summary:
    "Portées d'autorisation, rôles d'organisation et contrôles d'accès au niveau des ressources.",
  category: "Référence",
  subcategory: "APIs",
  order: 2
}
---

L'authentification établit une identité ; l'autorisation détermine les actions que cette identité peut effectuer. Voir [Authentification](/docs/reference/apis/authentication) pour les flux de connexion et de jetons.

## Portées

Les portées contrôlent les actions qu'un jeton peut effectuer. Elles suivent le motif `object:action`.

| Portée | Description |
|-------|-------------|
| `admin:read` | Lire les données d'administration de la plateforme (administrateurs de la plateforme uniquement) |
| `admin:write` | Mettre à jour les données d'administration de la plateforme (administrateurs de la plateforme uniquement) |
| `ops:read` | Lire les données opérationnelles de la plateforme (administrateurs de la plateforme uniquement) |
| `user:read` | Lire les informations de profil utilisateur |
| `user:write` | Mettre à jour le profil utilisateur |
| `account:read` | LISTER les comptes d'organisation auxquels vous avez accès |
| `organization:read` | Lire les détails de l'organisation (et lister vos organisations) |
| `organization:write` | Créer ou mettre à jour des organisations |
| `organization:claim` | Réclamer une organisation |
| `organization:delete` | Supprimer des organisations |
| `organization:admin` | Actions administratives d'organisation |
| `members:read` | Lire les membres de l'organisation et les invitations |
| `members:write` | Gérer les membres de l'organisation et les invitations |
| `project:read` | Lire les projets |
| `project:write` | Créer ou mettre à jour des projets |
| `project:admin` | Actions administratives de projet |
| `project:delete` | Supprimer des projets |
| `voice:read` | Lire la configuration de la voix |
| `voice:write` | Créer ou mettre à jour la configuration de la voix |
| `voice:admin` | Actions administratives de la voix |
| `glossary:read` | Lire les entrées du glossaire |
| `glossary:write` | Créer ou mettre à jour des entrées du glossaire |
| `glossary:admin` | Gérer les paramètres du glossaire |
| `discussion:read` | Lire les discussions |
| `discussion:write` | Créer ou mettre à jour des discussions |
| `discussion:admin` | Actions administratives de discussion |
| `ticket:read` | Lire les tickets |
| `ticket:write` | Créer ou mettre à jour des tickets |
| `ticket:admin` | Actions administratives de ticket |
| `llm_model:read` | Lire les modèles de langue du compte |
| `llm_model:write` | Gérer les modèles de langue du compte |
| `translation:read` | Lire l'activité de traduction du projet |
| `translation:write` | Écrire les données de traduction |
| `analytics:read` | Lire les analyses du site web du projet |
| `toki:read` | Lire vos propres conversations privées de projet |
| `toki:write` | Créer des conversations privées et indexer les réponses des compagnons |
| `api_credentials:read` | Lire les clés d'accès |
| `api_credentials:write` | Gérer les clés d'accès |

Les métadonnées de [découverte](/docs/reference/apis/authentication#discovery-endpoints) du serveur d'authentification publient les portées disponibles aux clients. Le fait qu'une portée soit disponible ne lui garantit pas l'accès par elle-même.

## Modèle d'autorisation

Glossia fait respecter **deux couches** pour l'interface de programmation applicative [Representational State Transfer](https://developer.mozilla.org/en-US/docs/Glossary/REST) et le serveur [Modèle de Contexte Protocol](https://modelcontextprotocol.io) :

1. **Vérification de la portée** : le jeton d'accès doit inclure la portée `object:action` requise.
2. **Politique au niveau des ressources** : l'utilisateur actuel doit être autorisé pour la ressource spécifique à travers des autorisations de membre explicites ou la politique basée sur les rôles.

Les portées représentent la capacité *maximale* d'un jeton. Les vérifications au niveau des ressources imposent l'autorisation *réelle* pour une ressource spécifique.

### Rôles

| Rôle | Description |
|------|-------------|
| `self` | L'utilisateur accédant à leurs propres ressources |
| `organization_member` | Un membre de l'organisation qui possède la ressource |
| `organization_admin` | Un administrateur de l'organisation qui possède la ressource |
| `public_account` | La ressource appartient à un compte public |

### Autorisations de membre

Les adhésies d'organisation non administrateur peuvent porter des portées de permission explicites. Les nouveaux membres commencent avec un accès en lecture au compte, à l'organisation, aux projets, à la voix, au glossaire, aux discussions, aux tickets, à l'activité de traduction et aux analyses, plus l'accès à leurs propres conversations Toki privées. Un administrateur d'organisation peut remplacer ces portées à travers [Membres → Autorisations](/docs/how-to/member-permissions). Une action demandée doit être incluse dans les portées autorisées du membre ainsi que dans les portées du jeton lorsque l'on utilise un jeton.

La propriété Toki privée est vérifiée avant le dépassement des portées du membre d'organisation. Ais mémoire, les rôles de membre n'accordent pas ni les rôles administrateur l'accès à la conversation d'un autre utilisateur. La visibilité du projet est vérifiée séparément. Voir le [API mobile et compagnon](/docs/reference/apis/mobile) pour les portées et limites des points d'extrémité.

Les administrateurs d'organisation conservent leur rôle d'administrateur. Les adhésies existantes sans portées explicites continuent d'utiliser la politique basée sur les rôles ci-dessous jusqu'à ce que les autorisations soient enregistrées.

### Autorisations de rôle

Le tableau ci-dessous montre les règles courantes basées sur les rôles pour les adhésies sans portées explicites. Ce n'est pas la politique complète : les requêtes de collecte, l'accès temporaire et les administrateurs de la plateforme ont des règles supplémentaires.

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
