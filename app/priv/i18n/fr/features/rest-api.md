%{
  title: "API REST",
  summary:
    "Une API REST conçue d'abord pour les développeurs avec de la documentation OpenAPI, une authentification OAuth 2.1 et une autorisation à grain fin. Tout ce que vous pouvez faire dans le tableau de bord, vous pouvez le faire via l'API.",
  order: 4,
  icon: "terminal",
  hero_cta_text: "Commencer",
  hero_cta_url: "/signup",
  highlights: [
    %{
      title: "Documenté OpenAPI",
      description:
        "Une spécification complète OpenAPI 3.1 alimente la documentation interactive via Scalar. Explorez les points de terminaison, essayez des requêtes et générez du code client à partir d'un seul fichier de spécification.",
      icon: "book-open"
    },
    %{
      title: "OAuth 2.1 avec PKCE",
      description:
        "Enregistrement dynamique des clients, flux de code d'autorisation avec PKCE, introspection de jetons et révocation. Les clients tiers s'authentifient en toute sécurité sans partager de secrets.",
      icon: "key-round"
    },
    %{
      title: "Pagination et filtrage",
      description:
        "Chaque point de terminaison de liste prend en charge la pagination par page, le filtrage par champ et le tri. Les métadonnées de réponse prévisibles facilitent la construction de clients.",
      icon: "code"
    }
  ]
}
---
## Développeur avant tout

L'API REST est le socle de Glossia. Le tableau de bord, la CLI, et le [serveur MCP](/features/mcp-server) tous consomment les mêmes endpoints. Lorsqu'on ajoute une fonctionnalité, elle arrive d'abord dans l'API et apparaît ensuite partout ailleurs.

Cela signifie que vous n'êtes jamais limité par l'interface utilisateur. N'importe quel flux de travail que vous puissiez imaginer, des intégrations CI/CD aux tableaux de bord personnalisés, peut être construit sur la même interface stable et documentée.

## Authentification

Glossia utilise OAuth 2.1 avec PKCE pour l'authentification API. Le flux prend en charge à la fois les clients de première et de troisième partie. Voir les [documents d'authentification et d'autorisation](/docs/reference/apis/authentication) pour le guide complet.

**Inscription dynamique des clients** -- Les clients s'inscrivent de manière programmatique à `/oauth/register` avec leurs URI de redirection et types d'octroi. Aucune étape d'approbation manuelle, aucun portail à cliquer.

**Code d'autorisation avec PKCE** -- Les utilisateurs autorisent les clients via un écran de consentement basé sur le navigateur. L'extension PKCE garantit que les jetons restent sécurisés même pour les clients publics ne pouvant pas stocker un secret.

**Cycle de vie des jetons** -- Les jetons d'accès peuvent être échangés, introspectés et révoqués via des points de terminaison OAuth standards. La limitation de débit sur les points de terminaison de jeton protège contre la force brute.

## Autorisation

Le contrôle d'accès utilise deux niveaux. Les [documents d'authentification](/docs/reference/apis/authentication) couvrent les portées, les rôles et la matrice complète des autorisations en détail.

**Portées** définissent les catégories de ressources à quoi un jeton peut accéder. Un jeton avec `voice:read` peut lire les configurations de voix mais ne peut pas les modifier. Les portées suivent le `resource:action` modèle : `account:read`, `organization:write`, `glossary:admin` pour l'administration des terminologies, et ainsi de suite.

**Politiques** véfifier la relation entre l'utilisateur et la ressource spécifique. Un jeton valide avec la portée appropriée ne peut toujours pas accéder à une organisation à laquelle l'utilisateur n'appartient pas. Chaque requête est vérifiée contre les deux couches.

## Pagination, filtrage et tri

Tous les points de terminaison de liste retournent des résultats paginés avec des métadonnées cohérentes :

Chaque réponse comprend `total_count`, `total_pages`, `current_page`, `page_size`, `has_next_page?`, et `has_previous_page?` pour que les clients puissent créer des contrôles de pagination sans deviner.

Filtrer par n'importe quel champ indexé en utilisant `filters[field]=value` des paramètres de requête. Trier par ordre croissant ou décroissant avec `order_by[]` paramètres. L'interface est la même pour chaque ressource.

## OpenAPI et documentation interactive

La spécification complète OpenAPI 3.1 est disponible à `/api/openapi.json`. La [référence API interactive](/docs/reference/apis/rest) est propulsée par Scalar et vous permet d'explorer les endpoints, d'inspecter les schémas et d'envoyer des requêtes de test directement depuis le navigateur.

Les bibliothèques de client de n'importe quel langage peuvent être générées à partir de la spécification. Le contrat est versionné et stable, de sorte que vos intégrations ne sont pas affectées lorsque nous déployons de nouvelles fonctionnalités.