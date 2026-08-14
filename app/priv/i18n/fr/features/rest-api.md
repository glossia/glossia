%{
  title: "API REST",
  summary: "Une API REST pensée pour les développeurs, avec une documentation OpenAPI, une authentification OAuth 2.1 et des autorisations précises. Tout ce que vous pouvez faire dans le tableau de bord est également accessible via l’API.",
  order: 4,
  icon: "terminal",
  hero_cta_text: "Commencer",
  hero_cta_url: "/signup",
  highlights: [
    %{title: "Documentation OpenAPI", description: "Une spécification OpenAPI 3.1 complète alimente une documentation interactive via Scalar. Explorez les points de terminaison, testez des requêtes et générez du code client à partir d’un fichier de spécification unique.", icon: "book-open"},
    %{title: "OAuth 2.1 avec PKCE", description: "Enregistrement dynamique des clients, flux de code d’autorisation avec PKCE, introspection des jetons et révocation. Les clients tiers s’authentifient de manière sécurisée sans partager de secrets.", icon: "key-round"},
    %{title: "Pagination et filtrage", description: "Chaque point de terminaison de liste prend en charge nativement la pagination par page, le filtrage par champ et le tri. Des métadonnées de réponse prévisibles facilitent le développement de clients.", icon: "code"}
  ]
}
---
## Priorité aux développeurs

L’API REST constitue la colonne vertébrale de Glossia. Le tableau de bord, la CLI et le [serveur MCP](/features/mcp-server) utilisent tous les mêmes points de terminaison. Lorsque nous ajoutons une fonctionnalité, elle est d’abord intégrée à l’API, puis rendue disponible partout ailleurs.

Vous n’êtes donc jamais limité par l’interface utilisateur. Tous les workflows imaginables, des intégrations CI/CD aux tableaux de bord personnalisés, peuvent être créés à partir de la même interface stable et documentée.

## Authentification

Glossia utilise OAuth 2.1 avec PKCE pour toute authentification auprès de l’API. Ce flux prend en charge les clients internes et tiers. Consultez la [documentation sur l’authentification et l’autorisation](/docs/reference/apis/authentication) pour découvrir la procédure complète.

**Enregistrement dynamique des clients** -- Les clients s’enregistrent par programmation à l’adresse `/oauth/register` avec leurs URI de redirection et leurs types d’autorisation. Aucune approbation manuelle ni aucun portail à parcourir.

**Code d’autorisation avec PKCE** -- Les utilisateurs autorisent les clients au moyen d’un écran de consentement dans le navigateur. L’extension PKCE garantit la sécurité des jetons, même pour les clients publics qui ne peuvent pas stocker de secret.

**Cycle de vie des jetons** -- Les jetons d’accès peuvent être échangés, inspectés et révoqués au moyen de points de terminaison OAuth standard. La limitation du débit sur les points de terminaison des jetons protège contre les attaques par force brute.

## Autorisation

Le contrôle des accès repose sur deux couches. La [documentation sur l’authentification](/docs/reference/apis/authentication) décrit en détail les portées, les rôles et la matrice complète des autorisations.

**Les portées** définissent les catégories de ressources auxquelles un jeton peut accéder. Un jeton doté de `voice:read` peut lire les configurations de voix, mais ne peut pas les modifier. Les portées suivent le modèle `resource:action` : `account:read`, `organization:write`, `glossary:admin` pour l’administration de la terminologie, et ainsi de suite.

**Les politiques** vérifient la relation entre l’utilisateur et la ressource concernée. Même avec une portée appropriée, un jeton valide ne peut pas accéder à une organisation dont l’utilisateur n’est pas membre. Chaque requête est vérifiée par rapport aux deux couches.

## Pagination, filtrage et tri

Tous les points de terminaison de liste renvoient des résultats paginés accompagnés de métadonnées cohérentes :

Chaque réponse inclut `total_count`, `total_pages`, `current_page`, `page_size`, `has_next_page?` et `has_previous_page?`, afin que les clients puissent créer des contrôles de pagination sans avoir à déduire les valeurs.

Filtrez les résultats selon n’importe quel champ indexé à l’aide des paramètres de requête `filters[field]=value`. Triez-les par ordre croissant ou décroissant à l’aide des paramètres `order_by[]`. L’interface est identique pour toutes les ressources.

## OpenAPI et documentation interactive

La spécification OpenAPI 3.1 complète est disponible à l’adresse `/api/openapi.json`. La [référence interactive de l’API](/docs/reference/apis/rest), fondée sur Scalar, vous permet d’explorer les points de terminaison, d’inspecter les schémas et d’effectuer des requêtes de test directement depuis le navigateur.

Des bibliothèques clientes peuvent être générées dans n’importe quel langage à partir de la spécification. Le contrat est versionné et stable, afin que vos intégrations ne soient pas interrompues lors du déploiement de nouvelles fonctionnalités.