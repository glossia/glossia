%{
  title: "Localisation continues",
  summary:
    "Intégrez les modifications linguistiques dans la boucle de livraison versionnée du produit, plutôt qu'à un cycle d'exportation et d'importation séparé.",
  category: "explication",
  section: "translation",
  order: 2
}
---

La livraison continue fonctionne parce que les petites modifications traversent un pipeline répétable : contrôle de version, révision, validation et déploiement. La localisation doit s'intégrer à ce pipeline plutôt que d'introduire un système de registre inutile.

## La boucle déconnectée

Dans un flux de travail déconnecté, un changement de produit déclenche une exportation, le travail se fait dans un autre outil, et le contenu traduit revient à la fin. Entre ces étapes, la source peut changer à nouveau. Les équipes doivent concilier les versions, décider si les traductions sont obsolètes et coordonner une autre version.

Le problème n'est pas qu'un éditeur web soit intrinsèquement incorrect. Il s'agit de ce qu'un système d'édition autoritaire indépendant peut séparer les décisions linguistiques du code et de la révision de contenu qu'ils décrivent.

## La boucle du référentiel

Le flux de travail du référentiel de Glossia conserve les fichiers source et la configuration de localisation dans Git. Un référentiel connecté fournit le contenu et les langues cibles. Les modifications de traduction retournent sous la forme de modifications de référentiel révisables, permettant ainsi aux équipes d'appliquer leurs conventions existantes de pull-request et de publication.

Une boucle typique est :

1. Une équipe modifie le contenu source avec le produit.
2. Glossia identifie les contenus qui nécessitent une traduction ou un affinement.
3. Les directives linguistiques et la terminologie fournissent un contexte pour la transformation.
4. La validation vérifie le résultat et les échecs restent actionnables.
5. Les réviseurs inspectent les changements avant que le pipeline de publication ne les livre.

[Affinement progressif](./progressive-refinement) explique comment l'hachage et la validation s'intègrent à cette boucle. [Récupération de traduction](./translation-recovery) explique ce qui se passe lors d'une génération ou d'une validation ratée.

## Continu ne signifie pas inexaminé

Un changement livrable en continu n'est pas nécessairement approuvé automatiquement. Les clauses juridiques, les promesses produit et le matériel culturellement sensible peuvent nécessiter une révision spécialisée. Conserver cette révision dans la boucle de livraison permet à une équipe de choisir la porte appropriée sans maintenir une autorité de publication distincte.

La localisation continue ne signifie pas non plus traduire l'ensemble du référentiel sur chaque commit. Le contenu inchangé ne doit pas consommer les mêmes ressources à nouveau.

## La limite pratique

Glossia fournit le contexte linguistique et les mécanismes de localisation. Les vérifications et le processus de déploiement de votre référentiel définissent toujours quand un changement est sûr de être publié. Glossia n'est pas un substitut aux tests d'application ni à la responsabilité d'un éditeur quant à l'exactitude.

D'autres plateformes offrent également des intégrations Git et une automatisation CI. La distinction est le centre de gravité visé : Glossia est construit autour de la propriété du contenu et de la révision dans le référentiel, et non d'une exigence de déplacer l'autorité éditoriale en cours vers un espace de travail de traduction hébergé.
