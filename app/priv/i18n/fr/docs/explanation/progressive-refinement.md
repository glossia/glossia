%{
  title: "Affinement progressif",
  summary: "Pourquoi la qualité du contenu converge au fil du temps, et non en une seule passe.",
  category: "explication",
  order: 1
}
---
Premiers brouillons de [grands modèles de langage](https://en.wikipedia.org/wiki/Large_language_model) sont structurellement corrects mais peuvent manquer de nuances, de ton ou de formulations spécifiques au domaine. C'est par conception. Glossia traite la génération de contenu de la même manière que les équipes logicielles traitent le code : lancez une version fonctionnelle, revoyez-la et améliorez-la itérativement.

## La boucle d'affinement

1. **Brouillon**: Glossia génère une première passe structurellement valide basée sur vos fichiers sources et le contexte dans `L10N.md`.
2. **Revue**: Votre équipe signale des problèmes via les pull requests et les diffs, le même workflow que vous utilisez déjà pour le code.
3. **Affiner**: Les fichiers de contexte mis à jour, les corrections de terminologie et les retours de révision alimentent la prochaine exécution.
4. **Converger**: Chaque cycle réduit l'écart avec la qualité de production. Le système apprend la voix de votre produit grâce au contexte que vous fournissez.

## Pourquoi cela fonctionne

Le principe clé est que le contexte s'accumule. Chaque commentaire de révision qui conduit à une mise à jour `L10N.md` ou une entrée terminologique corrigée améliore toutes les exécutions futures, et pas seulement le fichier qui a déclenché la révision.

Ceci suit le même principe que le Kaizen en fabrication et l'approximation successive en ingénierie : commencez avec une base suffisante et améliorez-la systématiquement avec un jugement humain en boucle.

## Conséquences pratiques

- Ne comptez pas sur la perfection lors du premier lancement. Prévoyez un ou deux cycles de révision.
- Investissez du temps dans la rédaction de fichiers de contexte clairs. Ils constituent l'amélioration la plus efficace que vous puissiez apporter.
- Utilisez la session de traduction du serveur pour suivre quels fichiers ont été traduits,
  ignorés, ou échoués.