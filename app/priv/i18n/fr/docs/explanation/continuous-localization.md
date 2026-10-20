%{
  title: "Localisation continue",
  summary:
    "Intégrez les modifications linguistiques dans la boucle de livraison versionnée du produit, plutôt que dans un cycle d'exportation et d'importation séparé.",
  category: "explication",
  section: "translation",
  order: 2
}
---

La livraison continue fonctionne car les petits changements traversent un pipeline répétitif : contrôle de version, revue, validation et déploiement. La localisation doit s'intégrer à ce pipeline plutôt que d'introduire un système de référence non lié.

## La boucle déconnectée

Dans un flux de travail déconnecté, une modification produit déclenche une exportation, les travaux sont effectués dans un autre outil et le contenu traduit revient à terme. Entre ces étapes, la source peut subir à nouveau des modifications. Les équipes doivent réconcilier les versions, décider si les traductions sont périmées et coordonner une autre livraison.

Le problème n'est pas qu'un éditeur web est intrinsèquement erroné. C'est qu'un système d'édition auo-vérité indépendamment peut séparer les décisions linguistiques du code et de la révision de contenu qu'ils décrivent.

## La boucle du dépôt

Le flux de travail de dépôt de Glossia conserve les fichiers source et la configuration de localisation dans Git. Un dépôt connecté fournit le contenu et les langues cibles. Les modifications de traduction reviennent sous forme de modifications de dépôt révisables, permettant aux équipes d'appliquer leurs conventions existantes de pull request et de publication.

Une boucle typique est :

1. Une équipe modifie le contenu source avec le produit.
2. Glossia identifie le contenu qui nécessite une traduction ou un affinement.
3. L'orientation linguistique et la terminologie fournissent le contexte pour la transformation.
4. La validation vérifie le résultat et les échecs restent actionnables.
5. Les réviseurs inspectent les modifications avant que le pipeline de publication ne les livre.

[Affinement progressif](./progressive-refinement) explique comment l'hashing et la validation s'intègrent dans cette boucle. [Récupération de traduction](./translation-recovery) explique ce qui se produit lors de l'échec de la génération ou de la validation.

## La livraison continue ne signifie pas l'absence de révision

Une modification continuellement livrable n'est pas nécessairement une modification automatiquement approuvée. Le langage juridique, les promesses de produit et les matériaux culturellement sensibles peuvent nécessiter l'examen d'experts. Maintenir cette révision dans le pipeline de livraison permet à une équipe de choisir le contrôle approprié sans maintenir une autorité de publication distincte.

La localisation continue ne signifie pas non plus de traduire l'intégralité du dépôt à chaque commit. Le contenu inchangé ne devrait pas consommer les mêmes ressources à la répétition.

## La limite pratique

Glossia fournit le contexte linguistique et les mécanismes de localisation. Les vérifications et le processus de déploiement de votre dépôt définissent toujours quand une modification est sûre à publier. Glossia n'est pas un substitut aux tests d'application ni à la responsabilité d'un éditeur concernant l'exactitude.

D'autres plateformes offrent également des intégrations Git et de l'automatisation CI. La distinction réside dans le centre de gravité visé : Glossia est construit autour de la propriété du contenu et de sa révision dans le dépôt, et non par une obligation de déplacer l'autorité éditoriale en cours dans un espace de travail de traduction hébergé.
