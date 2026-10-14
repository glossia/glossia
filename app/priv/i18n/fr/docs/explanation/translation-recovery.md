%{
  title: "Récupération de traduction",
  summary:
    "Comment Glossia conserve le Markdown intact et récupère après les limitations de débit des fournisseurs et les interruptions de traduction.",
  category: "explication",
  section: "translation",
  order: 8
}
---

Glossia valide le contenu traduit avant sa publication. La récupération préserve cette exigence : une nouvelle tentative doit toujours préserver la structure de la source et les placeholders requis, et chaque fichier assemblé passe ses commandes de validation configurées.

## Traduction Markdown

Glossia ne reconvertit jamais un document Markdown traduit. Il analyse la source uniquement pour trouver sa prose : paragraphes, titres, éléments de liste, cellules de tableau, les attributs visibles des composants et HTML (`title`, `details`, `alt`, `label`, `description`, `summary`, `placeholder`, `aria-label`, `caption`), et le texte d'un HTML `<summary>`. Chaque traduction est réécrite dans les octets exacts que sa source occupait, donc le code, les destinations de lien, les composants, les alertes GitHub, les ancres explicites de titre telles que `{#install}`, les marqueurs de liste et les lignes vides restent identiques byte pour byte.

Chaque paragraphe ou titre est traduit comme une phrase entière. La mise en forme en ligne devient des balises numérotées : `<gN>...</gN>` autour des mots liés ou soulignés, et `<gN/>` pour le contenu qui ne doit pas changer, tel que le code en ligne ou un composant. Le modèle peut déplacer les balises pour suivre l'ordre des mots de la langue cible, mais doit garder chaque balise exactement une fois. Chaque demande porte aussi le document source environnant et les traductions les plus récentes du même fichier, en référence.

Une unité qui abandonne ou invente une balise est envoyée à nouveau seule, avec la raison, jusqu'à trois fois. Les unités qui sont revenues valides sont conservées. Après l'assemblage, Glossia analyse le résultat et compare sa structure à la source. Une traduction qui se transformerait en un titre, une liste ou une mise en évidence par elle-même a sa prose échappée, ce qui ne nécessite aucun appel de modèle supplémentaire.

## Traduction de catalogue

Les catalogues Gettext sont analysés en chaînes de caractères avant la traduction. Les demandes transportent au maximum huit chaînes, avec un objectif de lots de 8 000 octets. Une seule chaîne plus grande reste intacte. Le modèle retourne un tableau avec le même nombre de chaînes dans le même ordre. Glossia vérifie les variables d'interpolation et rejette les traductions vides.

Les en-têtes sont construits en code en utilisant les règles de pluriel de la langue cible. Les identifiants de message source, les commentaires et la structure du catalogue proviennent de la source analysée. Si un lot retourne un contenu malformé, Glossia le réessaye une fois, puis le divise en lots plus petits. Les lots voisins réussis n'ont pas besoin d'être traduits à nouveau.

## Limitation du fournisseur

Glossia coordonne les demandes de traduction qui utilisent le même identifiant d'accès et le même modèle. Une réponse limitant le débit prolonge leur délai de récupération commun et augmente l'écart entre les nouvelles demandes. Le trafic réussi réduit graduellement cet écart après une minute sans ralentissement. Les demandes en cours d'exécution sont autorisées à se terminer.

Les indices de redémarrage du fournisseur sont des délais minimums. Les échecs répétés augmentent également le délai de retour en arrière, jusqu'à un délai de base de 30 secondes plus un jitter ; un indice de fournisseur plus long prend le dessus, plafonné à cinq minutes. L'en-tête `x-ratelimit-reset` de Together est reconnu en parallèle de `retry-after`.

Après huit tentatives infructueuses de demande, l'exécution du dépôt arrête de démarrer de nouveaux fichiers. Une poursuite différée hérite de la branche de traduction et reprend son travail inachevé. La tentative précédente reste visible dans l'historique de la session, liée à travers la poursuite. Les délais augmentent d'une minute à cinq minutes, avec au maximum six poursuites automatiques. Les sessions actives plus récentes prennent le dessus, et les sessions annulées ne sont jamais revitalisées. Les échecs de validation seuls ne programment pas la récupération du fournisseur.

## Progression durable

Les fichiers terminés et leurs fichiers de verrouillage sont publiés sur la branche de traduction en lots : une validation pour chaque 25 fichiers, ou toutes les 15 minutes, et une validation finale lorsque l'exécution se termine. Chaque push exécute les vérifications de pull request du dépôt, donc le lot maintient une grande exécution pour ne démarrer aucun contrôle par fichier. Un projet a une seule pull request de traduction : une nouveau commit sur la branche par défaut continue celui ouvert, et ne traduit que ce qui a changé. Une fois cette pull request fusionnée ou fermée, la prochaine exécution démarre une nouvelle. Dans les fichiers inachevés, les segments validés localement et les lots de récupération sont également sauvegardés dans la base de données pendant sept jours. Ces points de contrôle survivent à l'arrêt d'un processus de travailleur. Ils sont limités au compte, projet, entrée du document, identifiant d'accès et modèle effectif, contexte, et essai de segment ou de réparation.

Une exécution reprise peut réutiliser un segment seulement lorsque ses entrées correspondent toujours. Elle valide toujours à nouveau le document final assemblé. Les réponses de modèle rejetées ne sont pas des points de contrôle. Un échec de validation au niveau du document commence une tentative de réparation séparée car le validateur peut ne pas identifier un seul segment responsable.

Les points de contrôle expirés et les enregistrements de cadence du fournisseur inactifs sont supprimés par l'agent de récupération de session programmé. Ce sont des enregistrements opérationnels ; les utilisateurs n'ont pas besoin de les ajouter à leur dépôt ou de les configurer dans `L10N.md`.
