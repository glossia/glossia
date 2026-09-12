%{
  title: "Réessayer la configuration du projet",
  summary: "Récupérer un projet suite à un échec de la configuration.",
  category: "Guide",
  order: 4
}
---
Utiliser **Réessayer la configuration** Après avoir corrigé la condition ayant causé l'échec de la configuration du projet.

## 1\. Lire l'échec

Ouvrir la vue d'ensemble du projet. La carte de progression de la configuration affiche l'échec et la dernière activité de configuration.

Les causes courantes sont :

- Le compte ne dispose d'aucun modèle configuré.
- La clé du fournisseur manque ou n'est plus valide.
- L'application GitHub Glossia n'a pas accès au dépôt.
- Le dépôt n'a pas pu être préparé ou vérifié.

## 2\. Réglez le prérequis

Pour les problèmes de modèle, ouvrez **Paramètres** et **Modèles**. Pour les problèmes d'accès au dépôt, mettez à jour l'installation de l'application GitHub Glossia sur GitHub et accordez-lui l'accès au dépôt.

## 3\. Réessayer

Retourner à la vue d'ensemble du projet et sélectionner **Réessayer la configuration**.

La carte revient à **En attente**, puis **En cours**, et montre les nouvelles activités alors que les travaux avancent. Réessayer est disponible uniquement tant que le projet est dans **Échoué** état, ce qui empêche deux tentatives de configuration de s'exécuter à la même heure.

## 4\. Vérification de la complétion

Lorsque l'état change en **Terminé**, réviser la pull request résultante sur GitHub. Si elle échoue à nouveau, utilisez les nouvelles activités dans la carte plutôt que la tentative précédente pour identifier la prochaine action.