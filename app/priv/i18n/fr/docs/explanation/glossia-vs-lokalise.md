%{
  title: "Glossia contre Lokalise",
  summary:
    "Maintenez la localisation de produit dans votre pipeline de livraison, avec une source publique, vos propres tokens de modèle et une validation native.",
  category: "explication",
  markdown_only: true,
  section: "translation",
  order: 21
}
---

**Choisissez Glossia lorsque le dépôt de produit doit rester l'autorité pour le contenu multilingue.** Les chaînes, la documentation, la configuration et leurs vérifications évoluent déjà avec votre application. Glossia maintient les modifications linguistiques attachées à cette évolution au lieu de demander à votre équipe de faire d'un éditeur hébergé l'autorité de publication.

[Lokalise](https://lokalise.com/) offre une localisation collaborative, une gestion de traduction et des intégrations pour développeurs. La proposition de Glossia est plus spécifique : conservez le flux de travail du dépôt, apportez vos propres identifiants de modèle, réutilisez vos vérifications existantes et inspectez le système qui réalise le travail.

## Pourquoi choisir Glossia

| Votre priorité | L'avantage de Glossia |
|---|---|
| Adapter la vitesse de livraison logicielle | Les modifications de source entraînent le travail de traduction ; les sorties proposées reviennent par le biais d'un flux de travail de revue de dépôt. |
| Posséder l'implémentation | La source publique rend le traitement inspectable et prend en charge la modification et l'hébergement sous licence. |
| Utilisez vos propres jetons de modèle | Les identifiants du fournisseur liés au compte vous permettent de choisir les modèles pris en charge sans mettre de secrets dans Git. |
| Validez le contenu réel de l'application | Les scripts de dépôt peuvent vérifier le candidat là où l'application s'attend à le trouver. |
| Préservez une frontière de revue claire | Les pull requests gardent les modifications linguistiques visibles dans le même outil utilisé pour examiner le produit. |

## Gardez les modifications linguistiques attachées aux modifications de produit

Un nouveau message d'interface utilisateur ou une section de documentation n'est pas une tâche de traduction isolée. Elle appartient à une révision de produit, utilise sa terminologie et doit fonctionner avec sa structure.

Glossia lit la configuration `L10N.md` appartenant au dépôt, utilise les modifications de contenu et de contexte pour identifier les traductions obsolètes et propose des mises à jour pour examen. Les réviseurs voient les fichiers réels et les diffs ; le pipeline de publication reste le vôtre.

Lokalise dispose également d'automatisation et d'intégrations Git. La distinction de Glossia est le système d'enregistrement prévu : votre dépôt possède le contenu publié et ses règles de livraison, tandis que Glossia fournit le contexte linguistique et les mécanismes de transformation.

## Apportez vos propres jetons au lieu de câbler un choix de modèle

Glossia vous permet de configurer les modèles pris en charge en utilisant vos propres jetons d'API fournisseur. Un dépôt utilise une référence de modèle stable, donc la rotation des identifiants ou la mise à jour du modèle derrière cette référence ne nécessite pas de modifier chaque projet.

La configuration imbriquée et les conseils spécifiques à la localisation peuvent sélectionner un modèle configuré différent pour un domaine ou une langue particulier. C'est une sélection explicite, pas une promesse de basculement automatique du fournisseur. Voir [Modèles de compte](./account-models).

## Réutilisez la validation qui connaît déjà votre application

Votre dépôt peut déjà savoir comment détecter les chaînes invalides, les fichiers malformés, les attributs de composants brisés ou un échec de compilation de documentation. Glossia peut invoquer cette connaissance via une commande de validation configurée.

Le candidat est temporairement placé à son vrai chemin de sortie pour la vérification. L'objectif précédent est restauré après chaque tentative de validation, et le candidat accepté est écrit ensuite. La sortie refusée passe par le budget de récupération configuré plutôt que d'être accepté simplement parce que le texte semble plausible.

Les vérifications structurelles et de dépôt ne prouvent pas que chaque phrase est correcte. Elles complètent la révision linguistique humaine et rendent cette révision partie d'un changement livrable. Voir [L10N.md](/docs/reference/l10n-md) et [Récupération de traduction](./translation-recovery).

## Source publique et sorties appartenant au dépôt

L'implémentation de Glossia est disponible pour examen, modification et auto-hébergement sous [O'Saasy](https://github.com/glossia/glossia/blob/main/LICENSE.md). Cette licence restreint les services hébergés concurrents et n'est pas une licence open source non restreinte.

Plus important encore pour la livraison quotidienne, vos sorties traduites restent dans Git. Vous n'avez pas besoin d'une session d'édition dans un autre produit simplement pour publier les fichiers existants que vous possédez.

Lokalise peut convenir à une équipe qui souhaite une édition centralisée dans le navigateur et une coordination de la localisation. Glossia est le choix lorsque **la propriété du dépôt, vos propres jetons de modèle et les vérifications de produit existantes** constituent le flux de travail que vous souhaitez conserver.

Testez un changement représentatif avant de changer de système. Cette page ne promet pas la migration automatique ou la parité fonctionnelle, ni ne déclare que Lokalise manque d'automatisation ou de toutes les options de fournisseur. Consultez [la documentation de Lokalise](https://docs.lokalise.com/) pour ses capacités actuelles.
