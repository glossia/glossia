%{
  title: "Glossaire",
  summary:
    "Comment Glossia maintient la cohérence des traductions approuvées à travers toutes les langues et tous les fichiers.",
  category: "Explication",
  section: "translation",
  order: 5
}
---

Un glossaire est un ensemble curaté de termes que vos traductions doivent rendre de la même façon à chaque fois. "Commit" au sens de versionnement demeure `commit` en espagnol, devient `提交` en chinois simplifié et `コミット` en japonais. Une décision par langue, appliquée partout.

## Deux endroits où un glossaire peut résider

Glossia cherche les entrées de glossaire dans deux endroits et les fusionne au moment de la traduction :

- **Votre dépôt**, dans les fichiers que vous utilisez déjà pour les paramètres de traduction. `L10N.md` déclare les termes, et `L10N/<locale>.md` de chaque langue déclare leurs traductions. C'est le glossaire d'autorité des développeurs : les modifications transitent via des pull requests, les réviseurs de chaque langue possèdent leurs propres fichiers, et les fichiers imbriqués peuvent l'affiner pour une partie du dépôt.
- **Votre compte Glossia**, géré via le tableau de bord hébergé. C'est le glossaire d'autorité des linguistes : les réviseurs et contributeurs de localisation ajoutent ou affinent des entrées sans toucher au code, via le tableau de bord, [REST API](/docs/reference/apis) ou [serveur MCP](/docs/reference/mcp). Il s'applique à tous les dépôts que le compte traduit.

Les deux endroits sont utiles, ni l'un ni l'autre ne remplace l'autre.

## Quand utiliser lequel

Définissez un terme dans **votre compte Glossia** quand :

- **Il s'applique à plus d'un dépôt.** Les noms de produits, termes de marque et vocabulaire d'entreprise sont définis une fois et utilisés partout.
- **Les personnes qui y décident ne travaillent pas dans le dépôt.** Les linguistes, réviseurs et contributeurs externes peuvent affiner le glossaire même si le dépôt est de source fermée ou s'ils n'ont aucun accès en écriture dessus.
- **Vous voulez corriger un terme sans modification de code.** Une traduction corrigée s'applique lors du prochain lancement, sans pull request contre la base de code.
- **Les modifications nécessitent un examen et un historique.** Toute modification crée une nouvelle version avec une note de changement, les contributeurs peuvent proposer des modifications sous forme de suggestions pour qu'une personne les approuve, et les versions antérieures restent disponibles.
- **D'autres outils en ont besoin.** Les agents et intégrations peuvent lire le glossaire via le REST API et le serveur MCP, par exemple pour écrire du nouveau contenu qui utilise déjà les termes approuvés.

Définissez un terme dans **votre dépôt** quand :

- **Il appartient à cette base de code.** Un terme dont le sens est spécifique à un projet, tel que "commit" signifiant l'action de versionnement, se trouve à côté du code qui l'utilise.
- **Il doit changer avec le texte source.** Le terme et le texte qui l'a introduit atterrissent dans la même pull request et sont examinés ensemble.
- **Seule une partie du dépôt a besoin de cela.** Un fichier imbriqué `L10N.md` ou `L10N/<locale>.md` peut ajouter ou surcharger des entrées pour un répertoire, tel que les pages de marketing.
- **Il doit surcharger le glossaire du compte.** Une entrée de dépôt l'emporte sur une entrée de compte pour le même terme, pour les langues qu'il traduit.

## Comment ils se combinent

Pour chaque fichier et langue cible, Glossia résout les deux glossaires en un ensemble effectif :

1. Commencez par les entrées du glossaire du compte pour la langue cible.
2. Superposez les entrées de dépôt pour cette langue : les termes de la chaîne de fichiers `L10N.md` qui ont une traduction dans leur chaîne `L10N/<locale>.md`. Quand une entrée de dépôt a le même terme source qu'une entrée de compte, l'entrée de dépôt gagne.
3. Si un terme de dépôt n'a pas de traduction pour une langue, l'entrée du compte pour cette langue s'applique toujours. Le dépôt ne bloque jamais une langue qu'il n'a pas traduite.

La fusion se déroule **par langue cible**, pas par entrée. Une traduction espagnole de "commit" dans `L10N/es.md` remplace l'entrée espagnole du compte pour "commit", mais ne touche pas l'entrée japonaise du compte pour ce même terme. Les réviseurs peuvent voir quelles entrées du compte ont été remplacées : le résumé de la session de traduction montre combien ont été surchargés, et le lockfile de chaque fichier les liste sous `glossary.shadowed`.

## Lorsque le glossaire change, les fichiers retraduisent

Lorsque vous modifiez une entrée de glossaire, Glossia ne retraduit que les fichiers dont le *glossaire effectif a changé*. Si le texte source d'un fichier ne contient aucune correspondance pour le terme modifié, ses traductions restent intactes. Si un texte source utilise le terme, son prochain passage de traduction inclut l'instruction mise à jour.

Le même principe s'applique à l'inverse : ajouter un terme utilisé uniquement par un sous-ensemble de fichiers n'oblige pas à un nouvel exécution complète.

## Ce qu'un glossaire n'est pas

- Ce n'est pas un dictionnaire de traduction automatique. Le modèle de Glossia lit le contexte environnant et peut rendre un terme différemment si la phrase l'exige. Le glossaire est une orientation, pas un remplacement.
- Ce n'est pas le guide de style entier. La voix, le ton, la formalité et l'audience vit dans la configuration Voice de votre compte et dans `L10N.md`.
- Ce n'est pas silencieux. Chaque terme appliqué est enregistré dans le fichier de verrouillage du fichier afin qu'un réviseur puisse tracer exactement quelles entrées de glossaire ont atteint le modèle.

## Lié

- Ajoutez vos premiers termes : [Définir un glossaire](/docs/how-to/define-a-glossary).
- Chaque champ d'entrée : [Référence du glossaire](/docs/reference/glossary).
- Les autres `L10N.md` champs : [référence L10N.md](/docs/reference/l10n-md).
