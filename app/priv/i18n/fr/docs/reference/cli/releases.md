%{
  title: "Dernières versions",
  summary: "Historique des versions CLI.",
  category: "Référence",
  subcategory: "CLI",
  order: 2
}
---
## 0.14.1

*2026-02-14*

#### Corrections

- Renommer le binaire à l'intérieur des archives de release du nom spécifique à la plateforme au `glossia`.
- Supprimer l'attribut xattr de quarantaine macOS des binaires avant l'empaquetage.

## 0.14.0

*2026-02-14*

#### Fonctionnalités

- Ajout d'un script de release local et d'un workflow de journal des modifications maintenu manuellement.

## 0.2.0

*2026-02-14*

#### Corrections de bugs

- Rendre la configuration du fournisseur OAuth optionnelle en production. L'application doit démarrer même sans les identifiants OAuth GitHub/GitLab paramétrés. Ne configurez les fournisseurs que lorsque les variables d'environnement sont présentes.
- Utiliser le port 4000 par défaut pour la production et garder 4050 pour le développement. Le proxy de production s'attend à ce que l'application soit sur le port 4000. Le `runtime.exs` paramètre par défaut était 4050, ce qui a fait échouer les contrôles de santé lors du déploiement.

#### Fonctionnalités

- Ajout d'une application Phoenix avec connexion OAuth, améliorations de la documentation et de l'interface utilisateur.
- Utilisation du logo arrondi comme favicon.
- Migration du CLI vers Bun et mise à jour des builds exécutables CI.

## 0.1.0

*2026-02-12*

#### Corrections de bugs

- Prévention du débordement horizontal des extraits de code sur mobile.
- Ajouter une marge droite appropriée aux extraits de code sur mobile.
- Améliorer la mise en page mobile adaptative pour éviter le débordement horizontal.
- Appliquer le formatage biome.
- Ajouter des titres de groupe au modèle de notes de version.
- Mettre à jour le flux de traduction de Bun vers Rust.
- Aligner le corps de la publication avec la mise en page hero et améliorer le contenu des articles de blog.
- Centrer horizontalement le contenu des articles de blog.
- Corriger la panique lors de la troncature des résultats d'outils UTF-8 multi-octets.

#### Fonctionnalités

- Ajouter la section d'outils de première partie et de site web.
- Mettre en évidence les étapes de vérification des outils.
- Simplifier l'affichage de la progression.
- Appliquer une teinte aux lignes de progression.
- Afficher l'activité de traduction et de validation.
- Mettre en forme les lignes d'outils.
- Rendre le site web réactif avec un menu mobile et une mise en page à plusieurs points de rupture.
- Réimplémenter CLI dans Bun/TypeScript.
- Ajouter un workflow CI et des tests.
- Ajouter la vérification de format avec Biome.
- Ajouter une section Affinement progressif à la page d'accueil.
- Ajouter une section de blog avec support SEO et le premier article.
- Unifier la sortie CLI avec un format de verbe aligné à droite.
- Coloriser la sortie CLI avec un formatage de messages plus riche.
- Ajouter une image OG carrée et les balises meta Twitter Card.
- Rendre l'agent de coordination agentique avec l'utilisation d'outils.
- Réécriture `glossia init` avec le protocole Agent Client (ACP).
- Ajout de la prise en charge de Gemini, la validation automatique, le suivi des jetons et les améliorations de la fiabilité.

#### Refonte

- Diviser CI en jobs distincts : formatage, vérification de type, tests et build.
- Réécriture de la CLI de TypeScript/Bun vers Rust.