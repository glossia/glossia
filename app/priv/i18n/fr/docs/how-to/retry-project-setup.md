%{
  title: "Réessayer la configuration du projet",
  summary: "Restaurer un projet suite à un échec de configuration.",
  category: "Guide",
  section: "traduction",
  order: 4
}
---
Utilisez **Réessayer la configuration** après avoir corrigé la condition qui a provoqué l'échec de la configuration du projet.

## 1\. Lisez l'échec

Ouvrez la vue d'ensemble du projet. La carte de progression de configuration affiche l'échec et les dernières activités de configuration.

Les causes courantes incluent :

- Le compte n'a aucun modèle configuré.
- La clé du fournisseur est manquante ou n'est plus valide.
- Le Glossia GitHub App n'a pas accès au dépôt.
- Le dépôt n'a pas pu être préparé ou vérifié.

## 2\. Corriger le pré-requis.

Pour les problèmes de modèle, ouvrez **Settings** et **Models**.

## 3\. Réessayer

Retourner à la vue d'ensemble du projet et sélectionner **Réessayer la configuration**.

La carte revient à **En attente**, puis **En cours**, et montre de nouvelles activités alors que le travail avance. Le réessai est disponible uniquement tant que le projet est dans **Échoué** , état, qui empêche deux tentatives de configuration de s'exécuter en même temps.

## 4\. Revue de l'achèvement

Lorsque l'état change à **Terminé**, révisez la pull request résultante sur GitHub. Si elle échoue à nouveau, utilisez les nouvelles activités dans la carte plutôt que la tentative précédente pour identifier l'action suivante.