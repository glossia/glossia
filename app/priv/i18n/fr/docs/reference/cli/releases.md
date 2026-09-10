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

- Renommer le binaire dans les archives de distribution du nom spécifique à la plateforme à `glossia`.
- Supprimer l'attribut xattr de quarantaine macOS des binaires avant l'empaquetage.

## 0.14.0

*2026-02-14*

#### Fonctionnalités

- Ajout d'un script de publication local et d'un flux de travail de journal des modifications maintenu manuellement.

## 0.2.0

*2026-02-14*

#### Corrections de bugs

- La configuration du fournisseur OAuth optionnelle en production. L'application doit démarrer même sans les identifiants OAuth GitHub/GitLab définis. Configurez les fournisseurs uniquement lorsque les variables d'environnement sont présentes.
- Utiliser le port 4000 par défaut en production et conserver 4050 pour le développement. Le proxy de production attend l'application sur le port 4000. Le `runtime.exs` préréglage était 4050, ce qui a fait échouer les vérifications de santé pendant le déploiement.

#### Fonctionnalités

- Ajout d'une application Phoenix avec connexion OAuth, améliorations de la documentation et de l'interface utilisateur.
- Utilisation du logo arrondi comme favicon.
- Migration de la CLI vers Bun et mise à jour des builds exécutables CI.

## 0.1.0

*2026-02-12*

#### Corrections de bugs

- Prévention du débordement horizontal des extraits de code sur mobile.
- Ajouter une marge de droite appropriée aux extraits de code sur mobile.
- Améliorer la mise en page responsive mobile pour éviter le débordement horizontal.
- Appliquer la mise en forme Biome.
- Ajouter des en-têtes de groupe au modèle des notes de version.
- Mettre à jour le workflow de traduction de Bun vers Rust.
- Aligner le corps de l'article avec la mise en page Hero et améliorer le contenu de l'article de blog.
- Centrer le contenu de l'article de blog horizontalement.
- Corriger la panique lors de la troncature des résultats d'outils UTF-8 multioctets.

#### Fonctionnalités

- Ajouter les outils de premier parti et la section du site web.
- Afficher les étapes de vérification des outils.
- Simplifier l'affichage de la progression.
- Appliquer une teinte aux lignes de progression.
- Afficher l'activité de traduction et de validation.
- Formater les lignes des outils.
- Rendre le site web responsive avec un menu mobile et une mise en page multi-points de rupture.
- Réimplémenter CLI en Bun/TypeScript.
- Ajouter un workflow CI et des tests.
- Ajouter la vérification de formatage avec Biome.
- Ajouter une section d'Affinement progressif à la page d'accueil.
- Ajouter une section du blog avec support SEO et premier article.
- Unifier la sortie CLI avec un format de verbe aligné à droite.
- Coloriser la sortie CLI avec un formatage de message plus riche.
- Ajouter une image OG carrée et des balises meta pour les cartes Twitter.
- Rendre l'agent coordinateur agentic avec l'utilisation d'outils.
- Réécriture `glossia init` avec le protocole Agent Client (ACP).
- Ajouter la prise en charge de Gemini, la validation automatique, le suivi des tokens et les améliorations de fiabilité.

#### Refaçonnage

- Diviser la CI en tâches de formatage, vérification de type, tests et build séparées.
- Réécrire le CLI à partir de TypeScript/Bun vers Rust.