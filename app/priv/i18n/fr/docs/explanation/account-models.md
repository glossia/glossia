%{
  title: "Modèles de compte",
  summary:
    "Pourquoi les fournisseurs de modèles sont configurés une fois par compte et référencés par handle.",
  category: "explication",
  order: 2
}
---
Glossia sépare les instructions de dépôt des clés de fournisseur de modèle. Les dépôts décrivent ce qui doit être traduit, tandis que les comptes décident lequel [grand modèle de langage](https://en.wikipedia.org/wiki/Large_language_model) effectue le travail.

## Pourquoi les modèles appartiennent aux comptes

Une équipe traduit souvent plusieurs dépôts avec la même relation de fournisseur. Les modèles limités au compte permettent aux administrateurs de changer une clé de fournisseur ou de commuter le modèle sous-jacent une seule fois sans modifier chaque dépôt.

Cette frontière garde également les clés hors du contrôle de version. Un dépôt contient un nom lisible tel que `translation-default`, pas la clé du fournisseur.

## Les poignées fournissent une intention stable

Le `model` champ dans `L10N.md` se réfère à un identifiant de modèle de compte:

```yaml
model: translation-default
```

L'identifiant exprime l'intention du dépôt. Un administrateur peut plus tard mettre à jour le modèle de fournisseur sélectionné par cet identifiant, tout en gardant la configuration du dépôt stable.

## Comment plusieurs modèles sont utilisés

Glossia utilise un modèle configuré pour chaque traduction de document. Ajouter plusieurs modèles ne crée ni un ensemble, ni une chaîne de repli, ni un niveau de qualité automatique. L'auteur du dépôt choisit son objectif à travers des identifiants stables tels que `translation-default`, `long-form`, ou `japanese-specialist`.

La sélection suit la hiérarchie de contexte pour le document et la locale cible:

1. Le plus proche `L10N/<locale>.md` fichier qui déclare `model` l'emporte pour cette locale.
2. Sinon, le plus proche `L10N.md` fichier qui déclare `model` l'emporte pour son répertoire.
3. Parent `L10N.md` les paramètres sont hérités lorsqu'un fichier plus proche ne déclare pas un modèle.
4. Lorsqu'aucun fichier de contexte applicable ne déclare pas de handle, Glossia utilise la valeur par défaut du compte.

Un handle configuré explicitement doit exister. Glossia signale une erreur pour un handle inconnu plutôt que de basculer silencieusement vers la valeur par défaut du compte.

## Sélection par défaut

La configuration du projet nécessite un modèle avant qu'un dépôt n'ait le sien `L10N.md`. Glossia sélectionne donc la valeur par défaut du compte. Le premier modèle ajouté à un compte devient le modèle par défaut, et un administrateur peut en faire un autre le modèle par défaut depuis sa page de paramètres.

Une fois qu'un dépôt a `L10N.md`L'utilisation d'un identifiant explicite rend son choix clair pour les relecteurs. L'omission `model` conserve le dépôt sur la valeur par défaut du compte.

## La limite de révision humaine

La sortie du modèle est un travail proposé, pas une fusion automatique. L'activité de configuration et de traduction reste visible dans Glossia, tandis que les modifications du dépôt sont publiées via une demande de fusion pour examen par l'équipe. Cela préserve la même limite de qualité et de propriété que les équipes utilisent déjà pour le code.