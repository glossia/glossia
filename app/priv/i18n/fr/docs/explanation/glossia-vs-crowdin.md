%{
  title: "Glossia contre Crowdin",
  summary:
    "Choisissez Glossia pour conserver la localisation dans Git, apporter vos propres jetons de modèle et valider avec les contrôles de votre référentiel.",
  category: "explication",
  section: "translation",
  order: 20
}
---

**Choisissez Glossia lorsque la localisation doit aller à la vitesse de votre livraison de logiciels.** Votre référentiel définit déjà comment les modifications sont recensées, validées et expédiées. Glossia intègre le travail linguistique dans ce cycle au lieu de faire d'un espace de traduction séparé le centre de votre processus.

[Crowdin](https://crowdin.com/) propose une gestion collaborative des traductions, des flux de relecture, des mémoires de traduction et des intégrations de référentiels. L'avantage de Glossia pour une équipe de logiciels est la combinaison de contenus détenus par le référentiel, de sources inspectables, de vos propres identifiants de modèles, et d'une validation qui comprend le projet réel.

## Pourquoi choisir Glossia

| Votre priorité | L'avantage de Glossia |
|---|---|
| Livraison continue | Les exécutions de traduction suivent les modifications de la source et renvoyent des mises à jour du référentiel soumises à révision. Le contenu n'a pas besoin d'avoir son propre processus de publication externe. |
| Conserver le contrôle de l'implémentation | Application publique, CLI et code de déploiement peuvent être inspectés, modifiés, et auto-hébergés sous les termes de la licence. |
| Apportez vos propres jetons | Configurez les modèles pris en charge avec vos propres jetons API fournisseur. Les fichiers du référentiel font référence à des identifiants de modèle stables, pas à des secrets. |
| Réutilisez les vérifications que vous faites confiance | Exécutez une commande de validation de référentiel contre le candidat à son chemin cible réel avant de l'accepter. |
| Gardez le contenu vôtre | Les fichiers source, les sorties traduites, la configuration, et l'historique des pull-request restent dans votre référentiel. |

## Localisation qui reste au rythme des commits

Glossia fonctionne à partir des instructions `L10N.md` versionnées et détecte quel contenu doit être mis à jour. Les entrées inchangées n'ont pas besoin d'être traduites à nouveau. Un projet conserve une seule demande de traduction ouverte et publie les progrès par lots, réduisant les demandes inutiles et les exécutions CI répétées au fur et à mesure que la source évolue.

Le résultat est un flux linguistique conçu autour des mêmes petites modifications révisables que votre équipe expédie déjà. La continuité ne signifie pas 'non examiné' : les relecteurs décident toujours ce qui est sûr à fusionner.

Crowdin supporte aussi les intégrations Git et l'automatisation. La raison de choisir Glossia n'est pas que Crowdin ne peut pas se connecter à un référentiel ; c'est que la livraison du référentiel est la fondation du flux de travail de Glossia, pas seulement une frontière d'intégration.

## Vos jetons, vos choix de modèles

Vous ne devriez pas avoir à reconstruire la configuration du référentiel pour actualiser un jeton de fournisseur ou changer le modèle derrière un flux de traduction. Glossia stocke les identifiants dans les paramètres de compte et expose des identifiants stables au référentiel. Différentes zones de contenu ou cibles peuvent sélectionner des modèles configurés différents.

Cela donne à votre équipe le contrôle sur les relations fournisseurs pris en charge et les choix de modèles utilisés. Voir [Configurer un fournisseur de modèle](/docs/how-to/configure-a-model-provider).

## Validez la sortie comme partie de votre produit

Une traduction peut être bien comprise et quand même casser une construction de documentation, un composant, un placeholder, ou un parseur d'application. Glossia vous permet de réutiliser une vérification de référentiel plutôt que de s'arrêter à l'appréciation d'un éditeur du texte.

Si votre référentiel fournit déjà un script de validation de documentation, faites-le directement :

```yaml
validation:
  - ./scripts/validate-docs.sh
  - --strict
```

Le validateur reçoit le candidat à son chemin d'arrivée réel, retourne un statut non zéro en cas d'échec, et s'exécute dans le budget de reprise configuré. Ses dépendances doivent être disponibles dans l'environnement de validation. Voir [L10N.md](/docs/reference/l10n-md) pour le contrat.

## Source publique, sans abandonner le référentiel

Vous pouvez inspecter comment les plans Glossia fonctionnent, gèrent les identifiants, préservent Markdown, et valident un résultat. Les fichiers traduits existants restent publisibles via la pipeline de votre référentiel même si le service linguistique n'est pas disponible.

Glossia est disponible en source sous [O'Saasy license](https://github.com/glossia/glossia/blob/main/LICENSE.md), ce qui permet l'auto-hébergement mais restreint les services hébergés concurrents. Ce n'est pas une licence open-source sans restriction.

Crowdin peut encore être approprié pour un programme centré sur la coordination des contributeurs et un éditeur de traduction dédié. Pour une équipe de logiciels dont la priorité est **Contenu de propriété Git, validation existante, et localisation qui suit la livraison**, Glossia est conçu pour ce travail.

Cette comparaison ne prétend pas que Crowdin manque d'automatisation ou toute forme d'intégration de fournisseur, ou que Glossia migre automatiquement ses mémoires et ses historiques. Consultez [La documentation de Crowdin](https://support.crowdin.com/) pour les capacités actuelles.
