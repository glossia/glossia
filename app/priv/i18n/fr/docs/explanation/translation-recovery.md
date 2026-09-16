%{
  title: "Récupération des traductions",
  summary:
    "Comment Glossia récupère après la limitation du fournisseur et les traductions interrompues.",
  category: "explication",
  order: 8
}
---
Glossia valide le contenu traduit avant sa publication. Le rétablissement conserve
cette exigence : une nouvelle tentative doit toujours préserver la structure source et nécessaires
marqueurs, et chaque fichier assemblé passe ses commandes de validation configurées.

## Traduction du catalogue

Les catalogues Gettext sont convertis en chaînes avant traduction. Les requêtes contiennent au
plus de huit chaînes, avec un objectif de lot de 8 000 octets. Une seule chaîne plus longue
reste intacte. Le modèle renvoie un tableau avec le même nombre de chaînes dans le
même ordre. Glossia vérifie les variables d'interpolation et rejette les traductions vides.

Les en-têtes sont construits en code en utilisant les règles de pluriel de la locale cible. Message source
les identifiants, les commentaires et la structure du catalogue proviennent de la source analysée. Si un
lot renvoyant du contenu malformé, Glossia le réessaie une fois, puis le divise en
lots plus petits. Les lots voisins ayant réussi n'ont pas besoin d'être traduits à nouveau.

## Limitation de débit du fournisseur

Les travailleurs utilisant le même identifiant et le même modèle partagent l'accès aux requêtes via la
base de données, y compris les travailleurs sur différentes réplications d'application. Une limite de débit
La réponse étend leur délai de pause partagé et augmente l'espacement entre les nouvelles requêtes.
Un trafic réussi réduit progressivement cet intervalle après une minute sans limitation de débit.
Les requêtes déjà en cours sont autorisées à se terminer.

Les indices de réessai du fournisseur sont des délais minimums. Des échecs répétés augmentent également le
délai de repli, jusqu'à un délai de base de 30 secondes plus une variation ; un indicateur de fournisseur plus long prend
la priorité, plafonnée à cinq minutes. Celle de l'Ensemble `x-ratelimit-reset` l'en-tête est
reconnu aux côtés de `retry-after`.

Après huit tentatives de requêtes infructueuses, l'exécution du dépôt arrête de démarrer de nouveaux
fichiers. Une reprise différée hérite de la branche de traduction et reprend son
travail inachevé. La tentative précédente reste visible dans l'historique des sessions, liée
via la reprise. Les délais augmentent d'une minute à cinq minutes, avec
un maximum de six reprises automatiques. Les sessions actives plus récentes ont la priorité, et
les sessions annulées ne sont jamais réactivées. Les échecs de validation seuls ne planifient pas
la récupération du fournisseur.

## Progression durable

Les fichiers terminés et leurs fichiers de verrouillage sont publiés dans la branche de traduction comme
avant. Dans les fichiers inachevés, les segments validés localement et les lots de récupération
sont également sauvegardés dans la base de données pendant sept jours. Ces points de contrôle survivent à un travailleur
processus en cours d'arrêt. Ils sont limités au compte, au projet, à l'entrée du document,
à l'identifiant de connexion effectif et au modèle, au contexte, et au segment ou à la tentative de réparation.

Une exécution reprise peut réutiliser un segment uniquement lorsque ses entrées correspondent toujours. Elle
valide à nouveau le document final assemblé. Les réponses du modèle rejetées ne sont pas
des points de contrôle. Un échec de validation au niveau du document déclenche une tentative de réparation séparée
parce que le validateur peut ne pas identifier un segment unique responsable.

Les points de contrôle expirés et les enregistrements de cadence fournisseurs inactifs sont supprimés par le
travailleur de récupération de sessions planifiées. Ce sont des enregistrements opérationnels ; les utilisateurs ne
doivent pas les ajouter à leur dépôt ou les configurer dans `L10N.md`.