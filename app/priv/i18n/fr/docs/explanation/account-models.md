%{
  title: "Modèles de compte",
  summary:
    "Pourquoi les fournisseurs de modèles sont configurés une fois par compte et référencés par handle.",
  category: "explication",
  section: "platform",
  order: 2
}
---

Glossia sépare les instructions du dépôt des identifiants de modèle-fournisseur. Les dépôts décrivent ce qui doit être traduit, tandis que les comptes décident quel [modèle de langage naturel](https://en.wikipedia.org/wiki/Large_language_model) effectue le travail.

## Pourquoi les modèles relèvent des comptes

Une équipe traduit souvent plusieurs dépôts avec la même relation fournisseur. Les modèles à portée de compte permettent aux administrateurs de faire circuler une clé de fournisseur ou de basculer le modèle sous-jacent une fois sans modifier chaque dépôt.

Cette frontière maintient également les identifiants hors du contrôle de la source. Un dépôt contient une référence lisible telle `translation-default`, pas la clé du fournisseur.

## Les référents apportent une intention stable

Le champ `model` dans `L10N.md` renvoie à un modèle de compte référence :

```yaml
model: translation-default
```

Le référent exprime l'intention du dépôt. Un administrateur peut plus tard mettre à jour quel modèle fournisseur ce référent sélectionne lorsque la configuration du dépôt reste stable.

## Comment plusieurs modèles sont utilisés

Glossia utilise un modèle **génératif** configuré pour chaque traduction de document. L'ajout de plusieurs modèles ne crée pas un ensemble, une chaîne de régression ou un niveau de qualité automatique. L'auteur du dépôt choisit sa finalité à travers des référents stables tels `translation-default`, `long-form` ou `japanese-specialist`.

Sélection est guidée par la hiérarchie de contexte pour le document et la cible locale :

1. Le fichier `L10N/<locale>.md` le plus proche qui définit `model` prévaut pour cette locale.
2. Sinon, le fichier `L10N.md` le plus proche qui définit `model` prévaut pour son répertoire.
3. Les paramètres parent `L10N.md` sont hérités quand un fichier plus proche ne définit pas un modèle.
4. Quand aucun fichier de contexte applicable ne définit un identifiant, Glossia utilise le modèle génératif par défaut du compte.

Un idéalement configuré identifiant doit exister. Glossia signale une erreur pour un identifiant inconnu au lieu de basculer silencieusement vers le compte par défaut.

## Sélection par défaut

La mise en place du projet exige un modèle avant un dépôt a son propre `L10N.md`. Glossia sélectionne donc le compte par défaut. Le premier modèle ajouté à chaque catégorie devient le référent de la catégorie et un administrateur peut en faire un autre le par défaut depuis sa page de paramètres.

Une fois un dépôt a `L10N.md`, l'utilisation d'un identifiant explicite fait son choix clair aux réviseurs. Omettre `model` maintient le dépôt sur le compte par défaut.

## Modèles génératifs et de décision

Les configurations de modèle ont deux catégories :

- Les modèles **génératifs** écrivent les traductions et alimentent la mise en place du projet. Les référents de modèle de dépôt et les règles de routage de locale sélectionnent uniquement cette catégorie.
- Les modèles **de décision** évaluent les traductions face à une grille de qualité fixe. Lorsqu'un compte a un modèle de décision, son modèle de décision par défaut vérifie automatiquement chaque document de dépôt traduit après validation structurelle et traduction complète de document unique de l'endpoint du contenu. Les demandes de fragiles sont des primitives de génération ; les exécutions de dépôt évaluent leur sortie assemblée.

Les catégories ont des par défauts indépendants. Ajouter Jev ne change jamais le modèle qui écrit vos traductions. Le premier modèle de décision active l'évaluation pour les exécutions de traduction subséquentes ; supprimer le dernier désactive l'évaluation. Les comptes sans modèles de décision gardent leur comportement existant.

Glossia prend actuellement en charge [TypeSafe Jev](https://docs.typesafe.ai/introduction) comme fournisseur de décision. Jev retourne des choix et des scores prédéfinis plutôt qu'une prose. Glossia convertit les choix de faiblesse en indices de correction, sans les présenter comme des erreurs situées ou indépendamment vérifiées.

## Contrôles de qualité et de révisions

L'évaluateur reçoit la source, la traduction, la cible locale, le format de contenu, les instructions du projet, et le contexte de l'organisation résolu. Il évalue la conservation du sens, la complétude, la terminologie, la fluidité, la cohérence du document, l'adéquation de l'intention et du public, et l'adéquation locale. La voix et le registre sont évalués quand la voix, le projet ou la directive du document est disponible.

Chaque dimension doit atteindre le score minimum configuré, qui par défaut est de 7 sur 10. Une erreur majeure ou critique demande toujours une correction, indépendamment du score. La confiance est incluse dans les événements de contrôle en direct et ne change pas l'acceptation. Ces événements sont actuellement conservés ou affichés sur le tableau de bord. Un seuil de 10 nécessite un score pondéré parfait et est généralement trop strict.

Les dimensions échouées alimentent leurs indices de correction prédéfinis dans la prochaine tentative de traduction. Le paramètre `retries` existant du dépôt limite ces révisions ; l'endpoint du contenu permet trois tentatives de correction, configurable de zéro à trois avec son champ `retries`. Le document révisé complet passe à nouveau les contrôles structurels et l'évaluation de qualité avant d'être accepté.

Les échecs de fournisseur transitoires rétentent avec un délai de décalage exponentiel jusqu'à trois fois ; les identifiants invalides et les réponses mal formées échouent immédiatement. Les échecs de fournisseur épuisés arrêtent la traduction du fichier ; la sortie non vérifiée est jamais acceptée. Les évaluations utilisent des documents complets, et l'entrée d'évaluation de surdimension est rejetée plutôt que tronquée. L'entrée sérialisée est limitativement conservatrice de 30,000 octets pour l'état plus la question la plus longue, et 60,000 octets à travers la demande entière, pour rester dans [les limites de contexte de Jev](https://docs.typesafe.ai/models). Les scores automatisés sont jugements de modèle et nécessitent encore une calibration face à l'examen humain bilingue.

La configuration de l'évaluateur et la version du ruban participent aux verrous de traduction. L'activation de l'évaluation, changement des modèles ou seuils, ou suppression d'évaluation rend les traductions antérieures obsolètes pour le prochain cycle. Les clés de fournisseur sont exclues des verrous.

## La frontière de contrôle humain

La sortie de modèle est un travail proposé, pas une fusion automatique. L'activité de mise en place et de traduction reste visible dans Glossia, tandis que les modifications du dépôt sont publiées par une demande de tirage pour revus par l'équipe. Cela préserve la même frontière de qualité et de propriété que les équipes utilisent déjà pour le code.
