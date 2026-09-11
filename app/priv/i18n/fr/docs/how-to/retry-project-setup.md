%{
  title: "Réessayer la configuration du projet",
  summary: "Récupérer un projet après que la configuration signale un échec.",
  category: "Tutoriel",
  order: 4
}
---
Utiliser **Réessayer la configuration** après avoir corrigé la condition qui a entraîné l'échec de la configuration du projet.

## 1\. Consulter l'échec

Ouvrir la vue d'ensemble du projet. La carte de progression de la configuration affiche l'échec et les dernières activités de configuration.

Les causes courantes incluent :

- Le compte n'a aucun modèle configuré.
- La clé du fournisseur est manquante ou n'est plus valide.
- L'application GitHub de Glossia ne peut pas accéder au dépôt.
- Le dépôt n'a pas pu être préparé ou vérifié.

## 2\. Corriger le prérequis

Pour les problèmes de modèles, ouvrez **Paramètres** et **Modèles**.

## 3\. Réessayer

Revenez à l'aperçu du projet et sélectionnez **Réessayer la configuration**.

La carte revient à **En attente**, **En cours**, et affiche la nouvelle activité au fur et à mesure que les travaux progressent. Le réessai n'est disponible que tant que le projet est en **Échec** état, ce qui empêche deux tentatives de configuration de s'exécuter simultanément.

## 4\. Revue de la finalisation

Lorsque l'état change en **Complété**, révisez la demande d'extraction résultante dans GitHub. Si elle échoue à nouveau, utilisez la nouvelle activité dans la carte plutôt que l'ancienne tentative pour identifier l'action suivante.