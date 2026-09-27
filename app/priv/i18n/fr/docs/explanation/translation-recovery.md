%{
  title: "Récupération des traductions",
  summary:
    "Comment Glossia récupère après le ralentissement du fournisseur et les traductions interrompues.",
  category: "explication",
  section: "traduction",
  order: 8
}
---
Glossia valide le contenu traduit avant de le publier. La récupération préserve
cette exigence : un réessai doit toujours préserver la structure source et requis
les balises, et chaque fichier assemblé passe ses commandes de validation configurées.

## Traduction de catalogue

Les catalogues Gettext sont extraits en chaînes avant la traduction. Les requêtes transportent au
plus huit chaînes, avec un objectif de lot de 8,000 octets. Une chaîne plus grande
reste intacte. Le modèle renvoie un tableau avec le même nombre de chaînes dans le
même ordre. Glossia vérifie les variables d'interpolation et rejette les traductions vides.

Les en-têtes sont construits dans le code à l'aide des règles de pluriel de la langue cible. Message source
identifiants, commentaires et structure du catalogue proviennent de la source analysée. Si un
lot renvoie du contenu malformé, Glossia l'essaie une fois, puis le divise en
des lots plus petits. Les lots adjacents réussis n'ont pas besoin d'être retraduits.

## Limitation de débit du fournisseur

Les travailleurs utilisant le même identifiant et le même modèle partagent l'accès aux requêtes via la
base de données, y compris les travailleurs sur différentes répliques d'application. Une limitation de débit
réponse prolonge leur refroidissement commun et augmente l'écart entre les nouvelles requêtes.
Le trafic réussi réduit progressivement cet espacement après une minute sans limitation du débit.
Les requêtes déjà en cours sont autorisées à se terminer.

Les indicateurs de réessai du fournisseur sont des délais minimums. Les échecs répétés augmentent également le
backoff, jusqu'à un délai de base de 30 secondes plus jitter; un indice de fournisseur plus long prend
la priorité, limitée à cinq minutes. Celle de Together `x-ratelimit-reset` l'en-tête est
reconnu aux côtés de `retry-after`.

Après huit tentatives de requête infructueuses, l'exécution du référentiel arrête de lancer de nouveaux
fichiers. Une continuation différée hérite de la branche de traduction et reprend son
travail inachevé. La tentative précédente reste visible dans l'historique des sessions, liée
via la continuation. Les délais augmentent d'une minute à cinq minutes, avec
au maximum six continuations automatiques. Les sessions actives plus récentes prennent le pas, et
les sessions annulées ne sont jamais réactivées. Les échecs de validation seuls ne déclenchent pas de
récupération du fournisseur.

## Progrès durable

Les fichiers terminés et leurs fichiers de verrouillage sont publiés sur la branche de traduction comme
avant. Dans les fichiers inachevés, les segments validés localement et les lots de récupération
sont également enregistrés dans la base de données pendant sept jours. Ces points de contrôle survivent à un travailleur
l'arrêt du processus. Ils s'appliquent au compte, au projet, à l'entrée du document,
la clé d'accès valide et le modèle, le contexte, ainsi que le segment ou la tentative de réparation.

Une exécution reprise peut réutiliser un segment seulement si ses entrées correspondent toujours. Elle valide toujours
le document final assemblé à nouveau. Les réponses du modèle rejetées ne sont pas
des points de contrôle. Un échec de validation au niveau du document lance une tentative de réparation distincte
parce que le validateur peut ne pas identifier un seul segment responsable.

Les points de contrôle expirés et les enregistrements de rythme fournisseur inactifs sont supprimés par le
travailleur de récupération de session planifié. Il s'agit d'enregistrements opérationnels ; les utilisateurs n'ont
besoin de les ajouter à leur dépôt ou de les configurer dans `L10N.md`.