%{
  title: "Raffinement progressif",
  summary: "Pourquoi la qualité du contenu converge au fil du temps, et non en un seul passage.",
  category: "explication",
  order: 1
}
---
Premiers brouillons de [grands modèles de langage](https://en.wikipedia.org/wiki/Large_language_model) sont structuralement corrects mais peuvent manquer la nuance, le ton ou les formulations spécifiques au domaine. C'est par conception. Glossia traite la génération de contenu de la même manière que les équipes logicielles traitent le code : livrez une version fonctionnelle, révisez-la, puis améliorez-la de manière itérative.

## La boucle d'affinement

1. **Brouillon**: Glossia génère une première passe structuralement valide sur la base de vos fichiers sources et le contexte dans `L10N.md`.
2. **Revue**: votre équipe signale des problèmes via les pull requests et les diffs, le même flux de travail que vous utilisez déjà pour le code.
3. **Affiner**: les fichiers de contexte mis à jour, les corrections terminologiques et les retours de relecture alimentent la prochaine exécution.
4. **Converger**: Chaque cycle réduit la distance à la qualité de production. Le système apprend la voix de votre produit grâce au contexte que vous fournissez.

## Pourquoi cela fonctionne

: L'idée clé est que le contexte s'accumule. Chaque commentaire de relecture aboutissant à une mise à jour `L10N.md` ou une entrée terminologique corrigée améliore tous les futurs passages, et non seulement le fichier ayant déclenché la relecture.

Cela suit le même principe que celui du Kaizen dans la fabrication et de l'approximation successive en ingénierie : commencez avec un socle de départ suffisant et améliorez-le systématiquement avec le jugement humain dans la boucle.

## Implications pratiques

- N'attendez pas la perfection à la première exécution. Prévoyez un ou deux cycles de révision.
- Investissez du temps pour rédiger des fichiers de contexte clairs. Ce sont les améliorations les plus efficaces que vous puissiez apporter.
- Utilisez la session de traduction du serveur pour suivre les fichiers traduits,
  omis, ou échoués.