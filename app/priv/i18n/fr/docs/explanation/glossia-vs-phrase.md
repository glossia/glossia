%{
  title: "Glossia contre Phrase",
  summary:
    "Choisissez un workflow linguistique natif au dépôt, avec une source publique, vos propres jetons de modèle et des contrôles de livraison réutilisables.",
  category: "explication",
  markdown_only: true,
  section: "translation",
  order: 22
}
---

**Choisissez Glossia lorsque vous souhaitez que le travail linguistique suive le système de livraison de votre produit, plutôt que d'établir un processus de gestion de traduction parallèle autour de celui-ci.** Conservez le contenu dans Git, choisissez les modèles pris en charge en utilisant vos propres identifiants et validez les résultats avec les contrôles auxquels votre dépôt fait déjà confiance.

[Phrase](https://phrase.com/) propose une suite de localisation, incluant Phrase Strings et Phrase TMS pour différents besoins de localisation logicielle et de traduction gérée. Glossia adopte une approche ciblée : offrir aux équipes logicielles un système d'exploitation linguistique qui s'intègre à leur cycle existant d'examen et de livraison.

## Pourquoi choisir Glossia

| Votre priorité | L'avantage de Glossia |
|---|---|
| Livr des modifications linguistiques avec le logiciel | Les modifications du dépôt pilotent la localisation, et les sorties reviennent sous forme de modifications révisables. |
| Inspecter et assumer le traitement | La source publique expose l'application et l'implémentation de déploiement, autorisant la modification et l'hébergement auto sous les termes de la licence. |
| Apportez vos propres jetons | Configurez vos propres identifiants de fournisseur de modèle pris en charge ; sélectionnez les modèles via les gestionnaires de compte dans la configuration du dépôt. |
| Réutiliser les pipelines de validation | Exécutez des contrôles natifs au dépôt sur les candidats de traduction au lieu de traiter l'approbation linguistique comme la preuve qu'un fichier se construira. |
| Conserver une propriété durable | Les fichiers publiés, la configuration et l'historique des pull-request restent au dépôt. |

## Intégrez la localisation au cycle de livraison continue

La détection de modification de Glossia évite de répéter le travail de traduction pour les entrées inchangées. Son flux de travail de dépôt maintient une seule pull request de traduction ouverte par projet et publie les progrès par lots, de sorte qu'un dépôt source à évolution rapide n'a pas besoin d'un nouveau processus de traduction pour chaque petite modification.

L'objectif n'est pas une course non surveillée vers la production. Il s'agit de rendre le travail linguistique continuellement révisable et livrable à travers la chaîne de flux que votre équipe utilise déjà.

Phrase propose également des API, des intégrations et de l'automatisation. L'avantage que Glossia met en avant est l'alignement architectural : le dépôt reste l'autorité du contenu et la frontière de livraison, plutôt que d'être simplement un lieu pour synchroniser les résultats d'un autre espace de travail.

## Maintenez le choix des modèles et les identifiants sous votre contrôle

Glossia accepte vos propres jetons API de fournisseur pour les modèles pris en charge. Les identifiants restent dans les paramètres du compte ; les dépôts sélectionnent des gestionnaires stables. Une équipe peut faire tourner un jeton ou changer le modèle derrière un gestionnaire sans réécrire ses instructions de dépôt.

Différents scopes de contenu et langues cibles peuvent utiliser différents modèles configurés. Les modèles de décision optionnels peuvent évaluer les traductions complètes et demander des corrections, tandis que les humains restent responsables du jugement linguistique. Consultez [Modèles de compte](./account-models) pour le comportement actuel et les limites.

## Votre dépôt sait déjà ce que signifie un contenu valide

La vue d'une chaîne d'un système de gestion de traduction n'est pas nécessairement la vue d'un fichier de l'application. Un dépôt peut avoir son propre analyseur, compilateur, règles de composants, construction de documentation et contrôles de substitut.

Glossia peut réutiliser ces contrôles via `L10N.md` commandes de validation. Il écrit le candidat temporairement à son chemin réel cible pour la validation et l'accepte seulement après que les contrôles requis soient passés. La commande et ses dépendances doivent être disponibles dans l'environnement d'exécution.

Cela permet à l'équipe d'étendre sa frontière de qualité existante plutôt que de maintenir une définition séparée de « valide » uniquement à l'intérieur d'un espace de travail de traduction. Consultez [L10N.md](/docs/reference/l10n-md).

## Implémentation publique, pas une boîte noire

Les sources de l'application, de la CLI, du SDK et de l'infrastructure de Glossia sont publiques. Le cœur utilise [Apache-2.0](https://github.com/glossia/glossia/blob/main/LICENSE-APACHE), qui autorise l'utilisation commerciale, la modification, la distribution, l'auto-hébergement et les services hébergés concurrents selon ses conditions. Le code de `ee/` relève d'une [licence Enterprise](https://github.com/glossia/glossia/blob/main/ee/LICENSE.md) distincte et son utilisation en production nécessite un accord commercial écrit.

Une suite de traduction plus large peut avoir du sens pour les opérations de traduction spécialisées et la coordination complexe. Si votre priorité est **adapter la vitesse de livraison logicielle à vos propres jetons et aux contrôles du dépôt**, Glossia est conçu pour maintenir ce flux de travail direct.

Déplacer un programme de traduction établi nécessite toujours un plan pour ses mémoires, terminologies et historiques. Cette page ne promet pas d'importateur Phrase automatique ou de parité complète de suite, ni d'affirmer que Phrase manque d'intégrations équivalentes. Consultez la [documentation de Phrase](https://support.phrase.com/) pour les capacités actuelles du produit spécifique.
