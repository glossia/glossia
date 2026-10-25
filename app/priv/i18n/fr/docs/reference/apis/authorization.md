%{
  title: "Autorisation",
  summary:
    "Portées d'autorisation, rôles d'organisation et contrôles d'accès au niveau des ressources.",
  category: "Référence",
  subcategory: "API",
  order: 2
}
---

L'authentification établit une identité ; l'autorisation détermine quelles actions cette identité peut effectuer. Consultez [Authentification](/docs/reference/apis/authentication) pour les flux de connexion et de jeton.

## Périmètres

Les périmètres contrôlent quelles actions un jeton peut effectuer. Ils suivent le motif `object:action`.

| Périmètre | Description |
|-------|-------------|
| `admin:read` | Lire les données d'administration de la plateforme (administrateurs de plateforme uniquement) |
| `admin:write` | Mettre à jour les données d'administration de la plateforme (administrateurs de plateforme uniquement) |
| `ops:read` | Lire les données d'opérations de la plateforme (administrateurs de plateforme uniquement) |
| `user:read` | Lire les informations de profil utilisateur |
| `user:write` | Mettre à jour le profil utilisateur |
| `account:read` | Lister les comptes d'organisation auxquels vous pouvez accéder |
| `organization:read` | Lire les détails d'organisation (et lister vos organismes) |
| `organization:write` | Créer ou mettre à jour les organisations |
| `organization:claim` | Réclamer une organisation |
| `organization:delete` | Supprimer les organisations |
| `organization:admin` | Actions administratives d'organisation |
| `members:read` | Lire les membres et les invitations d'organisation |
| `members:write` | Gérer les membres et les invitations d'organisation |
| `project:read` | Lire les projets |
| `project:write` | Créer ou mettre à jour les projets |
| `project:admin` | Actions administratives de projet |
| `project:delete` | Supprimer les projets |
| `voice:read` | Lire la configuration de voix |
| `voice:write` | Créer ou mettre à jour la configuration de voix |
| `voice:admin` | Actions administratives de voix |
| `glossary:read` | Lire les entrées du glossaire |
| `glossary:write` | Créer ou mettre à jour les entrées du glossaire |
| `glossary:admin` | Gérer les paramètres du glossaire |
| `discussion:read` | Lire les discussions |
| `discussion:write` | Créer ou mettre à jour les discussions |
| `discussion:admin` | Actions administratives de discussion |
| `ticket:read` | Lire les tickets |
| `ticket:write` | Créer ou mettre à jour les tickets |
| `ticket:admin` | Actions administratives de ticket |
| `llm_model:read` | Lire les modèles de langue du compte |
| `llm_model:write` | Gérer les modèles de langue du compte |
| `translation:read` | Lire l'activité de traduction du projet |
| `translation:write` | Écrire les données de traduction |
| `analytics:read` | Lire les analyses du site web du projet |
| `toki:read` | Lire vos propres conversations privées de projet |
| `toki:write` | Créer des conversations privées et mettre les réponses des compagnons en file d'attente |
| `api_credentials:read` | Lire les identifiants d'accès |
| `api_credentials:write` | Gérer les identifiants d'accès |

Les métadonnées de [discovery metadata](/docs/reference/apis/authentication#discovery-endpoints) du serveur d'authentification publient les périmètres disponibles aux clients. La disponibilité d'un périmètre ne confère pas l'accès en soi.

## Modèle d'autorisation

Glossia impose **two layers** pour l'interface de programmation [Représentation d'État dans le transfert](https://developer.mozilla.org/en-US/docs/Glossary/REST) et le serveur de protocole [Modèle Context Protocol](https://modelcontextprotocol.io) :

1. **Vérification de périmètre** : le jeton d'accès doit inclure le `object:action` périmètre requis.
2. **Politique au niveau des ressources** : l'utilisateur actuel doit être autorisé pour la ressource spécifique par permissions des membres explicites ou la politique basée sur les rôles.

Les périmètres représentent la *capacité* maximale d'un jeton. Les vérifications au niveau des ressources imposent la *permission réelle* pour une ressource spécifique.

### Rôles

| Rôle | Description |
|------|-------------|
| `self` | L'utilisateur accédant à ses propres ressources |
| `organization_member` | Un membre de l'organisation qui possède la ressource |
| `organization_admin` | Un administrateur de l'organisation qui possède la ressource |
| `public_account` | La ressource appartient à un compte public |

### Permissions des membres

Les membres non-administrateurs peuvent porter des périmètres de permission explicites. Les nouveaux membres commencent avec un accès en lecture aux comptes, organisations, projets, voix, glossaires, discussions, tickets, activité de traduction et analyses, ainsi qu'un accès à leurs propres conversations privées Toki. Un administrateur d'organisation peut remplacer ces périmètres via [Membres → Permissions](/docs/how-to/member-permissions). Une action demandée doit être incluse dans les périmètres autorisés du membre ainsi que les périmètres du jeton lorsqu'un jeton est utilisé.

La propriété privée Toki est vérifiée avant les surcharges de périmètre de membre organisation. Ni l'adhésion ni les rôles administrateur ne permettent l'accès à une conversation d'un autre utilisateur. La visibilité du projet est vérifiée séparément. Consultez l'[API mobile et compagnon](/docs/reference/apis/mobile) pour les périmètres et limites des points de terminaison.

Les administrateurs d'organisation conservent leur rôle d'administrateur. Les adhésions existantes sans périmètres explicites continuent d'utiliser la politique basée sur les rôles ci-dessous jusqu'à ce que les permissions soient enregistrées.

### Permissions des rôles

Le tableau ci-dessous montre des règles courantes basées sur les rôles pour les adhésions sans périmètres explicites. Ce n'est pas la politique complète : les requêtes de collection, l'accès temporaire et les administrateurs de plateforme ont des règles supplémentaires.

| Périmètre | Moi-même | Membre d'organisation | Administrateur d'organisation | Compte public |
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
