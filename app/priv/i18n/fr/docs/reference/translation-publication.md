%{
  title: "Publication de la traduction",
  summary:
    "Réutilisation des pull requests, regroupement et la limite de push sur l'ensemble du projet.",
  category: "référence",
  section: "translation",
  order: 10
}
---

Glossia conserve une seule demande d'intégration de traduction ouverte par projet. Les nouveaux commits de la branche principale continuent sur leur branche plutôt que d'ouvrir une demande d'intégration pour chaque commit source. Une nouvelle demande d'intégration est créée après que la précédente ait été fusionnée ou fermée. Une publication fermée reçoit un nouveau nom de branche, y compris lors de la reprise du même commit source ; ses sorties refusées ne sont pas réutilisées comme travail terminé.

La synchronisation des sources se produit dans un checkout local effaçable avant l'évaluation, préservant les traductions achevées et les fichiers de verrouillage de la branche ouverte. Une exécution qui ne trouve aucune modification de sortie ou de fichier de verrouillage ne fait pas avancer la branche à distance uniquement pour rattraper la branche principale, et ne consomme pas un slot de publication. Lorsqu'un lot est prêt, la synchronisation des sources et les modifications validées sont publiées ensemble dans une seule mise à jour de branche non forcée. Le commit conserve à la fois la publication précédente et le commit source évalué comme ancêtres.

La publication et le remplacement de session partagent un verrouillage de projet soutenu par une base de données, y compris lorsqu'ils s'exécutent sur des répliques d'application différentes ou des exécuteurs détachés. Si un exécuteur a créé une demande d'intégration mais n'a pas pu sauvegarder ses métadonnées, la publication suivante récupère la demande d'intégration Glossia ouverte depuis GitHub avant d'en créer une autre. Une demande d'intégration ouverte n'est pas abandonnée lorsque sa branche est en conflit avec la source ou lorsque l'historique de la source est réécrit : la session échoue et conserve la publication existante pour résolution.

## Limite de pousse

La limite est fixe à **4 pousses par heure par projet**, partagée entre les sessions et les répliques. Elle n'est pas actuellement configurable.

Les pousses sont espacées régulièrement, non comptées dans des intervalles fixes d'heure d'horloge. Les mises à jour de branche sont séparées d'au moins 15 minutes. Le prochain intervalle commence lorsque l' tentative de publication se termine, de sorte qu'un lot lent ne puisse pas être suivi immédiatement par un lot rapide. Les lots intermédiaires, les tentatives de reprise et les vidages finaux partagent tous le même budget. Les tentatives d'échec ambiguës consomment également un slot, car GitHub aurait pu avancer la branche avant l'échec de la connexion. Le budget est stocké dans PostgreSQL et n'est pas réinitialisé par une nouvelle session ou par un redémarrage de processus.

Avant la publication, Glossia relis la tête à distance et fusionne à nouveau la source de la session localement. Cela préserve les lots antérieurs et détecte les conflits sans déplacer la branche. Si une mise à jour antérieure a réussi mais que sa réponse a été perdue, les modifications déjà présentes ne sont pas committées à nouveau ; les métadonnées de publication et la demande d'intégration sont récupérées sans autre mise à jour de branche. Si la référence a été créée mais que l'exécuteur s'est arrêté avant de créer sa demande d'intégration, une évaluation sans changement crée toujours la demande d'intégration manquante, sans consommer un slot de mise à jour de branche.

Un rattrapage distant inattendu n'est accepté que lorsque ses différences par rapport à l'arbre synchronisé attendu sont déjà présentes dans le lot en attente. D'autres modifications réalisées pendant l'évaluation échouent à publication plutôt que d'être écrasées ou de publier des traductions validées contre des entrées périmées. La demande d'intégration existante est conservée pour résolution.

## Groupement

Une exécution collecte les modifications de fichiers validées et demande la publication après 25 fichiers ou 15 minutes. Ces seuils ne contournent pas la limite de pousse. Pendant une période de refroidissement, des fichiers supplémentaires terminés rejoignent le lot en attente ; des modifications répétées sur le même chemin conservent le contenu le plus récent.

À la fin de l'exécution, le vidage final attend le même budget. La session reste active et envoie des battements de cœur en attendant. Elle vérifie périodiquement l'annulation et l'admission sans garder une transaction de base de données ouverte pendant sa période d'attente.
