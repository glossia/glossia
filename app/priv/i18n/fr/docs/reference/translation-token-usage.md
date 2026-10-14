%{
  title: "Utilisation des jetons de traduction",
  summary:
    "Comprendre la comptabilité des jetons et la répartition par projet, langue et fichier source.",
  category: "Référence",
  section: "translation",
  order: 12
}
---

## Tableau de bord

Ouvrez **Paramètres → Modèles → Utilisation des jetons** pour voir l'utilisation communiquée par le fournisseur pour les traductions génératives. L'accès nécessite l'autorisation de lire les paramètres des modèles.

Le tableau de bord prend en charge les derniers 7, 30 ou 90 jours civils, y compris aujourd'hui, en UTC. Les filtres de modèle, de projet et de langue s'appliquent aux totaux, au graphique quotidien et à la décomposition. La recherche s'applique uniquement aux lignes de décomposition. La période sélectionnée, la dimension, les filtres, la recherche, le tri et la page sont préservés dans l'URL.

## Métriques

| Métrique | Signification |
| --- | --- |
| Jetons d'entrée | En entrée traitée par le fournisseur, y compris les lectures de cache et écritures de cache signalées. |
| Jetons de sortie | Sortie signalée par le fournisseur, y compris le raisonnement lorsque le fournisseur l'inclut dans son comptage de sortie. |
| Jetons d'entrée en cache | Lectures de cache. Un sous-ensemble de jetons d'entrée, sans frais supplémentaire dans le total. |
| Jetons totaux | Jetons d'entrée plus jetons de sortie. |
| Réponses | Réponses disposant à la fois d'un comptage d'entrée et de sortie et d'un total de jetons positif. Les valeurs nulles pour les retombées d'utilisation manquante sont ignorées. |

Les comptages de jetons ne constituent pas des coûts monétaires. Les fournisseurs peuvent appliquer des tarifs différents pour l'entrée, la sortie, l'entrée en cache et les écritures de cache.

Chaque réponse signalée est comptabilisée, y compris les redémarrages de validation, les redémarrages de correction de qualité et les réponses rejetées pour avoir atteint leur limite de sortie. Les fichiers ignorés et les accès de point de contrôle qui ne communiquent pas avec un modèle n'ajoutent aucune utilisation. Les requêtes échouées sans utilisation ne peuvent être comptabilisées.

## Dimensions

- **Projets** regroupe l'utilisation par projet. Utilisez le filtre de projet pour restreindre toutes les métriques à un seul projet.
- **Langues** regroupe selon la locale cible, comme `es` ou `ja`, parmi les projets dans le périmètre actuel.
- **Fichiers** regroupe par voie source et projet. Un même fichier source traduit en plusieurs langues n'apparaît qu'une seule fois ; les fichiers de même nom dans différents projets restent distincts.

**Non affectés** conserve les requêtes sans métadonnées de projet ou voie source visibles. Les traductions de dépôt fournissent les deux automatiquement. Les requêtes API de contenu unique peuvent fournir `project_id` et `source_path` pour l'attribution ; un identifiant de projet en dehors du compte authentifié est traité comme non affecté. Les métadonnées optionnelles invalides ou de taille excessive sont considérées comme non affectées sans perdre les comptages de jetons.

## Couverture

L'utilisation est collectée à partir des réponses de clé API ReqLLM et OAuth, des complétions Together et des tours locaux Codex terminés. Seuls les comptages signalés par le fournisseur sont persistés. Les sessions Pi locales et les évaluations de modèle de décision ne sont pas incluses. Les traductions historiques ne sont pas reconstituées ou estimées. Les totaux décrivent donc l'utilisation enregistrée, pas une facture complète du fournisseur.

Le grand livre stocke le compte, le projet, l'identifiant et handle du modèle, la locale cible, la voie source, les comptages et l'horodatage. Il ne stocke pas de prompts, du contenu traduit, des identifiants de connexion ou des réponses brutes du fournisseur. Les échecs d'enregistrement de l'utilisation sont journalisés sans interrompre la traduction.
