%{
  title: "Réessayer la configuration du projet",
  summary: "Récupérer un projet après un échec de la configuration.",
  category: "guide pratique",
  section: "translation",
  order: 4
}
---
Lorsque le paramétrage automatisé échoue, Glossia rejette le projet provisoire afin que le dépôt puisse être sélectionné à nouveau. Une notification d'échec peut apparaître dans le flux de paramétrage, mais le projet échoué et son historique de progression ne sont pas conservés.

## 1\. Lire l'échec

Lire le message d'échec avant de quitter le flux de paramétrage. Les causes courantes incluent :

- Le compte ne dispose d'aucun modèle configuré.
- La clé du fournisseur est manquante ou n'est plus valide.
- La Glossia GitHub App ne peut pas accéder au dépôt.
- Le dépôt n'a pas pu être préparé ou vérifié.

## 2\. Corriger le prérequis

Pour les problèmes de modèles, ouvrez **Paramètres → Modèles**. Pour les problèmes d'accès au dépôt, mettez à jour l'installation de l'application GitHub de Glossia sur GitHub et accordez-lui l'accès au dépôt.

## 3\. Redémarrez la configuration

Ouvrir **Projets → Nouveau projet**, sélectionnez le dépôt, choisissez **Configuration automatisée**, et sélectionnez les langues cibles à nouveau. Suivez la nouvelle tentative de configuration jusqu'à sa complétion.

Si un projet en échec est toujours visible et propose **Réessayer la configuration**, cette action démarre une nouvelle tentative. Ne comptez pas sur sa disponibilité : les projets prévisionnels échoués sont supprimés lors du nettoyage.

## 4\. Revue de finalisation

Lorsque la configuration est terminée, révisez la demande de fusion résultante sur GitHub. Voir [Configuration du projet](/docs/reference/project-setup) pour le cycle de vie et le comportement de nettoyage.