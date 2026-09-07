%{
  title: "Modèles de compte",
  summary:
    "Pourquoi les fournisseurs de modèles sont configurés une fois par compte et référencés par handle.",
  category: "Explication",
  order: 2
}
---
Glossia sépare les instructions du dépôt des identifiants du fournisseur de modèle. Les dépôts décrivent ce qui doit être traduit, tandis que les comptes décident quel [modèle de langage](https://en.wikipedia.org/wiki/Large_language_model) effectue le travail.

## Pourquoi les modèles appartiennent aux comptes

Une équipe traduit souvent plusieurs dépôts avec la même relation fournisseur. Les modèles limités au compte permettent aux administrateurs de changer une clé de fournisseur ou de basculer sur le modèle sous-jacent une fois sans modifier chaque dépôt.

Cette limite maintient également les identifiants hors du contrôle de version. Un dépôt contient un identifiant lisible tel que `translation-default`, pas la clé du fournisseur.

## Les identifiants offrent une intention stable

Le champ `model` dans `GLOSSIA.md` fait référence à un identifiant de modèle de compte :

```yaml
model: translation-default
```

L'identifiant exprime l'intention du dépôt. Un administrateur peut par la suite mettre à jour le modèle du fournisseur sélectionné par cet identifiant, tant que la configuration du dépôt demeure stable.

## Comment plusieurs modèles sont utilisés

Glossia utilise un modèle configuré pour chaque traduction de document. L'ajout de plusieurs modèles ne crée pas un ensemble, une chaîne de repli ou un niveau de qualité automatique. L'auteur du dépôt choisit son objectif à travers des identifiants stables tels que `translation-default`, `long-form` ou `japanese-specialist`.

La sélection suit la hiérarchie de contexte pour le document et la locale cible :

1. Le fichier `GLOSSIA/<locale>.md` le plus proche qui déclare `model` prévaut pour cette locale.
2. Sinon, le fichier `GLOSSIA.md` le plus proche qui déclare `model` prévaut pour son répertoire.
3. Les paramètres du fichier `GLOSSIA.md` parent sont hérités lorsqu'un fichier plus proche ne déclare pas de modèle.
4. Lorsqu'aucun fichier de contexte applicable ne déclare un identifiant, Glossia utilise la valeur par défaut du compte.

Un identifiant configuré explicitement doit exister. Glossia signale une erreur pour un identifiant inconnu plutôt que de basculer silencieusement vers la valeur par défaut du compte.

## Sélection par défaut

La configuration du projet nécessite un modèle avant qu'un dépôt n'ait son propre `GLOSSIA.md`. Glossia sélectionne donc la valeur par défaut du compte. Le premier modèle ajouté à un compte devient la valeur par défaut, et un administrateur peut en faire un autre depuis sa page de paramètres.

Une fois qu'un dépôt possède `GLOSSIA.md`, l'utilisation d'un identifiant explicite rend son choix clair aux réviseurs. Omettre `model` maintient le dépôt sur la valeur par défaut du compte.

## La frontière de la révision humaine

La sortie du modèle est un travail proposé, pas une fusion automatique. L'activité de configuration et de traduction reste visible dans Glossia, tandis que les modifications du dépôt sont publiées via une pull request pour l'examen par l'équipe. Cela conserve la même frontière de qualité et de propriété déjà utilisée par les équipes pour le code.