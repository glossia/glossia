%{
  title: "Réessayer la configuration du projet",
  summary: "Récupérer un projet après un échec de configuration.",
  category: "Tutoriel",
  section: "translation",
  order: 4
}
---

Lorsque la configuration automatisée échoue, Glossia élimine le projet provisoire afin que le dépôt puisse être sélectionné à nouveau. Un message d'échec peut apparaître dans le flux de configuration, mais le projet ayant échoué et son historique de progression ne sont pas conservés.

## 1. Lire l'échec

Lire le message d'échec avant de quitter le flux de configuration. Les causes courantes sont :

- Le compte n'a aucun modèle configuré.
- La clé du fournisseur est manquante ou n'est plus valide.
- L'application GitHub Glossia ne peut pas accéder au dépôt.
- Le dépôt n'a pas pu être préparé ni vérifié.

## 2. Corriger le prérequis

Pour les problèmes de modèle, ouvrez **Paramètres → Modèles**. Pour les problèmes d'accès au dépôt, mettez à jour l'installation de l'application GitHub Glossia dans GitHub et accordez-lui l'accès au dépôt.

## 3. Relancer la configuration

Ouvrez **Projets → Nouveau projet**, sélectionnez le dépôt, choisissez **Configuration automatisée**, et sélectionnez les langues cibles à nouveau. Suivez la nouvelle tentative de configuration jusqu'à son achèvement.

Si un projet échoué est toujours visible et propose **Relancer la configuration**, cette action lance une autre tentative. Ne comptez pas sur sa disponibilité : les projets provisoires ayant échoué sont supprimés lors du nettoyage.

## 4. Examiner la finalisation

Lorsque la configuration est terminée, examinez le pull request résultant dans GitHub. Consultez [Configuration du projet](/docs/reference/project-setup) pour le cycle de vie et les comportements de nettoyage.
