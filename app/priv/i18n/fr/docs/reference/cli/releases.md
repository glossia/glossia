%{
  title: "Sorties",
  summary: "Historique des sorties CLI.",
  category: "Référence",
  subcategory: "CLI",
  order: 2
}
---

## 0.14.1

*2026-02-14*

#### Corrections de bogues
- Renommer le binaire contenu dans les archives de distribution du nom spécifique à la plateforme à simplement `glossia`.
- Supprimer l'attribut xattr de quarantaine macOS des binaires avant l'emballage.

## 0.14.0

*2026-02-14*

#### Fonctionnalités
- Ajouter un script de publication local et un workflow de journal de modification maintenu manuellement.

## 0.2.0

*2026-02-14*

#### Corrections de bogues
- Corriger la gestion de la configuration du fournisseur d'identification hébergé.
- Corriger les vérifications de santé du service hébergé.

#### Fonctionnalités
- Ajouter l'application Phoenix avec connexion OAuth, améliorations de la documentation et améliorations de l'interface utilisateur.
- Utiliser le logo arrondi comme favicon.
- Migrer l'interface en ligne de commande vers Bun et mettre à jour les builds d'exécutables CI.

## 0.1.0

*2026-02-12*

#### Corrections de bogues
- Prévenir le débordement horizontal des extraits de code sur mobile.
- Ajouter une marge droite appropriée aux extraits de code sur mobile.
- Améliorer la disposition réactive sur mobile pour éviter le débordement horizontal.
- Appliquer le formatage Biome.
- Ajouter des en-têtes de groupe au modèle des notes de version.
- Mettre à jour le flux de traduction de Bun vers Rust.
- Aligner le corps du message avec la disposition Hero et améliorer le contenu du message de blog.
- Centrer le contenu du message de blog horizontalement.
- Corriger la panique lors de la troncature des résultats d'outils multi-octets UTF-8.

#### Fonctionnalités
- Ajouter les outils de première partie et la section de site web.
- Afficher les étapes de vérification des outils.
- Simplifier la sortie de progression.
- Appliquer une teinte aux lignes de progression.
- Afficher l'activité de traduction et de validation.
- Formater les lignes d'outils.
- Rendre le site web réactif avec un menu mobile et une disposition multi-point de rupture.
- Réimplémenter CLI en Bun/TypeScript.
- Ajouter un workflow CI et des tests.
- Ajouter la vérification de format avec Biome.
- Ajouter la section Affinement progressif à la page d'accueil.
- Ajouter une section de blog avec support SEO et premier message de blog.
- Unifier la sortie CLI avec le format de verbe aligné à droite.
- Coloriser la sortie CLI avec un formatage de message plus riche.
- Ajouter une image OG carrée et les balises meta de carte Twitter.
- Rendre l'agent coordinateur agentic avec utilisation d'outils.
- Réécrire `glossia init` avec le Protocole Agent Client (ACP).
- Ajouter le support Gemini, la validation automatique, le suivi des jetons et les améliorations de la fiabilité.

#### Réaménagements
- Diviser CI en tâches distinctes de formatage, vérification de type, test et builds.
- Réécrire l'interface en ligne de commande de TypeScript/Bun vers Rust.
