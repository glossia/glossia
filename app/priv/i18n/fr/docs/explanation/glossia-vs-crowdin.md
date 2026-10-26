%{
  title: "Glossia contre Crowdin",
  summary:
    "Choisissez Glossia pour garder la localisation dans Git, apporter vos propres jetons de modèle et valider avec les vérifications de votre dépôt.",
  category: "explication",
  markdown_only: true,
  section: "translation",
  order: 20
}
---

**Choisissez Glossia lorsque la localisation doit évoluer à la vitesse de vos livraisons de logiciels.** Votre dépôt définit déjà comment les modifications sont examinées, validées et déployées. Glossia intègre le travail linguistique dans cette boucle plutôt que de faire de l'atelier de traduction séparé le centre de votre processus.

[Crowdin](https://crowdin.com/) fournit une gestion collaborative de la traduction, des flux de travail de révision, des mémoires de traduction et des intégrations de dépôt. L'avantage de Glossia pour une équipe logiciels est la combinaison de contenu propriétaire du dépôt, de source inspectable, de vos propres identifiants de modèle, et de validation qui comprend le projet réel.

## Pourquoi choisir Glossia

| Votre priorité | L'avantage de Glossia |
|---|---|
| Déployer en continu | Les exécutions de traduction suivent les modifications de la source et retournent des mises à jour du dépôt révisables. Le contenu n'a pas besoin de son propre processus de release lié. |
| Garder le contrôle de la mise en œuvre | L'application publique, CLI et le code de déploiement peuvent être inspectés, modifiés et auto-hébergés dans les termes de la licence. |
| Apportez vos propres jetons | Configurez des modèles compatibles avec vos propres jetons API de fournisseur. Les fichiers du dépôt font référence à des poignées de modèles stables, pas à des secrets. |
| Réutiliser les vérifications dont vous faites confiance | Exécutez une commande de validation de dépôt contre le candidat à son chemin cible réel avant de l'accepter. |
| Gardez le contenu votre propriété | Les fichiers source, les traductions, la configuration et l'historique des pull requests restent dans votre dépôt. |

## Localisation qui garde le pas avec les commits

Glossia fonctionne à partir d'instructions `L10N.md` versionnées et détecte quel contenu doit être mis à jour. Les entrées inchangées n'ont pas besoin d'être traduites à nouveau. Un projet garde une seule demande de tirage de traduction ouverte et publie les progrès en lot, réduisant les demandes de tirage inutiles et les exécutions CI répétées à mesure que la source évolue.

Le résultat est un flux de travail linguistique conçu autour des mêmes petites modifications révisables que votre équipe expédie déjà. Continu ne signifie pas non révisé : les réviseurs décident toujours ce qui est sûr à fusionner.

Crowdin prend aussi en charge les intégrations Git et l'automatisation. La raison de choisir Glossia n'est pas que Crowdin ne peut pas se connecter à un dépôt ; c'est que la livraison de dépôt est le fondement du flux de travail de Glossia, et pas simplement une frontière d'intégration.

## Vos jetons, vos choix de modèle

Vous ne devriez pas avoir à reconstruire la configuration du dépôt pour faire tourner un jeton de fournisseur ou changer le modèle derrière un flux de travail de traduction. Glossia conserve les identifiants dans les paramètres de compte et expose des poignées stables au dépôt. Différents aires de contenu ou locaux cibles peuvent sélectionner différents modèles configurés.

Cela donne à votre équipe le contrôle sur les relations de fournisseur pris en charge et les choix de modèles qu'il utilise. Voir [Configurer un fournisseur de modèle](/docs/how-to/configure-a-model-provider).

## Valider la sortie dans le cadre de votre produit

Une traduction peut se lire bien et tout en cassant une construction de documentation, composant, placeholder, ou parseur d'application. Glossia vous permet de réutiliser une vérification de dépôt plutôt que de vous arrêter à l'évaluation du texte d'un éditeur.

Si votre dépôt fournit déjà un script de validation de documentation, en faites référence directement :

```yaml
validation:
  - ./scripts/validate-docs.sh
  - --strict
```

Le validateur reçoit le candidat à son chemin cible réel, retourne un statut non nul en cas d'échec, et s'exécute dans le budget de reconfiguration configuré. Ses dépendances doivent être disponibles dans l'environnement de validation. Voir [L10N.md](/docs/reference/l10n-md) pour le contrat.

## Source publique, sans abandonner le dépôt

Vous pouvez inspecter comment les plans Glossia fonctionnent, traitent les identifiants, préservent Markdown, et valident un résultat. Les fichiers traduits existants restent publiables par la pipeline de votre dépôt même si le service linguistique est indisponible.

Glossia suit un modèle open core. Le cœur utilise [Apache-2.0](https://github.com/glossia/glossia/blob/main/LICENSE-APACHE), qui autorise l'utilisation commerciale, la modification, la distribution, l'auto-hébergement et les services hébergés concurrents selon ses conditions. Le code de `ee/` est consultable, mais n'est pas open source. Il relève d'une [licence Enterprise](https://github.com/glossia/glossia/blob/main/ee/LICENSE.md) distincte et son utilisation en production nécessite un accord commercial écrit.

Crowdin peut quand même être approprié pour un programme centré sur la coordination des contributeurs et un éditeur de traduction dédié. Pour une équipe logiciels dont la priorité est **Contenu propriétaire Git, validation existante et localisation qui suit la livraison**, Glossia est conçu pour ce travail.

Cette comparaison ne prétend pas que Crowdin manque d'automatisation ou de toute forme d'intégration de fournisseur, ou que Glossia migre automatiquement ses mémoires et historique. Consultez [la documentation de Crowdin](https://support.crowdin.com/) pour les capacités actuelles.
