%{
  title: "Glossia face à Lokalise",
  summary:
    "Maintenez la localisation de votre produit dans votre pipeline de livraison, avec une source publique, vos propres jetons de modèle et une validation native.",
  category: "explication",
  markdown_only: true,
  section: "translation",
  order: 21
}
---

**Choisissez Glossia lorsque le dépôt du produit doit rester l'autorité pour le contenu multilingue.** Les chaînes de caractères, la documentation, la configuration et leurs contrôles évoluent déjà avec votre application. Glossia maintient les changements linguistiques attachés à cette évolution plutôt que de demander à votre équipe de faire de l'éditeur hébergé l'autorité de publication.

[Lokalise](https://lokalise.com/) offre une localisation collaborative, la gestion de la traduction et des intégrations pour les développeurs. La proposition de Glossia est plus spécifique : conservez le flux de travail du dépôt, apportez vos propres informations d'identification de modèle, réutilisez vos contrôles existants et inspectez le système qui effectue le travail.

## Pourquoi choisir Glossia

| Votre priorité | L'avantage de Glossia |
|---|---|
| Correspondre à la vitesse des livraisons logicielles | Les changements de source pilotent le travail de traduction ; les sorties proposées reviennent par l'intermédiaire d'un flux de travail de révision de dépôt. |
| Maîtriser la mise en œuvre | La source publique rend le traitement inspectable et permet les modifications et l'hébergement autonome conformément aux termes de la licence. |
| Utiliser vos propres jetons de modèle | Les identifiants du fournisseur à portée de compte vous permettent de choisir des modèles pris en charge sans mettre de secrets dans Git. |
| Valider le contenu réel de l'application | Les scripts du dépôt peuvent vérifier le candidat là où l'application s'attend à le trouver. |
| Préserver une limite de révision claire | Les pull requests maintiennent les modifications linguistiques visibles dans le même outil utilisé pour réviser le produit. |

## Maintenez les changements linguistiques attachés aux changements de produit

Un nouveau message d'interface utilisateur ou une section de documentation n'est pas une tâche de traduction isolée. Il appartient à une révision de produit, utilise sa terminologie et doit fonctionner avec sa structure.

Glossia lit la configuration `L10N.md` de propriété du dépôt, utilise les changements de contenu et de contexte pour identifier les traductions obsolètes et propose des mises à jour pour révision. Les réviseurs voient les fichiers réels et les diffs ; la chaîne de publication reste la vôtre.

Lokalise dispose également d'automatisations et d'intégrations Git. La distinction de Glossia est le système de référence prévu : votre dépôt possède le contenu publié et ses règles de livraison, tandis que Glossia fournit le contexte linguistique et les mécanismes de transformation.

## Apportez vos propres jetons plutôt que de coder un choix de modèle permanent

Glossia vous permet de configurer les modèles pris en charge en utilisant vos propres jetons API de fournisseur. Un dépôt utilise un identifiant de modèle stable, donc faire tourner les identifiants de sécurité ou mettre à jour le modèle derrière cet identifiant n'exige pas de modifier chaque projet.

Une configuration imbriquée et un guidage spécifique à l'locale peuvent sélectionner un modèle configuré différent pour une zone ou langue particulière. Ceci est une sélection explicite, pas une promesse de basculement automatique de fournisseur. Voir [Modèles de compte](./account-models).

## Réutiliser la validation qui connaît déjà votre application

Votre dépôt peut déjà savoir comment détecter les chaînes invalides, les fichiers mal formés, les attributs de composant cassés ou un échec de build. Glossia peut invoquer cette connaissance via une commande de validation configurée.

Le candidat est temporairement placé à son chemin de sortie réel pour la vérification. La cible précédente est restaurée après chaque tentative de validation, et le candidat accepté est écrit par la suite. La sortie refusée passe par le budget de récupération configuré plutôt que d'être accepté simplement parce que le texte semble plausible.

Les contrôles structuraux et du dépôt ne prouvent pas que chaque phrase est correcte. Ils complètent la révision linguistique humaine et en font une partie du changement livrable. Voir [L10N.md](/docs/reference/l10n-md) et [Récupération de la traduction](./translation-recovery).

## Source publique et sorties appartenant au dépôt

Glossia suit un modèle open core. Le cœur utilise [Apache-2.0](https://github.com/glossia/glossia/blob/main/LICENSE-APACHE), qui autorise l'utilisation commerciale, la modification, la distribution, l'auto-hébergement et les services hébergés concurrents selon ses conditions. Le code de `ee/` est consultable, mais n'est pas open source. Il relève d'une [licence Enterprise](https://github.com/glossia/glossia/blob/main/ee/LICENSE.md) distincte et son utilisation en production nécessite un accord commercial écrit.

Plus important pour la livraison quotidienne, vos sorties de traduction restent dans Git. Vous n'avez pas besoin d'une session d'édition dans un autre produit simplement pour publier les fichiers dont vous êtes propriétaire.

Lokalise peut convenir à une équipe qui souhaite un montage de navigateur centralisé et une coordination de localisation. Glossia est le choix lorsque **la propriété du dépôt, vos propres jetons de modèle et les contrôles de produit existants** sont le flux de travail que vous souhaitez conserver.

Testez un changement représentatif avant de basculer vers les systèmes. Cette page ne promet pas de migration automatique ou de parité fonctionnelle, ni ne prétend que Lokalise manque d'automatisation ou de toutes les options de fournisseur. Voir [La documentation de Lokalise](https://docs.lokalise.com/) pour ses capacités actuelles.
