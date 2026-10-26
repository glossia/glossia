%{
  title: "Glossia contre Lokalise",
  summary:
    "Maintenez la localisation de vos produits dans votre pipeline de livraison, avec une source publique, vos propres jetons de modèle et une validation native.",
  category: "explication",
  markdown_only: true,
  section: "translation",
  order: 21
}
---

**Choisissez Glossia lorsque le dépôt de produit doit rester l'autorité pour le contenu multilingue.** Les chaînes, la documentation, la configuration et leurs contrôles évoluent déjà avec votre application. Glossia maintient les modifications linguistiques attachées à cette évolution plutôt que de demander à votre équipe de rendre l'éditeur hébergé l'autorité de publication.

[Lokalise](https://lokalise.com/) propose une localisation collaborative, la gestion de la traduction et des intégrations développeurs. La proposition de Glossia est plus précise : gardez le flux de travail du dépôt, apportez vos propres identifiants de modèle, réutilisez vos contrôles existants et inspectez le système qui effectue le travail.

## ## Pourquoi choisir Glossia

| Votre priorité | L'avantage de Glossia |
|---|---|
| Concilier la vitesse de livraison logicielle | Les modifications de source pilotent le travail de traduction ; les sorties proposées reviennent via un flux de révision du dépôt. |
| Maîtriser l'implémentation | Une source publique rend le traitement inspectable et soutient la modification et l'hébergement autonome sous les termes de la licence. |
| Utilisez vos propres jetons de modèle | Les identifiants du fournisseur limités au compte vous permettent de choisir les modèles pris en charge sans injecter de secrets dans Git. |
| Validez le contenu réel de l'application | Les scripts du dépôt peuvent vérifier le candidat là où l'application s'attend à le trouver. |
| Maintenez une frontière de révision claire | Les pull requests maintiennent les modifications linguistiques visibles dans les mêmes outils utilisés pour examiner le produit. |

## Maintenez les modifications linguistiques attachées aux modifications de produit.

Un nouveau message d'interface utilisateur ou une section de documentation n'est pas une tâche de traduction isolée. Il appartient à une révision de produit, utilise sa terminologie et doit fonctionner avec sa structure.

Glossia lit la configuration `L10N.md` du dépôt, utilise les modifications de contenu et de contexte pour identifier les traductions obsolètes et propose des mises à jour pour examen. Les réviseurs voient les fichiers réels et les diffs ; la chaîne de publication reste la vôtre.

Lokalise possède également de l'automatisation et des intégrations Git. La distinction de Glossia est le système de référence prévu : votre dépôt possède le contenu publié et ses règles de diffusion, tandis que Glossia fournit le contexte linguistique et les mécanismes de transformation.

## Apportez vos propres jetons plutôt que d'imposer un choix de modèle

Glossia vous permet de configurer les modèles pris en charge en utilisant vos propres jetons API fournisseur. Un dépôt utilise un gestionnaire de modèle stable, donc la rotation des identifiants ou la mise à jour du modèle derrière ce gestionnaire ne nécessite pas de changer chaque projet.

La configuration imbriquée et l'orientation locale spécifique peuvent sélectionner un modèle configuré différent pour une zone ou une langue particulière. Il s'agit d'un choix explicite, pas d'une promesse de basculement automatique du fournisseur. Voir [Modèles de compte](./account-models).

## Réutilisez la validation qui connaît déjà votre application.

Votre dépôt peut déjà savoir détecter les chaînes invalides, les fichiers malformés, les attributs de composants cassés ou une erreur de build de documentation. Glossia peut invoquer cette connaissance via une commande de validation configurée.

Le candidat est placé temporairement à son chemin de sortie réel pour la vérification. La cible précédente est restaurée après chaque tentative de validation, et le candidat accepté est écrit par la suite. La sortie rejetée passe par le budget de récupération configuré plutôt que d'être acceptée simplement parce que le texte semble plausible.

Les vérifications structurelles et de dépôt ne prouvent pas que chaque phrase est correcte. Elles complètent la révision linguistique humaine et rendent cette révision partie d'un changement livrable. Voir [L10N.md](/docs/reference/l10n-md) et [Récupération de traduction](./translation-recovery).

## Source publique et sorties propriétaires du dépôt.

Glossia suit un modèle open core. Le cœur utilise [Apache-2.0](https://github.com/glossia/glossia/blob/main/LICENSE-APACHE), qui autorise l'utilisation commerciale, la modification, la distribution, l'auto-hébergement et les services hébergés concurrents selon ses conditions. Le code de `ee/` est consultable, mais n'est pas open source. Il relève d'une [licence Enterprise](https://github.com/glossia/glossia/blob/main/ee/LICENSE.md) distincte et son utilisation en production nécessite un accord commercial écrit.

Plus important pour la distribution quotidienne, vos sorties traduites restent dans Git. Vous n'avez pas besoin d'une session de modification dans un autre produit simplement pour publier les fichiers existants que vous possédez.

Lokalise peut convenir à une équipe souhaitant une édition centralisée dans le navigateur et une coordination de la localisation. Glossia est le choix lorsque **propriété du dépôt, vos propres jetons de modèle et contrôles de produit existants** sont le flux de travail que vous souhaitez conserver.

Testez une modification représentative avant de passer à un autre système. Cette page ne promet pas de migration automatique ni de parité fonctionnelle, ni de déclamer que Lokalise manque d'automatisation ou d'options de fournisseur. Voir [La documentation de Lokalise](https://docs.lokalise.com/) pour ses capacités actuelles.
