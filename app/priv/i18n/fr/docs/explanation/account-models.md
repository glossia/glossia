%{
  title: "Modèles de compte",
  summary:
    "Pourquoi les fournisseurs de modèles sont configurés une fois par compte et référencés par handle.",
  category: "explication",
  order: 2
}
---
Glossia sépare les instructions des dépôts des identifiants de fournisseur de modèle. Les dépôts décrivent ce qui doit être traduit, tandis que les comptes décident lequel [modèle de langage à grande échelle](https://en.wikipedia.org/wiki/Large_language_model) effectue le travail.

## Pourquoi les modèles appartiennent aux comptes

Une équipe traduit souvent plusieurs dépôts avec la même relation de fournisseur. Les modèles limités au compte permettent aux administrateurs de faire tourner une clé de fournisseur ou de changer le modèle sous-jacent une fois, sans modifier chaque dépôt.

Cette frontière garde également les identifiants hors du contrôle de version. Un dépôt contient un identifiant lisible tel que `translation-default`, pas la clé du fournisseur.

## Les identifiants assurent une intention stable.

Le `model` champ de `L10N.md` fait référence au handle du modèle de compte :

```yaml
model: translation-default
```

Le handle exprime l'intention du dépôt. Un administrateur peut tout à l'heure mettre à jour quel modèle de fournisseur ce handle sélectionne lorsque la configuration du dépôt reste stable.

## Comment plusieurs modèles sont utilisés

Glossia utilise un modèle configuré pour chaque traduction de document. L'ajout de plusieurs modèles ne crée ni un ensemble, ni une chaîne de fallback, ni un niveau de qualité automatique. L'auteur du dépôt choisit son objectif par l'intermédiaire de handles stables tels que `translation-default`, `long-form`, ou `japanese-specialist`.

La sélection suit la hiérarchie de contexte du document et de la cible locale :

1. Le plus proche `L10N/<locale>.md` fichier qui déclare `model` l'emporte pour cette locale.
2. Sinon, le plus proche `L10N.md` fichier qui déclare `model` l'emporte pour son répertoire.
3. Parent `L10N.md` les paramètres sont hérités lorsqu'un fichier plus proche ne déclare pas de modèle.
4. Lorsqu'aucun fichier de contexte applicable ne déclare un handle, Glossia utilise la valeur par défaut du compte.

Un handle configuré explicitement doit exister. Glossia signale une erreur pour un handle inconnu au lieu de basculer silencieusement vers la valeur par défaut du compte.

## Sélection par défaut

La configuration du projet nécessite un modèle avant qu'un dépôt n'en ait le sien. `L10N.md`. Glossia sélectionne donc la valeur par défaut du compte. Le premier modèle ajouté à un compte devient la valeur par défaut, et un administrateur peut en faire un autre le défaut depuis sa page de paramètres.

Une fois qu'un dépôt a `L10N.md`, l'utilisation d'un identifiant explicite rend son choix clair pour les réviseurs. L'omission `model` maintient le dépôt sur la valeur par défaut du compte.

## La limite de révision humaine

La sortie du modèle est un travail proposé, pas une fusion automatique. L'activité de configuration et de traduction reste visible dans Glossia, tandis que les modifications du dépôt sont publiées via une pull request pour examen par l'équipe. Cela préserve la même limite de qualité et de propriété que les équipes utilisent déjà pour le code.