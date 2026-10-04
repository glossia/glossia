%{
  title: "Jetons de compte",
  summary: "Créer et gérer les jetons de compte pour vous authentifier avec l'API Glossia.",
  category: "Référence",
  subcategory: "APIs",
  order: 3
}
---
Les jetons de compte offrent un moyen simple d'authentifier les requêtes API sans passer par le flux OAuth complet. Ils sont idéaux pour les scripts, les pipelines CI/CD et l'automatisation personnelle.

## Création d'un jeton

1. Connectez-vous à Glossia et accédez à votre tableau de bord de compte.
2. Ouvrir le **API** section dans la barre latérale.
3. Cliquer **Jetons de compte**, ensuite **Nouveau jeton**.
4. Donnez au jeton un descriptif **nom** (par exemple, \\"CI deploy\\" ou \\"CLI access\\").
5. Choisissez les **portées** ce dont le jeton a besoin. Accordez uniquement les permissions minimales requises.
6. Définissez une **date d'expiration** ou laissez-le vide pour un jeton qui n'expirera jamais.
7. Cliquez **Créer un jeton**.

Après la création, la valeur complète du jeton est affichée. **Une fois**. Copiez-le immédiatement et stockez-le en toute sécurité. Vous ne serez plus en mesure de voir la valeur complète à nouveau.

## Utilisation d'un jeton

Incluez le jeton dans le `Authorization` en-tête de vos requêtes HTTP :

    Authorization: Bearer glsa_abc123def456...

Par exemple, en utilisant `curl`:

```bash
curl -H "Authorization: Bearer glsa_abc123def456..." \
  https://glossia.ai/api/projects
```

Les jetons de compte suivent le même [modèle d'autorisation](/docs/reference/apis/authorization) sous la forme de jetons OAuth. Les portées du jeton définissent l'ensemble maximal d'actions qu'il peut exécuter, et les politiques au niveau des ressources s'appliquent toujours selon les relations de votre compte.

## Format du jeton

Tous les jetons de compte commencent par le `glsa_` préfixe suivi d'une chaîne hexadécimale aléatoire. Ce préfixe permet d'identifier facilement les jetons Glossia dans les logs et les scanneurs de secrets.

## Portées

Les jetons de compte prennent en charge les mêmes portées que les jetons OAuth. Consultez la [référence des portées](/docs/reference/apis/authorization) pour la liste complète.

Lors de la création d'un jeton, sélectionnez uniquement les scopes requis par votre cas d'usage. Par exemple:

- Une intégration en lecture seule nécessite `project:read` et `voice:read`.
- Un pipeline CI qui crée des projets nécessite `project:read` et `project:write`.
- Un script qui gère les membres d'organisation a besoin `members:read` et `members:write`,

## Gestion des jetons

### Affichage des jetons

La **Jetons du compte** page liste tous les jetons actifs avec leur nom, leurs portées, la date de dernière utilisation et leur expiration. Les jetons qui n'ont jamais été utilisés affichent "Jamais" dans la colonne de dernière utilisation.

### Édition des jetons

Cliquez sur le nom d'un jeton pour modifier son **nom** et **description**. La portée et l'expiration ne peuvent pas être modifiées après la création. Si vous avez besoin de portées différentes, créez un nouveau jeton et révoquez l'ancien.

### Révocation des jetons

Pour révoquer un jeton, cliquez **Révoquer** sur la liste des jetons ou ouvrez la page de modification du jeton et utilisez le **Révoquer le jeton** bouton dans la zone de danger. Les jetons révoqués cessent de fonctionner immédiatement et ne peuvent pas être restaurés.

## Meilleures pratiques de sécurité

- **Stockez les jetons en toute sécurité.** Utilisez des variables d'environnement ou un gestionnaire de secrets. Ne commitez jamais les jetons dans le contrôle de version.
- **Utilisez des jetons à durée de vie courte.** Définissez une date d'expiration dès que possible.
- **Minimisez les portées.** N'accordez que les autorisations dont le jeton a réellement besoin.
- **Rotez-les régulièrement.** Créez de nouveaux jetons et révoquez les anciens selon un calendrier.
- **Surveillez l'utilisation.** Vérifiez périodiquement la date de « dernière utilisation ». Révoquez les jetons qui ne sont plus utilisés.
- **Utilisez un jeton par intégration.** De cette façon, révoquer un jeton n'affecte pas les autres flux de travail.

## Gestion de l'API

Vous pouvez également gérer les jetons de compte via l'API REST et le serveur MCP.

### REST API

| Méthode | Endpoint | Description |
|--------|----------|-------------|
| `GET` | `/api/tokens` | Liste des jetons actifs |
| `POST` | `/api/tokens` | Créer un nouveau jeton |
| `DELETE` | `/api/tokens/:id` | Révoquer un jeton |

### MCP

Le serveur MCP expose `list_tokens`, `create_token`, et `revoke_token` outils qui reflètent l'API REST.