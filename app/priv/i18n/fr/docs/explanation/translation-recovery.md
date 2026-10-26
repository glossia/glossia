%{
  title: "Récupération de traduction",
  summary:
    "Comment Glossia maintient Markdown intact et se remet de la limitation de débit des fournisseurs et des traductions interrompues.",
  category: "Explication",
  section: "translation",
  order: 8
}
---

Glossia valide le contenu traduit avant de le publier. La récupération préserve cette exigence : une nouvelle tentative doit toujours préserver la structure source et les placeholders requis, et chaque fichier assemblé passe ses commandes de validation configurées.

## ## Traduction Markdown

Glossia ne re-render jamais un document Markdown traduit. Il analyse uniquement la source pour en extraire le texte : les paragraphes, les en-têtes, les éléments de liste, les cellules de tableau, les attributs orientés lecteur des composants et du HTML (`title`, `details`, `alt`, `label`, `description`, `summary`, `placeholder`, `aria-label`, `caption`), ainsi que le texte d'un élément HTML `<summary>`. Chaque traduction est réécrite dans exactement les mêmes octets que ceux occupés par sa source, de sorte que le code, les destinations des liens, les composants, les alertes GitHub, les ancres d'en-tête explicites telles que `{#install}`, les marqueurs de listes et les lignes vides restent identiques, octet par octet.

Chaque paragraphe ou en-tête est traduit sentence par sentence. Le formatage en ligne devient des balises numérotées : `<gN>...</gN>` autour des mots liés ou soulignés, et `<gN/>` pour le contenu qui ne doit pas changer, comme le code en ligne ou un composant. Le modèle peut déplacer des balises pour suivre l'ordre des mots de la langue cible, mais doit garder chaque balise exactement une fois. Chaque demande transporte également le document source environnant, ainsi que les traductions les plus récentes provenant du même fichier, à titre de référence.

Une unité qui perd ou invente une balise est envoyée à nouveau seule, avec la raison, jusqu'à trois fois. Les unités valides sont conservées. Après assemblage, Glossia analyse le résultat et compare sa structure à la source. Une traduction qui se transformerait en en-tête, liste ou soulignement toute seule a son texte échappé, ce qui ne nécessite aucun appel de modèle supplémentaire.

## ## Traduction de catalogue

Les catalogues Gettext sont analysés en chaînes de caractères avant la traduction. Les demandes transportent au maximum huit chaînes, avec un objectif de regroupement de 8 000 octets. Une chaîne plus grande reste intacte. Le modèle renvoie un tableau contenant le même nombre de chaînes dans le même ordre. Glossia vérifie les variables d'interpolation et rejette les traductions vides.

Les en-têtes sont construits dans le code en utilisant les règles de pluriel de la localized cible. Les identifiants de messages source, les commentaires et la structure du catalogue proviennent de la source analysée. Si un lot retourne du contenu malformé, Glossia le retente une fois, puis le divise en lots plus petits. Les lots voisins réussis n'ont pas besoin d'être traduits à nouveau.

## ## Throttling du fournisseur

Glossia coordonne les demandes de traduction qui utilisent le même identifiant et le même modèle. La réponse limitant le débit prolonge leur délai de refroidissement commun et augmente l'espacement entre les nouvelles demandes. Le trafic réussi réduit progressivement cet espacement après une minute sans throttling. Les demandes déjà en cours sont autorisées à se terminer.

Les indices de re-tentative du fournisseur constituent des délais minimums. Les échecs répétés augmentent également le backoff, jusqu'à un délai de base de 30 secondes plus jitter ; un indice de fournisseur plus long prend le dessus, plafonné à cinq minutes. L'en-tête `x-ratelimit-reset` de Together est reconnu aux côtés de `retry-after`.

Après huit tentatives de demande infructueuses, l'exécution sur le référentiel arrête le lancement de nouveaux fichiers. Une continuation différée hérite de la branche de traduction et reprend son travail inachevé. La tentative précédente reste visible dans l'historique de session, reliée par la continuation. Les délais augmentent d'une minute à cinq minutes, avec au maximum six continuations automatiques. Les sessions actives plus récentes ont la priorité, et les sessions annulées ne sont jamais reprises. Les échecs de validation seuls ne déclenchent pas la récupération du fournisseur.

## ## Récupération après une version du moteur

