%{
  title: "Affinement progressif",
  summary: "Pourquoi la qualité du contenu converge au fil du temps, et non en une seule passe.",
  category: "explication",
  order: 1
}
---
Premiers jets de[gros modèles de langage](https://en.wikipedia.org/wiki/Large_language_model) sont corrects structurellement mais peuvent manquer de nuances, de ton ou de formulations spécifiques au domaine. C'est par conception. Glossia traite la génération de contenu de la même façon que les équipes logiciels traitent le code : déployer une version fonctionnelle, la revoir et l'améliorer de manière itérative.

## La boucle d'affinement

1. **Brouillon**: Glossia génère un premier jet structurellement valide basé sur vos fichiers sources et le contexte de`GLOSSIA.md`.
2. **Examen**: Votre équipe signale les problèmes via des pull requests et des diffs, le même flux de travail que vous utilisez déjà pour le code.
3. **Affiner**: Les fichiers de contexte mis à jour, les corrections de terminologie et les commentaires d'examen alimentent la prochaine exécution.
4. **Convergence**: Chaque cycle réduit l'écart avec la qualité de production. Le système apprend la voix de votre produit grâce au contexte que vous fournissez.

## Pourquoi cela fonctionne

La clé de l'intuition est que le contexte s'accumule. Chaque commentaire d'examen qui conduit à une`GLOSSIA.md` ou une entrée de terminologie corrigée améliore toutes les exécutions futures, pas seulement le fichier qui a déclenché l'examen.

Cela suit le même principe derrière le Kaizen dans la fabrication et l'approximation successive en génie : commencer par une base suffisante et l'améliorer systématiquement avec le jugement humain dans la boucle.

## Conséquences pratiques

- Ne pas attendre la perfection lors de la première exécution. Planifiez avec un ou deux cycles d'examen.
- Investissez du temps pour écrire des fichiers de contexte clairs. Ils constituent l'amélioration la plus rentable que vous puissiez apporter.
- Utilisez la session de traduction du serveur pour suivre les fichiers traduits,
  ignorés ou ayant échoué.