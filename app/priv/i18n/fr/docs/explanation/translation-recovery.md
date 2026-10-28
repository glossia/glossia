%{
  title: "Récupération de traduction",
  summary:
    "Comment Glossia maintient le Markdown intact et se remet en route en cas de ralentissement du fournisseur et d'interruption des traductions.",
  category: "explication",
  section: "translation",
  order: 8
}
---

Glossia valide le contenu traduit avant de le publier. La récupération préserve cette exigence : une nouvelle tentative doit toujours préserver la structure de la source et les espaces réservés requis, et chaque fichier assemblé passe ses commandes de validation configurées.

## Traduction Markdown

Glossia ne re-rend jamais un document Markdown traduit. Il analyse la source uniquement pour trouver son texte : paragraphes, titres, éléments de liste, cellules de tableau, les attributs destinés à l'utilisateur des composants et HTML (`title`, `details`, `alt`, `label`, `description`, `summary`, `placeholder`, `aria-label`, `caption`), et le texte d'un HTML `<summary>`. Chaque traduction est réécrite dans les octets exacts que la source occupait, de sorte que le code, les destinations de liens, les composants, les alertes GitHub, les ancres explicites de titres comme `{#install}`, les marqueurs de liste et les lignes vides restent identiques octet par octet.

Chaque paragraphe ou titre est traduit en tant que phrase complète. La mise en forme en ligne devient des balises numérotées : `<gN>...</gN>` autour des mots liés ou mis en gras, et `<gN/>` pour le contenu qui ne doit pas changer, tel que le code en ligne ou un composant. Le modèle peut déplacer des balises pour suivre l'ordre des mots de la langue cible, mais doit garder chaque balise exactement une fois. Chaque demande transporte également le document source environnant, et les traductions les plus récentes du même fichier, pour référence.

Une unité qui supprime ou invente une balise est envoyée à nouveau seule, avec la raison, jusqu'à trois fois. Les unités valides sont conservées. Après l'assemblage, Glossia analyse le résultat et compare sa structure à la source. Une traduction qui se transformerait en titre, liste ou emphase toute seule fait échapper son texte, ce qui ne nécessite aucun autre appel de modèle.

## Traduction de catalogue

Les catalogues Gettext sont analysés en chaînes avant traduction. Les demandes transportent au maximum huit chaînes, avec une cible de regroupement de 8 000 octets. Une chaîne plus grande reste intacte. Le modèle renvoie un tableau avec le même nombre de chaînes dans le même ordre. Glossia vérifie les variables d'interpolation et rejette les traductions vides.

Les en-têtes sont construits en code en utilisant les règles de pluriel de la langue cible. Les identifiants de message source, les commentaires et la structure du catalogue proviennent de la source analysée. Si un lot renvoie un contenu malformé, Glossia le réessaie une fois, puis le divise en lots plus petits. Les lots voisins réussis n'ont pas besoin d'être traduits à nouveau.

## Limitation de débit du fournisseur

Glossia coordonne les demandes de traduction qui utilisent la même identité d'accès et le même modèle. Une réponse de limitation de débit prolonge leur délai de réfrigération partagé et augmente l'espacement entre les nouvelles demandes. Un trafic réussi réduit progressivement cet espacement après une minute sans limitation. Les demandes déjà en cours sont autorisées à se terminer.

Les indices de réessai du fournisseur sont des délais minimaux. Les échecs répétés augmentent également le backoff, jusqu'à un délai de base de 30 secondes plus jitter ; un indice de fournisseur plus long prend le pas, plafonné à cinq minutes. Le `x-ratelimit-reset` de Together est reconnu aux côtés de `retry-after`.

Après huit tentatives de demande infructueuses, l'exécution de dépôt cesse de lancer de nouveaux fichiers. Une continuation différée hérite de la branche de traduction et reprend son travail inachevé. La tentative précédente reste visible dans l'historique des sessions, liée par la continuation. Les délais augmentent d'une minute à cinq minutes, avec au maximum six présidentielles automatiques. Les sessions actives plus récentes prennent le pas, et les sessions annulées ne sont jamais redressées. Les échecs de validation seuls ne planifient pas la récupération du fournisseur.

## Récupération après un déploiement de moteur

**Édition : Enterprise.** Les vérifications du déploiement Kubernetes et la récupération après une mise à jour du moteur décrites dans cette section nécessitent des [exécuteurs de traduction isolés](/fr/docs/reference/isolated-translation-runners). La récupération de Markdown, des catalogues et des fournisseurs, ainsi que la progression durable décrites ailleurs sur cette page restent disponibles dans Community.

