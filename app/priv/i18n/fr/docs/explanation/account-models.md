%{
  title: "Modèles de compte",
  summary:
    "Pourquoi les fournisseurs de modèles sont configurés une fois par compte et référencés par handle.",
  category: "explication",
  order: 2
}
---
Glossia sépare les instructions du dépôt des identifiants du fournisseur de modèle. Les dépôts décrivent ce qui doit être traduit, tandis que les comptes décident lequel [modèle de langage](https://en.wikipedia.org/wiki/Large_language_model) effectue le travail.

## Pourquoi les modèles appartiennent aux comptes

Une équipe traduit souvent plusieurs dépôts avec la même relation fournisseur. Les modèles liés au compte permettent aux administrateurs de faire tourner une clé de fournisseur ou de basculer sur le modèle sous-jacent une fois sans modifier chaque dépôt.

Cette limite maintient également les identifiants hors du contrôle de versions. Un dépôt contient un identifiant lisible tel que `translation-default`, pas la clé du fournisseur.

## Les identifiants fournissent une intention stable.

Le `model` champ dans `L10N.md` se réfère à un identifiant de modèle de compte :

```yaml
model: translation-default
```

Le handle exprime l'intention du référentiel. Un administrateur peut plus tard mettre à jour quel modèle de fournisseur ce handle sélectionne, tandis que la configuration du référentiel reste stable.

## Comment plusieurs modèles sont utilisés

Glossia utilise un modèle configuré pour chaque document traduit. Ajouter plusieurs modèles ne crée pas un ensemble, une chaîne de repli, ni un niveau de qualité automatique. L'auteur du référentiel choisit son objectif par des handles stables tels que `translation-default`, `long-form`, ou `japanese-specialist`.

La sélection suit la hiérarchie de contexte du document et la locale cible :

1. Le plus proche `L10N/<locale>.md` fichier qui déclare `model` l'emporte pour cette locale.
2. Sinon, le plus proche `L10N.md` fichier qui déclare `model` l'emporte pour son répertoire.
3. Parent `L10N.md` Les paramètres sont hérités lorsqu'un fichier plus proche ne déclare pas de modèle.
4. Lorsqu'aucun fichier de contexte applicable ne déclare de handle, Glossia utilise le défaut du compte.

Un handle configuré explicitement doit exister. Glossia signale une erreur pour un handle inconnu plutôt que de basculer silencieusement vers le défaut du compte.

## Sélection par défaut

La configuration du projet nécessite un modèle avant qu'un dépôt n'en possède un `L10N.md`. Glossia sélectionne donc le défaut du compte. Le premier modèle ajouté à un compte devient le défaut, et un administrateur peut en faire un autre modèle le défaut depuis sa page de paramètres.

Une fois qu'un dépôt a `L10N.md`L'utilisation d'un gestionnaire explicite rend son choix clair pour les examinateurs. L'omission, `model` maintient le dépôt au réglage par défaut du compte.

## La frontière d'examen humain

La sortie du modèle est un travail proposé, pas une fusion automatique. L'activité de configuration et de traduction reste visible dans Glossia, tandis que les modifications du dépôt sont publiées via une pull request pour examen par l'équipe. Cela préserve la même frontière de qualité et d'appartenance que les équipes utilisent déjà pour le code.