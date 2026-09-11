%{
  title: "Réessayer la configuration du projet",
  summary: "Récupérer un projet après un échec de configuration.",
  category: "Guide",
  order: 4
}
---
Utilisez **Retenter la configuration** après avoir corrigé la condition ayant provoqué l'échec de la configuration du projet.

## 1\. Lire l'échec

Ouvrez la vue d'ensemble du projet. La carte de progression de la configuration affiche l'échec et les dernières activités de configuration.

Les causes courantes sont :

- Le compte n'a aucun modèle configuré.
- La clé du fournisseur est manquante ou n'est plus valide.
- L'application Glossia GitHub ne peut pas accéder au dépôt.
- Le dépôt n'a pas pu être préparé ou vérifié.

## 2\. Corrigez le prérequis.

Pour les problèmes de modèle, ouvrez **Paramètres** et **Modèles**. Pour les problèmes d'accès au dépôt, mettez à jour l'installation de l'application Glossia GitHub sur GitHub et accordez-lui l'accès au dépôt.

## 3\. Réessayer

Revenir à l'aperçu du projet et sélectionner **Réessayer la configuration**.

La carte revient à **En attente**, puis **En cours**, et affiche les nouvelles activités au fur et à mesure que le travail progresse. La tentative de réessai est disponible uniquement tant que le projet est dans **Échoué** état, ce qui empêche deux tentatives de configuration de s'exécuter en même temps.

## 4\. Revue de finalisation

Lorsque l'état passe à **Complété**, révisez la pull request résultante sur GitHub. Si elle échoue à nouveau, utilisez les nouvelles activités dans la carte plutôt que la tentative précédente pour identifier la prochaine action.