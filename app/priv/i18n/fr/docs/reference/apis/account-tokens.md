%{
  title: "Jetons de compte",
  summary: "Créer et gérer des jetons de compte pour l'authentification avec l'API Glossia.",
  category: "Référence",
  subcategory: "APIs",
  order: 2
}
---
Les tokens de compte offrent un moyen simple d'authentifier les requêtes API sans passer par le flux OAuth complet. Ils sont idéaux pour les scripts, les pipelines CI/CD et l'automatisation personnelle.

## Créer un jeton

1. Connectez-vous à Glossia et naviguez vers le tableau de bord de votre compte.
2. Ouvrez la **API** section dans la barre latérale.
3. Cliquez sur **Tokens de compte**, puis **Nouveau jeton**.
4. Donnez au jeton un descriptif **nom** (par exemple, \\"CI deploy\\" ou \\"CLI access\\").
5. Choisissez les **domaines** dont le jeton a besoin. Accordez uniquement les autorisations minimales requises.
6. Définir une **date d'expiration** ou laissez-la vide pour un jeton qui n'expire jamais.
7. Cliquez **Créer un jeton**.

Après la création, la valeur complète du jeton est affichée **une fois**. Copiez-le immédiatement et stockez-le en toute sécurité. Vous ne pourrez plus voir la valeur complète à nouveau.

## En utilisant un jeton

Incluez le jeton dans le `Authorization` en-tête de vos requêtes HTTP:

    Authorization: Bearer glsa_abc123def456...

Par exemple, en utilisant `curl`:

```bash
curl -H "Authorization: Bearer glsa_abc123def456..." \
  https://glossia.ai/api/projects
```

Les jetons de compte suivent le même [modèle d'autorisation](/docs/reference/apis/authentication) comme des jetons OAuth. Les étendues d'autorisation du jeton définissent l'ensemble maximal des actions qu'il peut effectuer, et les politiques au niveau des ressources s'appliquent toujours en fonction des relations de votre compte.

## Format du jeton

Tous les jetons de compte commencent par le `glsa_` préfixe suivi d'une chaîne hexadécimale aléatoire. Ce préfixe facilite l'identification des jetons Glossia dans les journaux et les scanneurs de secrets.

## Étendues d'autorisation

Les jetons de compte prennent en charge les mêmes étendues d'autorisation que les jetons OAuth. Voir le [référence des étendues d'autorisation](/docs/reference/apis/authentication) pour la liste complète.

Lors de la création d'un jeton, sélectionnez uniquement les scopes requis pour votre cas d'usage. Par exemple :

- Une intégration en lecture seule nécessite `project:read` et `voice:read`.
- Un pipeline CI qui crée des projets nécessite `project:read` et `project:write`.
- Un script gérant les membres de l'organisation a besoin de `members:read` et `members:write`.

## Gestion des jetons

### Affichage des jetons

La **Jetons de compte** page liste tous les jetons actifs avec leur nom, leurs étendues, la date de dernière utilisation et leur expiration. Les jetons qui n'ont jamais été utilisés affichent "Jamais" dans la colonne de dernière utilisation.

### Édition des jetons

Cliquez sur le nom du jeton pour modifier son **nom** et **description**. Les scopes et l'expiration ne peuvent pas être modifiés après la création. Si vous avez besoin de scopes différents, créez un nouveau jeton et révoquez l'ancien.

### Révocation des jetons

Pour révoquer un jeton, cliquez **Révoquer** sur la liste des jetons ou ouvrez la page de modification du jeton et utilisez le **Révoquer le jeton** bouton dans la zone de danger. Les jetons révoqués cessent de fonctionner immédiatement et ne peuvent pas être restaurés.

## Meilleures pratiques de sécurité

- **Stockez les jetons en toute sécurité.** Utilisez des variables d'environnement ou un gestionnaire de secrets. Ne commitez jamais les jetons dans le contrôle de source.
- **Utilisez des jetons à courte durée de vie.** Définissez une date d'expiration lorsque possible.
- **Limitez les scopes.** Accordez uniquement les permissions dont le jeton a réellement besoin.
- **Renouvelez régulièrement.** Créez de nouveaux jetons et révoquez les anciens selon un calendrier.
- **Surveillez l'utilisation.** Vérifiez la date « dernière utilisation » périodiquement. Révoquez les jetons qui ne sont plus utilisés.
- **Utilisez un jeton par intégration.** Ainsi, révoquer un jeton n'affecte pas d'autres flux de travail.

## Gestion des API

Vous pouvez également gérer les jetons de compte via l'API REST et le serveur MCP.

### API REST

| Méthode | Endpoint | Description |
|--------|----------|-------------|
| `GET` | `/api/tokens` | Lister les jetons actifs |
| `POST` | `/api/tokens` | Créer un nouveau jeton |
| `DELETE` | `/api/tokens/:id` | Révoquer un jeton |

### MCP

Le serveur MCP expose `list_tokens`, `create_token`, et `revoke_token` outils qui reflètent la REST API.