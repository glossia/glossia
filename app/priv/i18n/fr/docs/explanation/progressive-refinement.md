%{
  title: "Affinement progressif",
  summary: "Pourquoi la qualité du contenu converge au fil du temps et non en une seule passe.",
  category: "explication",
  order: 1
}
---
Premiers brouillons de [modèles de langage à grande échelle](https://en.wikipedia.org/wiki/Large_language_model) sont corrects structurellement mais peuvent manquer de nuances, de ton ou de tournures spécifiques au domaine. C'est par conception. Glossia traite la génération de contenu de la même manière que les équipes logicielles traitent le code : publiez une version fonctionnelle, revoyez-la, et améliorez-la de manière itérative.

## Le cycle d'affinement

1. **Brouillon**: Glossia génère une première passe structurellement valide basée sur vos fichiers sources et le contexte dans `L10N.md`,
2. **Relecture**: Votre équipe signale des problèmes via des pull requests et des diffs, le même flux de travail que vous utilisez déjà pour le code.
3. **Affiner**: Les fichiers de contexte mis à jour, les corrections de terminologie et les retours de révision alimentent la prochaine exécution.
4. **Converger**: Chaque cycle réduit l'écart avec la qualité de production. Le système apprend la voix de votre produit grâce au contexte que vous fournissez.

## Pourquoi cela fonctionne

: L'intuition clé est que le contexte s'accumule. Chaque commentaire de révision menant à une mise à jour `L10N.md` ou une entrée terminologique corrigée améliore toutes les exécutions futures, pas seulement le fichier ayant déclenché la révision.

Cela suit le même principe que Kaizen en fabrication et l'approximation successive en ingénierie : commencez avec une base acceptable et améliorez-la systématiquement avec le jugement humain dans la boucle.

## Implications pratiques

- Ne comptez pas sur la perfection lors de la première exécution. Prévoyez un ou deux cycles de révision.
- Investissez du temps à la rédaction de fichiers de contexte clairs. Ce sont les améliorations à plus fort effet de levier que vous puissiez apporter.
- Utilisez la session de traduction du serveur pour suivre quels fichiers ont été traduits,
  omis, ou échoués.