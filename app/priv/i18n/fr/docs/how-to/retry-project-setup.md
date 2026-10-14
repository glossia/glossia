%{
  title: "Réessayer la configuration du projet",
  summary: "Récupérer un projet après un échec de configuration.",
  category: "guide",
  section: "translation",
  order: 4
}
---

Lorsque la configuration automatisée échoue, Glossia supprime le projet provisionnel afin que le dépôt puisse être sélectionné à nouveau. Un avis d'échec peut apparaître dans le flux de configuration, mais le projet échoué et son historique de progression ne sont pas conservés.

## 1. Lire l'échec

Lisez l'avis d'échec avant de quitter le flux de configuration. Les causes courantes sont :

- Le compte n'a aucun modèle configuré.
- La clé du fournisseur est manquante ou n'est plus valide.
- L'application GitHub de Glossia ne peut pas accéder au dépôt.
- Le dépôt n'a pas pu être préparé ou vérifié.

## 2. Réparer le prérequis

Pour les problèmes de modèle, ouvrez **Paramètres → Modèles**. Pour les problèmes d'accès au dépôt, mettez à jour l'installation de l'application GitHub de Glossia sur GitHub et accordez-y l'accès au dépôt.

## 3. Lancer à nouveau la configuration

Ouvrez **Projets → Nouveau projet**, sélectionnez le dépôt, choisissez **Configuration automatisée**, et sélectionnez les langues cibles à nouveau. Suivez la nouvelle tentative de configuration jusqu'à son achèvement.

Si un projet échoué est toujours visible et propose **Réessayer la configuration**, cette action lance une nouvelle tentative. Ne comptez pas sur sa disponibilité : les projets provisionnels échoués sont supprimés lors du nettoyage.

## 4. Examiner la finalisation

Quand la configuration se termine, examinez la demande de fusion résultante dans GitHub. Consultez [Configuration du projet](/docs/reference/project-setup) pour le cycle de vie et le comportement de nettoyage.
