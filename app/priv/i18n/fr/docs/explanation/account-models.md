%{
  title: "Modèles de compte",
  summary:
    "Pourquoi les fournisseurs de modèles sont configurés une fois par compte et référencés par handle.",
  category: "Explication",
  order: 2
}
---
Glossia sépare les instructions de dépôt des identifiants du fournisseur-modèle. Les dépôts décrivent ce qui doit être traduit, tandis que les comptes déterminent lequel [modèle de langage large](https://en.wikipedia.org/wiki/Large_language_model) effectue le travail.

## Pourquoi les modèles appartiennent aux comptes

Une équipe traduit souvent plusieurs dépôts avec la même relation avec le fournisseur. Les modèles limités aux comptes permettent aux administrateurs de faire pivoter une clé de fournisseur ou de changer le modèle sous-jacent une fois sans modifier chaque dépôt.

Cette frontière garde également les identifiants à l'extérieur du contrôle de source. Un dépôt contient un identifiant lisible tel que `translation-default`, pas le fournisseur.

## Les poignées fournissent une intention stable.

Le `model` champ dans `L10N.md` fait référence à un identifiant de modèle de compte :

```yaml
model: translation-default
```

L'identifiant exprime l'intention du dépôt. Un administrateur peut plus tard mettre à jour quel modèle de fournisseur que cet identifiant sélectionne, tandis que la configuration du dépôt reste stable.

## Comment utiliser plusieurs modèles

Glossia utilise un modèle configuré pour chaque traduction de document. Ajouter plusieurs modèles ne crée pas un ensemble, une chaîne de repli, ni un niveau de qualité automatique. L'auteur du dépôt choisit sa finalité à l'aide d'identifiants stables tels que `translation-default`, `long-form`ou `japanese-specialist`.

La sélection suit la hiérarchie du contexte pour le document et la locale cible :

1. Le plus proche `L10N/<locale>.md` fichier qui déclare `model` gagne pour cette locale.
2. Sinon, le plus proche `L10N.md` fichier qui déclare `model` gagne pour son répertoire.
3. Parent `L10N.md` les paramètres sont hérités lorsqu'un fichier plus proche ne déclare pas de modèle.
4. Lorsqu'aucun fichier de contexte applicable ne déclare de handle, Glossia utilise la valeur par défaut du compte.

Un handle configuré explicitement doit exister. Glossia signale une erreur pour un handle inconnu plutôt que de basculer silencieusement vers la valeur par défaut du compte.

## Sélection par défaut

La configuration du projet nécessite un modèle avant qu'un dépôt ne possède le sien `L10N.md`. Glossia choisit donc la valeur par défaut du compte. Le premier modèle ajouté à un compte devient la valeur par défaut, et un administrateur peut en faire un autre le défaut depuis sa page de paramètres.

Une fois qu'un dépôt a `L10N.md`, utiliser une référence explicite rend son choix clair pour les réviseurs. Omettant `model` conserve le dépôt sur le défaut du compte.

## La limite de la revue humaine

La sortie du modèle est un travail proposé, non une fusion automatique. L'activité de configuration et de traduction reste visible dans Glossia, tandis que les modifications du dépôt sont publiées via une demande de fusion pour revue par l'équipe. Cela préserve la même limite de qualité et de propriété que les équipes utilisent déjà pour le code.