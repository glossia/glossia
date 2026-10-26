%{
  title: "Glossia face à Crowdin",
  summary:
    "Choisissez Glossia pour garder la localisation dans Git, apportez vos propres tokens de modèle et validez avec les contrôles de votre dépôt.",
  category: "explication",
  markdown_only: true,
  section: "translation",
  order: 20
}
---

**Choisissez Glossia lorsque la localisation doit s'exécuter à la vitesse de la livraison de votre logiciel.** Votre dépôt définit déjà comment les modifications sont examinées, validées et déployées. Glossia intègre les travaux linguistiques dans ce cycle plutôt que de désigner un espace de travail de traduction séparé au centre de votre processus.

[Crowdin](https://crowdin.com/) fournit une gestion de traduction collaborative, des flux de travail de révision, des mémoires de traduction et des intégrations de dépôt. L'avantage de Glossia pour une équipe logicielle est la combinaison de contenus propriétaires d'un dépôt, de source inspectable, de vos propres identifiants de modèle, et d'une validation qui comprend le projet réel.

## Pourquoi choisir Glossia

| Votre priorité | L'avantage de Glossia |
|---|---|
| Déployer en continu | Les exécutions de traduction suivent les modifications de source et retournent des mises à jour du dépôt examinales. Le contenu n'a pas besoin d'avoir son propre processus de publication non lié. |
| Maintenir le contrôle de l'implémentation | L'application publique, le CLI et le code de déploiement peuvent être inspectés, modifiés et auto-hébergés selon les termes de la licence. |
| Apportez vos propres jetons | Configurez les modèles pris en charge avec vos propres jetons API de fournisseur. Les fichiers de dépôt font référence à des handles de modèle stables, pas à des secrets. |
| Réutilisez les contrôles que vous faites confiance | Exécutez une commande de validation de dépôt contre le candidat à son chemin cible réel avant de l'accepter. |
| Gardez le contenu à votre nom | Les fichiers sources, les sorties traduites, la configuration et l'historique des demandes de pull restent dans votre dépôt. |

## Localisation qui tient le rythme des commits

Glossia fonctionne à partir d'instructions `L10N.md` versionnées et détecte quels contenus nécessitent une mise à jour. Les entrées inchangées n'ont pas besoin d'être traduites à nouveau. Un projet maintient une seule demande de tirage de traduction ouverte et publie les progrès par lots, réduisant les demandes de pull inutiles et les exécutions CI répétées au fur et à mesure que la source évolue.

Le résultat est un flux de travail linguistique conçu autour des mêmes petits changements révisables que votre équipe consomme déjà. Continu ne signifie pas inexaminé : les réviseurs décident toujours ce qui est sûr à fusionner.

Crowdin prend également en charge les intégrations Git et l'automatisation. La raison de choisir Glossia n'est pas que Crowdin ne peut pas se connecter à un dépôt ; c'est que la livraison de dépôt est le pilier du flux de travail de Glossia, pas seulement une frontière d'intégration.

## Vos jetons, vos choix de modèle

Vous ne devriez pas avoir à reconstruire la configuration du dépôt pour faire tourner un jeton de fournisseur ou changer le modèle derrière un flux de traduction. Glossia stocke les identifiants dans les paramètres de compte et expose des handles stables au dépôt. Différentes zones de contenu ou cibles de localisation peuvent sélectionner différents modèles configurés.

Cela donne à votre équipe le contrôle sur les relations de fournisseur prises en charge et les choix de modèles qu'elle utilise. Voir [Configurer un fournisseur de modèle](/docs/how-to/configure-a-model-provider). :

## Validez la sortie en tant que partie de votre produit

Une traduction peut se lire bien et quand même casser une compilation de documentation, un composant, un placeholder, ou un parseur d'application. Glossia vous permet de réutiliser un contrôle de dépôt plutôt que de vous arrêter à l'évaluation d'un éditeur du texte.

Si votre dépôt fournit déjà un script de validation de documentation, référez-le directement:

```yaml
validation:
  - ./scripts/validate-docs.sh
  - --strict
```

Le validateur reçoit le candidat à son chemin cible réel, retourne un statut non zéro en cas d'échec et s'exécute dans le budget de rétentité configuré. Ses dépendances doivent être disponibles dans l'environnement de validation. Voir [L10N.md](/docs/reference/l10n-md) pour le contrat.

## Source publique, sans céder le dépôt

Vous pouvez examiner comment fonctionnent les plans de Glossia, les identifiants sont gérés, le Markdown est préservé, et un résultat est validé. Les fichiers traduits existants restent publiables via les pipelines de votre dépôt même si le service linguistique est indisponible.

Glossia suit un modèle open core. Le cœur utilise [Apache-2.0](https://github.com/glossia/glossia/blob/main/LICENSE-APACHE), qui autorise l'utilisation commerciale, la modification, la distribution, l'auto-hébergement et les services hébergés concurrents selon ses conditions. Le code de `ee/` est consultable, mais n'est pas open source. Il relève d'une [licence Enterprise](https://github.com/glossia/glossia/blob/main/ee/LICENSE.md) distincte et son utilisation en production nécessite un accord commercial écrit.

Crowdin peut encore être approprié pour un programme centré sur la coordination des contributeurs et un éditeur de traduction dédié. Pour une équipe logicielle dont la priorité est **contenu géré par Git, validation existante, et localisation qui suit la livraison**, Glossia est conçu pour ce travail.

Cette comparaison ne revendique pas que Crowdin manque d'automatisation ou de toute forme d'intégration de fournisseur, ou que Glossia migre automatiquement ses mémoires et son historique. Consultez [la documentation de Crowdin](https://support.crowdin.com/) pour les capacités actuelles.
