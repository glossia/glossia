%{
  title: "API REST",
  summary:
    "Une API REST axée sur les développeurs, avec documentation OpenAPI, authentification OAuth 2.1 et autorisation granulaire. Tout ce que vous pouvez faire dans le tableau de bord, vous pouvez le faire via l'API.",
  order: 4,
  icon: "Terminal",
  hero_cta_text: "Commencer",
  hero_cta_url: "/signup",
  highlights: [
    %{
      title: "Documentation OpenAPI",
      description:
        "Une spécification OpenAPI 3.1 complète alimente la documentation interactive via Scalar. Explorez les endpoints, tentez des requêtes et générez du code client à partir d'un fichier de spécification unique.",
      icon: "Documentation"
    },
    %{
      title: "OAuth 2.1 avec PKCE",
      description:
        "Enregistrement dynamique des clients, flux de code avec PKCE, introspection de jeton et révocation. Les clients tiers s'authentifient de manière sécurisée sans partager de secrets.",
      icon: "Authentification"
    },
    %{
      title: "Pagination et filtrage",
      description:
        "Chaque endpoint de liste prend en charge la pagination, le filtrage et le tri. Les métadonnées de réponse prévisibles rendent le développement de clients intuitif.",
      icon: "Code"
    }
  ]
}
---
## Développeur d'abord

La REST API est le socle de Glossia. Le tableau de bord, le CLI, et le [serveur MCP](/features/mcp-server) tous consomment les mêmes endpoints. Lorsqu'on ajoute une fonctionnalité, elle arrive dans l'API d'abord et apparaît ailleurs à partir de là.

Cela signifie que vous n'êtes jamais limité par l'interface utilisateur. Quel que soit le flux de travail que vous puissiez imaginer, des intégrations CI/CD aux tableaux de bord personnalisés, il peut être construit sur la même interface stable et documentée.

## Authentification

Glossia utilise OAuth 2.1 avec PKCE pour toute l'authentification API. Le flux prend en charge à la fois les clients de première et de troisième parties. Consultez la [documentation sur l'authentification et l'autorisation](/docs/reference/apis/authentication) pour le guide compétent.

**Enregistrement dynamique des clients** -- Les clients s'enregistrent de manière programmatique à `/oauth/register` avec leurs URI de redirection et leurs types d'autorisation. Aucune étape d'approbation manuelle, ni de portail à parcourir.

**Code d'autorisation avec PKCE** -- Les utilisateurs autorisent les clients via un écran de consentement basé sur le navigateur. L'extension PKCE garantit que les jetons restent sécurisés même pour les clients publics ne pouvant pas stocker un secret.

**Cycle de vie des jetons** -- Les jetons d'accès peuvent être échangés, introspectés et révoqués via les points d'extrémité OAuth standard. La limitation de débit sur les points d'extrémité des jetons protège contre la force brute.

## Autorisation

Le contrôle d'accès utilise deux couches. Les [documents d'authentification](/docs/reference/apis/authentication) couvrent les périmètres, les rôles et la matrice complète des autorisations en détail.

**Périmètres** définissent les catégories de ressources qu'un jeton peut accéder. Un jeton avec `voice:read` peut lire les configurations de voix mais ne peut pas les modifier. Les périmètres suivent le `resource:action` modèle: `account:read`, `organization:write`, `glossary:admin` pour l'administration du glossaire, et ainsi de suite.

**Politiques** vérifier la relation entre l'utilisateur et la ressource spécifique. Un jeton valide avec le périmètre approprié ne permet pas d'accéder à une organisation à laquelle l'utilisateur n'appartient pas. Chaque requête est vérifiée contre les deux couches.

## Pagination, filtrage et tri

Tous les points de liste renvoient des résultats paginés avec des métadonnées cohérentes :

Chaque réponse inclut `total_count`Le document reassemblé a précédemment échoué la validation : la récupération du texte Markdown littéral doit retourner un tableau de chaînes JSON de longueur correspondante `total_pages`, `current_page`Le document reconstitué a précédemment échoué la validation : la récupération du texte Markdown littéral doit retourner un tableau JSON de chaînes de même longueur. `page_size`Le document réassemblé a précédemment échoué la validation : la récupération de texte littéral Markdown doit renvoyer un tableau de chaînes JSON de longueur correspondante. `has_next_page?`, et `has_previous_page?` de sorte que les clients peuvent créer des contrôles de pagination sans avoir à deviner.

Filtrer par n'importe quel champ indexé en utilisant `filters[field]=value` des paramètres de requête. Trier de manière ascendante ou descendante avec `order_by[]` paramètres. L'interface est la même pour chaque ressource.

## OpenAPI et documentation interactive

La spécification OpenAPI 3.1 complète est disponible à. `/api/openapi.json`. La [référence API interactive](/docs/reference/apis/rest) est propulsée par Scalar et vous permet d'explorer les endpoints, d'inspecter les schémas et d'effectuer des requêtes de test directement depuis le navigateur.

Les bibliothèques clientes pour tous les langages peuvent être générées à partir de la spécification. Le contrat est versionné et stable, de sorte que vos intégrations ne seront pas rompues lorsque nous déployons de nouvelles fonctionnalités.