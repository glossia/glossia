%{
  title: "Versions",
  summary: "Historique des versions CLI.",
  category: "Référence",
  subcategory: "cli",
  order: 2
}
---

## 0.14.1

*2026-02-14*

#### Corrections de bugs
- Renommez le binaire dans les archives de publication du nom spécifique à la plateforme vers simplement `glossia`.
- Éliminez l'attribut xattr de quarantaine de macOS des binaires avant l'emballage.

## 0.14.0

*2026-02-14*

#### Fonctionnalités
- Ajout d'un script de publication local et d'un flux de travail de journal des modifications maintenu manuellement.

## 0.2.0

*2026-02-14*

#### Corrections de bugs
- Correction du traitement de la configuration de la connexion hébergée.
- Correction des vérifications de santé du service hébergé.

#### Fonctionnalités
- Ajout de l'application Phoenix avec la connexion OAuth, les améliorations de la documentation et les améliorations de l'interface utilisateur.
- Utilisez le logo arrondi comme favicon.
- Migration du CLI vers Bun et mise à jour des builds exécutables de CI.

## 0.1.0

*2026-02-12*

#### Corrections de bugs
- Empêchez le débordement horizontal des extraits de code sur mobile.
- Ajouter une marge droite appropriée aux extraits de code sur mobile.
- Améliorer la mise en page responsive mobile pour éviter le débordement horizontal.
- Appliquer le formatage Biome.
- Ajouter des titres de groupe au modèle de notes de publication.
- Mettre à jour le flux de travail de traduction de Bun vers Rust.
- Aligner le corps du message avec la mise en page Hero et améliorer le contenu du post de blog.
- Centrer le contenu du post de blog horizontalement.
- Correction de la panique lors du tronçonnage des résultats d'outils multi-octets UTF-8.

#### Fonctionnalités
- Ajout des outils de premier parti et de la section du site web.
- Présenter les étapes de vérification des outils.
- Simplifier la sortie de progression.
- Appliquer une couleur par défaut aux lignes de progression.
- Afficher l'activité de traduction et de validation.
- Formater les lignes d'outils.
- Rendre le site web responsive avec un menu mobile et une mise en page multi-point de rupture.
- Reimplémenter le CLI dans Bun/TypeScript.
- Ajouter le flux de travail CI et les tests.
- Ajouter la vérification de format avec Biome.
- Ajouter la section Progressive Refinement à la page d'accueil.
- Ajouter une section blog avec support SEO et premier post de blog.
- Unifier la sortie du CLI avec un format de verbe aligné à droite.
- Colorier la sortie du CLI avec un formatage de message plus riche.
- Ajouter une image carrée OG et des balises meta de cartes Twitter.
- Rendre l'agent coordinateur autonome avec l'utilisation d'outils.
- Réécrire `glossia init` avec le Protocole Client Agent (ACP).
- Ajout du support Gemini, de la validation automatique, du suivi des jetons et des améliorations de fiabilité.

#### Améliorations d'architecture
- Diviser CI en tâches séparées de formatage, de vérification de type, de test et de build.
- Réécrire le CLI de TypeScript/Bun vers Rust.
