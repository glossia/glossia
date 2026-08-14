%{
  title: "Modèles de compte",
  summary: "Pourquoi les fournisseurs de modèles sont configurés une seule fois par compte et référencés par leur identifiant.",
  category: "explanation",
  order: 2
}
---
Glossia sépare les instructions du dépôt des identifiants d’accès au fournisseur de modèles. Les dépôts décrivent ce qui doit être traduit, tandis que les comptes déterminent quel [grand modèle de langage](https://en.wikipedia.org/wiki/Large_language_model) effectue le travail.

## Pourquoi les modèles relèvent des comptes

Une équipe traduit souvent plusieurs dépôts avec le même fournisseur. Les modèles définis au niveau du compte permettent aux administrateurs de renouveler la clé d’un fournisseur ou de changer le modèle sous-jacent une seule fois, sans modifier chaque dépôt.

Cette séparation permet également de ne pas stocker les identifiants d’accès dans le gestionnaire de versions. Un dépôt contient un identifiant lisible tel que `translation-default`, et non la clé du fournisseur.

## Les identifiants garantissent une intention stable

Le champ `model` dans `GLOSSIA.md` fait référence à l’identifiant d’un modèle du compte :

```yaml
model: translation-default
```

Cet identifiant exprime l’intention du dépôt. Un administrateur peut ensuite modifier le modèle du fournisseur sélectionné par cet identifiant, tandis que la configuration du dépôt reste stable.

## Utilisation de plusieurs modèles

Glossia utilise un seul modèle configuré pour chaque traduction de document. L’ajout de plusieurs modèles ne crée ni ensemble de modèles, ni chaîne de repli, ni niveau de qualité automatique. L’auteur du dépôt définit leur fonction au moyen d’identifiants stables tels que `translation-default`, `long-form` ou `japanese-specialist`.

La sélection suit la hiérarchie de contexte du document et de la locale cible :

1. Le fichier `GLOSSIA/<locale>.md` le plus proche qui déclare `model` prévaut pour cette locale.
2. Sinon, le fichier `GLOSSIA.md` le plus proche qui déclare `model` prévaut pour son répertoire.
3. Les paramètres `GLOSSIA.md` du répertoire parent sont hérités lorsqu’un fichier plus proche ne déclare aucun modèle.
4. Lorsqu’aucun fichier de contexte applicable ne déclare d’identifiant, Glossia utilise le modèle par défaut du compte.

Tout identifiant configuré explicitement doit exister. Glossia signale une erreur lorsqu’un identifiant est inconnu, au lieu d’utiliser silencieusement le modèle par défaut du compte.

## Sélection par défaut

La configuration d’un projet nécessite un modèle avant que le dépôt ne dispose de son propre `GLOSSIA.md`. Glossia sélectionne donc le modèle par défaut du compte. Le premier modèle ajouté à un compte devient le modèle par défaut. Un administrateur peut ensuite en définir un autre comme modèle par défaut depuis sa page de paramètres.

Une fois qu’un dépôt dispose de `GLOSSIA.md`, l’utilisation d’un identifiant explicite clarifie son choix pour les personnes chargées de la révision. L’omission de `model` maintient le dépôt sur le modèle par défaut du compte.

## La limite de la révision humaine

La sortie du modèle constitue une proposition de modification, et non une fusion automatique. Les activités de configuration et de traduction restent visibles dans Glossia, tandis que les modifications du dépôt sont publiées dans une demande de fusion afin que l’équipe puisse les examiner. Ce processus préserve le même niveau d’exigence en matière de qualité et de responsabilité que celui déjà appliqué au code.