Une session dispose de deux versions indépendantes : la confirmation du référentiel en cours de traduction et l'image du moteur de traduction l'exécutant. Dans Kubernetes, chaque job fixe le digest d'image exact du réplica web qui l'a programmé. Les jobs survivent aux déploiements web et ne changent jamais de code à mi-chemin d'une traduction. Un job programmé juste avant un déploiement peut donc se terminer sur l'ancien moteur même après que l'application web ait été mise à jour. Les détails de la session montrent le digest du moteur ; les sessions plus anciennes sans cette origine affichent « N'enregistré. »

Toutes les cinq minutes, Glossia vérifie si son déploiement a roulement complet. Seule une tâche rentrée de cette version saine peut programmer la récupération du moteur. Si la session la plus récente d'un projet a été mise en file d'attente avant la fin de ce déploiement, a fonctionné sur un digest du moteur plus ancien enregistré, et a échoué ensuite dans les six dernières heures, Glossia peut créer une continuation sur la version actuelle. L'utilisation du temps d'attente couvre également les jobs qui attendent la capacité et n'ont instruments démarré qu'après le déploiement. Un digest d'image différent seul ne déclenche pas les re-tentatives des échecs ordinaires après des déploiements non liés. Les fichiers terminés et la pull request de traduction ouverte sont repris ; seul le travail inachevé est traduit à nouveau. Les continuations de version mises en file d'attente attendent pendant qu'un déploiement est en cours, pour un maximum de 15 minutes. Les échecs d'API Kubernetes ou de permission arrêtent le lancement avec une erreur explicite plutôt que d'être confondus avec un déploiement en cours.

La récupération est délibérément restrictive : la session doit se terminer par un échec de validation enregistré pour un élément, et chaque élément échoué de sa dernière tentative doit signaler un échec de structure Markdown, de contenu préservé ou d'unité Markdown. Les tentatives interrompues ou partiellement annulées ne remplissent pas les conditions. Les erreurs du fournisseur, le crédit épuisé, les identifiants rejetés, les échecs de publication, les erreurs de lecture de source, les échecs de commandes de validation externes, et les causes inconnues ne sont pas re-tentés par un déploiement. Les sessions réussies, actives, annulées, obsolètes et sans version sont également laissées de côté. Une session plus récente gagne toujours, même si l'utilisateur l'a annulée.

Une session reçoit au plus une continuation sur une version différente du moteur, avec au plus trois continuations de version dans une lignée. Si le nouveau moteur échoue toujours, il n'est pas re-tenté à nouveau sur cette même image, y compris après un retour en arrière. La lignée conserve ses digests de moteur précédemment essayés, et le lanceur les vérifie à nouveau avant de créer un job enfile d'attente. Les limites de récupération du fournisseur existantes sont préservées à travers les continuations de version. Les balises d'image modifiables et les déploiements sans une identité de version configurée n'activent pas la récupération automatique du moteur.

## ## Progression durable

Les fichiers terminés et leurs fichiers de verrouillage sont publiés sur la branche de traduction par lots : un commit pour chaque 25 fichiers, ou toutes les 15 minutes, et un commit final lorsque l'exécution se termine. Chaque push exécute les vérifications de pull request du dépôt, de sorte que le regroupement empêche de lancer une exécution de vérification par fichier. Un projet dispose d'une unique pull request de traduction : un nouveau commit sur la branche par défaut prolonge celle qui est ouverte, et ne traduit que ce qui a changé depuis. Once that pull request is merged or closed, the next run starts a new one. -> Once that pull request is merged or closed, l'exécution suivante démarre une nouvelle exécution. Au sein des fichiers inachevés, les segments validés localement et les lots de récupération sont également sauvegardés dans la base de données pendant sept jours. Ces points de contrôle survivent à l'arrêt d'un processus travailleur. Elles sont limitées au compte, au projet, à l'entrée du document, à l'identifiant et modèle effectif, au contexte, et au segment ou tentative de réparation.

Une reprise d'exécution peut réutiliser un segment seulement lorsque ses entrées correspondent toujours. Elle valide à nouveau le document final assemblé. Les réponses du modèle rejetées ne sont pas des points de contrôle. Un échec de validation au niveau du document démarre une tentative de réparation distincte car le validateur peut ne pas identifier un seul segment responsable.

Les points de contrôle périmés et les enregistrements de régulation du fournisseur inactifs sont supprimés par le travailleur de récupération de session planifié. Il s'agit d'enregistrements opérationnels ; les utilisateurs n'ont pas besoin de les ajouter à leur dépôt ni de les configurer dans `L10N.md`.
