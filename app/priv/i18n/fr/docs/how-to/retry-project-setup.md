%{
  title: "Réessayer la configuration du projet",
  summary: "Récupérer un projet après un échec de la configuration.",
  category: "guide",
  order: 4
}
---
Utilisez **Réessayer la configuration** après avoir corrigé la condition qui a provoqué l'échec de la configuration du projet.

## 1\. Lire l'échec

Ouvrez la vue d'ensemble du projet. La carte de progression de la configuration affiche l'échec et les dernières activités de configuration.

Les causes courantes incluent :

- Le compte n'a pas de modèle configuré.
- La clé du fournisseur est manquante ou n'est plus valide.
- L'application GitHub Glossia ne peut pas accéder au dépôt.
- Le dépôt n'a pas pu être préparé ou vérifié.

## 2\. Corriger le prérequis

Pour les problèmes de modèle, ouvrez **Paramètres** et **Modèles**. Pour les problèmes d'accès au dépôt, mettez à jour l'installation de l'application GitHub Glossia sur GitHub et accordez-lui l'accès au dépôt.

## 3\. Réessayer

Retourner à la vue d'ensemble du projet et sélectionner **Réessayer la configuration**.

La carte revient à **En attente**, puis **En cours**et affiche la nouvelle activité alors que le travail progresse. Réessayer est disponible uniquement tant que le projet est dans **Échoué** état, ce qui empêche deux tentatives de mise en place de s'exécuter simultanément.

## 4\. Revue de la finalisation

Lorsque l'état passe à **Complété**, révisez la demande de tirage résultante sur GitHub. Si elle échoue à nouveau, utilisez la nouvelle activité dans la carte plutôt que l'essai précédent pour identifier l'action suivante.