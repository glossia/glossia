%{
  title: "Réessayer la configuration du projet",
  summary: "Récupérer un projet après un échec de la configuration.",
  category: "guide",
  order: 4
}
---
Utiliser **Réessayer la configuration** après avoir corrigé la condition qui a provoqué l'échec de la configuration du projet.

## 1\. Lire l'échec

Ouvrir l'aperçu du projet. La carte de progression de configuration affiche l'échec et les dernières activités de configuration.

Les causes courantes incluent :

- Le compte n'a aucun modèle configuré.
- La clé du fournisseur est manquante ou n'est plus valide.
- L'application GitHub de Glossia ne peut pas accéder au dépôt.
- Le dépôt n'a pas pu être préparé ou vérifié.

## 2\. Corriger le prérequis

Pour les problèmes de modèle, ouvrez **Paramètres** et **Modèles**. Pour les problèmes d'accès au dépôt, mettez à jour l'installation de l'application GitHub de Glossia sur GitHub et accordez-lui l'accès au dépôt.

## 3\. Retenter

Revenir à la vue d'ensemble du projet et sélectionner **Retenter la configuration**.

La carte retourne vers **En attente**, puis **En cours**, et affiche de nouvelles activités à mesure que le travail progresse. Le réessai est disponible uniquement tant que le projet est dans **Échec** état, ce qui empêche deux tentatives de configuration de s'exécuter en même temps.

## 4\. Vérifier la finalisation

Lorsque l'état change en **Complété**, vérifiez la demande de fusion résultante sur GitHub. Si elle échoue à nouveau, utilisez la nouvelle activité dans la carte plutôt que la tentative précédente pour identifier la prochaine action.