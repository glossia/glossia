%{
  title: "Modèles de compte",
  summary:
    "Pourquoi les fournisseurs de modèles sont configurés une fois par compte et référencés par handle.",
  category: "explication",
  order: 2
}
---
Glossia sépare les instructions de dépôt des identifiants du fournisseur de modèle. Les dépôts décrivent ce qui doit être traduit, tandis que les comptes décident quel [modèle de langage](https://en.wikipedia.org/wiki/Large_language_model) exécute le travail.

## Pourquoi les modèles appartiennent aux comptes

Une équipe traduit souvent plusieurs dépôts avec la même relation de fournisseur. Les modèles à portée de compte permettent aux administrateurs de changer une clé de fournisseur ou de basculer le modèle sous-jacent une fois sans modifier chaque dépôt.

Cette frontière garde également les identifiants hors du contrôle de source. Un dépôt contient un identifiant lisible tel que `translation-default`, pas la clé du fournisseur.

## Les identifiants fournissent une intention stable.

Le `model` champ dans `L10N.md` fait référence à un identifiant de modèle de compte :

```yaml
model: translation-default
```

L'identifiant exprime l'intention du dépôt. Un administrateur peut ultérieurement mettre à jour le modèle de fournisseur sélectionné par cet identifiant, tandis que la configuration du dépôt reste stable.

## Comment plusieurs modèles sont utilisés

Glossia utilise un modèle configuré pour chaque traduction de document. Ajouter plusieurs modèles ne crée pas d'ensemble, une chaîne de repli ou un niveau de qualité automatique. L'auteur du dépôt choisit son objectif à travers des identifiants stables tels que `translation-default`, `long-form`, ou `japanese-specialist`.

La sélection suit la hiérarchie de contexte du document et de la locale cible :

1. Le plus proche `L10N/<locale>.md` fichier qui déclare `model` prévaut pour cette locale.
2. Sinon, le plus proche `L10N.md` fichier qui déclare `model` prévaut pour son répertoire.
3. Parent `L10N.md` Les paramètres sont hérités lorsqu'un fichier plus proche ne déclare pas de modèle.
4. Lorsqu'aucun fichier de contexte applicable ne déclare un handle, Glossia utilise le par défaut du compte.

Un handle configuré explicitement doit exister. Glossia signale une erreur pour un handle inconnu au lieu de basculer silencieusement vers le par défaut du compte.

## Sélection par défaut

La configuration du projet nécessite un modèle avant qu'un dépôt n'en ait un sien `L10N.md`. Glossia sélectionne donc le par défaut du compte. Le premier modèle ajouté à un compte devient le par défaut, et un administrateur peut en faire un autre par défaut depuis sa page de paramètres.

Dès qu'un dépôt possède `L10N.md`", en utilisant une gestion explicite, le choix est clair pour les relecteurs. L'omission `model` conserve le dépôt sur le compte par défaut."

## La limite de la relecture humaine

La sortie du modèle est du travail proposé, pas une fusion automatique. La mise en place et l'activité de traduction restent visibles dans Glossia, tandis que les modifications du dépôt sont publiées via une Pull Request pour que l'équipe puisse les examiner. Ceci préserve la même limite de qualité et de propriété que les équipes utilisent déjà pour le code.