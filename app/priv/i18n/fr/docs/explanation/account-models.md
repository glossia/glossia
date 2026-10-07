%{
  title: "Modèles de compte",
  summary:
    "Pourquoi les fournisseurs de modèles sont configurés une fois par compte et référencés par handle.",
  category: "explication",
  section: "platform",
  order: 2
}
---
Glossia sépare les instructions du dépôt des identifiants du fournisseur de modèle. Les dépôts décrivent ce qui doit être traduit, tandis que les comptes décident lequel [modèle de langage à grande échelle](https://en.wikipedia.org/wiki/Large_language_model) effectue le travail.

## Pourquoi les modèles appartiennent aux comptes

Une équipe traduit souvent plusieurs dépôts avec la même relation de fournisseur. Les modèles à portée de compte permettent aux administrateurs d'effectuer la rotation d'une clé de fournisseur ou de changer le modèle sous-jacent une fois sans modifier chaque dépôt.

Cette limite garde également les identifiants en dehors du contrôle de source. Un dépôt contient un identifiant lisible tel que `translation-default`, pas la clé du fournisseur.

## Les identifiants fournissent une intention stable.

Le `model` champ dans `L10N.md` se réfère à un identifiant de modèle de compte :

```yaml
model: translation-default
```

L'identifiant exprime l'intention du dépôt. Un administrateur peut ultérieurement mettre à jour quel modèle fournisseur cet identifiant sélectionne, alors que la configuration du dépôt demeure stable.

## Comment plusieurs modèles sont utilisés

Glossia utilise un configuré **génératif** modèle pour chaque traduction de document. Ajouter plusieurs modèles ne crée pas d'ensemble, une chaîne de basculement, ou un niveau de qualité automatique. L'auteur du dépôt choisit son objectif à travers des identifiants stables tels que `translation-default`, `long-form`, ou `japanese-specialist`.

Sélection suit la hiérarchie de contexte pour le document et la locale cible :

1. Le plus proche `L10N/<locale>.md` fichier qui déclare `model` l'emporte pour cette locale.
2. Sinon, le plus proche `L10N.md` fichier qui déclare `model` l'emporte pour son répertoire.
3. Parent `L10N.md` les paramètres sont hérités lorsqu'un fichier plus proche ne déclare pas de modèle.
4. Lorsqu'aucun fichier de contexte applicable ne déclare un gestionnaire, Glossia utilise le modèle génératif par défaut du compte.

Un gestionnaire configuré explicitement doit exister. Glossia signale une erreur en cas de gestionnaire inconnu plutôt que de basculer silencieusement vers le défaut du compte.

## Sélection par défaut

La configuration du projet nécessite un modèle avant que le dépôt n'en ait un. `L10N.md`. Glossia sélectionne donc la valeur par défaut du compte. Le premier modèle ajouté à chaque catégorie devient la valeur par défaut de cette catégorie, et un administrateur peut en faire un autre la valeur par défaut depuis sa page de paramètres.

Dès qu'un dépôt a `L10N.md`, en utilisant un identifiant explicite rend son choix clair pour les réviseurs. L'omission `model` maintient le dépôt sur la valeur par défaut du compte.

## Modèles génératifs et décisionnels

Les configurations de modèle comportent deux catégories :

- **Génératifs** les modèles génèrent les traductions et alimentent la configuration du projet. Les identifiants de modèle de dépôt et les règles de routage de localisation ne sélectionnent que cette catégorie.
- **Décision** Les modèles évaluent les traductions selon une grille de qualité fixe. Lorsqu'un compte dispose d'un modèle de décision, son modèle de décision par défaut vérifie automatiquement chaque document de dépôt traduit après validation structurelle et les traductions complètes, uniques par document, issues de l'endpoint de contenu. Les requêtes fragmentées sont des primitives de génération ; les exécutions de dépôt évaluent leur résultat assemblé.

Les catégories ont des valeurs par défaut indépendantes. L'ajout de Jev ne modifie jamais le modèle qui génère vos traductions. Le premier modèle de décision active l'évaluation pour les exécutions de traduction ultérieures ; supprimer le dernier modèle désactive l'évaluation. Les comptes sans modèle de décision conservent leur comportement actuel.

Glossia prend actuellement en charge [TypeSafe Jev](https://docs.typesafe.ai/introduction) en tant que fournisseur de décision. Jev renvoie des choix prédéfinis et des scores plutôt que du texte. Glossia transforme les choix relatifs aux faiblesses en indices de correction, sans les présenter comme des erreurs localisées ou vérifiées indépendamment.

## Contrôles de qualité et révisions

L'évaluateur reçoit la source, la traduction, la langue cible, le format de contenu, les instructions de projet et le contexte organisationnel résolu. Il évalue la préservation du sens, la complétude, la terminologie, la fluidité, la cohérence du document, l'adéquation à l'objectif et au public, et l'adéquation à la localisation. La voix et le registre sont évalués lorsque des directives pour la voix, le projet ou le document sont disponibles.

Chaque dimension doit atteindre le score minimum configuré, qui par défaut est de 7 sur 10. Une erreur majeure ou critique demande toujours une correction, indépendamment du score. La confiance est incluse dans les événements d'évaluation en direct et ne change pas l'acceptation. Ces événements ne sont actuellement pas conservés ou affichés dans le tableau de bord. Un seuil de 10 exige un score pondéré parfait et est généralement trop strict.

Les dimensions échouées alimentent leurs indices de correction prédéfinis dans la prochaine tentative de traduction. Le paramètre `retries` existant du dépôt limite ces révisions ; le point de terminaison de contenu autorise trois reprises de correction, configurables de zéro à trois avec son champ `retries`. Le document révisé complet passe à nouveau les vérifications structurelles et l'évaluation de qualité avant d'être accepté.

Les échecs de fournisseur transitoires réessaient avec un backoff exponentiel jusqu'à trois fois ; les identifiants non valides et les réponses malformées échouent immédiatement. Les échecs de fournisseur épuisés arrêtent la traduction du fichier ; la sortie non vérifiée n'est jamais acceptée. Les évaluations utilisent des documents complets, et l'entrée d'évaluation de taille excessive est rejetée plutôt que tronquée. L'entrée sérialisée est conservativement limitée à 30 000 octets pour l'état plus la question la plus longue, et 60 000 octets sur la demande complète, pour rester dans [limites de contexte de Jev](https://docs.typesafe.ai/models). Les scores automatisés sont des jugements de modèles et nécessitent toujours un recalibrage par rapport à la vérification humaine bilingue.

La configuration de l'évaluateur et la version de la rubrique participent aux fichiers de verrouillage de traduction. L'activation de l'évaluation, le changement de modèles ou de seuils, ou la suppression de l'évaluation rend les traductions précédentes obsolètes pour la prochaine exécution. Les clés de fournisseur sont exclues des fichiers de verrouillage.

## La limite de la relecture humaine

La sortie du modèle est un travail proposé, pas une fusion automatique. L'activité de configuration et de traduction reste visible dans Glossia, tandis que les modifications du dépôt sont publiées via une Pull Request pour que l'équipe puisse examiner. Cela préserve la même frontière de qualité et de propriété que les équipes utilisent déjà pour le code.