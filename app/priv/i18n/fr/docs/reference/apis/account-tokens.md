%{
  title: "Jetons de compte",
  summary: "Créez et gérez les jetons de compte pour vous authentifier auprès de l’API Glossia.",
  category: "reference",
  subcategory: "apis",
  order: 2
}
---
Les jetons de compte offrent un moyen simple d’authentifier les requêtes API sans passer par l’intégralité du flux OAuth. Ils sont adaptés aux scripts, aux pipelines CI/CD et aux automatisations personnelles.

## Création d’un jeton

1. Connectez-vous à Glossia et accédez au tableau de bord de votre compte.
2. Ouvrez la section **API** depuis la barre latérale.
3. Cliquez sur **Jetons de compte**, puis sur **Nouveau jeton**.
4. Attribuez au jeton un **nom** descriptif, par exemple « Déploiement CI » ou « Accès CLI ».
5. Choisissez les **portées** dont le jeton a besoin. Accordez uniquement les autorisations minimales requises.
6. Définissez une **date d’expiration** ou laissez ce champ vide pour créer un jeton qui n’expire jamais.
7. Cliquez sur **Créer le jeton**.

Après sa création, la valeur complète du jeton n’est affichée qu’**une seule fois**. Copiez-la immédiatement et conservez-la en lieu sûr. Vous ne pourrez plus consulter sa valeur complète par la suite.

## Utilisation d’un jeton

Incluez le jeton dans l’en-tête `Authorization` de vos requêtes HTTP :

```
Authorization: Bearer glsa_abc123def456...
```

Par exemple, avec `curl` :

```bash
curl -H "Authorization: Bearer glsa_abc123def456..." \
  https://glossia.ai/api/projects
```

Les jetons de compte suivent le même [modèle d’autorisation](/docs/reference/apis/authentication) que les jetons OAuth. Les portées du jeton définissent l’ensemble maximal d’actions qu’il peut effectuer. Les politiques propres aux ressources continuent de s’appliquer en fonction des relations de votre compte.

## Format des jetons

Tous les jetons de compte commencent par le préfixe `glsa_`, suivi d’une chaîne hexadécimale aléatoire. Ce préfixe permet d’identifier facilement les jetons Glossia dans les journaux et les outils d’analyse des secrets.

## Portées

Les jetons de compte prennent en charge les mêmes portées que les jetons OAuth. Consultez la [référence des portées](/docs/reference/apis/authentication) pour obtenir la liste complète.

Lors de la création d’un jeton, sélectionnez uniquement les portées nécessaires à votre cas d’usage. Par exemple :

- Une intégration en lecture seule nécessite `project:read` et `voice:read`.
- Un pipeline CI qui crée des projets nécessite `project:read` et `project:write`.
- Un script qui gère les membres d’une organisation nécessite `members:read` et `members:write`.

## Gestion des jetons

### Consultation des jetons

La page **Jetons de compte** répertorie tous les jetons actifs avec leur nom, leurs portées, leur date de dernière utilisation et leur date d’expiration. Pour les jetons qui n’ont jamais été utilisés, la colonne de dernière utilisation affiche « Jamais ».

### Modification des jetons

Cliquez sur le nom d’un jeton pour modifier son **nom** et sa **description**. Les portées et la date d’expiration ne peuvent plus être modifiées après la création. Si vous avez besoin de portées différentes, créez un nouveau jeton et révoquez l’ancien.

### Révocation des jetons

Pour révoquer un jeton, cliquez sur **Révoquer** dans la liste des jetons, ou ouvrez la page de modification du jeton et utilisez le bouton **Révoquer le jeton** dans la zone de danger. Les jetons révoqués cessent immédiatement de fonctionner et ne peuvent pas être restaurés.

## Bonnes pratiques de sécurité

- **Conservez les jetons en lieu sûr.** Utilisez des variables d’environnement ou un gestionnaire de secrets. Ne validez jamais de jetons dans le système de gestion du code source.
- **Utilisez des jetons à durée de vie courte.** Définissez une date d’expiration chaque fois que possible.
- **Réduisez les portées au minimum.** Accordez uniquement les autorisations dont le jeton a réellement besoin.
- **Renouvelez régulièrement les jetons.** Créez de nouveaux jetons et révoquez les anciens selon un calendrier défini.
- **Surveillez l’utilisation.** Vérifiez régulièrement la date de « dernière utilisation ». Révoquez les jetons qui ne sont plus utilisés.
- **Utilisez un jeton par intégration.** Ainsi, la révocation d’un jeton n’interrompt pas les autres processus.

## Gestion par API

Vous pouvez également gérer les jetons de compte par l’intermédiaire de l’API REST et du serveur MCP.

### API REST

| Méthode | Point de terminaison | Description |
|--------|----------|-------------|
| `GET` | `/api/tokens` | Répertorier les jetons actifs |
| `POST` | `/api/tokens` | Créer un nouveau jeton |
| `DELETE` | `/api/tokens/:id` | Révoquer un jeton |

### MCP

Le serveur MCP expose les outils `list_tokens`, `create_token` et `revoke_token`, qui reproduisent l’API REST.