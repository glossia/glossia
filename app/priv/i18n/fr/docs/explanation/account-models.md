%{
  title: "Modèles de compte",
  summary:
    "Pourquoi les fournisseurs de modèles sont configurés une fois par compte et référencés par handle.",
  category: "explication",
  order: 2
}
---
Glossia sépare les instructions de dépôt des identifiants du fournisseur de modèle. Les dépôts décrivent ce qui doit être traduit, tandis que les comptes décident lequel [modèle de langage naturel](https://en.wikipedia.org/wiki/Large_language_model) réalise le travail.

## Pourquoi les modèles appartiennent aux comptes

Une équipe traduit souvent plusieurs dépôts avec la même relation de fournisseur. Les modèles à portée de compte permettent aux administrateurs de faire pivoter une clé de fournisseur ou de changer le modèle sous-jacent une fois sans modifier chaque dépôt.

Cette frontière éloigne également les identifiants du contrôle de version. Un dépôt contient un identifiant lisible tel que `translation-default`, pas la clé du fournisseur.

## Les identifiants fournissent une intention stable.

Le `model` champ dans `L10N.md` se réfère à un identifiant de modèle de compte :

```yaml
model: translation-default
```

L'identifiant exprime l'intention du référentiel. Un administrateur peut ensuite mettre à jour quel modèle de fournisseur celui-ci sélectionne, tant que la configuration du référentiel reste stable.

## Comment plusieurs modèles sont utilisés

Glossia utilise un modèle configuré pour chaque traduction de document. Ajouter plusieurs modèles ne crée pas un ensemble, une chaîne de repli, ni un niveau de qualité automatique. L'auteur du référentiel choisit son objectif grâce à des handles stables tels que `translation-default`, `long-form`, `japanese-specialist`.

La sélection suit la hiérarchie de contexte pour le document et la locale cible :

1. Le plus proche `L10N/<locale>.md` fichier qui déclare `model` l'emporte pour cette locale.
2. Sinon, le plus proche `L10N.md` fichier qui déclare `model` l'emporte pour son répertoire.
3. Parent `L10N.md` Les paramètres sont hérités lorsqu'un fichier plus proche ne déclare pas de modèle.
4. Lorsqu'aucun fichier de contexte applicable ne déclare un handle, Glossia utilise la valeur par défaut du compte.

Un handle configuré explicitement doit exister. Glossia signale une erreur pour un handle inconnu plutôt que de basculer silencieusement vers la valeur par défaut du compte.

## Choix par défaut

La configuration du projet nécessite un modèle avant que le dépôt n'ait le sien. `L10N.md`. Glossia sélectionne donc la valeur par défaut du compte. Le premier modèle ajouté à un compte devient le défaut, et un administrateur peut en faire un autre le défaut depuis sa page de paramètres.

Une fois qu'un dépôt a `L10N.md`, l'utilisation d'un identifiant explicite rend son choix clair pour les réviseurs. Omission `model` , conserve le dépôt par défaut du compte.

## La frontière de la revue humaine

La sortie du modèle est du travail proposé, pas une fusion automatique. L'activité de configuration et de traduction reste visible dans Glossia, tandis que les modifications du dépôt sont publiées via une pull request pour examen par l'équipe. Cela préserve la même frontière de qualité et de propriété que les équipes utilisent déjà pour le code.