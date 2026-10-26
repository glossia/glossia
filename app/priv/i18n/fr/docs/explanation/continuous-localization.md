%{
  title: "Localisation continue",
  summary:
    "Intégrez les modifications linguistiques dans la boucle de livraison versionnée du produit, plutôt que dans un cycle d'exportation et d'importation séparé.",
  category: "Explication",
  section: "translation",
  order: 2
}
---

La livraison continue fonctionne car de petites modifications traversent une pipeline reproductible : contrôle de version, examen, validation et déploiement. La localisation devrait s'aligner sur cette pipeline plutôt que d'introduire un système de référence indépendant.

## La boucle déconnectée

Dans un flux de travail déconnecté, un changement de produit déclenche une exportation, le travail se fait dans un autre outil, et le contenu traduit revient en retour. Entre ces étapes, la source peut changer à nouveau. Les équipes doivent harmoniser les versions, décider si les traductions sont obsolètes et coordonner une autre mise à jour.

Le problème n'est pas qu'un éditeur Web est intrinsèquement incorrect. C'est qu'un système d'édition de référence indépendant peut séparer les décisions linguistiques du code et de la révision de contenu qu'ils décrivent.

## La boucle de dépôt

Le flux de travail de dépôt de Glossia conserve les fichiers source et la configuration de localisation dans Git. Un dépôt connecté fournit le contenu et les langues cibles. Les changements de traduction retournent comme des modifications de dépôt révisables, permettant ainsi aux équipes d'appliquer leurs conventions de pull request et de publication existantes.

Une boucle typique est :

1. L'équipe modifie le contenu de la source avec le produit.
2. Glossia identifie le contenu nécessitant une traduction ou un affinement.
3. Les directives linguistiques et la terminologie fournissent le contexte pour la transformation.
4. La validation vérifie le résultat et les échecs restent actionnables.
5. Les réviseurs examinent les changements avant que la pipeline de publication ne les livre.

[Affinement progressif](./progressive-refinement) explique comment le hachage et la validation s'intègrent à cette boucle. [Récupération de traduction](./translation-recovery) explique ce qui se produit lors d'un échec de génération ou de validation.

## La livraison continue ne signifie pas sans examen

Un changement continuellement livrable n'est pas nécessairement approuvé automatiquement. Le langage juridique, les promesses de produit et les matériaux culturels sensibles peuvent nécessiter un examen par des spécialistes. Garder cet examen dans la boucle de livraison permet à une équipe de choisir la passerelle appropriée sans maintenir une autorité de publication séparée.

La localisation continue ne signifie pas non plus traduire l'intégralité du dépôt à chaque commit. Le contenu inchangé ne devrait pas consommer les mêmes ressources à plusieurs reprises.

## La limite pratique

Glossia fournit le contexte linguistique et les mécanismes de localisation. Les contrôles et le processus de déploiement de votre dépôt définissent toujours quand un changement est sûr à publier. Glossia n'est pas un substitut aux tests d'application ni à la responsabilité d'un éditeur concernant l'exactitude.

D'autres plateformes offrent également des intégrations Git et une automatisation CI. La distinction réside dans le centre de gravité visé : Glossia est construit autour de la propriété du contenu et de son examen dans le dépôt, et non d'une obligation de déplacer l'autorité éditoriale en cours dans un espace de travail de traduction hébergé.
