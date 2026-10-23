%{
  title: "Modèles de compte",
  summary:
    "Pourquoi les fournisseurs de modèles sont configurés une fois par compte et référencés par handle.",
  category: "explication",
  section: "platform",
  order: 2
}
---

Glossia sépare les instructions de dépôt des coordonnées de modèles-fournisseurs. Les dépôts décrivent ce qui doit être traduit, tandis que les comptes décident quel [modèle de langue large](https://en.wikipedia.org/wiki/Large_language_model) effectue le travail.

## Pourquoi les modèles appartiennent aux comptes

Une équipe traduit souvent plusieurs dépôts avec la même relation fournisseur. Les modèles limités aux comptes permettent aux administrateurs de faire pivoter une clé fournisseur ou de basculer vers le modèle sous-jacent une fois sans modifier chaque dépôt.

Cette frontière ten également les coordonnées hors du contrôle source. Un dépôt contient un identifiant lisible tel que `translation-default`, et non la clé fournisseur.

## Les identifiants garantissent une intention stable

Le champ `model` dans `L10N.md` fait référence à un gestionnaire de modèle de compte :

```yaml
model: translation-default
```

L'identifiant exprime l'intention du dépôt. Un administrateur peut plus tard mettre à jour quel modèle fournisseur cet identifiant sélectionne, tandis que la configuration du dépôt reste stable.

## Comment plusieurs modèles sont utilisés

Glossia utilise un modèle **génératif** configuré pour chaque traduction de document. L'ajout de plusieurs modèles ne crée pas un ensemble, une chaîne de repli ou un niveau de qualité automatique. L'auteur du dépôt choisit son objectif via des identifiants stables tels que `translation-default`, `long-form`, ou `japanese-specialist`.

La sélection suit la hiérarchie du contexte pour le document et la locale cible :

1. Le fichier `L10N/<locale>.md` le plus proche qui déclare `model` gagne pour cette locale.
2. Sinon, le fichier `L10N.md` le plus proche qui déclare `model` gagne pour son répertoire.
3. Les paramètres `L10N.md` parents sont hérités lorsqu'un fichier plus proche ne déclare pas de modèle.
4. Quand aucun fichier de contexte applicable ne déclare d'identifiant, Glossia utilise le modèle génératif par défaut du compte.

Un identifiant configuré explicitement doit exister. Glossia signale une erreur en cas d'identifiant inconnu au lieu de basculer silencieusement vers le défaut du compte.

## Sélection par défaut

La configuration de projet a besoin d'un modèle avant qu'un dépôt n'ait son propre `L10N.md`. Glossia sélectionne donc le défaut du compte. Le premier modèle ajouté à chaque catégorie devient le défaut de cette catégorie, et un administrateur peut en faire un autre le défaut depuis sa page de paramètres.

Une fois qu'un dépôt possède `L10N.md`, utiliser un identifiant explicite rend son choix clair pour les réviseurs. Omettre `model` maintient le dépôt sur le défaut du compte.

## Modèles génératifs et modèles de décision

Les configurations de modèles ont deux catégories :

- Les modèles **Génératifs** écrivent des traductions et propulsent la configuration de projet. Les gestionnaires de modèles de dépôt et les règles de routage de locale sélectionnent uniquement cette catégorie.
- Les modèles **Décision** évaluent les traductions par rapport à un canevas de qualité fixe. Lorsqu'un compte dispose d'un modèle de décision, son modèle de décision par défaut vérifie automatiquement chaque document de dépôt traduit après la validation structurelle et les traductions complètes de documents uniques depuis l'endpoint du contenu. Les requêtes de fragment sont des primitives de génération ; les exécutions de dépôt évaluent leur assemblage de sortie.

Les catégories ont des valeurs par défaut indépendantes. Ajouter Jev ne change jamais le modèle qui écrit vos traductions. Le premier modèle de décision active l'évaluation pour les exécutions de traduction subséquentes ; supprimer le dernier désactive l'évaluation. Les comptes sans modèles de décision conservent leur comportement existant.

Glossia prend actuellement en charge [TypeSafe Jev](https://docs.typesafe.ai/introduction) en tant que fournisseur de décision. Jev renvoie des choix prédéfinis et des scores plutôt que du texte. Glossia transforme les choix de faiblesse en indices de correction, sans les présenter comme des erreurs localisées ou indépendamment vérifiées.

## Contrôles de qualité et révisions

L'évaluateur reçoit la source, la traduction, la locale cible, le format de contenu, les instructions de projet et le contexte d'organisation résolu. Il évalue la préservation du sens, la complétude, la terminologie, la fluidité, la cohérence du document, l'adéquation à l'objectif et au public, et l'appropriation locale. Voix et registre sont évalués quand des directives voix, de projet ou de document sont disponibles.

Chaque dimension doit atteindre le score minimum configuré, qui par défaut vaut 7 sur 10. Une erreur majeure ou critique exige toujours une correction, indépendamment du score. La confiance est incluse dans les événements d'évaluation en direct et ne change pas l'acceptation. Ces événements ne sont actuellement ni conservés ni affichés dans le tableau de bord. Un seuil de 10 exige un score pondéré parfait et est généralement trop strict.

Les dimensions échouées alimentent leurs indices de correction prédéfinis dans la prochaine tentative de traduction. Le paramètre `retries` existant du dépôt limite ces révisions ; l'endpoint de contenu permet trois redémarrages de correction, configurables de zéro à trois avec son champ `retries`. Le document révisé complet passe à nouveau les vérifications structurelles et l'évaluation de qualité avant d'être accepté.

Les échecs de fournisseur transitoires redécouvrent avec ralentissement exponentiel jusqu'à trois fois ; les coordonnées invalides et les réponses malformées échouent immédiatement. Les échecs de fournisseur épuisés arrêtent la traduction du fichier ; la sortie non vérifiée n'est jamais acceptée. Les évaluations utilisent des documents complets, et l'entrée d'évaluation démesurée est rejetée plutôt que tronquée. L'entrée sérialisée est limitée de façon conservatrice à 30 000 octets pour l'état plus la question la plus longue, et 60 000 octets à travers la requête complète, pour rester dans les [limites de contexte de Jev](https://docs.typesafe.ai/models). Les scores automatisés sont des jugements de modèle et nécessitent toujours une calibration par la révision humaine bilingue.

La configuration de l'évaluateur et la version de la rubrique participent aux verrous de traduction. Activer l'évaluation, changer de modèles ou de seuils, ou supprimer l'évaluation rend les traductions précédentes obsolètes pour la prochaine exécution. Les clés de fournisseur sont exclues des verrous.

## La frontière de révision humaine

La sortie de modèle est un travail proposé, pas une fusion automatique. L'activité de configuration et de traduction reste visible dans Glossia, tandis que les modifications de dépôt sont publiées via une pull request pour que l'équipe les examine. Cela préserve la même frontière de qualité et de propriété que les équipes utilisent déjà pour le code.
