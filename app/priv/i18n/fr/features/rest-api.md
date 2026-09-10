%{
  title: "API REST",
  summary:
    "Une API REST d'abord pour les développeurs avec une documentation OpenAPI, une authentification OAuth 2.1 et une autorisation granulaire. Tout ce que vous pouvez faire dans le tableau de bord, vous pouvez le faire via l'API.",
  order: 4,
  icon: "terminal",
  hero_cta_text: "Commencer",
  hero_cta_url: "/signup",
  highlights: [
    %{
      title: "Documenté OpenAPI",
      description:
        "Une spécification OpenAPI 3.1 complète alimente une documentation interactive via Scalar. Explorez les endpoints, testez les requêtes et générez du code client à partir d'un fichier de spécification unique.",
      icon: "book-open"
    },
    %{
      title: "OAuth 2.1 avec PKCE",
      description:
        "Enregistrement dynamique de clients, flux d'autorisation avec PKCE, introspection de jeton et révocation. Les clients tiers s'authentifient de manière sécurisée sans partager de secrets.",
      icon: "key-round"
    },
    %{
      title: "Pagination et filtrage",
      description:
        "Chaque endpoint de liste prend en charge nativement la pagination, le filtrage de champ et le tri. Des métadonnées de réponse prévisibles rendent la création de clients plus simple.",
      icon: "code"
    }
  ]
}
---
## Développeurs d'abord

L'API REST est le socle de Glossia. Le tableau de bord, la CLI et le [serveur MCP](/features/mcp-server) tous consomment les mêmes points de terminaison. Lorsqu'on ajoute une fonctionnalité, elle est déployée dans l'API d'abord et devient ensuite accessible partout ailleurs.

Cela signifie que vous n'êtes jamais limité par l'interface utilisateur. Tout flux de travail que vous pouvez imaginer, des intégrations CI/CD aux tableaux de bord personnalisés, peut être construit au-dessus de la même interface stable et documentée.

## Authentification

Glossia utilise OAuth 2.1 avec PKCE pour l'authentification API. Le flux prend en charge à la fois les clients de première partie et les clients tiers. Voir la [documentation sur l'authentification et l'autorisation](/docs/reference/apis/authentication) pour le guide complet.

**Inscription dynamique des clients** -- Les clients s'enregistrent de manière programmatique à `/oauth/register` avec leurs URI de redirection et leurs types de mandat. Aucune étape d'approbation manuelle, aucun portail à parcourir.

**Code d'autorisation avec PKCE** -- Les utilisateurs autorisent les clients via un écran de consentement basé sur le navigateur. L'extension PKCE garantit que les jetons restent sécurisés, même pour les clients publics qui ne peuvent pas stocker un secret.

**Cycle de vie des jetons** -- Les jetons d'accès peuvent être échangés, introspectés et révoqués via des points de terminaison OAuth standard. La limitation de débit sur les points de terminaison des jetons protège contre les attaques par force brute.

## Autorisation

Le contrôle d'accès utilise deux niveaux. Les [documents d'authentification](/docs/reference/apis/authentication) couvrent les portées, les rôles et la matrice complète des permissions en détail.

**Portées** définissent quelles catégories de ressources un jeton peut accéder. Un jeton avec `voice:read` peut lire les configurations de voix mais ne peut pas les modifier. Les portées suivent le `resource:action` modèle : `account:read`, `organization:write`, `glossary:admin` , pour l'administration terminologique, et ainsi de suite.

**Politiques** vérifier la relation entre l'utilisateur et la ressource spécifique. Un jeton valide avec la bonne portée ne peut toujours pas accéder à une organisation à laquelle l'utilisateur n'appartient pas. Toute demande est vérifiée contre les deux couches.

## Pagination, filtrage et tri

Tous les endpoints de liste renvoient des résultats paginés avec des métadonnées cohérentes :

Toute réponse inclut `total_count`, `total_pages`, `current_page`, `page_size`, `has_next_page?`, et `has_previous_page?` afin que les clients puissent créer des contrôles de pagination sans avoir à deviner.

Filtrer par tout champ indexé à l'aide de `filters[field]=value` les paramètres de requête. Trier par ordre croissant ou décroissant avec `order_by[]` paramètres. L'interface est la même pour chaque ressource.

## OpenAPI et documentation interactive

La spécification complète OpenAPI 3.1 est disponible à `/api/openapi.json`. La [référence API interactive](/docs/reference/apis/rest) est alimentée par Scalar et vous permet d'explorer les endpoints, d'inspecter les schémas et d'envoyer des requêtes de test directement depuis le navigateur.

Les bibliothèques clientes de tous les langages peuvent être générées à partir de la spécification. Le contrat est versionné et stable, de sorte que vos intégrations ne cassent pas lorsque nous déployons de nouvelles fonctionnalités.