%{
  title: "API REST",
  summary:
    "Une API REST conçue pour les développeurs, avec une documentation OpenAPI, une authentification OAuth 2.1 et une autorisation granulaire. Tout ce que vous pouvez faire dans le tableau de bord est possible via l'API.",
  order: 4,
  icon: "terminal",
  hero_cta_text: "Commencer",
  hero_cta_url: "/signup",
  highlights: [
    %{
      title: "Documenté en OpenAPI",
      description:
        "Une spécification OpenAPI 3.1 complète alimente la documentation interactive via Scalar. Explorez les points de terminaison, essayez des requêtes et générez du code client à partir d'un fichier de spécification unique.",
      icon: "book-open"
    },
    %{
      title: "OAuth 2.1 avec PKCE",
      description:
        "Enregistrement dynamique de clients, flux de codes d'autorisation avec PKCE, introspection et révocation de jetons. Les clients tiers s'authentifient en toute sécurité sans partager de secrets.",
      icon: "key-round"
    },
    %{
      title: "Pagination et filtrage",
      description:
        "Chaque point de terminaison de liste prend en charge une pagination basée sur les pages, un filtrage de champs et un tri natif. Les métadonnées de réponse prévisibles facilitent la création de clients.",
      icon: "code"
    }
  ]
}
---
## Priorité aux développeurs

L'API REST est l'ossature de Glossia. Le tableau de bord, la CLI et le [serveur MCP](/features/mcp-server) tous consomment les mêmes points de terminaison. Lorsqu'une fonctionnalité est ajoutée, elle arrive dans l'API en premier et est exposée partout ailleurs à partir de là.

Cela signifie que vous n'êtes jamais limité par l'interface. N'importe quel flux de travail que vous puissiez imaginer, des intégrations CI/CD aux tableaux de bord personnalisés, peut être construit sur la même interface stable et documentée.

## Authentification

Glossia utilise OAuth 2.1 avec PKCE pour l'authentification API. Ce flux prend en charge à la fois les clients de première partie et les clients tiers. Consultez les [documents d'authentification et d'autorisation](/docs/reference/apis/authentication) pour le guide complet.

**Enregistrement dynamique des clients** -- Les clients s'enregistrent de manière programmatique à `/oauth/register` avec leurs URIs de redirection et leurs types de demande. Aucune étape d'approbation manuelle, aucun portail à parcourir.

**Code d'autorisation avec PKCE** -- Les utilisateurs autorisent les clients via un écran de consentement basé sur le navigateur. L'extension PKCE garantit que les jetons restent sécurisés même pour les clients publics ne pouvant pas stocker un secret.

**Cycle de vie des jetons** -- Les jetons d'accès peuvent être échangés, introspectés et révoqués via des points de terminaison OAuth standards. La limitation de débit sur les points de terminaison de jeton protège contre les attaques par force brute.

## Autorisation

Le contrôle d'accès utilise deux couches. Les [documents d'authentification](/docs/reference/apis/authentication) couvrent les portées, les rôles et la matrice d'autorisations complète en détail.

**Portées** définissent les catégories de ressources qu'un jeton peut accéder. Un jeton avec `voice:read` peut lire les configurations de voix, mais ne peut pas les modifier. Les Portées suivent la `resource:action` modèle : `account:read`, `organization:write`, `glossary:admin` ,pour l'administration de la terminologie, et ainsi de suite.

**,Politiques** ,Vérifier la relation entre l'utilisateur et la ressource spécifique. Un jeton valide avec le bon périmètre ne peut pas accéder à une organisation à laquelle l'utilisateur n'appartient pas. Chaque requête est vérifiée contre les deux couches.

## ,Pagination, filtrage et tri

,Tous les points de terminaison de liste renvoient des résultats paginés avec des métadonnées cohérentes :

,Toute réponse comprend `total_count`, `total_pages`, `current_page`, `page_size`, `has_next_page?`, et `has_previous_page?` de sorte que les clients puissent créer des contrôles de pagination sans deviner.

Filtrer par n'importe quel champ indexé à l'aide de `filters[field]=value` paramètres de requête. Trier par ordre croissant ou décroissant avec `order_by[]` paramètres. L'interface est la même pour chaque ressource.

## OpenAPI et documentation interactive

La spécification OpenAPI 3.1 complète est disponible à `/api/openapi.json`". Le [référence API interactive](/docs/reference/apis/rest) est alimentée par Scalar et vous permet d'explorer les endpoints, d'inspecter les schémas et d'envoyer des requêtes de test directement depuis le navigateur.

Les bibliothèques clientes dans n'importe quel langage peuvent être générées à partir de la spécification. Le contrat est versionné et stable, de sorte que vos intégrations ne sont pas rompues lors de la publication de nouvelles fonctionnalités.