%{
  title: "Glossia face à Phrase",
  summary:
    "Choisissez un flux de travail linguistique natif au dépôt, avec source publique, vos propres jetons de modèle et des vérifications de livraison réutilisables.",
  category: "explication",
  markdown_only: true,
  section: "translation",
  order: 22
}
---

**Choisissez Glossia lorsque vous souhaitez que le travail linguistique suive le système de livraison de votre produit, plutôt que de construire un processus de gestion de traduction parallèle autour de celui-ci.** Gardez le contenu dans Git, choisissez les modèles pris en charge à l'aide de vos propres identifiants et validez les résultats avec les contrôles que votre dépôt fait déjà confiance.

[Phrase](https://phrase.com/) propose une suite de localisation, incluant Phrase Strings et Phrase TMS pour différents besoins de localisation logicielle et de gestion de traduction. Glossia adopte une approche ciblée : offrir aux équipes logicielles un OS linguistique qui s'intègre à leur cycle de révision et de livraison existant.

## Pourquoi choisir Glossia

| Votre priorité | Avantage de Glossia |
|---|---|
| Diffuser les modifications linguistiques avec le logiciel | Les modifications du dépôt pilotent la localisation, et les sorties reviennent sous forme de modifications révisables. |
| Inspecter et maîtriser le traitement | La source publique expose l'application et la mise en œuvre de déploiement, avec la modification et l'hébergement interne autorisés sous les termes de la licence. |
| Apportez vos propres jetons | Configurez vos propres identifiants pour le fournisseur de modèle pris en charge ; sélectionnez les modèles via les handles de compte dans la configuration du dépôt. |
| Réutiliser les pipelines de validation | Exécuter des contrôles natifs du dépôt sur les candidats de traduction au lieu de traiter l'approbation linguistique comme une preuve qu'un fichier se construira. |
| Conserver une propriété durable | Les fichiers publiés, la configuration et l'historique des pull requests restent dans le dépôt. |

## Intégrez la localisation à la livraison continue

La détection de modification de Glossia évite de répéter le travail de traduction pour des entrées inchangées. Son flux de travail de dépôt maintient une seule demande de tirage de traduction ouverte par projet et publie les progrès par lots, de sorte qu’un dépôt source en évolution rapide n’a pas besoin d’un nouveau processus de traduction pour chaque petite modification.

L’objectif n’est pas une course non revue vers la production. Il s’agit de rendre le travail linguistique constamment révisable et livrable à travers le pipeline que votre équipe utilise déjà.

Phrase propose également des API, des intégrations et de l’automatisation. L’avantage que Glossia met en avant est l’alignement architectural : le dépôt reste l’autorité du contenu et la frontière de livraison, plutôt qu’uniquement un lieu pour synchroniser les résultats d’un autre espace de travail.

## Gardez le choix du modèle et des identifiants sous votre contrôle

Glossia accepte vos propres jetons d’API de fournisseur pour les modèles pris en charge. Les identifiants restent dans les paramètres du compte ; les dépôts sélectionnent des handles stables. Une équipe peut faire tourner un jeton ou changer le modèle situé derrière un handle sans réécrire ses instructions de dépôt.

Différentes portées de contenu et langues cibles peuvent utiliser différents modèles configurés. Les modèles de décision optionnels peuvent évaluer des traductions complètes et demander des corrections, tandis que les humains restent responsables du jugement linguistique. Voir [Modèles de compte](./account-models) pour le comportement actuel et les limites.

## Votre dépôt sait déjà ce que signifie le contenu valide

La vision d’un système de gestion de traduction d’une chaîne n’est pas nécessairement la vision de l’application d’un fichier. Un dépôt peut avoir son propre analyseur, compilateur, règles de composant, construction de documentation et contrôles de placeholder.

Glossia peut réutiliser ces contrôles à travers `L10N.md` commandes de validation. Elle écrit le candidat temporairement à son véritable chemin cible pour la validation et l’accepte uniquement après que les contrôles requis aient passé. La commande et ses dépendances doivent être disponibles dans l’environnement d’exécution.

Cela permet à l’équipe d’étendre sa frontière de qualité existante plutôt que de maintenir une définition séparée de "valide" uniquement dans un espace de travail de traduction. Consultez [L10N.md](/docs/reference/l10n-md).

## Mise en œuvre publique, pas une boîte noire

Les sources de l'application, de la CLI, du SDK et de l'infrastructure de Glossia sont publiques. Le cœur utilise [Apache-2.0](https://github.com/glossia/glossia/blob/main/LICENSE-APACHE), qui autorise l'utilisation commerciale, la modification, la distribution, l'auto-hébergement et les services hébergés concurrents selon ses conditions. Le code de `ee/` relève d'une [licence Enterprise](https://github.com/glossia/glossia/blob/main/ee/LICENSE.md) distincte et son utilisation en production nécessite un accord commercial écrit.

Une suite de traduction plus large peut avoir du sens pour les opérations de traduction spécialisées et la coordination complexe. Si votre priorité est **corriger la vitesse de livraison de logiciels avec vos propres jetons et les contrôles du dépôt**, Glossia est conçu pour maintenir ce flux de travail direct.

Le déplacement d’un programme de traduction établi nécessite toujours un plan pour ses mémoires, terminologie et historique. Cette page ne promet pas un importeur de Phrase automatique ou une parité de suite complète, ni d’affirmer que Phrase manque toutes les intégrations équivalentes. Consultez [la documentation de Phrase](https://support.phrase.com/) pour les capacités actuelles du produit spécifique.
