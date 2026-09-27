%{
  title: "Modèles de compte",
  summary:
    "Pourquoi les fournisseurs de modèles sont configurés une fois par compte et référencés par handle.",
  category: "Explication",
  section: "Plateforme",
  order: 2
}
---
Glossia sépare les instructions de dépôt des informations d'identification du modèle-fournisseur. Les dépôts décrivent ce qui doit être traduit, tandis que les comptes décident duquel [modèle de langage à grande échelle](https://en.wikipedia.org/wiki/Large_language_model) réalise le travail.

## Pourquoi les modèles appartiennent aux comptes

Une équipe traduit souvent plusieurs dépôts avec le même fournisseur. Les modèles limités au compte permettent aux administrateurs de pivoter une clé de fournisseur ou de modifier le modèle sous-jacent une fois sans modifier chaque dépôt.

, `translation-default`pas la clé de fournisseur.

## Les identifiants fournissent une intention stable

Le `model` champ dans `L10N.md` fait référence à un identifiant de modèle de compte :

```yaml
model: translation-default
```

L'identifiant exprime l'intention du référentiel. Un administrateur peut par la suite modifier quel modèle de fournisseur cet identifiant sélectionne tant que la configuration du référentiel reste stable.

## Comment plusieurs modèles sont utilisés

Glossia utilise un modèle configuré pour chaque traduction de document. Ajouter plusieurs modèles ne crée ni un ensemble, ni une chaîne de repli, ni un niveau de qualité automatique. L'auteur du dépôt choisit son objectif via des handles stables tels que `translation-default`, `long-form`, ou `japanese-specialist`.

La sélection suit la hiérarchie des contextes pour le document et la locale cible :

1. Le plus proche `L10N/<locale>.md` fichier qui déclare `model` l'emporte pour cette locale.
2. Sinon, le plus proche `L10N.md` fichier qui déclare `model` l'emporte pour son répertoire.
3. Parent `L10N.md` Les paramètres sont hérités lorsqu'un fichier plus proche ne déclare pas de modèle.
4. Lorsqu'aucun fichier de contexte applicable ne déclare un identifiant, Glossia utilise la valeur par défaut du compte.

Un identifiant explicitement configuré doit exister. Glossia signale une erreur pour un identifiant inconnu plutôt que de basculer silencieusement vers la valeur par défaut du compte.

## Sélection par défaut

La configuration de projet nécessite un modèle avant qu'un dépôt n'ait le sien `L10N.md`. Glossia sélectionne donc la valeur par défaut du compte. Le premier modèle ajouté à un compte devient la valeur par défaut, et un administrateur peut en faire un autre le par défaut depuis sa page de paramètres.

Une fois qu'un dépôt a `L10N.md`, utiliser un identifiant explicite rend le choix clair pour les réviseurs. L'omission `model` maintient le référentiel sur la configuration par défaut du compte.

## La limite de la relecture humaine

La sortie du modèle est un travail proposé, non une fusion automatique. L'activité de configuration et de traduction reste visible dans Glossia, tandis que les modifications du référentiel sont publiées via une pull request pour examen par l'équipe. Cela préserve la même frontière de qualité et de propriété que les équipes utilisent déjà pour le code.