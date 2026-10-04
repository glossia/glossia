%{
  title: "Récupération des traductions",
  summary:
    "Comment Glossia récupère après la limitation de débit du fournisseur et les traductions interrompues.",
  category: "explication",
  section: "translation",
  order: 8
}
---
Glossia valide le contenu traduit avant de le publier. La récupération préserve
cette exigence : une nouvelle tentative doit toujours préserver la structure source et requis
emplacements réservés, et chaque fichier assemblé passe ses commandes de validation configurées.

## Traduction de catalogue

Les catalogues Gettext sont analysés en chaînes avant la traduction. Les requêtes portent au
plus huit chaînes, avec un objectif de groupage de 8 000 octets. Une chaîne plus grande
reste intacte. Le modèle renvoie un tableau avec le même nombre de chaînes dans le
même ordre. Glossia vérifie les variables d'interpolation et rejette les traductions vides.

Les en-têtes sont construites dans le code en utilisant les règles de pluriel de la locale cible. Message source
Les identifiants, les commentaires et la structure du catalogue proviennent de la source analysée. Si un
un lot renvoie du contenu malformé, Glossia réessaie une fois, puis le divise en
Des lots plus petits. Les lots voisins réussis n'ont pas besoin d'être traduits à nouveau.

## Limitation du fournisseur

Glossia coordonne les requêtes de traduction utilisant le même identifiant et le même modèle. Une limitation de débit
La réponse prolonge leur délai d'attente commun et augmente l'espacement entre les nouvelles requêtes.
Le trafic réussi réduit progressivement cet espacement après une minute sans limitation.
Les requêtes déjà en cours sont autorisées à se terminer.

Les indices de délai de reconnexion du fournisseur sont des délais minima. Les échecs répétés augmentent également
le délai de backoff, jusqu'à un délai de base de 30 secondes plus jitter ; une indication du fournisseur plus longue prend
la priorité, limitée à cinq minutes. d'Ensemble `x-ratelimit-reset` l'en-tête est
reconnu aux côtés de `retry-after`.

Après huit tentatives de requête infructueuses, l'exécution du référentiel cesse de démarrer de nouvelles
fichiers. Une continuation différée hérite de la branche de traduction et reprend ses
travaux inachevés. L'ancienne tentative reste visible dans l'historique de session, liée
par la continuation. Les délais augmentent d'une minute à cinq minutes, avec
au plus six tentatives de continuation automatiques. Les sessions actives plus récentes priment, et
Les sessions annulées ne sont jamais réactivées. Les échecs de validation seuls ne planifient pas
la récupération du fournisseur.

## Progression durable

Les fichiers terminés et leurs lockfiles sont publiés dans la branche de traduction en tant que
avant. Dans les fichiers inachevés, les segments validés localement et les lots de récupération
sont également enregistrés dans la base de données pendant sept jours. Ces points de contrôle survivent à un travailleur
l'arrêt d'un processus. Ils s'appliquent au compte, au projet, à l'entrée de document,
identité valide et modèle, contexte, et segment ou tentative de réparation.

Une exécution reprise peut réutiliser un segment uniquement si ses entrées correspondent toujours. Elle vérifie toujours
revalide le document final assemblé à nouveau. Les réponses du modèle rejetées ne sont
des points de contrôle. Un échec de validation au niveau du document déclenche une tentative de réparation distincte
car le validateur peut ne pas identifier un seul segment responsable.

Les points de contrôle expirés et les enregistrements de cadence de fournisseur inactifs sont supprimés par le
travailleur de récupération de session programmé. Il s'agit d'enregistrements opérationnels ; les utilisateurs ne
doivent les ajouter à leur dépôt ou les configurer dans `L10N.md`.