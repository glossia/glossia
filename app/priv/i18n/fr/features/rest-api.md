%{
  title: "API REST",
  summary:
    "Une API REST conçue pour les développeurs avec une documentation OpenAPI, une authentification OAuth 2.1 et une autorisation granulaire. Tout ce que vous pouvez faire dans le tableau de bord est possible via l'API.",
  order: 4,
  icon: "terminal",
  hero_cta_text: "Commencer",
  hero_cta_url: "/signup",
  highlights: [
    %{
      title: "Documenté en OpenAPI",
      description:
        "Une spécification OpenAPI 3.1 complète permet une documentation interactive via Scalar. Explorez les endpoints, essayez des requêtes et générez le code client à partir d'un seul fichier de spécification.",
      icon: "book-open"
    },
    %{
      title: "OAuth 2.1 avec PKCE",
      description:
        "Inscription dynamique de clients, flux de code d'autorisation avec PKCE, introspection de jeton et révocation. Les clients tiers s'authentifient en toute sécurité sans partager de secrets.",
      icon: "key-round"
    },
    %{
      title: "Pagination et filtrage",
      description:
        "Tous les endpoints de liste supportent la pagination par page, le filtrage de champ et le tri sans configuration. Les métadonnées de réponse prévisibles facilitent la création de clients.",
      icon: "code"
    }
  ]
}
---
## Développeur d'abord

La REST API est l'ossature de Glossia. Le tableau de bord, la CLI, et le [serveur MCP](/features/mcp-server) consomment tous les mêmes points d'accès. Lorsqu'une fonctionnalité est ajoutée, elle est déployée d'abord dans l'API et apparaît ailleurs à partir de là.

Cela signifie que vous n'êtes jamais limité par l'UI. Tout flux de travail que vous puissiez imaginer, des intégrations CI/CD aux tableaux de bord personnalisés, peut s'appuyer sur la même interface stable et documentée.

## Authentification

Glossia utilise OAuth 2.1 avec PKCE pour l'authentification API. Le flux prend en charge à la fois les clients de première partie et les clients tiers. Voir la [documentation de l'authentification et de l'autorisation](/docs/reference/apis/authentication) pour la marche à suivre complète.

**Enregistrement dynamique des clients** -- Les clients s'inscrivent de manière programmatique sur `/oauth/register` avec leurs URI de redirection et leurs types d'octroi. Aucune étape d'approbation manuelle, aucun portail à cliquer.

**Code d'autorisation avec PKCE** -- Les utilisateurs autorisent les clients via un écran de consentement basé sur le navigateur. L'extension PKCE garantit que les jetons restent sécurisés même pour les clients publics qui ne peuvent pas stocker un secret.

**Cycle de vie des jetons** -- Les jetons d'accès peuvent être échangés, introspectés et révoqués via des endpoints OAuth standard. La limitation du débit sur les endpoints de jeton protège contre les attaques par force brute.

## Autorisation

Le contrôle d'accès utilise deux couches. Les [documents d'authentification](/docs/reference/apis/authentication) couvrent les scopes, les rôles et la matrice complète des permissions en détail.

**Portées** définit quelles catégories de ressources un jeton peut accéder. Un jeton avec `voice:read` peut lire les configurations vocales mais ne peut pas les modifier. Les portées suivent le `resource:action` modèle : `account:read`, `organization:write`, `glossary:admin` pour l'administration de la terminologie, et ainsi de suite.

**Politiques** vérifier la relation entre l'utilisateur et la ressource spécifique. Un jeton valide avec le bon périmètre ne peut tout de même pas accéder à une organisation à laquelle l'utilisateur n'appartient pas. Chaque demande est vérifiée contre les deux couches.

## Pagination, filtrage et tri

Tous les points de liste retournent des résultats paginés avec des métadonnées cohérentes:

Chaque réponse inclut `total_count`Le document reconstitué a échoué la validation précédemment : la récupération de texte Markdown a retourné un JSON non valide `total_pages`Le document réassemblé a précédemment échoué la validation : la récupération des littéraux de texte Markdown a retourné un JSON invalide `current_page`, `page_size`, `has_next_page?`, et `has_previous_page?` afin que les clients puissent construire des contrôles de pagination sans avoir à deviner.

Filtrer par n'importe quel champ indexé en utilisant `filters[field]=value` des paramètres de requête. Trier par ordre croissant ou décroissant avec `order_by[]` paramètres. L'interface est la même pour chaque ressource.

## OpenAPI et documentation interactive

La spécification OpenAPI 3.1 complète est disponible à `/api/openapi.json`. Le [référence API interactive](/docs/reference/apis/rest) est alimentée par Scalar et vous permet d'explorer les points de terminaison, d'inspecter les schémas et d'envoyer des requêtes de test directement depuis le navigateur.

Les bibliothèques clientes de n'importe quel langage peuvent être générées à partir de la spécification. Le contrat est versionné et stable, donc vos intégrations ne cassent pas lorsque nous livrons de nouvelles fonctionnalités.