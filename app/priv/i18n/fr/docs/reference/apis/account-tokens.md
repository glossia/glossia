%{
  title: "Jetons de compte",
  summary: "Créer et gérer les jetons de compte pour l'authentification avec l'API Glossia.",
  category: "Référence",
  subcategory: "APIs",
  order: 2
}
---
Les jetons de compte offrent un moyen simple d'authentifier les requêtes API sans passer par le flux OAuth complet. Ils sont idéaux pour les scripts, les pipelines CI/CD et l'automatisation personnelle.

## Création d'un jeton

1. Connectez-vous à Glossia et naviguez vers votre tableau de bord compte.
2. Ouvrez la section **API** depuis la barre latérale.
3. Cliquez sur **Jetons de compte**, puis sur **Nouveau jeton**.
4. Donnez un **nom** descriptif au jeton (par exemple, "CI deploy" ou "Accès CLI").
5. Choisissez les **portées** dont le jeton a besoin. Autorisez uniquement les permissions minimales requises.
6. Définissez une **date d'expiration** ou laissez-la vide pour un jeton qui n'expire jamais.
7. Cliquez sur **Créer un jeton**.

Après la création, la valeur complète du jeton est affichée **une seule fois**. Copiez-la immédiatement et stockez-la de manière sécurisée. Vous ne pourrez plus voir la valeur complète à nouveau.

## Utilisation d'un jeton

Incluez le jeton dans l'en-tête `Authorization` de vos requêtes HTTP :

    Authorization: Bearer glsa_abc123def456...

Par exemple, utilisez `curl` :

```bash
curl -H "Authorization: Bearer glsa_abc123def456..." \
  https://glossia.ai/api/projects
```

Les jetons de compte suivent le même [modèle d'autorisation](/docs/reference/apis/authentication) que les jetons OAuth. Les portées du jeton définissent l'ensemble maximal d'actions qu'il peut réaliser, et les politiques au niveau des ressources s'appliquent toujours en fonction des relations de votre compte.

## Format du jeton

Tous les jetons de compte commencent par le préfixe `glsa_` suivi d'une chaîne hexadécimale aléatoire. Ce préfixe facilite l'identification des jetons Glossia dans les journaux et les scanners de secrets.

## Portées

Les jetons de compte prennent en charge les mêmes portées que les jetons OAuth. Consultez la [référence des portées](/docs/reference/apis/authentication) pour la liste complète.

Lors de la création d'un jeton, sélectionnez uniquement les portées requises par votre cas d'usage. Par exemple :

- Une intégration en lecture seule nécessite `project:read` et `voice:read`.
- Une pipeline CI qui crée des projets nécessite `project:read` et `project:write`.
- Un script qui gère les membres de l'organisation nécessite `members:read` et `members:write`.

## Gestion des jetons

### Affichage des jetons

La page **Jetons de compte** liste tous les jetons actifs avec leur nom, portées, date de dernière utilisation et expiration. Les jetons jamais utilisés affichent "Jamais" dans la colonne de Dernière utilisation.

### Modification des jetons

Cliquez sur le nom du jeton pour modifier son **nom** et sa **description**. Les portées et l'expiration ne peuvent pas être modifiées après la création. Si vous avez besoin de portées différentes, créez un nouveau jeton et révoquez l'ancien.

### Révocation des jetons

Pour révoquer un jeton, cliquez sur **Révoquer** dans la liste des jetons ou ouvrez la page de modification du jeton et utilisez le bouton **Révoquer le jeton** dans la zone de danger. Les jetons révoqués cessent de fonctionner immédiatement et ne peuvent pas être restaurés.

## Bonnes pratiques de sécurité

- **Stockez les jetons de manière sécurisée.** Utilisez des variables d'environnement ou un gestionnaire de secrets. Ne committez jamais les jetons dans le contrôle de source.
- **Utilisez des jetons à durée de vie courte.** Définissez une date d'expiration à chaque fois que possible.
- **Minimisez les portées.** Accordez uniquement les permissions dont le jeton a réellement besoin.
- **Faites tourner les jetons régulièrement.** Créez de nouveaux jetons et révoquez les anciens selon un planning.
- **Surveillez l'utilisation.** Vérifiez périodiquement la date de « Dernière utilisation ». Révoquez les jetons inutilisés.
- **Utilisez un jeton par intégration.** Ainsi, révoquer un jeton ne rompt pas d'autres flux de travail.

## Gestion de l'API

Vous pouvez également gérer les jetons de compte via l'API REST et le serveur MCP.

### API REST

| Méthode | Endpoint | Description |
|--------|----------|-------------|
| `GET` | `/api/tokens` | Liste les jetons actifs |
| `POST` | `/api/tokens` | Crée un nouveau jeton |
| `DELETE` | `/api/tokens/:id` | Révoque un jeton |

### MCP

Le serveur MCP expose `list_tokens`, `create_token` et `revoke_token`, des outils qui reflètent l'API REST.