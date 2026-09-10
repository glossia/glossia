%{
  title: "Réessayer la mise en place du projet",
  summary: "Récupérer un projet après un échec de la mise en place.",
  category: "Tutoriel",
  order: 4
}
---
Utilisez **Réessayer la configuration** après avoir corrigé la condition qui a causé l'échec de la configuration du projet.

## 1\. Lisez l'échec

Ouvrez la vue d'ensemble du projet. La carte de progression de configuration affiche l'échec et les dernières activités de configuration.

Les causes courantes incluent :

- Le compte ne possède aucun modèle configuré.
- La clé du fournisseur est manquante ou n'est plus valide.
- L'application GitHub Glossia n'a pas accès au dépôt.
- Le dépôt n'a pas pu être préparé ou vérifié.

## 2\. Corriger le prérequis

Pour les problèmes de modèles, ouvrez **Paramètres** et **Modèles**. Pour les problèmes d'accès au dépôt, mettez à jour l'installation de l'application GitHub Glossia sur GitHub et accordez-lui l'accès au dépôt.

## 3\. Réessayer

Retour à la vue d'ensemble du projet et sélection **Réessayer la configuration**.

La carte retourne à **En attente**, puis **En cours**, et affiche de nouvelles activités au fur et à mesure que le travail se poursuit. Le réessai est disponible uniquement tant que le projet est dans **Échec** état, ce qui empêche deux tentatives de configuration de s'exécuter simultanément.

## 4\. Revue de la finalisation

Lorsque l'état change vers **Terminée**, révisez la pull request résultante sur GitHub. Si elle échoue à nouveau, utilisez la nouvelle activité dans la carte plutôt que la tentative précédente pour identifier la prochaine action.