Une session a deux versions indépendantes : le commit de dépôt en cours de traduction et l'image de moteur de traduction l'exécutant. Dans Kubernetes, chaque job épingle le digest d'image exact du réplica web qui l'a programmé. Les Job survivent aux déploiements web et ne basculent jamais le code à moitié travers une traduction. Un job programmé juste avant un déploiement peut donc finir sur le moteur précédent même après que l'application web ait été mise à jour. Les détails de session affichent le digest moteur ; les sessions plus anciennes sans cette provenance affICHent « Non enregistré. »

Toutes les cinq minutes, Glossia vérifie si son déploiement s'est entièrement déployé. Uniquement un travailleur de cette version saine peut programmer la récupération du moteur. Si la dernière session d'un projet a été mise en file d'attente avant ce déploiement terminé, a fonctionné sur un digest d'ancien moteur enregistré, et a échoué par la suite dans les six dernières heures, Glossia peut créer une continuité sur la version actuelle. L'utilisation du temps d'attente couvre également les jobs qui attendent la capacité et ne démarrent qu'après le déploiement. Un différent digest d'image seul ne déclenche pas les réessais des échecs ordinaires après des déploiements non liés. Les fichiers terminés et la pull request de traduction ouverte sont conservés ; seul le travail inachevé est traduit à nouveau. Les continuits de version en file d'attente attendent pendant qu'un déploiement est en cours, pendant au maximum 15 minutes. Les échecs de l'API Kubernetes ou des permissions arrêtent le lancement avec une erreur explicite plutôt que d'être pris pour un déploiement en cours.

La récupération est intentionnellement étroite : la session doit avoir terminé par un échec de validation d'objet enregistré, et chaque objet échoué dans sa dernière tentative doit signaler une structure Markdown, un contenu préservé ou un échec d'unité Markdown. Les tentatives interrompues ou annulées partiellement ne sont pas éligibles. Les erreurs de fournisseur, le crédit épuisé, les identifiants rejetés, les échecs de publication, les erreurs de lecture de source, les échecs de commande de validation externe, et les causes inconnues ne sont pas réessayés par un déploiement. Les sessions réussies, actives, annulées, supplantées et sans version sont également laissées en l'état. Une session plus récente gagne toujours, même si l'utilisateur l'a annulée.

Une session obtient au plus une continuité sur une version différente de moteur, avec au plus trois continuités de version dans une lignée. Si le nouveau moteur échoue toujours, il n'est pas réessayé encore sur cette même image, y compris après un rollback. La lignée conserve ses digests de moteur précédemment essayés, et le lanceur les vérifie à nouveau avant de créer une job en file d'attente. Les limites de récupération de fournisseur existantes sont conservées à travers les continuités de version. Les balises d'image modifiables et les déploiements sans identité de version configurée n'activent pas la récupération automatique de moteur.

## Progression durable

Les fichiers terminés et leurs lockfiles sont publiés dans la branche de traduction par lots : un commit pour chaque 25 fichiers, ou toutes les 15 minutes, et un commit final lorsque l'exécution se termine. Chaque push exécute les contrôles de pull request du référentiel, donc le groupement empêche une grande exécution de lancer une vérification par fichier. Un projet dispose d'une unique pull request de traduction : un nouveau commit sur la branche par défaut reprend l'exécution ouverte, et traduit uniquement les modifications intervenues depuis. Une fois que cette pull request est fusionnée ou fermée, la prochaine exécution en lance une nouvelle. Au sein des fichiers inachevés, les segments validés localement et les lots de récupération sont également sauvegardés dans la base de données pendant sept jours. Ces points de contrôle survivent à l'arrêt d'un processus de travailleur. Ils sont limités au compte, au projet, à l'entrée du document, à l'identifiant effectif et au modèle, au contexte, ainsi qu'à la tentative de segment ou de réparation.

Une exécution reprise peut réutiliser un segment uniquement lorsque ses entrées correspondent toujours. Elle valide toujours à nouveau le document final assemblé. Les réponses du modèle rejetées ne sont pas des points de contrôle. Un échec de validation au niveau du document déclenche une tentative de réparation séparée parce que le validateur peut ne pas identifier un segment responsable unique.

Les points de contrôle expirés et les enregistrements de cadencement fournisseur inactifs sont supprimés par le travailleur de récupération de session programmé. Ce sont des enregistrements opérationnels ; les utilisateurs n'ont pas besoin de les ajouter à leur référentiel ou de les configurer dans `L10N.md`.
