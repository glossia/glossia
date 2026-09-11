%{
  title: "Modèles de compte",
  summary:
    "Pourquoi les fournisseurs de modèles sont configurés une fois par compte et référencés par handle.",
  category: "explication",
  order: 2
}
---
Glossia sépare les instructions de dépôt des identifiants du fournisseur de modèle. Les dépôts décrivent ce qui doit être traduit, tandis que les comptes décident lequel [modèle de langage à grande échelle](https://en.wikipedia.org/wiki/Large_language_model) effectue le travail.

## Pourquoi les modèles appartiennent aux comptes

Une équipe traduit souvent plusieurs dépôts avec le même fournisseur. Les modèles à portée compte permettent aux administrateurs de changer une clé de fournisseur ou de basculer le modèle sous-jacent une seule fois sans modifier chaque dépôt.

Cette frontière maintient également les identifiants hors du contrôle de source. Un dépôt contient une poignée lisible telle que `translation-default`, pas la clé de fournisseur.

## Les poignées fournissent une intention stable

Le `model` champ « `L10N.md` renvoie à un identifiant de modèle de compte :

```yaml
model: translation-default
```

L'identifiant exprime l'intention du référentiel. Un administrateur pourra plus tard mettre à jour quel modèle de fournisseur cet identifiant sélectionne tant que la configuration du référentiel reste stable.

## Comment plusieurs modèles sont utilisés

Glossia utilise un modèle configuré pour chaque traduction de document. L'ajout de plusieurs modèles ne crée pas d'ensemble, de chaîne de secours ni de niveau de qualité automatique. L'auteur du référentiel choisit sa finalité à travers des identifiants stables tels que `translation-default`,, `long-form`ou `japanese-specialist`.

La sélection suit la hiérarchie contextuelle du document et la locale cible :

1. Le plus proche `L10N/<locale>.md` fichier qui déclare `model` est prioritaire pour cette locale.
2. Sinon, le plus proche `L10N.md` fichier qui déclare `model` est prioritaire pour son répertoire.
3. Paramètre `L10N.md` Les paramètres sont hérités lorsque le fichier le plus proche ne déclare pas de modèle.
4. Lorsqu'aucun fichier de contexte applicable ne déclare de paramètre, Glossia utilise la valeur par défaut du compte.

Un paramètre configuré explicitement doit exister. Glossia signale une erreur en cas de paramètre inconnu au lieu de passer silencieusement à la valeur par défaut du compte.

## Sélection par défaut

La configuration du projet nécessite un modèle avant qu'un dépôt n'en possède un `L10N.md`. Glossia sélectionne donc la valeur par défaut du compte. Le premier modèle ajouté à un compte devient le par défaut, et un administrateur peut en faire un autre le par défaut à partir de sa page de paramètres.

Une fois qu'un dépôt possède `L10N.md`, l'utilisation d'un identifiant explicite rend son choix clair aux réviseurs. L'omission `model` maintient le dépôt sur la valeur par défaut du compte.

## La limite de révision manuelle

La sortie du modèle est un travail proposé, pas une fusion automatique. L'activité de configuration et de traduction reste visible dans Glossia, tandis que les modifications du dépôt sont publiées via une demande de fusion pour examen par l'équipe. Ceci préserve la même limite de qualité et de propriété que les équipes utilisent déjà pour le code.