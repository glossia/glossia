%{
  title: "Affinement progressif",
  summary: "Pourquoi la qualité du contenu converge avec le temps, et non en un seul passage.",
  category: "Explication",
  order: 1
}
---
Premiers brouillons de [grands modèles de langage](https://en.wikipedia.org/wiki/Large_language_model) sont structurellement corrects, mais peuvent manquer de nuances, de ton ou de formulations spécifiques au domaine. C'est par conception. Glossia traite la génération de contenu de la même manière que les équipes logicielles traitent le code : livrer une version fonctionnelle, la réviser et l'améliorer de manière itérative.

## Boucle d'affinement

1. **Brouillon**: Glossia génère une première passe structurellement valide basée sur vos fichiers sources et le contexte dans `L10N.md`.
2. **Revue**: Votre équipe signale des problèmes via les pull requests et les diffs, le même flux de travail que vous utilisez déjà pour le code.
3. **Affiner**: Les fichiers de contexte mis à jour, les corrections de terminologie et les retours de révision contribuent à la prochaine exécution.
4. **Converger**: Chaque cycle réduit la distance à la qualité de production. Le système apprend la voix de votre produit grâce au contexte que vous fournissez.

## Pourquoi cela fonctionne

Le principe clé est que le contexte s'accumule. Chaque commentaire de révision qui conduit à une mise à jour `L10N.md` ou une entrée terminologique rectifiée améliore toutes les exécutions futures, pas seulement le fichier ayant déclenché la révision.

Ceci suit le même principe que le Kaizen dans la fabrication et l'approximation successive en ingénierie : commencez avec une base jugée suffisante et améliorez-la systématiquement avec le jugement humain en boucle.

## Implications pratiques

- Ne comptez pas sur la perfection lors de la première exécution. Prévoyez un ou deux cycles de révision.
- Prenez le temps d'écrire des fichiers de contexte clairs. Ils constituent l'amélioration la plus rentable que vous puissiez apporter.
- Utilisez la session de traduction du serveur pour suivre quels fichiers ont été traduits,
  ignorés, ou échoués.