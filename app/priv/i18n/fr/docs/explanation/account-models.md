%{
  title: "Modèles de compte",
  summary:
    "Pourquoi les fournisseurs de modèles sont configurés une fois par compte et référencés par handle.",
  category: "Explication",
  section: "platform",
  order: 2
}
---

Glossia sépare les instructions du dépôt des identifiants du modèle-fournisseur. Les dépôts décrivent ce qui doit être traduit, tandis que les comptes déterminent quel [modèle de langage à grande échelle](https://en.wikipedia.org/wiki/Large_language_model) effectue le travail.

## Pourquoi les modèles appartiennent aux comptes

Une équipe traduit souvent plusieurs dépôts avec la même relation avec le fournisseur. Les modèles à portée de compte permettent aux administrateurs de changer la clé du fournisseur ou de basculer le modèle sous-jacent une fois sans modifier chaque dépôt.

Cette frontière garde également les identifiants hors de la source de contrôle. Un dépôt contient un identifiant lisible tel que `translation-default` , et non la clé du fournisseur.

## Les poignées fournissent une intention stable

Le champ `model` dans `L10N.md` fait référence à un identifiant de modèle du compte :

```yaml
model: translation-default
```

L'identifiant exprime l'intention du dépôt. Un administrateur peut plus tard mettre à jour quel modèle du fournisseur cet identifiant sélectionne, alors que la configuration du dépôt reste stable.

## Comment plusieurs modèles sont utilisés

Glossia utilise un modèle **génératif** configuré pour chaque traduction de document. Ajouter plusieurs modèles ne crée pas un ensemble, une chaîne de basculement, ni un niveau de qualité automatique. L'auteur du dépôt choisit son but à travers des poignées stables telles que `translation-default` , `long-form` , ou `japanese-specialist`.

La sélection suit la hiérarchie de contexte pour le document et la cible locale :

1. Le fichier `L10N/<locale>.md` le plus proche qui déclare `model` remporte pour cette cible locale.
2. Sinon, le fichier `L10N.md` le plus proche qui déclare `model` remporte pour son répertoire.
3. Les paramètres parent `L10N.md` sont hérités lorsqu'un fichier plus proche ne déclare pas un modèle.
4. Lorsqu'aucun fichier de contexte applicable ne déclare un identifiant, Glossia utilise le modèle génératif par défaut du compte.

Un identifiant-configuré explicitement doit exister. Glossia signale une erreur pour un identifiant inconnu au lieu de passer silencieusement au modèle par défaut du compte.

## Sélection par défaut

La configuration du projet a besoin d'un modèle avant qu'un dépôt n'ait sa propre `L10N.md`. Glossia sélectionne donc le modèle par défaut du compte. Le premier modèle ajouté à chaque catégorie devient le modèle par défaut de cette catégorie, et un administrateur peut faire d'un autre modèle le par défaut depuis la page de ses paramètres.

Une fois qu'un dépôt a `L10N.md` , utiliser un identifiant explicite rend son choix clair pour les revues. L'omission de `model` maintient le dépôt sur le modèle par défaut du compte.

## Modèles génératifs et décisionnels

Les configurations de modèle ont deux catégories :

- **Génératif** les modèles écrivent les traductions et actionnent la configuration de projet. Les identifiants de modèle de dépôt et les règles de routage de cible locale ne sélectionnent que cette catégorie.
- **Décision** les modèles évaluent les traductions par rapport à une grille de qualité fixe. Lorsqu'un compte dispose d'un modèle décisionnel, son modèle décisionnel par défaut vérifie automatiquement chaque document de dépôt traduit après la validation structurelle et les traductions complètes, monodocumentaires depuis le point de terminaison de contenu. Les requêtes de fragment sont des primitives de génération ; les exécutions de dépôt évaluent leur produit assemblé.

Les catégories disposent de par défauts indépendants. L'ajout de Jev ne change jamais le modèle qui écrit vos traductions. Le premier modèle décisionnel active l'évaluation pour les cycles de traduction ultérieurs ; la suppression du dernier modèle désactive l'évaluation. Les comptes sans modèles décisionnels conservent leur comportement existant.

Glossia prend actuellement en charge [TypeSafe Jev](https://docs.typesafe.ai/introduction) en tant que fournisseur de décision. Jev retourne des choix et des points prédéfinis au lieu de la prose. Glossia transforme les faiblesses de choix en indices de correction, sans les présenter comme des erreurs localisées ou indépendamment vérifiées.

## Contrôles de qualité et révisions

L'évaluateur reçoit le source, la traduction, la cible locale, le format de contenu, les instructions de projet et le contexte d'organisation résolu. Il évalue la préservation de sens, la complétude, la terminologie, la fluidité, la cohérence du document, l'adéquation au but et au public, ainsi que la pertinence locale. La voix et le registre sont évalués lorsque la voix, le projet ou les instructions du document sont disponibles.

Chaque dimension doit atteindre le score minimum configuré, qui par défaut est de 7 sur 10. Un grave ou une erreur critique demande toujours une correction, sans considération du score. La confiance est incluse dans les événements d'évaluation en direct et ne change pas l'acceptation. Ces événements ne sont pas actuellement conservés ou affichés dans le tableau de bord. Un seuil de 10 nécessite un score pondéré parfait et est généralement trop strict.

Les dimensions échouées poussent leurs indices de correction prédéfinis dans la prochaine tentative de traduction. Le paramètre `retries` existant du dépôt limite ces révisions ; le point de terminaison de contenu autorise trois rééssais de correction, configurables de zéro à trois avec son champ `retries`. Le document révisé complet passe les vérifications structurelles et l'évaluation de qualité à nouveau avant d'être accepté.

Les échecs transitoires du fournisseur réessaient avec backoff exponentiel jusqu'à trois fois ; les identifiants invalides et les réponses malformatées échouent immédiatement. Les échecs du fournisseur épuisés arrêtent la traduction du fichier ; la sortie non vérifiée n'est jamais acceptée. Les évaluations utilisent des documents complets, et une entrée d'évaluation trop grande est refusée plutôt que tronquée. L'entrée sérialisée est conservatrice limitée à 30 000 octets pour l'état plus la plus longue question, et 60 000 octets tout au long de la requête complète, pour rester dans [limites de contexte de Jev](https://docs.typesafe.ai/models) . Les scores automatisés sont un jugement de modèle et nécessitent encore une calibration par rapport à une revue bilingue humaine.

La configuration de l'évaluateur et la version de la grille participent aux fichiers de verrouillage de traduction. Activer l'évaluation, changer des modèles ou des seuils, ou supprimer l'évaluation rend les traductions antérieures obsolètes pour le cycle suivant. Les clés fournisseurs sont exclues des fichiers de verrouillage.

## La frontière de relecture humaine

La sortie du modèle est un travail proposé, pas une fusion automatique. L'activité de configuration et de traduction reste visible dans Glossia, tandis que les changements de dépôt sont publiés par une demande d'extraction pour que l'équipe la révise. Cela préserve la même frontière de qualité et de propriété d'équipe déjà utilisée pour le code.
