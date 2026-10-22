%{
  title: "Modèles de compte",
  summary:
    "Pourquoi les fournisseurs de modèles sont configurés une fois par compte et référencés par identifiant.",
  category: "Explication",
  section: "platform",
  order: 2
}
---

Glossia sépare les instructions de dépôt des identifiants de modèle-provideur. Les dépôts décrivent ce qui doit être traduit, tandis que les comptes décident [quel modèle de langage à grande échelle](https://en.wikipedia.org/wiki/Large_language_model) effectue le travail.

## Pourquoi les modèles appartiennent aux comptes

Une équipe traduit souvent plusieurs dépôts avec la même relation fournisseur. Les modèles limités au compte permettent aux administrateurs de changer une clé de fournisseur ou de basculer le modèle sous-jacent une fois sans modifier chaque dépôt.

Cette frontière garde aussi les identifiants hors du contrôle de source. Un dépôt contient un qualifiant lisible tel que `translation-default`, et non la clé de fournisseur.

## Les handles fournissent une intention stable

Le champ `model` de `L10N.md` fait référence à un handle de modèle de compte :

```yaml
model: translation-default
```

Le handle exprime l'intention du dépôt. Un administrateur peut mettre à jour quel modèle de fournisseur ce handle sélectionne tant que la configuration du dépôt reste stable.

## Comment plusieurs modèles sont utilisés

Glossia utilise un modèle **génératif** configuré pour chaque traduction de document. Ajouter plusieurs modèles ne crée ni un ensemble, ni une chaîne de repli, ni un niveau qualité automatique. L'auteur du dépôt choisit son objectif via des handles stables tels que `translation-default`, `long-form`, ou `japanese-specialist`.

La sélection suit la hiérarchie de contexte pour le document et la locale cible :

1. Le fichier `L10N/<locale>.md` le plus proche qui déclare `model` l'emporte pour cette locale.
2. Autrement, le fichier `L10N.md` le plus proche qui déclare `model` l'emporte pour son répertoire.
3. Les paramètres `L10N.md` du parent sont hérités lorsqu'un fichier plus proche ne déclare pas de modèle.
4. Lorsqu'aucun fichier de contexte applicable ne déclare un handle, Glossia utilise le modèle génératif par défaut du compte.

Un handle configuré explicitement doit exister. Glossia signale une erreur pour un handle inconnu plutôt que de basculer silencieusement vers le modèle par défaut du compte.

## Sélection par défaut

La configuration du projet nécessite un modèle avant que le dépôt n'ait sa propre `L10N.md`. Glossia sélectionne donc le modèle par défaut du compte. Le premier modèle ajouté à chaque catégorie devient le modèle par défaut de cette catégorie, et un administrateur peut en faire défiler un autre modèle via sa page de paramètres.

Une fois qu'un dépôt a `L10N.md`, l'utilisation d'un handle explicite rend son choix clair aux réviseurs. Omettre `model` conserve le dépôt sur le modèle par défaut du compte.

## Modèles génératifs et de décision

Les configurations de modèles ont deux catégories :

- **Génératif** rédigent des traductions et alimentent la configuration du projet. Les handles de modèle de dépôt et les règles de routage de locale sélectionnent uniquement cette catégorie.
- **Décision** évaluent les traductions selon une grille de qualité fixe. Lorsqu'un compte possède un modèle de décision, son modèle de décision par défaut vérifie automatiquement chaque document de dépôt traduit après validation structurelle et les traductions complètes du point de terminaison du contenu. Les demandes de fragments sont des primitives de génération ; les exécutions de dépôt évaluent leur sortie assemblée.

Les catégories ont des valeurs par défaut indépendantes. Ajouter Jev ne modifie jamais le modèle qui rédige vos traductions. Le premier modèle de décision active l'évaluation pour les futures exécutions de traduction ; supprimer le dernier désactive l'évaluation. Les comptes sans modèle de décision gardent leur comportement existant.

Glossia prend actuellement en charge [TypeSafe Jev](https://docs.typesafe.ai/introduction) en tant que fournisseur de décision. Jev renvoie des choix et des scores prédéfinis plutôt qu'un texte. Glossia convertit les choix en cases avec des indices de correction, sans les présenter comme des erreurs situées ou vérifiées indépendamment.

## Contrôles de qualité et révisions

L'évaluateur reçoit la source, la traduction, la locale cible, le format de contenu, les instructions du projet et le contexte de l'organisation résolu. Il évalue la conservation de sens, la complétude, la terminologie, la fluidité, la cohérence du document, l'adéquation de l'objectif et du public, et la pertinence de la locale. La voix et le registre sont évalués si des directives de voix, de projet ou de document sont disponibles.

Chaque dimension doit atteindre le score minimum configuré, ce qui par défaut est de 7 sur 10. Une erreur majeure ou critique demande toujours une correction, quel que soit le score. Le niveau de confiance est inclus dans les événements d'évaluation en direct et ne change pas l'acceptation. Ces événements ne sont actuellement pas conservés ou affichés dans le tableau de bord. Un seuil de 10 nécessite un score pondéré parfait et est généralement trop strict.

Les dimensions échouées envoient leurs indices de correction prédéfinis à la tentative de traduction suivante. Le `retries` du dépôt limite ces révisions ; le point de terminaison du contenu permet trois redémarrages de correction, configurables de zéro à trois avec son champ `retries`. Le document révisé complet passe à nouveau les vérifications structurelles et l'évaluation de qualité avant d'être accepté.

Les défaillances transitoires du fournisseur réessaient avec un backoff exponentiel jusqu'à trois fois ; les identifiants invalides et les réponses malformées échouent immédiatement. Les défaillances du fournisseur épuisées arrêteront la traduction du fichier ; la sortie non vérifiée n'est jamais acceptée. Les évaluations utilisent des documents complets et une entrée d'évaluation surdimensionnée est rejetée plutôt que tronquée. L'entrée sérialisée est limitativement conservatrice à 30 000 octets pour l'état plus la plus longue question, et 60 000 octets dans la demande complète, pour rester dans [limites de contexte de Jev](https://docs.typesafe.ai/models). Les scores automatisés sont des Jugements du modèle et nécessitent encore une calibration contre un examen humain bilingue.

La configuration de l'évaluateur et la version de la grille de qualité participent aux fichiers de verrouillage de traduction. Activer l'évaluation, changer les modèles ou les seuils, ou supprimer l'évaluation rend les traductions précédentes obsolètes pour la prochaine exécution. Les clés de fournisseur sont exclues des fichiers de verrouillage.

## La frontière de la révision humaine

La sortie de modèle est un travail proposé, pas une fusion automatique. L'activité de configuration et de traduction reste visible dans Glossia, tandis que les changements de dépôt sont publiés via pull request pour que l'équipe puisse les examiner. Cela préserve la même frontière de qualité et de propriété que les équipes utilisent déjà pour le code.
