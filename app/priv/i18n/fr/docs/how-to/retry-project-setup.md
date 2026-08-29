%{
  title: "Réessayer la configuration du projet",
  summary: "Récupérer un projet après un échec de configuration signalé.",
  category: "how-to",
  order: 4
}
---
Utilisez **Réessayer la configuration** après avoir corrigé la condition ayant entraîné l'échec de la configuration du projet.

## 1\. Lire l'échec

Ouvrez la vue d'ensemble du projet. La carte de progression de la configuration affiche l'échec et les dernières activités de configuration.

Les causes courantes incluent :

- Le compte ne dispose d'aucun modèle configuré.
- La clé du fournisseur est manquante ou n'est plus valide.
- L'application Glossia GitHub ne peut pas accéder au dépôt.
- Le dépôt n'a pas pu être préparé ou vérifié.

## 2\. Corriger le prérequis

Pour les problèmes de modèle, ouvrez **Paramètres** et **Modèles**. Pour les problèmes d'accès au dépôt, mettez à jour l'installation de l'application Glossia GitHub sur GitHub et accordez-lui l'accès au dépôt.

## 3\. Réessayer

Revenez à la vue d'ensemble du projet et sélectionnez **Réessayer la configuration**.

La carte revient à **En attente**, puis **En cours**, et affiche de nouvelles activités au fur et à mesure que le travail avance. Le réessai n'est disponible que tant que le projet est dans l'état **Échoué**, ce qui empêche deux tentatives de configuration d'exécuter simultanément.

## 4\. Examiner la finalisation

Quand l'état passe à **Terminé**, examinez la demande de tirage résultante sur GitHub. Si elle échoue à nouveau, utilisez les nouvelles activités dans la carte plutôt que la tentative précédente pour identifier l'action suivante.