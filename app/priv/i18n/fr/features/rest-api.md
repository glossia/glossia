%{
  title: "REST API",
  summary:
    "Une API REST centrée sur les développeurs avec documentation OpenAPI, authentification OAuth 2.1 et autorisation granulaire. Tout ce que vous pouvez faire dans le tableau de bord, vous pouvez le faire via l'API.",
  order: 4,
  icon: "terminal",
  hero_cta_text: "Commencer",
  hero_cta_url: "/signup",
  highlights: [
    %{
      title: "Documenté OpenAPI",
      description:
        "Une spécification OpenAPI 3.1 complète permet une documentation interactive via Scalar. Explorez les endpoints, essayez des requêtes et générez du code client à partir d'un seul fichier de spécification.",
      icon: "book-open"
    },
    %{
      title: "OAuth 2.1 avec PKCE",
      description:
        "Enregistrement dynamique des clients, flux d'autorisation de code avec PKCE, introspection des jetons et révocation. Les clients tiers s'authentifient de manière sécurisée sans partager de secrets.",
      icon: "key-round"
    },
    %{
      title: "Pagination et filtrage",
      description:
        "Chaque endpoint de liste prend en charge la pagination basée sur les pages, le filtrage de champs et le tri par défaut. Les métadonnées de réponse prévisibles facilitent la création des clients.",
      icon: "code"
    }
  ]
}
---
## Développeur avant tout

L'API REST est le socle de Glossia. Le tableau de bord, le CLI, et le [serveur MCP](/features/mcp-server) tous consomment les mêmes points d'extrémité. Lorsqu'une fonctionnalité est ajoutée, elle est d'abord mise en place dans l'API et devient visible partout ailleurs.

Cela signifie que vous n'êtes jamais limité par l'interface utilisateur. Tout flux de travail que vous pouvez imaginer, des intégrations CI/CD aux tableaux de bord personnalisés, peut être construit sur la même interface stable et documentée.

## Authentification

Glossia utilise OAuth 2.1 avec PKCE pour toutes les authentifications API. Ce flux prend en charge à la fois les clients de première et de tierce partie. Voir la [documentation d'authentification et d'autorisation](/docs/reference/apis/authentication) pour le guide complet.

**Enregistrement dynamique des clients** -- Les clients s'enregistrent de manière programmée à `/oauth/register` avec leurs URIs de redirection et leurs types d'autorisation. Aucune étape d'approbation manuelle, aucun portail à cliquer.

**Code d'autorisation avec PKCE** -- Les utilisateurs autorisent les clients via un écran de consentement basé sur le navigateur. L'extension PKCE garantit que les jetons restent sécurisés même pour les clients publics qui ne peuvent pas stocker un secret.

**Cycle de vie des jetons** -- Les jetons d'accès peuvent être échangés, introspectés et révoqués via les points d'extrémité OAuth standard. La limitation du débit sur les points d'extrémité de jeton protège contre les attaques par force brute.

## Autorisation

Le contrôle d'accès utilise deux couches. La [documentation d'authentification](/docs/reference/apis/authentication) couvre les portées, les rôles et la matrice complète des permissions en détail.

**Portées** définissent quelles catégories de ressources un jeton peut accéder. Un jeton avec `voice:read` peut lire les configurations de voix mais ne peut pas les modifier. Les portées suivent le `resource:action` modèle: `account:read`, `organization:write`, `glossary:admin` ,pour l'administration de la terminologie, et ainsi de suite.

**Politiques** vérifier la relation entre l'utilisateur et la ressource spécifique. Un jeton valide avec la portée appropriée ne peut toujours pas accéder à une organisation à laquelle l'utilisateur n'appartient pas. Chaque demande est vérifiée contre les deux couches.

## Pagination, filtrage et tri

Tous les points de terminaison de liste retournent des résultats paginés avec des métadonnées cohérentes :

Chaque réponse inclut `total_count`, `total_pages`La validation du document reconstitué a échoué précédemment : la récupération du texte-littéral Markdown doit retourner un tableau de chaînes JSON de longueur correspondante. `current_page`Le document reconstitué a échoué la validation précédemment : la récupération du nœud de texte Markdown a produit une traduction vide `page_size`Le document reconstitué a échoué la validation précédemment : la récupération du nœud de texte Markdown a produit une traduction vide `has_next_page?`, et `has_previous_page?` donc les clients peuvent créer des contrôles de pagination sans deviner.

Filtrer par tout champ indexé en utilisant `filters[field]=value` paramètres de requête. Trier par ordre croissant ou décroissant avec `order_by[]` paramètres. L'interface est la même pour chaque ressource.

## OpenAPI et documentation interactive

La spécification complète OpenAPI 3.1 est disponible à `/api/openapi.json`. Le [référence API interactive](/docs/reference/apis/rest) est propulsée par Scalar et vous permet d'explorer des points de terminaison, d'inspecter des schémas et d'envoyer des requêtes de test directement depuis le navigateur.

Les bibliothèques clientes dans n'importe quel langage peuvent être générées à partir de la spécification. Le contrat est versionné et stable, de sorte que vos intégrations ne se brisent pas lors du déploiement de nouvelles fonctionnalités.