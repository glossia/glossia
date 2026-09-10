%{
  title: "Affinement progressif",
  summary: "Pourquoi la qualité du contenu converge au fil du temps, et non en un seul passage.",
  category: "explication",
  order: 1
}
---
Premiers brouillons à partir de [grands modèles de langage](https://en.wikipedia.org/wiki/Large_language_model) sont structurellement corrects mais peuvent manquer de nuances, de ton, ou de formulations spécifiques au domaine. C'est par conception. Glossia traite la génération de contenu de la même manière que les équipes logicielles traitent le code : livrer une version fonctionnelle, la revoir et l'améliorer de manière itérative.

## La boucle d'affinement

1. **Brouillon**: Glossia génère un premier passage structurellement valide basé sur vos fichiers sources et le contexte dans `L10N.md`.
2. **Reviser**Votre équipe signale les problèmes via des pull requests et des diffs, le même flux de travail que vous utilisez déjà pour le code.
3. **Affiner**Les fichiers de contexte mis à jour, les corrections terminologiques et les retours de revue alimentent la prochaine exécution.
4. **Converger**Chaque cycle rapproche la qualité de production. Le système apprend la voix de votre produit grâce au contexte que vous fournissez.

## Pourquoi cela fonctionne

Le principe clé est que le contexte s'accumule. Chaque commentaire de revue qui conduit à une mise à jour `L10N.md` ou une entrée terminologique corrigée améliore toutes les exécutions futures, pas seulement le fichier ayant déclenché la revue.

Ceci suit le même principe que le Kaizen dans la production et l'approximation successive en ingénierie : commencez avec une base suffisante et améliorez-la systématiquement avec le jugement humain dans la boucle.

## Implications pratiques

- N'attendez pas la perfection à la première exécution. Prévoyez un ou deux cycles de révision.
- Investissez du temps pour rédiger des fichiers de contexte clairs. Ils représentent l'amélioration offrant le meilleur levier que vous puissiez apporter.
- Utilisez la séance de traduction du serveur pour suivre quels fichiers ont été traduits,
  ignorés, ou échoués.