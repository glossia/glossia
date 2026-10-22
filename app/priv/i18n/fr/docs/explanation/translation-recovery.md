%{
  title: "Récupération de la traduction",
  summary:
    "Comment Glossia maintient le Markdown intact et se remet des ralentissements du fournisseur et des traductions interrompues.",
  category: "Explication",
  section: "translation",
  order: 8
}
---

Glossia valide le contenu traduit avant de le publier. La récupération préserve cette exigence : un réessai doit toujours préserver la structure de la source et les marqueurs de remplacement requis, et chaque fichier assemblé passe ses commandes de validation configurées.

## Traduction Markdown

Glossia ne re-rend jamais un document Markdown traduit. Il analyse la source uniquement pour trouver son corps de texte : paragraphes, titres, éléments de liste, cellules de tableau, les attributs visibles des composants et de l'HTML (`title`, `details`, `alt`, `label`, `description`, `summary`, `placeholder`, `aria-label`, `caption`) et le texte d'un élément HTML `<summary>`. Chaque traduction est réécrite dans les moindres octets occupés par la source, afin que le code, les destinations de liens, les composants, les alertes GitHub, les ancres explicites de titre telles que `{#install}`, les marqueurs de liste et les lignes vides restent identiques byte pour byte.

Chaque paragraphe ou titre est traduit dans son intégralité. La mise en forme en ligne devient des balises numérotées : `<gN>...</gN>` autour des mots liens ou mis en relief, et `<gN/>` pour le contenu qui doit rester inchangé, comme le code en ligne ou un composant. Le modèle peut déplacer les balises pour suivre l'ordre des mots du langage cible, mais doit conserver chaque balise exactement une fois. Chaque demande transporte également le document source environnant et les traductions les plus récentes du même fichier, pour référence.

Une unité qui perd ou invente une balise est envoyée à nouvelle, avec la raison, jusqu'à trois fois. Les unités validées sont conservées. Après assemblage, Glossia analyse le résultat et compare sa structure avec la source. Une traduction qui se transformerait en titre, liste ou mise en évidence par elle-même voit son corps de texte échappé, ce qui ne nécessite aucun appel de modèle supplémentaire.

## Traduction des catalogues

Les catalogues Gettext sont analysés en chaînes de caractères avant la traduction. Les demandes transportent au plus huit chaînes, avec un objectif de lot de 8 000 octets. Une chaîne plus grande reste inchangée. Le modèle retourne un tableau avec le même nombre de chaînes dans le même ordre. Glossia vérifie les variables d'interpolation et rejette les traductions vides.

Les en-têtes sont construits en code en utilisant les règles de pluriel de la zone cible. Les identifiants de message source, commentaires et structure du catalogue proviennent de la source analysée. Si un lot renvoie du contenu malformé, Glossia le réessaye une fois, puis le divise en lots plus petits. Les lots voisins réussis n'ont pas besoin d'être traduits à nouveau.

## Limitation du fournisseur

Glossia coordonne les demandes de traduction utilisant la même authentification et le même modèle. Une réponse de limitation de débit étend leur délai de refroidissement partagé et augmente l'écart entre les nouvelles demandes. Le trafic réussi réduit progressivement cet écart après une minute sans limitation. Les demandes déjà en cours sont autorisées à se terminer.

Les indices de réessai du fournisseur sont des délais minimums. Les échecs répétés augmentent également le délai d'attente, jusqu'à un délai de base de 30 secondes plus le jitter ; un indice de fournisseur plus long prend le dessus, plafonné à cinq minutes. L'en-tête `x-ratelimit-reset` de Together est reconnu aux côtés de `retry-after`.

Après huit tentatives de demande infructueuses, l'exécution du dépôt arrête le lancement de nouveaux fichiers. Une continuation retardée hérite de la branche de traduction et reprend son travail inachevé. La tentative précédente reste visible dans l'historique de la session, liée par la continuation. Les délais augmentent d'une minute à cinq minutes, avec au maximum six continuations automatiques. Les sessions actives plus récentes ont la priorité, et les sessions annulées ne sont jamais réactivées. Les échecs de validation seuls ne programment pas la récupération du fournisseur.

## Progression durable

Les fichiers terminés et leurs fichiers de verrouillage sont publiés sur la branche de traduction par lots : un commit pour chaque 25 fichiers, ou chaque 15 minutes, et un commit final à la fin de l'exécution. Chaque push exécute les vérifications de pull request du dépôt, donc le groupement empêche un grand exécution de lancer une vérification par fichier. Un projet a une seule demande de pull request de traduction : un nouveau commit sur la branche par défaut continue celle qui est ouverte et ne traduit que ce qui a changé depuis. Une fois cette pull request fusionnée ou fermée, la prochaine exécution démarre une nouvelle. Dans les fichiers inachevés, les segments validés localement et les lots de récupération sont également sauvegardés dans la base de données pour sept jours. Ces points de contrôle survivent à l'arrêt d'un processus de travail. Ils sont limités au compte, au projet, à l'entrée du document, à l'authentification crédence et modèle effectif, au contexte, et au segment ou à la tentative de correction.

Une exécution reprise peut réutiliser un segment uniquement lorsque ses entrées correspondent toujours. Elle valide toujours à nouveau le document assemblé final. Les réponses de modèle rejetées ne sont pas des points de contrôle. Un échec de validation au niveau du document déclenche une tentative de réparation séparée car le validateur peut ne pas identifier un seul segment responsable.

Les points de contrôle périmés et les enregistrements de rythme du fournisseur inactifs sont supprimés par le processus de travail de récupération de session planifié. Ce sont des enregistrements opérationnels ; les utilisateurs n'ont pas besoin de les ajouter à leur dépôt ou de les configurer dans `L10N.md`.
