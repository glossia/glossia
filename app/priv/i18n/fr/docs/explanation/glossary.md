%{
  title: "Glossaire",
  summary:
    "Comment Glossia maintient la cohérence des traductions approuvées à travers chaque langue et chaque fichier.",
  category: "explication",
  section: "translation",
  order: 5
}
---

Un glossaire est un ensemble curaté de termes que vos traductions doivent rendre de la même manière à chaque fois. "Commit" au sens versioning reste `commit` en espagnol, devient `提交` en chinois simplifié, et `コミット` en japonais. Une décision par langue, appliquée partout.

## Deux endroits où un glossaire peut résider

Glossia recherche les entrées de glossaire dans deux endroits et les fusionne au moment de la traduction :

- **Votre dépôt**, dans les fichiers que vous utilisez déjà pour les paramètres de traduction. `L10N.md` déclare les termes, et la `L10N/<locale>.md` de chaque langue déclare leurs traductions. C'est le glossaire autoritaire des développeurs : les modifications circulent via les pull requests, les réviseurs de chaque langue ont leur propre fichier, et les fichiers imbriqués peuvent l'affiner pour une partie du dépôt.
- **Votre compte Glossia**, géré via le tableau de bord hébergé. C'est le glossaire autoritaire des linguistes : les réviseurs et contributeurs de localisation ajoutent ou affinent des entrées sans toucher au code, via le tableau de bord, la [REST API](/docs/reference/apis) ou le [serveur MCP](/docs/reference/mcp). Il s'applique à tous les dépôts traduits par le compte.

Les deux endroits sont utiles, et l'un ne remplace pas l'autre.

## Quand utiliser l'un ou l'autre

Définissez un terme dans **votre compte Glossia** quand :

- **Il s'applique à plus d'un dépôt.** Les noms de produit, les termes de marque et le vocabulaire de l'entreprise sont définis une fois et utilisés partout.
- **Ceux qui décident ne travaillent pas dans le dépôt.** Linguistes, réviseurs et contributeurs externes peuvent affiner le glossaire même si le dépôt est privé ou s'ils n'ont pas d'accès en écriture.
- **Vous voulez corriger un terme sans changer le code.** Une traduction corrigée s'applique au prochain exécution, sans pull request contre la base de code.
- **Les changements nécessitent des révisions et un historique.** Chaque édition crée une nouvelle version avec une note de changement, les contributeurs peuvent proposer des modifications en suggestions pour qu'une autre personne les approuve, et les versions précédentes restent disponibles.
- **D'autres outils en ont besoin.** Les agents et intégrations peuvent lire le glossaire via la REST API et le serveur MCP, par exemple pour écrire du nouveau contenu qui utilise déjà les termes approuvés.

Définissez un terme dans **votre dépôt** quand :

- **Il appartient à cette base de code.** Un terme dont le sens est spécifique à un projet, tel que "commit" signifiant l'action de contrôle de version, se trouve à côté du code qui l'utilise.
- **Il devrait changer conjointement avec le texte source.** Le terme et le contenu qui l'introduisent arrivent dans la même pull request et sont examinés ensemble.
- **Seule une partie du dépôt en a besoin.** Un `L10N.md` ou `L10N/<locale>.md` imbriqué peut ajouter ou surcharger des entrées pour un dossier, tels que les pages marketing.
- **Il doit surcharger le glossaire du compte.** Une entrée de dépôt l'emporte sur une entrée de compte pour le même terme, pour les langues qu'il traduit.

## Comment elles se combinent

Pour chaque fichier et langue cible, Glossia résout les deux glossaires en un ensemble efficace :

1. Commencez par les entrées du glossaire du compte pour la langue cible.
2. Superposez les entrées du dépôt pour cette langue : les termes du `L10N.md` par défaut du fichier qui ont une traduction dans leur `L10N/<locale>.md` par défaut. Lorsque l'entrée du dépôt a le même terme source qu'une entrée de compte, l'entrée du dépôt l'emporte.
3. Si un terme du dépôt n'a pas de traduction pour une langue, l'entrée de compte pour cette langue s'applique encore. Le dépôt n'empêche jamais une langue qu'il n'a pas traduite.

La fusion se produit **par langue cible**, pas par entrée. Une traduction espagnole de "commit" dans `L10N/es.md` remplace l'entrée espagnole du compte pour "commit", mais ne touche pas l'entrée japonaise du compte pour ce terme. Les réviseurs peuvent voir quelles entrées de compte ont été remplacées : le résumé de la session de traduction montre combien ont été surchargées, et le fichier de verrouillage de chaque fichier les liste sous `glossary.shadowed`.

## Quand le glossaire change, les fichiers se rétraduisent

Lorsque vous modifiez une entrée de glossaire, Glossia ne rétraduit que les fichiers dont le *glossaire effectif a changé*. Si le texte source d'un fichier ne contient aucune correspondance pour le terme modifié, ses traductions restent intactes. Si un fichier utilise le terme, son prochain passage de traduction inclut l'instruction mise à jour.

Le même principe s'applique en sens inverse : ajouter un terme utilisé uniquement par un sous-ensemble de fichiers n'entraîne pas une réexécution complète.

## Qu'est-ce qu'un glossaire n'est pas

- Pas un dictionnaire de traduction automatique. Le modèle de Glossia lit le contexte environnant et peut rendre un terme différemment si la phrase l'exige. Le glossaire est une directive, pas un remplacement.
- Pas tout le guide de style. La voix, le ton, la formalité et le public vivent dans la configuration de la Voix de votre compte et dans `L10N.md`. Le glossaire est uniquement pour les termes individuels et leurs traductions approuvées.
- Pas silencieux. Tout terme appliqué est enregistré dans le fichier de verrouillage du fichier afin qu'un réviseur puisse tracer exactement quelles entrées de glossaire sont parvenues au modèle.

## Lié

- Ajoutez vos premiers termes : [Définir un glossaire](/docs/how-to/define-a-glossary).
- Chaque champ d'entrée : [Référence glossaire](/docs/reference/glossary).
- Les autres `L10N.md` champs : [Référence L10N.md](/docs/reference/l10n-md).
