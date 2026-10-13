%{
  title: "Versions",
  summary: "Historique des versions CLI.",
  category: "Référence",
  subcategory: "CLI",
  order: 2
}
---

## 0.14.1

*2026-02-14*

#### Corrections de bugs
- Renommer le binaire à l'intérieur des archives de version à partir du nom spécifique à la plateforme jusqu'à simplement `glossia`.
- Supprimer l'attribut de quarantaine macOS xattr des binaires avant l'emballage.

## 0.14.0

*2026-02-14*

#### Fonctionnalités
- Ajouter un script de version locale et un flux de travail d'historique des modifications maintenu manuellement.

## 0.2.0

*2026-02-14*

#### Corrections de bugs
- Corriger la gestion de la configuration du fournisseur d'authentification hébergé.
- Corriger les contrôles de santé des services hébergés.

#### Fonctionnalités
- Ajouter une application Phoenix avec authentification OAuth, améliorations de la documentation et améliorations de l'interface utilisateur.
- Utiliser le logo arrondi comme favicon.
- Migrer le CLI vers Bun et mettre à jour les builds exécutables CI.

## 0.1.0

*2026-02-12*

#### Corrections de bugs
- Empêcher le débordement horizontal des extrait de code sur mobile.
- Ajouter une marge droite appropriée aux extraits de code sur mobile.
- Améliorer la disposition responsive mobile pour empêcher le débordement horizontal.
- Appliquer le formatage Biome.
- Ajouter des titres de groupe au modèle des notes de version.
- Mettre à jour le workflow de traduction de Bun vers Rust.
- Aligner le corps du message avec la disposition hero et améliorer le contenu du message de blog.
- Centrer le contenu du message de blog horizontalement.
- Corriger la panique lors de la troncation des résultats d'outils multi-octets UTF-8.

#### Fonctionnalités
- Ajouter une section d'outils de la première partie et du site web.
- Rendre visibles les étapes de vérification de l'outil.
- Simplifier la sortie de progression.
- Appliquer une teinte aux lignes de progression.
- Afficher l'activité de traduction et de validation.
- Formater les lignes des outils.
- Rendre le site web responsive avec un menu mobile et une disposition multi-point de rupture.
- Réimplémenter le CLI en Bun/TypeScript.
- Ajouter un workflow CI et des tests.
- Ajouter une vérification de format avec Biome.
- Ajouter la section d'affinement progressif à la page d'accueil.
- Ajouter une section de blog avec support SEO et premier message de blog.
- Unifier la sortie CLI avec un format de verbe aligné à droite.
- Coloriser la sortie CLI avec un formatage de message plus riche.
- Ajouter une image carrée OG et des balises meta de carte Twitter.
- Rendre l'agent de coordinateur agentic avec l'utilisation d'outils.
- Réécrire `glossia init` avec le protocole Agent Client (ACP).
- Ajouter le support de Gemini, la validation automatique, le suivi des jetons et des améliorations de la fiabilité.

#### Réstructurations
- Séparer la CI en tâches distinctes de format, de vérification de type, de test et de builds.
- Réécrire le CLI de TypeScript/Bun vers Rust.
