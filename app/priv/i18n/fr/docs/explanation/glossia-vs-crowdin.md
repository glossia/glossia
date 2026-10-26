%{
  title: "Glossia contre Crowdin",
  summary:
    "Choisissez Glossia pour conserver la localisation dans Git, apporter vos propres jetons de modèle et valider avec les contrôles de votre dépôt.",
  category: "explication",
  markdown_only: true,
  section: "translation",
  order: 20
}
---

**Choisissez Glossia lorsque la localisation doit suivre le rythme de votre livraison logicielle.** Votre dépôt définit déjà la manière dont les modifications sont révisées, validées et livrées. Glossia intègre les travaux linguistiques dans ce cycle plutôt que de placer un espace de travail de traduction séparé au cœur de votre processus.

[Crowdin](https://crowdin.com/) offre une gestion collaborative de la traduction, des flux de travail d'examen, des mémoires de traduction et des intégrations de dépôt. L'avantage de Glossia pour une équipe logicielle est la combinaison de contenu propriétaire du dépôt, d'une source inspectable, de vos identifiants de modèle personnels et d'une validation qui comprend le projet réel.

## Pourquoi choisir Glossia

| Votre priorité | L'avantage de Glossia |
|---|---|
| Livraison continue | Les exécutions de traduction suivent les modifications de la source et retournent des mises à jour du dépôt examinables. Le contenu n'a pas besoin de son propre processus de publication indépendant. |
| Conservez le contrôle de la mise en œuvre | L'application publique, la CLI et le code de déploiement peuvent être inspectés, modifiés et auto-hébergés selon les termes de la licence. |
| Apportez vos propres jetons | Configurez les modèles pris en charge avec vos propres jetons API de fournisseur. Les fichiers de dépôt font référence à des manipulations de modèle stables, pas à des secrets. |
| Réutilisez les vérifications que vous faites confiance | Exécutez une commande de validation de dépôt sur le candidat à son chemins de cible réel avant de l'accepter. |
| Conservez votre contenu | Les fichiers source, les sorties traduites, la configuration et l'historique des pull requests restent dans votre dépôt. |

## Une localisation qui suit les commits

Glossia fonctionne à partir d'instructions versionnées `L10N.md` et détecte quel contenu nécessite une mise à jour. Les entrées inchangées n'ont pas besoin d'être retraduites à nouveau. Un projet conserve un seul pull request de traduction ouvert et publie la progression par lots, réduisant les pull requests inutiles et les exécutions CI répétées lors de l'évolution de la source.

Le résultat est un flux de travail linguistique conçu autour des mêmes petites modifications examinables livrées par votre équipe. Continu ne signifie pas non examiné : les réviseurs décident toujours ce qui est sûr à fusionner.

Crowdin prend également en charge les intégrations Git et l'automatisation. La raison de choisir Glossia n'est pas que Crowdin ne peut pas se connecter à un dépôt ; c'est que la livraison de dépôt est le fondement du flux de travail de Glossia, et non seulement une frontière d'intégration.

## Vos jetons, vos choix de modèle

Vous ne devriez pas avoir à reconstruire la configuration du dépôt pour faire tourner un jeton de fournisseur ou changer le modèle derrière un flux de traduction. Glossia stocke les identifiants dans les paramètres du compte et expose des manipulations de modèle stables au dépôt. Différents domaines de contenu ou locales cibles peuvent sélectionner différents modèles configurés.

Cela donne à votre équipe le contrôle sur les relations avec les fournisseurs supportées et les choix de modèles qu'elle utilise. Voir [Configurer un fournisseur de modèle](/docs/how-to/configure-a-model-provider).

## Validez la sortie comme partie intégrante de votre produit

Une traduction peut être bien lue et encore casser la compilation de la documentation, d'un composant, d'un placeholder ou d'un analyseur d'application. Glossia vous permet de réutiliser une vérification de dépôt plutôt que de vous arrêter à l'évaluation de l'éditeur du texte.

Si votre dépôt fournit déjà un script de validation de documentation, référez-le directement :

```yaml
validation:
  - ./scripts/validate-docs.sh
  - --strict
```

Le validateur reçoit le candidat à son véritable chemin de cible, retourne un état non nul en cas d'échec, et s'exécute dans le budget de tentative configuré. Ses dépendances doivent être disponibles dans l'environnement de validation. Voir [L10N.md](/docs/reference/l10n-md) pour le contrat.

## Source publique, sans renoncer au dépôt

Vous pouvez inspecter comment Glossia gère les plans, les identifiants, préserve le Markdown et valide un résultat. Les fichiers traduits restent publiables grâce au pipeline de votre dépôt même si le service linguistique est indisponible.

Glossia est open core : [Apache-2.0](https://github.com/glossia/glossia/blob/main/LICENSE-APACHE) couvre le cœur et permet l'auto-hébergement et les services hébergés concurrents. Le code d'entreprise available source sous `ee/` a une [licence](https://github.com/glossia/glossia/blob/main/ee/LICENSE.md) séparée nécessitant un accord commercial écrit pour une utilisation en production.

Crowdin peut toujours être approprié pour un programme centré sur la coordination des contributeurs et un éditeur de traduction dédié. Pour une équipe logicielle dont la priorité est **contenu Git, validation existante et localisation qui suit la livraison**, Glossia est conçu pour ce travail.

Cette comparaison ne prétend pas que Crowdin manque d'automatisation ou de toute forme d'intégration de fournisseur, ou que Glossia migre automatiquement ses mémoires et son historique. Consultez [la documentation de Crowdin](https://support.crowdin.com/) pour les capacités actuelles.
