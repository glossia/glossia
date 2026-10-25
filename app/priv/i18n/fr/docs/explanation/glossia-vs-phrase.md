%{
  title: "Glossia contre Phrase",
  summary:
    "Choisissez un flux de travail linguistique natif au dépôt avec une source publique, vos propres tokens de modèle et des vérifications de livraison réutilisables.",
  category: "explication",
  markdown_only: true,
  section: "translation",
  order: 22
}
---

**Choisissez Glossia lorsque vous souhaitez que les travaux linguistiques suivent le système de livraison de votre produit, plutôt que de créer un processus de gestion de traduction parallèle autour de celui-ci.** Gardez le contenu dans Git, choisissez des modèles pris en charge en utilisant vos propres identifiants, et validez les résultats avec les contrôles dont votre dépôt fait déjà confiance.

[Phrase](https://phrase.com/) fournit une suite de localisation, incluant Phrase Strings et Phrase TMS pour différents besoins de localisation logicielle et de traduction gérée. Glossia adopte une approche centrée : donnez aux équipes logicielles un OS linguistique qui s'intègre à leur boucle existante d'examen et de livraison.

## Pourquoi choisir Glossia

| Votre priorité | L'avantage de Glossia |
|---|---|
| Intégrez les modifications linguistiques avec le logiciel | Les modifications du dépôt pilotent la localisation, et les sorties reviennent en tant que modifications révisables. |
| Examinez et possédez le traitement | La source publique expose l'application et l'implémentation de déploiement, avec modification et auto-hébergement autorisés selon les termes de la licence. |
| Apportez vos propres jetons | Configurez vos propres identifiants pour les modèles pris en charge ; sélectionnez des modèles via les identifiants de compte dans la configuration du dépôt. |
| Réutilisez les pipelines de validation | Exécutez des contrôles natifs au dépôt sur les candidats de traduction plutôt que de considérer l'approbation linguistique comme une preuve qu'un fichier se construira. |
| Maintenez une propriété durable | Les fichiers publiés, la configuration et l'historique des pull requests restent avec le dépôt. |

## Intégrez la localisation dans la livraison continue

La détection des modifications de Glossia évite de répéter les travaux de traduction pour des entrées inchangées. Son flux de travail de dépôt maintient une seule pull request de traduction ouverte par projet et publie les progrès par lots, afin qu'un dépôt source à évolution rapide n'ait pas besoin d'un nouveau processus de traduction pour chaque petite modification.

L'objectif n'est pas une course non révisée vers la production. Il s'agit de rendre les travaux linguistiques continuellement révisables et livrables à travers le pipeline que votre équipe utilise déjà.

Phrase offre également des APIs, intégrations et automatisation. L'avantage que Glossia met en avant est l'alignement architectural : le dépôt reste l'autorité sur le contenu et la frontière de livraison, plutôt que de n'être qu'un endroit pour synchroniser les résultats d'un autre espace de travail.

## Gardez le choix de modèle et les identifiants sous votre contrôle

Glossia accepte vos propres jetons API de fournisseur pour les modèles pris en charge. Les identifiants restent dans les paramètres de compte ; les dépôts sélectionnent des handles stables. Une équipe peut faire tourner un jeton ou changer le modèle derrière un handle sans réécrire ses instructions de dépôt.

Différents domaines de contenu et langues cibles peuvent utiliser des modèles configurés différents. Les modèles de décision optionnels peuvent évaluer les traductions complètes et demander des corrections, tandis que les humains restent responsables du jugement linguistique. Consultez [Account models](./account-models) pour le comportement et limites actuelles.

## Votre dépôt sait déjà ce que signifie le contenu valide

La vision d'un système de gestion de traduction d'une chaîne n'est pas nécessairement la vision de l'application d'un fichier. Un dépôt peut avoir son propre parser, compilateur, règles de composants, construction de documentation, et contrôles de placeholder.

Glossia peut réutiliser ces contrôles via `L10N.md` de commandes de validation. Il écrit le candidat temporairement à son chemin d'objet réel pour validation et l'accepte seulement après que les contrôles requis soient passés. La commande et ses dépendances doivent être disponibles dans l'environnement d'exécution.

Cela permet à l'équipe d'étendre sa frontière de qualité existante plutôt que de maintenir une définition séparée de "valide" uniquement à l'intérieur d'un espace de travail de traduction. Consultez [L10N.md](/docs/reference/l10n-md).

## Implémentation publique, pas une boîte noire

Les sources d'application, CLI, SDK et déploiement de Glossia sont publiques. Vous pouvez examiner comment le contenu est traité et modifier ou auto-héberger l'implémentation sous la [O'Saasy license](https://github.com/glossia/glossia/blob/main/LICENSE.md). La licence restreint les services hébergés concurrents et n'est pas une licence open-source sans restriction.

Une suite de traduction plus large peut avoir du sens pour les opérations de traduction spécialisées et une coordination complexe. Si votre priorité est **matching software-delivery speed with your own tokens and repository checks**, Glossia est conçu pour maintenir ce flux de travail direct.

Déplacer un programme de traduction établi nécessite encore un plan pour ses mémoires, terminologie et historique. Cette page ne promet pas un importeur Phrase automatique ou une équivalence totale de suite, ou affirmer que Phrase manque toutes les intégrations équivalentes. Consultez [Phrase's documentation](https://support.phrase.com/) pour les capacités actuelles du produit spécifique.
