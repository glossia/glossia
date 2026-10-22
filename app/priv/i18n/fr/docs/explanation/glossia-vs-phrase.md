%{
  title: "Glossia versus Phrase",
  summary:
    "Choisissez un workflow de traduction natif au dépôt avec une source publique, vos propres tokens de modèle, et des vérifications de livraison réutilisables.",
  category: "explication",
  section: "translation",
  order: 22
}
---

**Choisissez Glossia lorsque vous souhaitez que le travail linguistique suive le système de livraison de votre produit, plutôt que de mettre en place un processus de gestion de traduction parallèle autour de lui.** Gardez le contenu dans Git, choisissez les modèles pris en charge à l'aide de vos propres identifiants, et validez les résultats avec les vérifications que votre référentiel connaît déjà.

[Phrase](https://phrase.com/) propose une suite de localisation, incluant Phrase Strings et Phrase TMS pour différents besoins de localisation de logiciel et de traduction sous gestion. Glossia adopte une approche centrée : offrir aux équipes logicielles un système d'exploitation linguistique qui s'adapte à leur cycle existant de révision et de livraison.

## Pourquoi choisir Glossia

| Votre priorité | L'avantage de Glossia |
|---|---|
| Livrer des modifications de langue avec le logiciel | Les modifications du référentiel entraînent la localisation, et les sorties reviennent sous forme de modifications révisables. |
| Inspecter et assumer le traitement | Une source publique expose l'application et l'implémentation de déploiement, avec modification et auto-hébergement autorisés dans les termes de la licence. |
| Apportez vos propres jetons | Configurez vos propres identifiants de fournisseur de modèles pris en charge ; sélectionnez les modèles via des identifiants de compte dans la configuration du référentiel. |
| Réutiliser des pipelines de validation | Exécutez des vérifications natives au référentiel sur les candidats à la traduction au lieu de considérer l'approbation linguistique comme la preuve qu'un fichier se construira. |
| Conserver une propriété durable | Les fichiers publiés, la configuration et l'historique des pull-requests demeurent avec le référentiel. |

## Intégrez la localisation dans la livraison continue

La détection de modification de Glossia évite de répéter le travail de traduction pour les entrées inchangées. Son flux de travail de référentiel maintient une seule demande de tirage de traduction ouverte par projet et publie les progrès par lot, de sorte qu'un référentiel source en évolution rapide n'a pas besoin d'un nouveau processus de traduction pour chaque petite modification.

L'objectif n'est pas une course non révisée vers la production. Il s'agit de rendre le travail linguistique continuellement révisable et livrable via le pipeline que votre équipe utilise déjà.

Phrase propose également des API, des intégrations et une automatisation. L'avantage que Glossia met en avant est l'alignement architectural : le référentiel demeure l'autorité sur le contenu et la frontière de livraison, plutôt que de n'être qu'un endroit pour synchroniser les résultats d'un autre espace de travail.

## Conservez le choix des modèles et les identifiants sous votre contrôle

Glossia accepte vos propres jetons API de fournisseur pour les modèles pris en charge. Les identifiants restant dans les paramètres de compte ; les référentiels sélectionnent des alias stables. Une équipe peut faire rouler un jeton ou changer le modèle associé à un alias sans réécrire ses instructions de référentiel.

Les différentes écorces de contenu et les langues cibles peuvent utiliser différents modèles configurés. Les modèles décisionnels facultatifs peuvent évaluer des traductions complètes et demander une correction, alors que les humains restent responsables du jugement linguistique. Voir [Modèles de compte](./account-models) pour le comportement et les limites actuelles.

## Votre référentiel sait déjà ce que signifie le contenu valide

La vision d'un système de gestion de traduction d'une chaîne n'est pas nécessairement la vue de l'application d'un fichier. Un référentiel peut avoir son propre parseur, compilateur, règles de composant, construction de documentation, et vérifications de marqueurs.

Glossia peut réutiliser ces vérifications grâce `L10N.md` aux commandes de validation. Il écrit temporairement le candidat à son chemin cible réel pour la validation et l'accepte uniquement après que les vérifications requises aient été passées. La commande et ses dépendances doivent être disponibles dans l'environnement d'exécution.

Cela permet à l'équipe d'étendre sa frontière de qualité existante plutôt que de maintenir une définition séparée de « valide » uniquement à l'intérieur d'un espace de travail de traduction. Voir [L10N.md](/docs/reference/l10n-md).

## Implémentation publique, pas une boîte noire

L'application, CLI, SDK et les sources de déploiement de Glossia sont publics. Vous pouvez inspecter la manière dont le contenu est géré et modifier ou auto-héberger l'implémentation sous la licence [Licence O'Saasy](https://github.com/glossia/glossia/blob/main/LICENSE.md). La licence restreint les services hébergés concurrents et n'est pas une licence open-source sans restriction.

Une suite de traduction plus large peut avoir du sens pour des opérations de traduction spécialisées et une coordination complexe. Si votre priorité consiste à **aligner la vélocité de livraison de logiciel avec vos propres jetons et les vérifications du référentiel**, Glossia est conçu pour maintenir ce flux direct.

Déplacer un programme de traduction établi nécessite toujours un plan pour ses mémoires, sa terminologie et son historique. Cette page ne promet pas un importateur automatique Phrase ou une égalité complète d'ensemble, ni d'affirmer que Phrase manque toutes les intégrations équivalentes. Consulter [Documentation de Phrase](https://support.phrase.com/) pour les capacités du produit spécifique actuelle.
