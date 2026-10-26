%{
  title: "REST API",
  summary:
    "Une REST API axée sur les développeurs, avec une documentation OpenAPI, une authentification OAuth 2.1 et une autorisation granulaire. Tout ce que vous pouvez faire dans le tableau de bord, vous pouvez le faire via l'API.",
  order: 4,
  icon: "Terminal",
  hero_cta_text: "Commencer",
  hero_cta_url: "/signup",
  highlights: [
    %{
      title: "Documenté OpenAPI",
      description:
        "Une spécification OpenAPI 3.1 complète propose une documentation interactive via Scalar. Explorez les endpoints, testez des requêtes et générez du code client à partir d'un seul fichier de spécification.",
      icon: "book-open"
    },
    %{
      title: "OAuth 2.1 avec PKCE",
      description:
        "Inscription dynamique de clients, flux de code d'autorisation avec PKCE, introspection de tokens et révocation. Les clients tiers s'authentifient en toute sécurité sans partager de secrets.",
      icon: "key-round"
    },
    %{
      title: "Pagination et filtrage",
      description:
        "Tous les endpoints de liste supportent la pagination par page, le filtrage des champs et le tri par défaut. Les métadonnées de réponse prévisibles simplifient la création de clients.",
      icon: "Code"
    }
  ]
}
---

## Développeur d'abord

L'API REST est le pilier de Glossia. Le tableau de bord, la CLI, et le [serveur MCP](/features/mcp-server) consomment tous les mêmes points de terminaison. Lorsque nous ajoutons une fonctionnalité, elle arrive d'abord dans l'API puis se propage par la suite partout ailleurs.

Cela signifie que vous n'êtes jamais limité par l'interface utilisateur. Tout flux de travail que vous pouvez imaginer, des intégrations CI/CD aux tableaux de bord personnalisés, peut être construit en utilisant la même interface stable et documentée.

## Authentification

Glossia utilise OAuth 2.1 avec PKCE pour toute l'authentification API. Le flux prend en charge à la fois les clients de première partie et les clients tiers. Consultez la [documentation d'authentification et d'autorisation](/docs/reference/apis/authentication) pour le guide complet.

**Enregistrement dynamique des clients** -- Les clients s'enregistrent de manière programmatique à `/oauth/register` avec leurs URI de redirection et leurs types de droits. Aucune étape manuelle d'approbation, aucun portail à cliquer.

**Code d'autorisation avec PKCE** -- Les utilisateurs autorisent les clients via une interface de consentement basée sur le navigateur. L'extension PKCE garantit que les tokens restent sécurisés même pour les clients publics qui ne peuvent pas stocker un secret.

**Cycle de vie des tokens** -- Les tokens d'accès peuvent être échangés, introspectés et révoqués via des points de terminaison OAuth standard. La restriction de débit sur les points de terminaison de tokens protège contre les attaques par force brute.

## Autorisation

Le contrôle d'accès utilise deux couches. La [documentation d'authentification](/docs/reference/apis/authentication) couvre les portées, les rôles et la matrice de permissions complète en détail.

Les **Portées** définissent quelles catégories de ressources un token peut accéder. Un token avec `voice:read` peut lire des configurations vocales mais ne peut pas les modifier. Les portées suivent le pattern `resource:action` : `account:read`, `organization:write`, `glossary:admin` pour l'administration du glossaire, et ainsi de suite.

Les **Politiques** vérifient la relation entre l'utilisateur et la ressource spécifique. Un token valide avec la bonne portée ne peut toujours accéder à une organisation à laquelle l'utilisateur n'appartient pas. Chaque requête est vérifiée contre les deux couches.

## Pagination, filtrage et tri

Tous les endpoints de liste restituent des résultats paginés avec des métadonnées cohérentes :

Chaque réponse comprend `total_count`, `total_pages`, `current_page`, `page_size`, `has_next_page?`, et `has_previous_page?` afin que les clients puissent construire des contrôles de pagination sans deviner.

Filtrez par n'importe quel champ indexé en utilisant les paramètres `filters[field]=value`. Triez dans un ordre ascendant ou descendant avec les paramètres `order_by[]`. L'interface est la même pour chaque ressource.

## OpenAPI et documentation interactive

La spécification OpenAPI 3.1 complète est disponible à `/api/openapi.json`. La [référence API interactive](/docs/reference/apis/rest) est propulsée par Scalar et vous permet d'explorer des points de terminaison, d'inspecter des schémas, et d'envoyer des requêtes de test directement depuis le navigateur.

Les bibliothèques clients dans n'importe quel langage peuvent être générées à partir de la spécification. Le contrat est versionné et stable, de sorte que vos intégrations ne cassent pas lorsque nous publions de nouvelles fonctionnalités.
