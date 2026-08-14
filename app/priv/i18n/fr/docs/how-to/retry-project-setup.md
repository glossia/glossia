%{
  title: "Réessayer la configuration du projet",
  summary: "Récupérer un projet après l’échec de sa configuration.",
  category: "how-to",
  order: 4
}
---
Utilisez **Relancer la configuration** après avoir corrigé la cause de l’échec de la configuration d’un projet.

## 1. Examiner l’échec

Ouvrez la vue d’ensemble du projet. La carte de progression de la configuration affiche l’échec et l’activité de configuration la plus récente.

Causes courantes :

- Aucun modèle n’est configuré pour le compte.
- La clé du fournisseur est manquante ou n’est plus valide.
- L’application GitHub Glossia ne peut pas accéder au dépôt.
- Le dépôt n’a pas pu être préparé ou vérifié.

## 2. Corriger le prérequis

Pour les problèmes de modèle, ouvrez **Paramètres**, puis **Modèles**. Pour les problèmes d’accès au dépôt, mettez à jour l’installation de l’application GitHub Glossia dans GitHub et accordez-lui l’accès au dépôt.

## 3. Relancer

Revenez à la vue d’ensemble du projet et sélectionnez **Relancer la configuration**.

La carte repasse à l’état **En attente**, puis **En cours**, et affiche les nouvelles activités à mesure que le traitement avance. La relance n’est disponible que lorsque le projet est à l’état **Échec**, ce qui empêche l’exécution simultanée de deux tentatives de configuration.

## 4. Vérifier le résultat

Lorsque l’état passe à **Terminée**, examinez la pull request créée dans GitHub. En cas de nouvel échec, utilisez les nouvelles activités affichées dans la carte, plutôt que celles de la tentative précédente, pour déterminer l’action suivante.