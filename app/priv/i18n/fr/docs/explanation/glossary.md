%{
  title: "Glossaire",
  summary:
    "Comment Glossia maintient la cohérence des traductions approuvées à travers chaque langue et chaque fichier.",
  category: "explication",
  section: "traduction",
  order: 5
}
---
Un glossaire est un ensemble de termes soigneusement sélectionnés que vos traductions doivent rendre de la même manière à chaque fois. "Commit" dans le sens du contrôle de version reste `commit` en espagnol, devient `提交` en chinois simplifié, et `コミット` en japonais. Une décision par langue, appliquée partout.

## Deux endroits où un glossaire peut se trouver

Glossia consulte deux endroits pour les entrées de glossaire et les fusionne au moment de la traduction :

- **Votre dépôt**, dans les fichiers que vous utilisez déjà pour les paramètres de traduction. `L10N.md` déclare les termes, et de chaque langue `L10N/<locale>.md` déclare leurs traductions. Il s'agit du glossaire de référence des développeurs : les modifications transitent par les pull requests, les relecteurs de chaque langue gèrent leur propre fichier, et les fichiers imbriqués peuvent l'affiner pour une partie du dépôt.
- **Le serveur**, stocké avec votre compte. Il s'agit du glossaire de référence des linguistes : les réviseurs et contributeurs de localisation ajoutent ou affinent les entrées sans toucher le code, via le tableau de bord, le [REST API](/docs/reference/apis), ou le [MCP server](/docs/reference/mcp). Il s'applique à tous les dépôts que le compte traduit.

Les deux endroits sont utiles, et l'un ne remplace pas l'autre.

## Quand utiliser lequel

Définir un terme sur **le serveur** quand:

- **Cela s'applique à plus d'un dépôt.** Les noms de produits, les termes de marque et le vocabulaire d'entreprise sont définis une fois et utilisés partout.
- **Les personnes qui décident cela ne travaillent pas dans le dépôt.** Les linguistes, réviseurs et contributeurs externes peuvent affiner le glossaire même si le référentiel est en source fermée ou s'ils n'ont aucun accès en écriture.
- **Vous souhaitez corriger un terme sans modifier le code.** Une traduction corrigée s'applique à l'exécution suivante, sans pull request.
- **Des modifications nécessitent une revue et un historique.** Chaque édition crée une nouvelle version avec une note de modification, les contributeurs peuvent proposer des changements sous forme de suggestions pour qu'un autre les approuve, et les versions antérieures restent disponibles.
- **D'autres outils en ont besoin.** Des agents et des intégrations peuvent lire le glossaire via l'API REST et le serveur MCP, par exemple pour écrire du nouveau contenu qui utilise déjà les termes approuvés.

Définir un terme dans **votre dépôt** quand :

- **Il appartient à cette base de code.** Un terme dont la signification est spécifique à un projet, tel que "commit" pour désigner l'action de gestion de version, se trouve à côté du code qui l'utilise.
- **Il doit évoluer conjointement avec le texte source.** Le terme et le texte qui l'a introduit se trouvent dans la même demande de fusion et sont examinés ensemble.
- **Seule une partie du dépôt en a besoin.** Un emboîté `L10N.md` ou `L10N/<locale>.md` peuvent ajouter ou surclasser des entrées pour un seul répertoire, telles que les pages marketing.
- **Elle doit surclasser le serveur.** Une entrée de dépôt l'emporte sur une entrée de serveur pour le même terme, pour les langues qu'elle traduit.

## Comment ils se combinent

Pour chaque fichier et langue cible, Glossia résout les deux glossaires en un ensemble effectif :

1. Commencez par les entrées du glossaire du serveur pour la langue cible.
2. Superposez les entrées du dépôt pour cette langue : les termes du fichier `L10N.md` chaîne qui a une traduction dans sa `L10N/<locale>.md` chaîne. Lorsqu'une entrée de référentiel a le même terme source qu'une entrée de serveur, l'entrée de référentiel l'emporte.
3. Si un terme de référentiel ne dispose pas de traduction pour une langue, l'entrée serveur de cette langue s'applique toujours. Le référentiel ne bloque jamais une langue qu'il n'a pas traduite.

La fusion a lieu **par langue cible**, non pas par entrée. Une traduction en espagnol de "commit" dans `L10N/es.md` remplace l'entrée espagnole du serveur pour "commit", mais ne touche pas l'entrée japonaise du serveur pour le même terme. Les réviseurs peuvent voir quelles entrées serveur ont été surclassées : le résumé de la session de traduction montre combien ont été surclassées, et le fichier de verrouillage de chaque fichier les liste sous `glossary.shadowed`.

## Quand le glossaire change, les fichiers sont retraduits

Lorsque vous modifiez une entrée de glossaire, Glossia ne retraduit que les fichiers dont *le glossaire effectif a changé*. Si le texte source du fichier ne contient aucune correspondance pour le terme modifié, ses traductions restent inchangées. Si un fichier utilise le terme, son prochain passage de traduction inclut l'instruction mise à jour.

Le même principe s'applique en sens inverse : ajouter un terme utilisé uniquement par un sous-ensemble de fichiers ne force pas une re-exécution complète.

## Ce qu'un glossaire n'est pas

- Ce n'est pas un dictionnaire de traduction automatique. Le modèle Glossia lit le contexte environnant et peut rendre un terme différemment si la phrase l'exige. Le glossaire est un guide, pas un substitut.
- Ce n'est pas le guide de style complet. Voix, ton, degré de formalité et public se trouvent dans la configuration Voix de votre compte et dans `L10N.md`. Le glossaire ne concerne que les termes individuels et leurs traductions approuvées.
- Non silencieux. Chaque terme appliqué est enregistré dans le fichier de verrouillage afin qu'un relecteur puisse tracer exactement quelles entrées de glossaire ont atteint le modèle.

## Lié

- Ajoutez vos premiers termes : [Définir un glossaire](/docs/how-to/define-a-glossary).
- Chaque champ d'entrée : [Référence de glossaire](/docs/reference/glossary).
- Les autres `L10N.md` champs: [L10N.md référence](/docs/reference/l10n-md).