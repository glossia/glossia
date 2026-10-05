%{
  title: "Autorisation",
  summary:
    "Portées de permissions, rôles organisationnels et vérifications d'accès au niveau des ressources.",
  category: "Référence",
  subcategory: "API",
  order: 2
}
---
L'authentification établit une identité ; l'autorisation détermine quelles actions cette identité peut effectuer. Voir [Authentification](/docs/reference/apis/authentication) pour les flux de connexion et de jeton.

## Portées

Les portées contrôlent les actions qu'un jeton peut exécuter. Elles suivent le `object:action` modèle.

| Portée | Description |
|-------|-------------|
| `admin:read` | Lire les données d'administration de la plateforme (administrateurs de la plateforme uniquement) |
| `admin:write` | Mettre à jour les données d'administration de la plateforme (administrateurs de la plateforme uniquement) |
| `ops:read` | Lire les données opérationnelles de la plateforme (administrateurs de la plateforme uniquement) |
| `user:read` | Lire les informations du profil utilisateur |
| `user:write` | Mettre à jour le profil utilisateur |
| `account:read` | Lister les comptes des organisations auxquels vous avez accès |
| `organization:read` | Lire les détails des organisations (et lister vos organisations) |
| `organization:write` | Créer ou mettre à jour les organisations |
| `organization:claim` | Rejoindre une organisation |
| `organization:delete` | Supprimer des organisations |
| `organization:admin` | Actions administratives des organisations |
| `members:read` | Voir les membres et les invitations de l'organisation |
| `members:write` | Gérer les membres de l'organisation et les invitations |
| `project:read` | Voir les projets |
| `project:write` | Créer ou mettre à jour les projets |
| `project:admin` | Actions administratives sur les projets |
| `project:delete` | Supprimer les projets |
| `voice:read` | Lire la configuration vocale |
| `voice:write` | Créer ou mettre à jour la configuration vocale |
| `voice:admin` | Actions administratives de la voix |
| `glossary:read` | Lire les entrées du glossaire |
| `glossary:write` | Créer ou mettre à jour des entrées du glossaire |
| `glossary:admin` | Gérer les paramètres du glossaire |
| `discussion:read` | Lire les discussions |
| `discussion:write` | Créer ou mettre à jour les discussions |
| `discussion:admin` | Actions administratives de discussions |
| `ticket:read` | Lire les tickets |
| `ticket:write` | Créer ou mettre à jour les tickets |
| `ticket:admin` | Actions sur les tickets administratifs |
| `llm_model:read` | Lire les modèles de langue du compte |
| `llm_model:write` | Gérer les modèles de langue du compte |
| `translation:write` | Écrire les données de traduction |
| `api_credentials:read` | Identifiants d'accès en lecture |
| `api_credentials:write` | Gérer les identifiants d'accès |

Le serveur d'authentification [métadonnées de découverte](/docs/reference/apis/authentication#discovery-endpoints) publie les portées disponibles aux clients. Une portée disponible ne confère pas l'accès par elle-même.

## Modèle d'autorisation

Glossia impose **deux couches** pour le [Transfert d'État Représentatif](https://developer.mozilla.org/en-US/docs/Glossary/REST) interface de programmation applicative et le [Protocole de Contexte Modélisation](https://modelcontextprotocol.io) serveur:

1. **Vérification de portée**: le jeton d'accès doit inclure le nécessaire `object:action` périmètre.
2. **Politique de niveau de ressource**: l'utilisateur actuel doit être autorisé pour la ressource spécifique via les permissions explicites des membres ou la politique basée sur les rôles.

Les périmètres représentent le *maximum* capacité d'un jeton. Les contrôles de niveau de ressource imposent la *réelle* autorisation pour une ressource spécifique.

### Rôles

| Rôle | Description |
|------|-------------|
| `self` | L'utilisateur accédant à ses propres ressources |
| `organization_member` | Un membre de l'organisation qui possède la ressource |
| `organization_admin` | Un administrateur de l'organisation qui possède la ressource |
| `public_account` | La ressource appartient à un compte public |

### Autorisations des membres

Les membres non administrateurs de l'organisation peuvent avoir des portées d'autorisation explicites. Les nouveaux membres commencent avec un accès en lecture au compte, à l'organisation, aux projets, à la voix, au glossaire, aux discussions et aux tickets. Un administrateur de l'organisation peut remplacer ces portées via [Membres → Autorisations](/docs/how-to/member-permissions). Une action demandée doit être incluse dans les portées autorisées du membre ainsi que dans les portées du jeton lors de l'utilisation d'un jeton.

Les administrateurs d'organisation conservent leur rôle d'administrateur. Les membres existants sans périmètres explicites continuent d'utiliser la politique basée sur les rôles ci-dessous jusqu'à ce que les autorisations soient enregistrées.

### Autorisations de rôle

Le tableau ci-dessous présente les règles courantes basées sur les rôles pour les membres sans périmètres explicites. Ce n'est pas la politique complète : les demandes de collection, l'accès temporaire et les administrateurs de la plateforme ont des règles supplémentaires.

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