%{
  title: "Localisation continue",
  summary:
    "Intégrez les changements de langue dans la boucle de livraison versionnée du produit plutôt que dans un cycle d'exportation et d'importation séparé.",
  category: "explication",
  section: "translation",
  order: 2
}
---

La livraison continue fonctionne parce que les petites modifications traversent un pipeline reproductible : contrôle de version, revue, validation et déploiement. La localisation devrait s'intégrer à ce pipeline plutôt que d'introduire un système de registre indépendant.

## La boucle déconnectée

Dans un flux de travail déconnecté, une modification de produit déclenche une exportation, le travail se fait dans un autre outil et le contenu traduit revient finalement. Entre ces étapes, la source peut changer à nouveau. Les équipes doivent harmoniser les versions, décider si les traductions sont obsolètes et coordonner un autre déploiement.

Le problème n'est pas qu'un éditeur web soit intrinsèquement incorrect. C'est que le système d'édition, possédant une autorité indépendante, peut séparer les décisions linguistiques du code et des révisions de contenu qu'il décrit.

## La boucle de dépôt

Le flux de travail de dépôt de Glossia conserve les fichiers sources et la configuration de localisation dans Git. Un dépôt connecté fournit le contenu et les langues cibles. Les modifications de traduction reviennent sous forme de modifications de dépôt révisables, permettant aux équipes d'appliquer leurs conventions de pull-request et de publication existantes.

Une boucle typique est :

1. L'équipe modifie le contenu source avec le produit.
2. Glossia identifie le contenu qui nécessite une traduction ou un affinement.
3. Les directives linguistiques et la terminologie fournissent le contexte pour la transformation.
4. La validation vérifie le résultat et les échecs restent actionnables.
5. Les réviseurs examinent les changements avant que le pipeline de publication ne les livre.

[Raffinement progressif](./progressive-refinement) explique comment l'hachage et la validation s'intègrent dans cette boucle. [Récupération de traduction](./translation-recovery) explique ce qui se produit lors de l'échec de la génération ou de la validation.

## La livraison continue ne signifie pas une absence de révision.

Une modification livrable en continu n'est pas nécessairement une modification automatiquement approuvée. Le langage juridique, les promesses de produit et les éléments culturellement sensibles peuvent nécessiter une révision spécialisée. Maintenir cette révision dans la boucle de livraison permet à une équipe de choisir le contrôle approprié sans préserver une autorité de publication séparée.

La localisation continue ne signifie pas non plus de traduire l'ensemble du dépôt à chaque commit. Le contenu inchangé ne devrait pas consommer les mêmes ressources à plusieurs reprises.

## La limite pratique

Glossia fournit le contexte linguistique et les mécanismes de localisation. Les contrôles et le processus de déploiement de votre dépôt définissent toujours quand une modification est sûre pour publier. Glossia n'est pas un substitut aux tests d'application ni la responsabilité d'un éditeur pour la précision.

D'autres plateformes offrent également des intégrations Git et une automatisation CI. La distinction réside dans le centre de gravité prévu : Glossia est construit autour de la propriété et de la révision du contenu dans le dépôt, et non sur l'obligation de déplacer l'autorité éditoriale continue vers un espace de traduction hébergé.
