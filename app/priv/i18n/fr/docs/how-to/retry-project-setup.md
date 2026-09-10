%{
  title: "Réessayer la configuration du projet",
  summary: "Récupérer un projet après un échec de la configuration.",
  category: "Comment faire",
  order: 4
}
---
Utilisez **Réessayer la configuration** après avoir corrigé la condition qui a provoqué l'échec d'une configuration de projet.

## 1\. Lisez l'échec

Ouvrez la vue d'ensemble du projet. La carte de progression de la configuration affiche l'échec et l'activité de configuration la plus récente.

Les causes courantes incluent :

- Le compte n'a aucun modèle configuré.
- La clé du fournisseur est manquante ou n'est plus valide.
- L'application GitHub de Glossia ne peut pas accéder au dépôt.
- Le dépôt n'a pas pu être préparé ou vérifié.

## 2\. Corriger le prérequis

Pour les problèmes de modèles, ouvrez **Paramètres** et **Modèles**. Pour les problèmes d'accès au dépôt, mettez à jour l'installation de l'application GitHub de Glossia sur GitHub et accordez-lui l'accès au dépôt.

## 3\. Réessayer

Retournez à la vue d'ensemble du projet et sélectionnez **Réessayer la configuration**.

La carte retourne à **En attente**, puis **En cours**, et affiche les nouvelles activités à mesure que le travail avance. Le réessayage n'est disponible que tant que le projet se trouve dans **Échec** état, ce qui empêche deux tentatives de configuration de s'exécuter simultanément.

## 4\. Revue de finalisation

Lorsque l'état passe à **Complété**, examinez la pull request résultante dans GitHub. Si elle échoue à nouveau, utilisez la nouvelle activité dans la carte plutôt que la tentative précédente pour identifier la prochaine action.