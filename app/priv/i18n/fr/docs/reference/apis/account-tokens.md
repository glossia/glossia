%{
  title: "Jetons de compte",
  summary: "Créer et gérer les jetons de compte pour vous authentifier avec l'API Glossia.",
  category: "reference",
  subcategory: "apis",
  order: 2
}
---
Les jetons de compte offrent un moyen simple d'authentifier les requêtes API sans passer par le flux OAuth complet. Ils sont idéaux pour les scripts, les pipelines CI/CD et l'automatisation personnelle.

## Créer un jeton

1. Connectez-vous à Glossia et accédez à votre tableau de bord de compte.
2. Ouvrez la **API** section de la barre latérale.
3. Cliquez **Jetons de compte**, puis **Nouveau jeton**.
4. Donnez au jeton un descriptif **nom** (par exemple, \\"CI deploy\\" ou \\"CLI access\\").
5. Choisissez les **portées** dont le jeton a besoin. Accordez uniquement les permissions minimales requises.
6. Définir une **date d'expiration** ou laissez-le vide pour un jeton qui n'expirera jamais.
7. Cliquez **Créer un jeton**.

Après la création, la valeur complète du jeton est affichée. **une fois**. Copiez-le immédiatement et stockez-le en toute sécurité. Vous ne serez plus en mesure de voir la valeur complète.

## Utilisation d'un jeton

Incluez le jeton dans le `Authorization` en-tête de vos requêtes HTTP :

    Authorization: Bearer glsa_abc123def456...

Par exemple, en utilisant `curl`:

```bash
curl -H "Authorization: Bearer glsa_abc123def456..." \
  https://glossia.ai/api/projects
```

Les jetons de compte suivent la même [modèle d'autorisation](/docs/reference/apis/authentication) en tant que jetons OAuth. Les portées du jeton définissent l'ensemble maximal d'actions qu'il peut exécuter, et les politiques au niveau des ressources s'appliquent toujours en fonction des relations de votre compte.

## Format de jeton

Tous les jetons de compte commencent par le `glsa_` préfixe suivi d'une chaîne hexadécimale aléatoire. Ce préfixe facilite l'identification des jetons Glossia dans les journaux et les scanneurs de secrets.

## Portées

Les jetons de compte prennent en charge les mêmes portées que les jetons OAuth. Voir le [référence des portées](/docs/reference/apis/authentication) pour la liste complte.

Lors de la création d'un jeton, sélectionnez uniquement les étendues requises par votre cas d'utilisation. Par exemple :

- Une intégration en lecture seule a besoin de `project:read` et `voice:read`.
- Un pipeline CI qui crée des projets a besoin de `project:read` et `project:write`.
- Un script qui gère les membres d'organisation a besoin de `members:read` et `members:write`.

## Gestion des jetons

### Affichage des jetons

Le **Jetons du compte** page liste tous les jetons actifs avec leur nom, leurs portées, leur date de dernière utilisation et leur expiration. Les jetons qui n'ont jamais été utilisés affichent "Jamais" dans la colonne de dernière utilisation.

### Édition des jetons

Cliquez sur le nom d'un jeton pour modifier son **nom** et **description**. Les portées et l'expiration ne peuvent pas être modifiées après la création. Si vous avez besoin de portées différentes, créez un nouveau jeton et révoquez l'ancien.

### Révocation des jetons

Pour révoquer un jeton, cliquez **Révoquer** sur la liste des jetons ou ouvrez la page de modification du jeton et utilisez le **Révoquer le jeton** bouton dans la zone de danger. Les jetons révoqués cessent de fonctionner immédiatement et ne peuvent pas être rétablis.

## Meilleures pratiques de sécurité

- **Stockez les jetons en toute sécurité.** Utilisez des variables d'environnement ou un gestionnaire de secrets. Ne commettez jamais de jetons dans le contrôle de versions.
- **Utilisez des jetons à durée de vie limitée.** Définissez une date d'expiration dans la mesure du possible.
- **Minimisez les périmètres.** Accordez uniquement les autorisations dont le jeton a réellement besoin.
- **Renouvelez les jetons régulièrement.** Créez de nouveaux jetons et révoquez les anciens selon un calendrier.
- **Surveillez l'utilisation.** Vérifiez la date "dernière utilisation" périodiquement. Révoquez les jetons qui ne sont plus utilisés.
- **Utilisez un jeton par intégration.** De cette manière, révoquer un jeton n'interrompt pas les autres flux de travail.

## Gestion des API

Vous pouvez également gérer les jetons de compte via la REST API et le serveur MCP.

### REST API

| Méthode | Point de terminaison | Description |
|--------|----------|-------------|
| `GET` | `/api/tokens` | Lister les jetons actifs |
| `POST` | `/api/tokens` | Créer un nouveau jeton |
| `DELETE` | `/api/tokens/:id` | Révoquer un jeton |

### MCP

Le serveur MCP expose `list_tokens`, `create_token`, et `revoke_token` outils qui reflètent l'API REST.