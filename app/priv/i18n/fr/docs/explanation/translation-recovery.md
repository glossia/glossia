%{
  title: "Récupération de la traduction",
  summary:
    "Comment Glossia conserve le Markdown intact et se remet de la limitation du débit des fournisseurs et des traductions interrompues.",
  category: "explication",
  section: "translation",
  order: 8
}
---

Glossia valide le contenu traduit avant de le publier. La récupération préserve cette exigence : une nouvelle tentative doit toujours préserver la structure source et les placeholders requis, et chaque fichier assemblé passe ses commandes de validation configurées.

## Traduction Markdown

Glossia ne re-rend jamais un document Markdown traduit. Il analyser la source seulement pour trouver son texte : paragraphes, titres, éléments de liste, cellules de tableau, les attributs visibles du lecteur des composants et du HTML (`title`, `details`, `alt`, `label`, `description`, `summary`, `placeholder`, `aria-label`, `caption`), et le texte d'un élément HTML `<summary>`. Chaque traduction est réécrite dans les octets exacts que sa source occupait, de sorte que le code, les destinations de liens, les composants, les alertes GitHub, les ancres de titres explicites telles que `{#install}`, les marqueurs de liste et les lignes vides restent identiques octet par octet.

Chaque paragraphe ou titre est traduit comme une phrase complète. Le formatage en ligne devient des balises numérotées : `<gN>...</gN>` autour des mots liés ou soulignés, et `<gN/>` pour le contenu qui ne doit pas changer, tel que le code en ligne ou un composant. Le modèle peut déplacer les balises pour suivre l'ordre des mots de la langue cible, mais doit conserver chaque balise exactement une fois. Chaque demande porte également le document source environnant, et les traductions les plus récentes provenant du même fichier, à titre de référence.

L'unité qui perd ou invente une balise est retransmise de manière autonome, avec la raison, trois fois au maximum. Les unités qui reviennent valides sont conservées. Après assemblage, Glossia analyse le résultat et compare sa structure à la source. Une traduction qui se transformerait en titre, liste ou soulignement par elle-même a son texte échappé, ce qui n'exige pas d'appel de modèle supplémentaire.

## Traduction de catalogue

Avant la traduction, les catalogues Gettext sont analysés en chaînes de caractères. Les requêtes transmettent au plus huit chaînes, avec un objectif de lotissement de 8 000 octets. Une chaîne plus grande reste intacte. Le modèle retourne un tableau contenant le même nombre de chaînes dans le même ordre. Glossia vérifie les variables d'interpolation et rejette les traductions vides.

Les en-têtes sont construites en code en utilisant les règles de pluriel de la langue cible. Les identifiants de messages source, les commentaires et la structure du catalogue proviennent de la source analysée. Si un lot retourne un contenu au format incorrect, Glossia le retente une fois, puis le divise dans des lots plus petits. Les lots voisins réussis n'ont pas besoin d'être retraduits.

## Limitation de débit du fournisseur

Glossia coordonne les requêtes de traduction qui utilisent la même authentification et le même modèle. Une réponse de limitation de débit prolonge leur délai d'attente partagé et augmente l'écart entre les nouvelles requêtes. Le trafic réussi réduit progressivement cet écart après une minute sans limitation de débit. Les requêtes déjà en cours sont autorisées à se terminer.

Les indices de tentative de réessai du fournisseur sont des délais minimums. Les échecs répétés augmentent également le backoff, jusqu'à un délai de base de 30 secondes plus un jitter ; un indice de fournisseur plus long a la priorité, limité à cinq minutes. L'entête `x-ratelimit-reset` de Together est reconnue à côté de `retry-after`.

Après huit tentatives de requête infructueuses, l'exécution du référentiel arrête le démarrage de nouveaux fichiers. Une continuation différée hérite de la branche de traduction et reprend ses tâches inachevées. La tentative précédente reste visible dans l'historique de la session, liée via la continuation. Les délais augmentent d'une minute à cinq minutes, avec un maximum de six continuations automatiques. Les sessions actives plus récentes ont la priorité, et les sessions annulées ne sont jamais réactivées. Les échecs de validation seuls ne planifient pas la récupération du fournisseur.

## Récupération après une mise à jour du moteur

