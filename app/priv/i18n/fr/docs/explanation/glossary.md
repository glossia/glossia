%{
  title: "Glossaire",
  summary:
    "Comment Glossia assure la cohérence des traductions approuvées à travers chaque langue et chaque fichier.",
  category: "explication",
  section: "translation",
  order: 5
}
---

Un glossaire est un ensemble de termes curatés que vos traductions doivent rendre de la même manière à chaque fois. « Commit » dans le sens de la gestion de version reste `commit` en espagnol, devient `提交` en chinois simplifié, et `コミット` en japonais. Une décision par langue, appliquée partout.

## Deux endroits où réside un glossaire

Glossia recherche les entrées de glossaire en deux endroits et les fusionne au moment de la traduction :

- **Votre dépôt**, dans les fichiers que vous utilisez déjà pour les paramètres de traduction. `L10N.md` déclare les termes, et `L10N/<locale>.md` déclare leurs traductions. Ceci est le glossaire défini par les développeurs : les modifications voyagent via des pull requests, les réviseurs de chaque langue possèdent leur propre fichier, et les fichiers imbriqués peuvent l'affiner pour une partie du dépôt.
- **Votre compte Glossia**, géré via le tableau de bord hébergé. Ceci est le glossaire défini par les linguistes : les réviseurs et les contributeurs de localisation ajoutent ou affinent les entrées sans toucher au code, via le tableau de bord, [l'API REST](/docs/reference/apis) ou [le serveur MCP](/docs/reference/mcp). Il s'applique à chaque dépôt que le compte traduit.

Les deux endroits sont utiles, et l'un ne remplace pas l'autre.

## Quand utiliser lequel

Définissez un terme dans **votre compte Glossia** quand :

- **Il s'applique à plus d'un dépôt.** Les noms de produits, les termes de marque et le vocabulaire de l'entreprise sont définis une fois et utilisés partout.
- **Les personnes qui décident ne travaillent pas dans le dépôt.** Linguistes, réviseurs et contributeurs externes peuvent affiner le glossaire même si le dépôt est à source fermée ou s'ils n'ont pas de droits d'écriture sur lui.
- **Voulez-vous corriger un terme sans modification du code.** Une traduction corrigée s'applique à l'exécution suivante, sans pull request vers la base de code.
- **Les modifications nécessitent une révision et un historique.** Chaque modification crée une nouvelle version avec une note de modification ; les contributeurs peuvent proposer des modifications sous forme de suggestions pour qu'une personne les approuve, et les versions antérieures restent disponibles.
- **D'autres outils en ont besoin.** Les agents et les intégrations peuvent lire le glossaire via l'API REST et le serveur MCP, par exemple pour créer un nouveau contenu qui utilise déjà les termes approuvés.

Définissez un terme dans **votre dépôt** quand :

- **Il appartient à cette base de code.** Un terme dont le sens est spécifique à un projet, tel que « commit » signifiant l'action de gestion de version, est situé à côté du code qui l'utilise.
- **Il devrait changer ensemble avec le texte source.** Le terme et le contenu qui l'a introduit atterrissent dans la même pull request et sont examinés ensemble.
- **Seule une partie du dépôt en a besoin.** Un fichier imbriqué `L10N.md` ou `L10N/<locale>.md` peut ajouter ou surcharger des entrées pour un seul répertoire, tel que des pages marketing.
- **Il doit surcharger le glossaire du compte.** Une entrée de dépôt l'emporte sur une entrée de compte pour le même terme, pour les langues qu'elle traduit.

## Comment ils se combinent

Pour chaque fichier et langue cible, Glossia résout les deux glossaires en un ensemble effectif :

1. Commencez par les entrées du glossaire de compte pour la langue cible.
2. Superposez les entrées de dépôt pour cette langue : les termes de la chaîne `L10N.md` du fichier qui ont une traduction dans sa chaîne `L10N/<locale>.md`. Lorsque une entrée de dépôt a le même terme source qu'une entrée de compte, l'entrée du dépôt l'emporte.
3. Si un terme de dépôt n'a pas de traduction pour une langue, l'entrée de compte pour cette langue s'applique toujours. Le dépôt ne bloque jamais une langue qu'il n'a pas traduite.

La fusion a lieu **par langue cible**, pas par entrée. Une traduction espagnole de « commit » dans `L10N/es.md` remplace l'entrée de compte espagnole pour « commit », mais ne touche pas l'entrée japonaise du compte pour le même terme. Les réviseurs peuvent voir quelles entrées de compte ont été remplacées : le résumé de la session de traduction montre combien ont été surchargées, et le lockfile de chaque fichier les liste sous `glossary.shadowed`.

## Quand le glossaire change, les fichiers se retraduisent

Lorsque vous modifiez une entrée de glossaire, Glossia ne retraduit que les fichiers dont le *glossaire effectif a changé*. Si le texte source d'un fichier ne contient aucune correspondance pour le terme modifié, ses traductions restent inchangées. Si un fichier utilise le terme, son passe de traduction suivant inclut la mise à jour de l'instruction.

Le même principe s'applique à l'inverse : ajouter un terme utilisé uniquement par un sous-ensemble de fichiers n'obfigure pas une nouvelle exécution complète.

## Ce qu'un glossaire n'est pas

- Pas un dictionnaire de traduction automatique. Le modèle de Glossia lit le contexte environnant et peut rendre un terme différemment si la phrase le demande. Le glossaire est un guide, pas un remplacement.
- Pas tout le guide de style. Voix, ton, niveau de formalité et public cible vivent dans la configuration Voix de votre compte et dans `L10N.md`. Le glossaire est réservé aux termes individuels et à leurs traductions approuvées.
- Pas silencieux. Chaque terme appliqué est enregistré dans le fichier de verrouillage du fichier afin qu'un réviseur puisse tracer exactement quelles entrées de glossaire ont atteint le modèle.

## Voir aussi

- Ajoutez vos premiers termes : [Définir un glossaire](/docs/how-to/define-a-glossary).
- Chaque champ d'entrée : [Référence du glossaire](/docs/reference/glossary).
- Les autres champs `L10N.md` : [Référence L10N.md](/docs/reference/l10n-md).
