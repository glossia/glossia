%{
  title: "Glossaire",
  summary:
    "Comment Glossia maintient la cohérence des traductions approuvées pour chaque langue et chaque fichier.",
  category: "explication",
  section: "translation",
  order: 5
}
---
Un glossaire est un ensemble de termes soigneusement sélectionnés que vos traductions doivent rendre de la même manière à chaque fois. \\"Commit\\" dans le sens du contrôle de version reste `commit` en espagnol, devient `提交` en chinois simplifié, et `コミット` en japonais. Une décision par langue, appliquée partout.

## Deux endroits où un glossaire peut résider

Glossia recherche les entrées de glossaire dans deux endroits et les fusionne au moment de la traduction :

- **Votre dépôt**, dans les fichiers que vous utilisez déjà pour les paramètres de traduction. `L10N.md` déclare les termes, et celui de chaque langue `L10N/<locale>.md` déclare leurs traductions. Il s'agit du glossaire autoritaire des développeurs : les modifications transitent via des pull requests, les relecteurs de chaque langue possèdent leur propre fichier, et les fichiers imbriqués peuvent l'affiner pour une partie du dépôt.
- **Votre compte Glossia**, géré via le tableau de bord hébergé. Il s'agit du glossaire autoritaire des linguistes : les relecteurs et contributeurs à la localisation ajoutent ou affinent les entrées sans modifier le code, via le tableau de bord, le [REST API](/docs/reference/apis), ou le [serveur MCP](/docs/reference/mcp). Il s'applique à chaque dépôt que le compte traduit.

Les deux sont utiles et ni l'un ni l'autre ne remplace l'autre.

## Quand utiliser lequel

Définir un terme dans **votre compte Glossia** quand :

- **Il s’applique à plus d’un dépôt.** Les noms de produits, les termes de marque et le vocabulaire d’entreprise sont définis une fois et utilisés partout.
- **Les personnes qui le décident ne travaillent pas dans le dépôt.** Les linguistes, les réviseurs et les contributeurs externes peuvent affiner le glossaire même lorsque le dépôt est à source fermée ou s'ils n'ont pas accès en écriture.
- **Vous souhaitez corriger un terme sans modifier le code.** Une traduction corrigée s'applique lors du prochain lancement, sans pull request sur la base de code.
- **Les modifications nécessitent une revue et un historique.** Chaque modification crée une nouvelle version avec une note de changement, les contributeurs peuvent proposer des modifications en suggestions pour approbation, et les versions précédentes restent disponibles.
- **D'autres outils en ont besoin.** Les agents et les intégrations peuvent lire le glossaire via l'API REST et le serveur MCP, par exemple pour écrire un nouveau contenu qui utilise déjà les termes approuvés.

Définir un terme dans **votre dépôt** quand :

- **Il appartient à cette base de code.** Un terme dont le sens est spécifique à un projet, tel que "commit" signifiant l'action de contrôle de version, se trouve à côté du code qui l'utilise.
- **Il doit évoluer conjointement avec le texte source.** Le terme et le texte qui l'introduisent se trouvent dans la même pull request et sont examinés ensemble.
- **Seule une partie du dépôt en a besoin.** Un imbriqué `L10N.md` ou `L10N/<locale>.md` peut ajouter ou remplacer des entrées pour un seul répertoire, tel que les pages marketing.
- **Il doit remplacer le glossaire de compte.** Une entrée de dépôt l'emporte sur une entrée de compte pour le même terme, pour les langues qu'il traduit.

## Comment ils se combinent

Pour chaque fichier et langue cible, Glossia résout les deux glossaires en un ensemble effectif :

1. Commencez avec les entrées du glossaire de compte pour la langue cible.
2. Superposer les entrées de dépôt pour cette langue : les termes du fichier `L10N.md` chaîne qui a une traduction dans sa `L10N/<locale>.md` chaîne. Lorsqu'une entrée de référentiel a le même terme source qu'une entrée de compte, l'entrée de référentiel l'emporte.
3. Si un terme de référentiel n'a pas de traduction pour une langue, l'entrée de compte pour cette langue s'applique toujours. Le référentiel ne bloque jamais une langue qu'il n'a pas traduite.

La fusion se produit **par langue cible**, non par entrée. Une traduction espagnole de "commit" dans `L10N/es.md` remplace l'entrée espagnole du compte pour "commit", mais ne touche pas l'entrée japonaise du compte pour le même terme. Les réviseurs peuvent voir quelles entrées de compte ont été remplacées : le résumé de la session de traduction indique combien ont été surimposés, et le lockfile de chaque fichier les liste sous `glossary.shadowed`.

## Lorsque le glossaire change, les fichiers sont retraduits

Lorsque vous éditez une entrée de glossaire, Glossia ne re-traduit que les fichiers dont *le glossaire effectif a changé*. Si le texte source du fichier ne contient aucune correspondance pour le terme modifié, ses traductions restent inchangées. Si le fichier utilise le terme, son prochain passage de traduction intègre l'instruction mise à jour.

Le même principe s'applique à l'inverse : l'ajout d'un terme utilisé uniquement par un sous-ensemble de fichiers ne force pas une nouvelle exécution complète.

## Ce qu'un glossaire n'est pas

- Ce n'est pas un dictionnaire de traduction automatique. Le modèle de Glossia lit le contexte environnant et peut rendre un terme différemment si la phrase l'exige. Le glossaire est une orientation, pas une substitution.
- Ce n'est pas l'intégralité du guide de style. La Voix, le ton, la formalité et le public se trouvent dans la configuration de la Voix de votre compte et dans `L10N.md`. Le glossaire est uniquement pour les termes individuels et leurs traductions approuvées.
- Pas silencieux. Chaque terme appliqué est enregistré dans le fichier de verrouillage du fichier afin qu'un réviseur puisse tracer exactement quelles entrées de glossaire ont atteint le modèle.

## Lié

- Ajoutez vos premiers termes : [Définir un glossaire](/docs/how-to/define-a-glossary).
- Chaque champ d'entrée : [Référence de glossaire](/docs/reference/glossary).
- Les autres `L10N.md` champs : [Référence L10N.md](/docs/reference/l10n-md).