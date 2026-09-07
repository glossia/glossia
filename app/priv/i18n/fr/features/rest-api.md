%{
  title: "API REST",
  summary:
    "Une API REST axée sur les développeurs, dotée de documentation OpenAPI, d'une authentification OAuth 2.1 et d'une autorisation granulaire. Tout ce que vous pouvez faire dans le tableau de bord, vous pouvez le faire via l'API.",
  order: 4,
  icon: "Terminal",
  hero_cta_text: "Commencer",
  hero_cta_url: "/signup",
  highlights: [
    %{
      title: "Documenté par OpenAPI",
      description:
        "Une spécification OpenAPI 3.1 complète permet une documentation interactive via Scalar. Explorez les endpoints, testez des requêtes et générez du code client à partir d'un seul fichier de spécification.",
      icon: "book-open"
    },
    %{
      title: "OAuth 2.1 avec PKCE",
      description:
        "Inscription dynamique de client, flux de code d'autorisation avec PKCE, introspection de jetons et révocation. Les clients tiers s'authentifient de manière sécurisée sans partager de secrets.",
      icon: "key-round"
    },
    %{
      title: "Pagination et filtrage",
      description:
        "Chaque endpoint de liste supporte la pagination par page, le filtrage de champ et le tri de base. Les métadonnées de réponse prévisibles facilitent la création de clients.",
      icon: "Code"
    }
  ]
}
---
## Développeurs en premier

La REST API est l'ossature de Glossia. Le dashboard, la CLI et le [MCP server](/features/mcp-server) consomment tous les mêmes endpoints. Lorsque nous ajoutons une fonctionnalité, elle est déployée d'abord dans l'API et se manifeste partout ailleurs à partir de là.

Cela signifie que vous n'êtes jamais limité par l'interface. Tout flux de travail que vous pouvez imaginer, des intégrations CI/CD aux tableaux de bord personnalisés, peut être construit sur la même interface stable et documentée.

## Authentification

Glossia utilise OAuth 2.1 avec PKCE pour l'authentification de l'API. Le flux supporte à la fois les clients de première partie et les clients tiers. Voir la [documentation sur l'authentification et l'autorisation](/docs/reference/apis/authentication) pour le parcours complet.

**Enregistrement dynamique des clients** -- Les clients s'enregistrent automatiquement au `/oauth/register` avec leurs URI de redirection et leurs types de concessions. Aucune étape d'approbation manuelle, aucun portail à cliquer.

**Code d'autorisation avec PKCE** -- Les utilisateurs autorisent les clients via un écran de consentement dans le navigateur. L'extension PKCE garantit que les jetons restent sécurisés pour les clients publics qui ne peuvent pas stocker un secret.

**Cycle de vie des jetons** -- Les jetons d'accès peuvent être échangés, introspectés et révoqués via les endpoints OAuth standards. La limitation de débit sur les endpoints de jetons protège contre la force brute.

## Autorisation

Le contrôle d'accès utilise deux niveaux. La [documentation sur l'authentification](/docs/reference/apis/authentication) couvre les portées, les rôles et la matrice des permissions.

**Portées** définissent quelles catégories de ressources un jeton peut accéder. Un jeton avec `voice:read` peut lire les configurations vocales mais ne peut pas les modifier. Les portées suivent le pattern `resource:action` : `account:read`, `organization:write`, `glossary:admin` pour l'administration de la terminologie, et ainsi de suite.

**Politiques** vérifient la relation entre l'utilisateur et la ressource spécifique. Un jeton valide avec la portée correcte ne peut pas accéder à une organisation à laquelle l'utilisateur n'appartient pas. Chaque requête est vérifiée contre les deux niveaux.

## Pagination, filtrage et tri

Tous les endpoints de liste retournent des résultats paginés avec des métadonnées cohérentes :

Chaque réponse inclut `total_count`, `total_pages`, `current_page`, `page_size`, `has_next_page?`, et `has_previous_page?` afin que les clients puissent construire des contrôles de pagination sans deviner.

Filtrer par tout champ indexé avec les paramètres de requête `filters[field]=value`. Trier par ordre croissant ou décroissant avec les paramètres `order_by[]`. L'interface est la même pour chaque ressource.

## OpenAPI et documentation interactive

La spécification OpenAPI 3.1 complète est disponible à `/api/openapi.json`. La [référence API interactive](/docs/reference/apis/rest) est propulsée par Scalar et vous permet d'explorer les endpoints, d'inspecter les schémas et d'exécuter des requêtes de test directement depuis le navigateur.

Les bibliothèques clientes de tout langage peuvent être générées à partir de la spécification. Le contrat est versionné et stable, de sorte que vos intégrations ne sont pas rompues lorsque nous lançons de nouvelles fonctionnalités.