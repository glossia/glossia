%{
  title: "Utilisation des jetons de traduction",
  summary:
    "Comprendre la comptabilité des jetons et les détails de projet, de langue et de fichier source.",
  category: "Référence",
  section: "translation",
  order: 12
}
---

## Tableau de bord

Ouvrez **Paramètres → Modèles → Utilisation des jetons** pour voir l'utilisation rapportée par le fournisseur pour les traductions génératives. L'accès nécessite l'autorisation de lire les paramètres du modèle.

Le tableau de bord prend en charge les 7 derniers, 30 ou 90 jours civils, incluant aujourd'hui, en UTC. Les filtres de modèle, de projet et de langue s'appliquent aux totaux, graphique quotidien et détail. La recherche s'applique uniquement aux lignes de détail. La période sélectionnée, la dimension, les filtres, la recherche, le tri et la page sont conservés dans l'URL.

## Métriques

| Métrique | Signification |
| --- | --- |
| Jetons d'entrée | Entrées traitées par le fournisseur, y compris les lectures et écritures de cache rapportées. |
| Jetons de sortie | Sortie rapportée par le fournisseur, y compris le raisonnement lorsque le fournisseur l'inclut dans son comptage de sortie. |
| Jetons d'entrée en cache | Lectures de cache. Un sous-ensemble des jetons d'entrée, qui ne constituent pas une charge supplémentaire dans le total. |
| Jetons totaux | Jetons d'entrée plus jetons de sortie. |
| Réponses | Les réponses comportant à la fois un comptage d'entrée et de sortie et un total de jetons positif. Les valeurs de repli d'utilisation manquante ramenées à zéro sont ignorées. |

Les comptages de jetons ne sont pas des coûts monétaires. Les fournisseurs peuvent facturer des tarifs différents pour l'entrée, la sortie, l'entrée en cache et les écritures de cache.

Chaque réponse rapportée est prise en compte, y compris les réessais de validation, les réessais de correction de qualité et les réponses rejetées car elles ont atteint leur limite de sortie. Les fichiers ignorés et les sauts de point de contrôle qui n'appellent pas un modèle n'ajoutent pas d'utilisation. Les requêtes échouées sans utilisation ne peuvent pas être comptées.

## Dimensions

- **Projets** regroupe l'utilisation par projet. Utilisez le filtre de projet pour limiter toutes les métriques à un seul projet.
- **Langues** regroupe par localisation cible, tel que `es` ou `ja`, à travers les projets dans le périmètre actuel.
- **Fichiers** regroupe par chemin source et projet. Le même fichier source traduit dans plusieurs langues apparaît une seule fois ; les fichiers identiquement nommés dans des projets différents restent séparés.

**Non affectés** garde les requêtes sans métadonnées de projet ou de chemin source visibles. Les traductions de dépôt fournissent les deux automatiquement. Les requêtes API à contenu unique peuvent fournir `project_id` et `source_path` pour l'attribution ; un ID de projet en dehors du compte authentifié est traité comme non affecté. Les métadonnées optionnelles invalides ou trop volumineuses sont non affectées sans éliminer les comptages de jetons.

## Couverture

L'utilisation est collectée à partir des réponses de clé API ReqLLM et OAuth, des complétions Together et des tours locaux Codex terminés. Seuls les comptages rapportés par le fournisseur sont persistés. Les sessions Pi locales et les évaluations de modèles de décision ne sont pas incluses. Les traductions historiques ne sont pas reconstituées ou estimées. Les totaux décrivent donc l'utilisation enregistrée, pas une facture complète du fournisseur.

Le registre conserve le compte, le projet, l'identifiant et la poignée de modèle, la localisation cible, le chemin source, les comptages et l'horodatage. Il ne conserve pas les prompts, le contenu traduit, les identifiants ou les réponses brutes du fournisseur. Les échecs d'enregistrement d'utilisation sont journalisés sans interrompre la traduction.
