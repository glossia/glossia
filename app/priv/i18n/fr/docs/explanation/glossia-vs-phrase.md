%{
  title: "Glossia contre Phrase",
  summary:
    "Choisissez un flux de travail linguistique natif au dépôt avec une source publique, vos propres jetons de modèle et des contrôles de livraison réutilisables.",
  category: "explication",
  markdown_only: true,
  section: "translation",
  order: 22
}
---

**Sélectionnez Glossia lorsque vous voulez que le travail linguistique suive le système de livraison de votre produit, plutôt que de construire un processus de gestion de traduction parallèle autour de celui-ci.** Gardez le contenu dans Git, choisissez des modèles pris en charge en utilisant vos propres identifiants, et validez les résultats avec les contrôles que votre dépôt fait déjà confiance.

[Phrase](https://phrase.com/) fournit une suite de localisation, y compris Phrase Strings et Phrase TMS pour différents besoins de localisation de logiciels et de traduction gérée. Glossia prend une approche ciblée : offrir aux équipes logicielles un système d'exploitation pour la langue qui s'adapte à leur boucle de révision et de livraison existante.

## Pourquoi choisir Glossia

| Votre priorité | L'avantage de Glossia |
|---|---|
| Livrez les modifications linguistiques avec le logiciel | Les modifications du dépôt pilotent la localisation, et les résultats reviennent sous forme de modifications révisables. |
| Inspectez et maîtrisez le traitement | La source publique expose l'application et la mise en œuvre du déploiement, avec les modifications et l'hébergement autonome permis selon les termes de la licence. |
| Apportez vos propres jetons | Configurez vos propres identifiants de jeton de modèle fournisseur pris en charge ; sélectionnez des modèles via les identifiants de compte dans la configuration du dépôt. |
| Réutilisez les pipelines de validation | Exécutez des contrôles natifs du dépôt sur les candidats de traduction au lieu de considérer l'approbation linguistique comme la preuve qu'un fichier sera compilé. |
| Maintenez une propriété durable | Les fichiers publiés, la configuration et l'historique des pull requests restent associés au dépôt. |

## Intégrez la localisation à la livraison continue

La détection des modifications de Glossia évite de répéter le travail de traduction pour les entrées inchangées. Son workflow du dépôt maintient une seule demande de tirage de traduction ouverte par projet et publie les progrès par lots, de sorte qu'un dépôt de source en pleine évolution n'a pas besoin d'un nouveau processus de traduction pour chaque petite modification.

L'objectif n'est pas une course non révisée vers la production. Il s'agit de rendre le travail linguistique continuellement révisable et livrable via le pipeline que votre équipe utilise déjà.

Phrase offre également des API, des intégrations et de l'automatisation. L'avantage que Glossia met en avant est l'alignement architectural : le dépôt reste l'autorité sur le contenu et la limite de livraison, plutôt que d'être simplement un lieu pour synchroniser les résultats d'un autre espace de travail.

## Gardez le choix des modèles et les identifiants sous votre contrôle

Glossia accepte vos propres jetons API de fournisseur pour les modèles pris en charge. Les identifiants restent dans les paramètres de compte ; les dépôts sélectionnent des identifiants de compte stables. Une équipe peut faire tourner un jeton ou changer le modèle derrière un identifiant sans réécrire ses instructions de dépôt.

Différentes portées de contenu et langues cibles peuvent utiliser des modèles configurés différents. Les modèles de décision optionnels peuvent évaluer les traductions complètes et demander des corrections, tandis que les humains restent responsables du jugement linguistique. Voir [Modèles de compte](./account-models) pour le comportement actuel et les limites.

## Votre dépôt sait déjà ce que signifie un contenu valide

La vision d'une chaîne par un système de gestion de la traduction n'est pas nécessairement la vision d'un fichier par l'application. Un dépôt peut avoir son propre parseur, compilateur, règles de composant, construction de documentation et contrôles de marqueurs.

Glossia peut réutiliser ces contrôles via `L10N.md` des commandes de validation. Il écrit provisoirement le candidat dans son véritable chemin de destination pour la validation et l'accepte uniquement après que les contrôles requis aient été validés. La commande et ses dépendances doivent être disponibles dans l'environnement d'exécution.

Cela permet à l'équipe d'étendre sa frontière de qualité existante plutôt que de maintenir une définition séparée de "valide" uniquement à l'intérieur d'un espace de traduction. Voir [L10N.md](/docs/reference/l10n-md).

## Implémentation publique, pas une boîte noire

L'application, la CLI, le SDK et les sources de déploiement de Glossia sont publics. Le cœur du projet est open source sous [Apache-2.0](https://github.com/glossia/glossia/blob/main/LICENSE-APACHE), ce qui autorise les modifications, la distribution, l'hébergement autonome et les services hébergés concurrents. Le code d'entreprise sous `ee/` dispose d'une licence [licence](https://github.com/glossia/glossia/blob/main/ee/LICENSE.md) nécessitant un accord commercial écrit pour un usage en production.

Une suite de traduction plus vaste peut avoir du sens pour les opérations de traduction spécialisées et une coordination complexe. Si votre priorité est **aligner la rapidité de livraison du logiciel avec vos propres jetons et contrôles du dépôt**, Glossia est conçu pour maintenir ce flux de travail direct.

Déplacer un programme de traduction établi nécessite toujours un plan pour ses mémoires, la terminologie et l'historique. Cette page ne promet pas d'importateur Phrase automatique ou une équivalence complète de la suite, ou d'affirmer que Phrase manque d'intégrations équivalentes. Consulter [la documentation Phrase](https://support.phrase.com/) pour les capacités actuelles du produit spécifique.
