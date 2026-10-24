%{
  title: "Glossia vs Crowdin",
  summary:
    "Choisissez Glossia pour garder la localisation dans Git, apportez vos propres jetons de modèle, et validez avec les vérifications de votre dépôt",
  category: "explication",
  markdown_only: true,
  section: "translation",
  order: 20
}
---

**Choisissez Glossia lorsque la localisation doit suivre le rythme de votre livraison de logiciel.** Votre dépôt définit déjà la façon dont les modifications sont examinées, validées et déployées. Glossia intègre les travaux linguistiques dans cette boucle plutôt que de faire d'un espace de travail de traduction séparé le centre de votre processus.

[Crowdin](https://crowdin.com/) propose une gestion collaborative de la traduction, des flux de travail d'examen, des mémoires de traduction et des intégrations de dépôt. L'avantage de Glossia pour une équipe logicielle est la combinaison d'un contenu appartenant au dépôt, d'une source inspectable, de vos propres identifiants de modèle et d'une validation qui comprend le projet réel.

## Pourquoi choisir Glossia

| Votre priorité | L'avantage de Glossia |
|---|---|
| Livraison continue | Les exécutions de traduction suivent les modifications de la source et retournent des mises à jour de dépôt révisables. Le contenu n'a pas besoin de son propre processus de diffusion non lié. |
| Maintenez le contrôle de la mise en œuvre | L'application publique, le CLI et le code de déploiement peuvent être inspectés, modifiés et hébergés sur votre propre infrastructure selon les termes de la licence. |
| Apportez vos propres jetons | Configurez les modèles pris en charge avec vos propres jetons d'API du fournisseur. Les fichiers du dépôt font référence à des identifiants de modèle stables, pas à des secrets. |
| Réutilisez les contrôles que vous faites confiance | Exécutez une commande de validation de dépôt contre le candidat à sa véritable cible avant de l'accepter. |
| Gardez le contenu le vôtre | Les fichiers source, les traductions, la configuration et l'historique des pull-request restent dans votre dépôt. |

## Localisation qui suit le rythme des commits

Glossia fonctionne avec des `L10N.md` instructions versionnées et détecte quels contenus doivent être mis à jour. Les entrées inchangées ne nécessitent pas de nouvelles traductions. Un projet conserve une seule pull request de traduction ouverte et publie des stratégies par lots, réduisant ainsi les pull requests inutiles et les exécutions CI répétées à mesure que la source évolue.

Le résultat est un flux de travail linguistique conçu autour des mêmes petites modifications révisables que votre équipe dépose déjà. Continu ne signifie pas non examiné : les examinateurs décident toujours ce qui est sûr à fusionner.

Crowdin prend également en charge les intégrations Git et l'automatisation. La raison de choisir Glossia n'est pas que Crowdin ne peut se connecter à un dépôt ; c'est que la livraison du dépôt est la base du flux de travail de Glossia, et non simplement une frontière d'intégration.

## Vos jetons, vos choix de modèle

Vous ne devriez pas avoir à reconstruire la configuration du dépôt pour faire tourner un jeton de fournisseur ou modifier le modèle en arrière-plan d'un flux de travail de traduction. Glossia stocke les identifiants dans les paramètres de compte et expose des identifiants stables au dépôt. Les différentes zones de contenu ou cibles de localisation peuvent sélectionner différents modèles configurés.

Cela donne à votre équipe le contrôle sur les relations de fournisseur pris en charge et les choix de modèle utilisés. Consultez [Configurer un fournisseur de modèle](/docs/how-to/configure-a-model-provider).

## Validez la sortie comme partie intégrante de votre produit

Une traduction peut se lire couramment tout en cassant une construction de la documentation, un composant, un placeholder ou un analyseur d'application. Glossia vous permet de réutiliser une vérification de dépôt plutôt que de vous arrêter à l'évaluation d'un éditeur sur le texte.

Si votre dépôt fournit déjà un script de validation de documentation, référez-y directement :

```yaml
validation:
  - ./scripts/validate-docs.sh
  - --strict
```

Le validateur reçoit le candidat à son chemin cible réel, renvoie un statut non nul en cas d'échec et s'exécute dans le budget de réessai configuré. Ses dépendances doivent être disponibles dans l'environnement de validation. Consultez [L10N.md](/docs/reference/l10n-md) pour le contrat.

## Source publique, sans abandonner le dépôt

Vous pouvez inspecter comment les plans Glossia fonctionnent, gèrent les authentifications, préservent le Markdown et valident un résultat. Les fichiers de traduction existants restent publiables via le pipeline de votre dépôt même si le service linguistique est inaccessible.

Glossia suit un modèle open core. Le cœur utilise [Apache-2.0](https://github.com/glossia/glossia/blob/main/LICENSE-APACHE), qui autorise l'utilisation commerciale, la modification, la distribution, l'auto-hébergement et les services hébergés concurrents selon ses conditions. Le code de `ee/` est consultable, mais n'est pas open source. Il relève d'une [licence Enterprise](https://github.com/glossia/glossia/blob/main/ee/LICENSE.md) distincte et son utilisation en production nécessite un accord commercial écrit.

Crowdin reste approprié pour un programme centré sur la coordination des contributeurs et un éditeur de traduction dédié. Pour une équipe logicielle dont la priorité est **contenu appartenant à Git, validation existante et localisation qui suit la livraison**, Glossia est conçu pour cette mission.

Cette comparaison n'affirme pas que Crowdin manque d'automatisation ou de toute forme d'intégration de fournisseur, ni que Glossia migre automatiquement ses mémoires et historiques. Consultez [la documentation de Crowdin](https://support.crowdin.com/) pour les capacités actuelles.
