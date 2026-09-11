%{
  title: "Réessayer la configuration du projet",
  summary: "Récupérer un projet après que la configuration signale un échec.",
  category: "Guide pratique",
  order: 4
}
---
Utilisez **Réessayer la configuration** après avoir corrigé la condition qui a provoqué l'échec de la configuration du projet.

## 1\. Lire l'échec

Ouvrez la vue du projet. La carte de progression de la configuration affiche l'échec et la dernière activité de configuration.

Les causes courantes incluent :

- Le compte ne dispose pas de modèle configuré.
- La clé du fournisseur est manquante ou n'est plus valide.
- L'application GitHub App Glossia n'a pas accès au dépôt.
- Le dépôt n'a pas pu être préparé ou vérifié.

## 2\. Corrigez le prérequis.

Pour les problèmes de modèle, ouvrez **Paramètres** et **Modèles**. Pour les problèmes d'accès au dépôt, mettez à jour l'installation de l'application GitHub App Glossia sur GitHub et accordez-lui l'accès au dépôt.

## 3\. Réessayer

Retour à l'aperçu du projet et sélection **Réessayer la configuration**.

La carte revient à **En attente**, puis **En cours**, et affiche de nouvelles activités à mesure que le travail avance. Le réessai est disponible uniquement tant que le projet est dans **Échoué** état, ce qui empêche deux tentatives de configuration de s'exécuter simultanément.

## 4\. Examen de l'achèvement

Lorsque l'état change en **Complété**, révisez la pull request résultante sur GitHub. Si elle échoue à nouveau, utilisez la nouvelle activité dans la carte plutôt que la tentative précédente pour identifier l'action suivante.