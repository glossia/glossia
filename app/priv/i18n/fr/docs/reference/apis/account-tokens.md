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

1. Connectez-vous à Glossia et accédez à votre tableau de bord de compte.
2. Ouvrez le **API** section de la barre latérale.
3. Cliquez **Jetons de compte**, puis **Nouveau jeton**.
4. Donnez à votre jeton un **nom** (par exemple, "Déploiement CI" ou "Accès CLI").
5. Choisissez les **portées** que le jeton nécessite. N'accordez que les autorisations minimales requises.
6. Définissez une **date d'expiration** ou laissez-le vide pour un jeton qui n'expire jamais.
7. Cliquez **Créer un jeton**.

Après la création, la valeur complète du jeton est affichée. **une fois**. Copiez-la immédiatement et stockez-la en toute sécurité. Vous ne pourrez plus voir la valeur complète à nouveau.

## Utilisation d'un jeton

Incluez le jeton dans le `Authorization` en-tête de vos requêtes HTTP :

    Authorization: Bearer glsa_abc123def456...

Par exemple, en utilisant `curl`:

```bash
curl -H "Authorization: Bearer glsa_abc123def456..." \
  https://glossia.ai/api/projects
```

Les jetons de compte suivent le même [modèle d'autorisation](/docs/reference/apis/authentication) en tant que jetons OAuth. Les étendues du jeton définissent l'ensemble maximal d'actions qu'il peut effectuer, et les politiques de niveau ressource s'appliquent toujours en fonction des relations de votre compte.

## Format de jeton

Tous les jetons de compte commencent par le `glsa_` préfixe suivi d'une chaîne hexadécimale aléatoire. Ce préfixe facilite l'identification des jetons Glossia dans les journaux et les scanners de secrets.

## Étendues

Les jetons de compte supportent les mêmes étendues que les jetons OAuth. Consultez le [référence des étendues](/docs/reference/apis/authentication) pour la liste complète.

Lors de la création d'un jeton, sélectionnez uniquement les portées nécessaires à votre cas d'utilisation. Par exemple :

- Une intégration en lecture seule nécessite `project:read` et `voice:read`.
- Un pipeline CI créant des projets nécessite `project:read` et `project:write`.
- Un script qui gère les membres de l'organisation a besoin de `members:read` et `members:write`.

## Gestion des jetons

### Affichage des jetons

La **Jetons du compte** page liste tous les jetons actifs avec leur nom, leurs portées, la date de dernière utilisation et leur expiration. Les jetons qui n'ont jamais été utilisés affichent "Jamais" dans la colonne de dernière utilisation.

### Édition des jetons

Cliquez sur le nom d'un jeton pour modifier son **nom** et **description**. Les portées et l'expiration ne peuvent être modifiées après la création. Si vous avez besoin de portées différentes, créez un nouveau jeton et révoquez l'ancien.

### Révocation des jetons

Pour révoquer un jeton, cliquez sur **Révoquer** sur la liste des jetons ou ouvrez la page de modification du jeton et utilisez le **Révoquer le jeton** bouton de la zone de danger. Les jetons révoqués cessent de fonctionner immédiatement et ne peuvent pas être restaurés.

## Meilleures pratiques de sécurité

- **Stockez les jetons en toute sécurité.** Utilisez des variables d'environnement ou un gestionnaire de secrets. Ne commitez jamais de jetons dans le contrôle de version.
- **Utilisez des jetons à courte durée de vie.** Définissez une date d'expiration dans la mesure du possible.
- **Minimisez les portées.** Accordez uniquement les autorisations dont le jeton a réellement besoin.
- **Renouvelez les jetons régulièrement.** Créez de nouveaux jetons et révoquez les anciens selon un calendrier.
- **Surveillez l'utilisation.** Vérifiez périodiquement la date « dernière utilisation ». Révoquez les jetons qui ne sont plus utilisés.
- **Utilisez un jeton par intégration.** Ainsi, la révocation d'un seul jeton ne rompt pas d'autres flux de travail.

## Gestion de l'API

Vous pouvez également gérer les jetons de compte via l'API REST et le serveur MCP.

### API REST

| Méthode | Endpoint | Description |
|--------|----------|-------------|
| `GET` | `/api/tokens` | Lister les jetons actifs |
| `POST` | `/api/tokens` | Créer un nouveau jeton |
| `DELETE` | `/api/tokens/:id` | Révoquer un jeton |

### MCP

Le serveur MCP expose `list_tokens`, `create_token`, et `revoke_token` outils qui reflètent l'API REST.