%{
  title: "Récupération de traduction",
  summary:
    "Comment Glossia maintient le Markdown intact et se remet de la limitation de débit des fournisseurs et des traductions interrompues.",
  category: "Explication",
  section: "translation",
  order: 8
}
---
Glossia valide le contenu traduit avant de le publier. La récupération conserve
cette exigence : une nouvelle tentative doit encore préserver la structure source et requis
les espaces réservés, et chaque fichier assemblé passe ses commandes de validation configurées.

## Traduction Markdown

Glossia ne reconstruit jamais un document Markdown traduit. Elle analyse la source
uniquement pour en extraire le texte : paragraphes, titres, éléments de liste, cellules de tableau, le
attributs destinées au lecteur des composants et de l'HTML (`title`, `details`, `alt`Le document réassemblé a échoué la validation précédemment : la récupération du texte Markdown doit retourner un tableau de chaînes JSON de longueur correspondante
`label`Le document réassemblé a précédemment échoué la validation : la récupération de texte Markdown a retourné un JSON invalide `description`Le document reconstitué a échoué la validation précédemment : la récupération de texte littéral Markdown a retourné un JSON invalide `summary`, `placeholder`, `aria-label`Le document réassemblé a échoué la validation précédemment : la récupération du nœud de texte Markdown a produit une traduction vide. `caption`), et
le texte d'un HTML `<summary>`. Chaque traduction est réécrite dans le nombre exact
d'octets qu'occupait sa source, ainsi le code, les destinations de liens, les composants, GitHub
alertes, ancres d'en-tête explicites telles que `{#install}`, les marqueurs de liste et vides
lignes restent identiques d'octet à octet.

Chaque paragraphe ou en-tête est traduit en phrase complète. La mise en forme en ligne
devient des balises numérotées: `<gN>...</gN>` autour des mots liés ou mis en valeur, et
`<gN/>` pour le contenu qui ne doit pas changer, tel que le code en ligne ou un composant.
Le modèle peut déplacer les balises pour suivre l'ordre des mots de la langue cible, mais doit
conserver chaque balise exactement une fois. Chaque demande contient également la source environnante
document, et les traductions les plus récentes du même fichier, à titre de référence.

Une unité qui supprime ou invente une balise est renvoyée séparément, avec la raison,
jusqu'à trois fois. Les unités valides retournées sont conservées. Après l'assemblage, Glossia
analyse le résultat et compare sa structure à la source. Une traduction qui
qui, tout seul, deviendrait un titre, une liste ou une emphase, et dont la prose est échappée,
ce qui nécessite aucun appel de modèle supplémentaire.

## Traduction de catalogue

Les catalogues Gettext sont analysés en chaînes avant la traduction. Les requêtes transportent au
plus huit chaînes, avec pour objectif de lot de 8 000 octets. Une seule chaîne plus grande
reste intacte. Le modèle retourne un tableau avec le même nombre de chaînes dans la
même ordre. Glossia vérifie les variables d'interpolation et rejette les traductions vides.

Les en-têtes sont construits en code en utilisant les règles de pluriel de la cible locale. Message source
Les identifiants, commentaires et la structure du catalogue proviennent de la source analysée. Si un
lot renvoie du contenu défectueux, Glossia l'essaie une fois, puis le divise en
plus petits lots. Les lots voisins réussis n'ont pas besoin d'être traduits à nouveau.

## Ralentissement du fournisseur

Glossia coordonne les requêtes de traduction utilisant le même identifiant de connexion et le même modèle. Une limitation de débit
prolonge leur période d'attente commune et augmente l'intervalle entre les nouvelles requêtes.
Le trafic réussi réduit progressivement cet intervalle après une minute sans ralentissement.
Les requêtes déjà en cours peuvent se terminer.

Les indices de réessaie du fournisseur sont des délais minima. Les échecs répétés augmentent également le
backoff, jusqu'à un délai de base de 30 secondes plus jitter ; un indice de fournisseur plus long prend
priorité, limitée à cinq minutes. de Together `x-ratelimit-reset` l'en-tête est
reconnu aux côtés de `retry-after`.

Après huit tentatives de requête infructueuses, l'exécution du référentiel arrête de démarrer les nouveaux
fichiers. Une reprise différée hérite de la branche de traduction et reprend sa
travail inachevé. La tentative précédente reste visible dans l'historique des sessions, liée
par la reprise. Les délais augmentent d'une minute à cinq minutes, avec
au maximum six reprises automatiques. Les sessions actives plus récentes ont la priorité, et
les sessions annulées ne sont jamais relancées. les échecs de validation seuls ne planifient pas
la récupération du fournisseur.

## Progression durable

Les fichiers terminés et leurs fichiers de verrouillage sont publiés dans la branche de traduction en
lots : un commit pour chaque 25 fichiers, ou toutes les 15 minutes, et un commit final
lorsque l'exécution se termine. Chaque pousse exécute les vérifications de la demande de traduction du dépôt, donc
La mise en lots empêche une grande exécution de démarrer une vérification par fichier. Un projet a
une seule demande de traduction : un nouveau commit sur la branche par défaut continue
celle qui est ouverte, et traduit uniquement les modifications depuis. Une fois cette demande de traduction
fusionnée ou fermée, la prochaine exécution lance une nouvelle. Pour les fichiers inachevés, les segments validés localement et les lots de récupération
sont également enregistrés dans la base de données pendant sept jours. Ces points de contrôle persistent même en cas d'arrêt d'un travailleur
processus en cours d'arrêt. Ils sont limités au compte, au projet et à l'entrée du document,
les identifiants et le modèle valides, le contexte, et le segment ou la tentative de réparation.

Une exécution reprise peut réutiliser un segment uniquement lorsque ses entrées correspondent toujours. Elle toujours
valide le document assemblé final à nouveau. Les réponses du modèle rejetées ne sont
des points de contrôle. Un échec de validation au niveau du document déclenche une tentative de réparation séparée
car le validateur peut ne pas identifier un seul segment responsable.

Les points de contrôle expirés et les enregistrements de rythme de fournisseur inactifs sont supprimés par le
travailleur de récupération de session planifiée. Ce sont des enregistrements opérationnels ; les utilisateurs ne
il faut les ajouter à leur dépôt ou les configurer dans `L10N.md`.