Une session possède deux versions indépendantes : le commit du référentiel en cours de traduction et l'image du moteur de traduction l'exécutant. Dans Kubernetes, chaque tâche fixe le digest intégral exact de l'image du réplica web qui l'a planifiée. Les tâches survivent aux déploiements web et n'échangent jamais de code à mi-parcours d'une traduction. Une tâche planifiée juste avant un déploiement peut donc se terminer sur le moteur précédent même après la mise à jour de l'application web. Les détails de la session affichent le digest du moteur ; les sessions plus anciennes sans cette provenance affichent « Non enregistré. »

Toutes les cinq minutes, Glossia vérifie si son déploiement est pleinement déployé. Uniquement un travailleur de cette version saine peut planifier la récupération du moteur. Si la dernière session d'un projet était en file d'attente avant que ce déploiement soit achevé, s'exécutait sur un digest de moteur précédent enregistré et a échoué par la suite dans les six dernières heures, Glossia peut créer une continuation sur la version actuelle. L'utilisation du temps d'attente couvre également les tâches qui attendent la capacité et ne démarrent qu'après le déploiement. Un digest d'image différent ne déclenche pas des rétentives d'échecs ordinaires après des déploiements non liés. Les fichiers complétés et la demande de fusion de traduction ouverte sont conservés ; seul le travail inachevé est retraduit. Les continuations de déploiement en file d'attente attendent pendant qu'un déploiement est en cours, pour un maximum de 15 minutes. Des échecs d'API ou de permission de Kubernetes stoppent le lancement avec une erreur explicite plutôt que d'être confondus avec un déploiement en cours.

La récupération est délibérément limitée : la session doit avoir terminé avec un échec de validation d'élément enregistré, et chaque élément échoué dans sa tentative la plus récente doit déclarer un échec de structure Markdown, de contenu préservé ou d'unité Markdown. Les tentatives interrompues ou partiellement annulées ne répondent pas aux critères. Les erreurs du fournisseur, le crédit épuisé, les identifiants rejetés, les échecs de publication, les erreurs de lecture source, les échecs de commande de validation externe et les causes inconnues ne sont pas retravaillés par un déploiement. Les sessions réussies, actives, annulées, remplacées et sans version sont également ignorées. Une session plus récente gagne toujours, même si l'utilisateur l'a annulée.

Une session obtient au plus une continuation sur une version de moteur différente, avec au maximum trois continuations de version dans une lignée. Si le nouveau moteur échoue toujours, il n'est pas retravaillé à nouveau sur la même image, y compris après un retour en arrière. La lignée conserve ses digests de moteur tentés précédemment, et le lanceur les vérifie à nouveau avant de créer une tâche en file d'attente. Les limites de récupération du fournisseur existantes sont préservées lors des continuations de version. Les balises d'image mutables et les déploiements sans identité de version configurée n'activent pas la récupération automatique du moteur.

## Progrès durable

Les fichiers terminés et leurs fichiers de verrouillage sont publiés sur la branche de traduction par lots : un commit pour chaque 25 fichiers, ou tous les 15 minutes, et un commit final lorsque l'exécution se termine. Chaque push exécute les vérifications de pull request du dépôt, de sorte que le traitement par lots évite qu'une grande exécution ne démarre une vérification par fichier. Un projet dispose d'une seule pull request de traduction : un nouveau commit sur la branche par défaut reprend celle ouverte, et ne traduit que les modifications depuis lors. Une fois cette pull request fusionnée ou fermée, l'exécution suivante lance une nouvelle tâche. Dans les fichiers non terminés, les segments validés localement et les lots de récupération sont également enregistrés dans la base de données pendant sept jours. Ces points de contrôle survivent à l'arrêt d'un processus travailleur. Ils sont limités au compte, projet, entrée de document, clé active et modèle, contexte, et segment ou tentative de réparation.

L'exération reprise ne peut réutiliser un segment que lorsque ses entrées conviennent toujours. Elle valide toujours le document final assemblé à nouveau. Les réponses du modèle rejetées ne sont pas des points de contrôle. Un échec de validation au niveau du document déclenche une tentative de réparation distincte car le validateur peut ne pas identifier un segment responsable unique.

Les points de contrôle expirés et les enregistrements de régulation du fournisseur inactifs sont supprimés par le travailleur de récupération de session programmé. Il s'agit d'enregistrements opérationnels ; les utilisateurs n'ont pas besoin de les ajouter à leur dépôt ou de les configurer dans `L10N.md`.
