%{
  title: "Publication de traduction",
  summary:
    "Réutilisation des pull requests, le traitement par lots et la limite de push au niveau du projet.",
  category: "référence",
  section: "translation",
  order: 10
}
---

Glossia conserve une seule demande de fusion de traduction ouverte par projet. Les nouveaux commits de la branche par défaut prolongent la branche plutôt que d'ouvrir une demande de fusion pour chaque commit de source. Une nouvelle demande de fusion est créée après que la précédente soit fusionnée ou fermée.

Publication et remplacement de session partagent un verrou de projet soutenu par une base de données, y compris lorsqu'ils s'exécutent sur des réplicas d'application différents ou des exécuteurs détachés. Si un exécuteur a créé une demande de fusion mais n'a pas pu sauvegarder ses métadonnées, la prochaine publication récupère la demande de fusion Glossia ouverte à partir de GitHub avant d'en créer une autre. Une demande de fusion ouverte n'est pas abandonnée lorsque sa branche est en conflit avec la source ou que l'historique de la source est réécrit : la session échoue et conserve la publication existante pour résolution.

## Limite de pousses

La limite est fixée à **4 pousses par heure par projet**, partagée entre les sessions et les réplicas. Elle n'est pas actuellement configurable.

Les pousses sont régulièrement espacées, elles ne sont pas comptabilisées dans des créneaux d'heure fixes. Les mises à jour de branche sont au moins séparées par 15 minutes. L'intervalle suivant débute lorsque la tentative de publication est terminée, de sorte qu'un lot lent ne peut pas être suivi immédiatement par un lot rapide. Les fusions de branche source, les lots intermédiaires, les reprises et les vidages finaux partagent tous le même budget. Les tentatives échouées ambiguës consomment également un créneau, car GitHub peut avoir avancé la branche avant qu'une connexion n'échoue. Ce budget est stocké dans PostgreSQL et n'est pas réinitialisé par une nouvelle session ou un redémarrage du processus.

## Groupement

Une exécution collecte les changements de fichiers validés et demande une publication après 25 fichiers ou 15 minutes. Ces seuils ne contournent pas la limite des pousses. Durant une période de refroidissement, des fichiers supplémentaires terminés rejoignent le lot en attente ; les changements répétés sur le même chemin conservent le contenu le plus récent.

À la fin de l'exécution, le vidage final attend le même budget. La session reste active et envoie des battements de cœur en attendant. Elle vérifie périodiquement l'annulation et l'admission sans maintenir une transaction de base de données ouverte en veille.
