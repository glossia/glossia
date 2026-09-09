%{
  title: "Jetons de compte",
  summary: "Créer et gérer des jetons de compte pour vous authentifier avec l'API Glossia.",
  category: "Référence",
  subcategory: "APIs",
  order: 2
}
---
Les jetons de compte offrent un moyen simple d'authentifier les requêtes API sans passer par le flux OAuth complet. Ils sont idéaux pour les scripts, les pipelines CI/CD et l'automatisation personnelle.

## Créer un jeton

1. Connectez-vous à Glossia et accédez à votre tableau de bord de compte.
2. Ouvrez **API** section de la barre latérale.
3. Cliquez **Jetons de compte**, puis **Nouveau jeton**.
4. Donnez au jeton un descriptif **nom** (par exemple, "CI deploy" ou "CLI access").
5. Choisissez les **portées** ce dont le jeton a besoin. Accordez uniquement les permissions minimales requises.
6. Définissez une **date d'expiration** ou laissez-le vide pour un jeton qui n'expire jamais.
7. Cliquez sur **Créer un jeton**.

Après la création, la valeur complète du jeton est affichée **une fois**. Copiez-le immédiatement et stockez-le en toute sécurité. Vous ne pourrez plus voir la valeur complète à nouveau.

## Utiliser un jeton

Incluez le jeton dans l' `Authorization` en-tête de vos requêtes HTTP :

    Authorization: Bearer glsa_abc123def456...

Par exemple, en utilisant `curl`:

```bash
curl -H "Authorization: Bearer glsa_abc123def456..." \
  https://glossia.ai/api/projects
```

Les jetons de compte suivent la même [modèle d'autorisation](/docs/reference/apis/authentication) en tant que jetons OAuth. Les portées du jeton définissent l'ensemble maximal des actions qu'il peut exécuter, et les politiques au niveau des ressources s'appliquent toujours selon les relations de votre compte.

## Format de jeton

Tous les jetons de compte commencent par le `glsa_` préfixe suivi d'une chaîne hexadécimale aléatoire. Ce préfixe facilite l'identification des jetons Glossia dans les journaux et les scanners de secrets.

## Portées

Les jetons de compte disposent des mêmes portées que les jetons OAuth. Consultez la [référence des portées](/docs/reference/apis/authentication) pour la liste complète.

Lors de la création d'un jeton, sélectionnez uniquement les scopes requis par votre cas d'usage. Par exemple :

- Une intégration en lecture seule nécessite `project:read` et `voice:read`.
- Un pipeline CI qui crée des projets nécessite `project:read` et `project:write`.
- Un script qui gère les membres de l'organisation nécessite `members:read` et `members:write`.

## Gestion des jetons

### Affichage des jetons

La **des jetons du compte** cette page liste tous les jetons actifs avec leur nom, leurs portées, leur date de dernière utilisation et leur expiration. Les jetons qui n'ont jamais été utilisés affichent "Jamais" dans la colonne de dernière utilisation.

### Édition des jetons

Cliquez sur le nom d'un jeton pour modifier ses **nom** et **description**. Les portées et l'expiration ne peuvent pas être modifiées après la création. Si vous avez besoin de différentes portées, créez un nouveau jeton et révoquez l'ancien.

### Révocation des jetons

Pour révoquer un jeton, cliquez **Révoquer** sur la liste des jetons ou ouvrez la page de modification du jeton et utilisez le **Révoquer le jeton** bouton dans la zone de danger. Les jetons révoqués cessent de fonctionner immédiatement et ne peuvent pas être restaurés.

## Meilleures pratiques de sécurité

- **Stockez les jetons en toute sécurité.** Utilisez des variables d'environnement ou un gestionnaire de secrets. Ne committez jamais les jetons dans le contrôle de source.
- **Utilisez des jetons à courte durée de vie.** Définir une date d'expiration lorsque possible.
- **Minimiser les portées.** Accorder uniquement les autorisations dont le jeton a réellement besoin.
- **Effectuer la rotation régulièrement.** Créer de nouveaux jetons et révoquer les anciens selon un calendrier.
- **Surveiller l'utilisation.** Vérifier la date de « dernière utilisation » périodiquement. Révoquer les jetons qui ne sont plus utilisés.
- **Utiliser un seul jeton par intégration.** De cette façon, la révocation d'un jeton ne perturbe pas les autres flux de travail.

## Gestion API

Vous pouvez également gérer les jetons de compte via REST API et le serveur MCP.

### REST API

| Méthode | Endpoint | Description |
|--------|----------|-------------|
| `GET` | `/api/tokens` | Lister les jetons actifs |
| `POST` | `/api/tokens` | Créer un nouveau jeton |
| `DELETE` | `/api/tokens/:id` | Révoquer un jeton |

### MCP

Le serveur MCP expose `list_tokens`, `create_token`et `revoke_token` outils qui reflètent l'API REST.