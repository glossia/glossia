%{
  title: "API REST",
  summary:
    "Une API REST d'abord pour les développeurs, avec documentation OpenAPI, authentification OAuth 2.1 et autorisation granulaire. Tout ce que vous pouvez faire dans le tableau de bord, vous pouvez le faire via l'API.",
  order: 4,
  icon: "Terminal",
  hero_cta_text: "Commencer",
  hero_cta_url: "/signup",
  highlights: [
    %{
      title: "Documenté en OpenAPI",
      description:
        "Une spécification complète OpenAPI 3.1 anime la documentation interactive via Scalar. Explorez les endpoints, essayez des requêtes, et générez du code client à partir d'un fichier spécification unique.",
      icon: "Livre ouvert"
    },
    %{
      title: "OAuth 2.1 avec PKCE",
      description:
        "Enregistrements de clients dynamiques, flux de code d'autorisation avec PKCE, introspection de jetons et révocation. Les clients tiers s'authentifient de manière sécurisée sans partager de secrets.",
      icon: "Clef ronde"
    },
    %{
      title: "Pagination et filtrage",
      description:
        "Chaque endpoint de liste prend en charge la pagination, le filtrage de champs et le tri directement. Des métadonnées de réponse prévisibles rendent la construction de clients simple.",
      icon: "Code"
    }
  ]
}
---

## Développeur en premier

L'API REST constitue l'épine dorsale de Glossia. Le tableau de bord, la CLI et le [MCP server](/features/mcp-server) consomment tous les mêmes points d'API. Lorsqu'une fonctionnalité est ajoutée, elle est d'abord intégrée dans l'API et devient visible partout ailleurs à partir de là.

Cela signifie que vous n'êtes jamais limité par l'interface. Tout flux de travail que vous pouvez imaginer, des intégrations CI/CD aux tableaux de bord personnalisés, peut être construit au-dessus de la même interface stable et documentée.

## Authentification

Glossia utilise OAuth 2.1 avec PKCE pour toute authentification API. Le flux prend en charge à la fois les clients de première partie et les clients tiers. Consultez les [docs d'authentification et d'autorisation](/docs/reference/apis/authentication) pour le guide complet.

**Inscription dynamique des clients** -- Les clients s'inscrivent de manière programmatique à `/oauth/register` avec leurs URI de redirection et types de concession. Aucune étape manuelle d'approbation, aucun portail à cliquer.

**Code d'autorisation avec PKCE** -- Les utilisateurs autorisent les clients via un écran de consentement basé sur le navigateur. L'extension PKCE garantit que les jetons restent sécurisés même pour les clients publics qui ne peuvent pas stocker un secret.

**Cycle de vie des jetons** -- Les jetons d'accès peuvent être échangés, introspectés et révoqués via des points d'API OAuth standards. La limitation du débit sur les points d'API des jetons protège contre les attaques par force brute.

## Autorisation

Le contrôle d'accès utilise deux niveaux. Les [docs d'authentification](/docs/reference/apis/authentication) couvrent les portées, les rôles et la matrice des permissions complète en détail.

Les **Portées** définissent quelles catégories de ressources un jeton peut accéder. Un jeton avec `voice:read` peut lire les configurations de voix mais ne peut pas les modifier. Les portées suivent le `resource:action` modèle : `account:read`, `organization:write`, `glossary:admin` pour l'administration du glossaire, et ainsi de suite.

Les **Politiques** vérifient la relation entre l'utilisateur et la ressource spécifique. Un jeton valide avec la bonne portée ne peut pas accéder à une organisation à laquelle l'utilisateur n'appartient pas. Chaque requête est vérifiée contre les deux couches.

## Pagination, filtrage et tri

Tous les points de liste retournent des résultats paginés avec des métadonnées cohérentes :

Chaque réponse inclut `total_count`, `total_pages`, `current_page`, `page_size`, `has_next_page?`, et `has_previous_page?` pour que les clients puissent construire des contrôles de pagination sans avoir à deviner.

Filtrez par n'importe quel champ indexé en utilisant `filters[field]=value` paramètres de requête. Triez croissant ou décroissant avec `order_by[]` paramètres. L'interface est la même pour chaque ressource.

## OpenAPI et documentation interactive

La spécification complète OpenAPI 3.1 est disponible à `/api/openapi.json`. La [référence des API interactive](/docs/reference/apis/rest) est pilotée par Scalar et vous permet d'explorer les points d'API, d'inspecter les schémas, et d'envoyer des requêtes de test directement depuis le navigateur.

Les bibliothèques de clients dans n'importe quel langage peuvent être générées à partir de la spécification. Le contrat est versionné et stable, donc vos intégrations ne sont pas brisées lorsque nous livrons de nouvelles fonctionnalités.
