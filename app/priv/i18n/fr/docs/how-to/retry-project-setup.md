%{
  title: "Réessayer la configuration du projet",
  summary: "Récupérer un projet suite à un échec de la configuration.",
  category: "Tutoriel",
  section: "translation",
  order: 4
}
---

Lorsque la configuration automatique échoue, Glossia écarte le projet provisoire afin que le dépôt puisse être sélectionné à nouveau. Un message d'échec peut apparaître dans le flux de configuration, mais le projet échoué et son historique de progression ne sont pas conservés.

## 1. Lire l'échec

Lisez l'avis d'échec avant de quitter le flux de configuration. Les causes courantes incluent :

- Le compte n'a aucun modèle configuré.
- La clé du fournisseur fait défaut ou n'est plus valide.
- L'application Glossia GitHub ne peut pas accéder au dépôt.
- Le dépôt n'a pas pu être préparé ou vérifié.

## 2. Corriger le prérequis

Pour les problèmes de modèle, ouvrez **Paramètres → Modèles**. Pour les problèmes d'accès au dépôt, mettez à jour l'installation de l'application Glossia GitHub sur GitHub et accordez-lui l'accès au dépôt.

## 3. Recommencer la configuration

Ouvrez **Projets → Nouveau projet**, sélectionnez le dépôt, choisissez **Configuration automatique**, et sélectionnez les langues cibles à nouveau. Suivez la nouvelle tentative de configuration jusqu'à sa conclusion.

Si un projet échoué est toujours visible et propose **Réessayer la configuration**, cette action déclenche une autre tentative. Ne comptez pas sur sa disponibilité : les projets provisoires échoués sont supprimés lors du nettoyage.

## 4. Examiner la finalisation

Lorsque la configuration est terminée, examinez la demande tirée résultante sur GitHub. Voir [Configuration du projet](/docs/reference/project-setup) pour le cycle de vie et les comportements de nettoyage.
