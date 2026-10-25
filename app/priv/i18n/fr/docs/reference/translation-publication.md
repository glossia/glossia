%{
  title: "Publication de traduction",
  summary: "Réutilisation de pull requests, regroupement et la limite de push du projet.",
  category: "référence",
  section: "translation",
  order: 10
}
---

Glossia conserve un seul pull request de traduction ouvert par projet. Les nouveaux commits de la branche principale prolongent la sienne plutôt que d'ouvrir un pull request pour chaque commit de source. Un nouveau pull request est créé après que la précédente est fusionnée ou fermée.

La publication et le remplacement de session partagent un verrou de projet s'appuyant sur une base de données, y compris lorsqu'ils s'exécutent sur différentes réplicas d'application ou des exécuteurs détachés. Si un exécuteur a créé un pull request mais n'a pas pu sauvegarder ses métadonnées, la publication suivante récupère le pull request de Glossia ouvert sur GitHub avant d'en créer un autre. Un pull request ouvert n'est pas abandonné lorsque sa branche est en conflit avec la source ou lorsque l'historique de la source est réécrit : la session échoue et conserve la publication existante en attente de résolution.

## Limite d'envoi

La limite est fixée à **4 envois par heure par projet**, partagée parmi les sessions et les exécuteurs. Elle n'est pas actuellement configurable.

Les envois sont espacés de manière régulière, sans compter d'intervalles fixes d'heure. Les mises à jour de la branche sont espacées d'au moins 15 minutes. Le prochain intervalle commence une fois une tentative de publication terminée, de sorte qu'un lot lent ne peut pas être immédiatement suivi par un lot rapide. Les fusions de branche source, les lots intermédiaires, les re tentatives et les vidages finals partagent le même budget. Les tentatives d'échec ambiguës consomment également un créneau, car GitHub peut avoir avancé la branche avant l'échec de la connexion. Le budget est stocké dans PostgreSQL et n'est pas réinitialisé par une nouvelle session ou un redémarrage du processus.

## Traitement par lots

Une exécution collecte les modifications de fichiers validées et demande la publication après 25 fichiers ou 15 minutes. Ces seuils ne contournent pas la limite d'envoi. Pendant la période de refroidissement, les fichiers supplémentaires terminés rejoignent le lot en attente ; les modifications répétées au même chemin conservent le dernier contenu.

À la fin de l'exécution, le vidage final attend le même budget. La session reste active et envoie des battements de cœur pendant l'attente. Elle révérifie l'annulation et l'admission périodiquement sans maintenir une transaction de base de données ouverte en veille.
