%{
  title: "Modèles de compte",
  summary:
    "Pourquoi les fournisseurs de modèles sont configurés une fois par compte et référencés par identifiant.",
  category: "explication",
  section: "platform",
  order: 2
}
---

Glossia sépare les instructions de dépôt des identifiants modèle-fournisseur. Les dépôts décrivent ce qui doit être traduit, tandis que les comptes décident quel [modèle de langage de grande taille](https://en.wikipedia.org/wiki/Large_language_model) effectue le travail.

## ## Pourquoi les modèles appartiennent aux comptes

Une équipe traduit souvent plusieurs dépôts avec la même relation fournisseur. Les modèles à portée de compte permettent aux administrateurs de faire tourner une clé fournisseur ou de changer le modèle sous-jacent sans éditer chaque dépôt.

Cette frontière maintient également les identifiants hors du contrôle de source. Un dépôt contient un identifiant lisible tel que `translation-default`, pas la clé fournisseur.

## ## Les identifiants fournissent une intention stable

Le `model` champ dans `L10N.md` fait référence à un identifiant de modèle de compte:

```yaml
model: translation-default
```

L'identifiant exprime l'intention du dépôt. Un administrateur peut mettre à jour plus tard quel modèle fournisseur celui-ci sélectionne, tandis que la configuration du dépôt reste stable.

## ## Comment plusieurs modèles sont utilisés

Glossia utilise un **modèle génératif** configuré pour chaque traduction de document. Ajouter plusieurs modèles ne crée pas un ensemble, une chaîne de secours ou un niveau de qualité automatique. L'auteur du dépôt choisit sa finalité via des identifiants stables tels que `translation-default`, `long-form` ou `japanese-specialist`.

La sélection suit la hiérarchie de contexte pour le document et la cible locale:

1. Le fichier `L10N/<locale>.md` le plus proche qui déclare `model` gagne pour ce locale.
2. Sinon, le fichier `L10N.md` le plus proche qui déclare `model` gagne pour son répertoire.
3. Les paramètres `L10N.md` parent sont hérités lorsqu'un fichier plus proche ne déclare pas de modèle.
4. Lorsqu'aucun fichier de contexte pertinent ne déclare d'identifiant, Glossia utilise le modèle génératif par défaut du compte.

Un identifiant explicitement configuré doit exister. Glossia signale une erreur pour un identifiant inconnu au lieu de basculer silencieusement vers celui par défaut du compte.

## ## Sélection par défaut

Mise en place de projet nécessite un modèle avant qu'un dépôt n'ait son propre `L10N.md`. Glossia sélectionne donc le défaut du compte. Le premier modèle ajouté à chaque catégorie devient le défaut de cette catégorie, et un administrateur peut en faire un autre modèle par défaut depuis sa page de paramètres.

Une fois qu'un dépôt a `L10N.md`, utiliser un identifiant explicite rend le choix clair pour les réviseurs. Omettre `model` maintient le dépôt sur le défaut du compte.

## ## Modèles génératifs et décisionnels

Les configurations de modèles ont deux catégories:

- Les **modèles génératifs** écrivent les traductions et propulsent la mise en place de projet. Les identifiants de modèle de dépôt et les règles de routage de locale ne sélectionnent que cette catégorie.
- Les **modèles de décision** évaluent les traductions selon une grille de qualité fixe. Lorsqu'un compte a un modèle de décision, son modèle de décision par défaut vérifie automatiquement chaque document de dépôt traduit après validation structurelle et traductions complètes, un document à la fois, depuis l'endpoint de contenu. Les requêtes de fragment sont des primitives de génération; les exécutions de dépôt valident leur assemblage.

Les catégories ont des par défauts indépendants. Ajouter Jev ne change jamais le modèle qui écrit vos traductions. Le premier modèle de décision active l'évaluation pour les exécutions de traduction ultérieures; supprimer le dernier désactive l'évaluation. Les comptes sans modèles de décision conservent leur comportement.

Glossia soutient actuellement [TypeSafe Jev](https://docs.typesafe.ai/introduction) comme fournisseur de décision. Jev renvoie des choix et des scores prédéfinis plutôt que du texte. Glossia convertit les choix de faiblesse en indices de correction, sans les présenter comme des erreurs localisées ou vérifiées indépendamment.

## ## Contrôles de qualité et révisions

L'évaluateur reçoit la source, la traduction, la locale cible, le format de contenu, les instructions de projet et le contexte d'organisation résolu. Il évalue la préservation du sens, la complétude, la terminologie, la fluidité, la cohérence du document, l'adéquation à la finalité et à l'auditoire, et l'adéquation locale. Le ton et le registre sont évalués lorsque des directives sur le ton, le projet ou le document sont disponibles.

Chaque dimension doit atteindre le minimum de score configuré, qui par défaut est 7 sur 10. Une erreur majeure ou critique demande toujours une correction, indépendamment du score. La confiance est incluse dans les événements d'évaluation en direct et ne change pas l'acceptation. Ces événements ne sont actuellement pas conservés ou affichés dans le tableau de bord. Un seuil de 10 demande un score pondéré parfait et est généralement trop strict.

Les dimensions échouées alimentent leurs indices de correction prédéfinis dans la prochaine tentative de traduction. La configuration `retries` existante du dépôt borde ces révisions; l'endpoint de contenu permet trois réessais de correction, configurable de zéro à trois avec son champ `retries`. Le document révisé complet passe à nouveau les vérifications structurelles et l'évaluation de qualité avant d'être accepté.

Les échecs de fournisseur transitoires réessaient avec recul exponentiel jusqu'à trois fois; les identifiants invalides et les réponses malformées échouent immédiatement. Les échecs de fournisseur épuisés arrêtent la traduction du fichier; la sortie non vérifiée n'est jamais acceptée. Les évaluations utilisent des documents complets, et une entrée d'évaluation surdimensionnée est rejetée plutôt que tronquée. L'entrée sérialisée est conservatrice limitée à 30 000 octets pour l'état plus la question la plus longue, et 60 000 octets sur la demande complète, pour rester dans [limites de contexte de Jev](https://docs.typesafe.ai/models). Les scores automatisés sont des jugements de modèle et nécessitent toujours une calibration contre une revue humaine bilingue.

La configuration de l'évaluateur et la version de la grille participent aux fichiers de verrouillage de traduction. Activer l'évaluation, changer les modèles ou les seuils, ou retirer l'évaluation rend les traductions précédentes obsolètes pour la prochaine exécution. Les clés fournisseur sont exclues des fichiers de verrouillage.

## ## La frontière de revue humaine

La sortie du modèle est du travail proposé, pas une fusion automatique. L'activité de configuration et de traduction reste visible dans Glossia, tandis que les changements de dépôt sont publiés via une Pull Request pour l'équipe à vérifier. Cela préserve la même limite de qualité et de propriété déjà utilisée par les équipes pour le code.
