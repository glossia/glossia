%{
  title: "Amélioration progressive",
  summary: "Pourquoi la qualité du contenu converge au fil du temps, et non en une seule passe.",
  category: "explication",
  section: "translation",
  order: 1
}
---

Les premiers jets générés par [modèles de langage de grande échelle](https://en.wikipedia.org/wiki/Large_language_model) sont structuralement corrects mais peuvent manquer de nuances, de ton ou de formulations spécifiques au domaine. C'est par conception. Glossia traite la génération de contenu de la même manière que les équipes logicielles traitent le code : livrez une version fonctionnelle, révisez-la et améliorez-la de manière itérative.

## La boucle de raffinement

1. **Brouillon** : Glossia génère une première version structurellement valide basée sur vos fichiers sources et le contexte dans `L10N.md`.
2. **Revue** : Votre équipe signale les problèmes via les pull requests et les diffs, le même flux de travail que vous utilisez déjà pour le code.
3. **Affiner** : Les fichiers de contexte mis à jour, les corrections de glossaire et les retours de révision s'intègrent dans la prochaine exécution.
4. **Convergence** : Chaque cycle réduit la distance vers la qualité de production. Le système apprend la voix de votre produit grâce au contexte que vous fournissez.

## Pourquoi cela fonctionne

L'insight clé est que le contexte s'accumule. Chaque commentaire de révision qui conduit à une mise à jour de `L10N.md` ou à une entrée de glossaire corrigée améliore toutes les exécutions futures, et non seulement le fichier ayant déclenché la révision.

Cela suit le même principe sous-jacent à Kaizen en fabrication et à l'approximation successive en ingénierie : commencez par une base de départ suffisante et améliorez-la systématiquement avec le jugement humain dans la boucle.

## Conséquences pratiques

- Ne vous attendez pas à la perfection lors de la première exécution. Prévoyez un ou deux cycles de révision.
- Investissez du temps à rédiger des fichiers de contexte clairs. Ce sont les améliorations les plus rentables que vous puissiez apporter.
- Utilisez la session de traduction de Glossia pour suivre les fichiers traduits, omis ou échoués.
