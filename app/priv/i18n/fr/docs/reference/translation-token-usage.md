%{
  title: "Utilisation des jetons de traduction",
  summary:
    "Comprendre la comptabilité des jetons et les décomptes de projet, de langue et de fichier source.",
  category: "Référence",
  section: "translation",
  order: 12
}
---
## Tableau de bord

Ouvrir **Paramètres → Modèles → Consommation de jetons** pour voir l'utilisation rapportée par le fournisseur pour les traductions génératives. L'accès nécessite l'autorisation de lire les paramètres des modèles.

Le tableau de bord prend en charge les 7, 30 ou 90 derniers jours civils, y compris aujourd'hui, en UTC. Les filtres de modèle, de projet et de langue s'appliquent aux totaux, au graphique quotidien et à la décomposition. La recherche s'applique uniquement aux lignes de décomposition. La période, la dimension, les filtres, la recherche, le tri et la page sélectionnés sont conservés dans l'URL.

## Métriques

| Métrique | Signification |
| --- | --- |
| Tokens d'entrée | Entrées traitées par le fournisseur, y compris les lectures de cache et les écritures de cache signalées. |
| Tokens de sortie | Données de sortie signalées par le fournisseur, incluant le raisonnement lorsque le fournisseur l'inclut dans son total de sortie. |
| Tokens d'entrée en cache | Lectures de cache. Sous-ensemble des tokens d'entrée, sans frais supplémentaires dans le total. |
| Tokens totaux | Tokens d'entrée plus tokens de sortie. |
| Réponses | Réponses comportant des comptages d'entrée et de sortie et un total de tokens positif. Les valeurs de repli pour l'utilisation manquante ramenée à zéro sont ignorées. |

Les comptages de tokens ne constituent pas des coûts monétaires. Les fournisseurs peuvent appliquer des tarifs différents pour l'entrée, la sortie, l'entrée en cache et les écritures de cache.

Chaque réponse signalée est comptabilisée, y compris les reprises de validation, les reprises de correction de qualité, et les réponses rejetées pour avoir atteint leur limite de sortie. Les fichiers ignorés et les accès aux points de contrôle ne faisant pas appel à un modèle n'ajoutent aucune utilisation. Les requêtes échouées sans utilisation ne peuvent pas être comptées.

## Dimensions

- **Projets** regroupe l'utilisation par projet. Utilisez le filtre de projet pour limiter toutes les métriques à un seul projet.
- **Langues** regroupe par locale cible, telle que `es` ou `ja`, sur tous les projets dans la portée actuelle.
- **Fichiers** regroupe par chemin source et projet. Un même fichier source traduit dans plusieurs langues apparaît une seule fois ; les fichiers de noms identiques dans des projets différents restent séparés.

**Non attribué** garde les requêtes sans métadonnées de projet ou de source-path visibles. Les traductions de dépôt fournissent les deux automatiquement. Les requêtes API à contenu unique peuvent fournir `project_id` et `source_path` pour l'attribution ; un identifiant de projet en dehors du compte authentifié est traité comme non attribué. Les métadonnées optionnelles invalides ou excessives sont non attribuées sans effacer les comptes de jetons.

## Couverture

L'utilisation est collectée à partir des réponses ReqLLM clés API et OAuth, des compléments Together, et des tours de Codex locaux terminés. Seuls les comptes déclarés par le fournisseur sont conservés. Les sessions locales Pi et les évaluations de modèles de décision ne sont pas incluses. Les traductions historiques ne sont pas remplies rétrospectivement ni estimées. Les totaux décrivent donc l'utilisation enregistrée, pas une facture complète du fournisseur.

Le registre stocke le compte, le projet, l'identifiant et la handle du modèle, la locale cible, le chemin source, les comptes et l'horodatage. Il ne stocke pas les invites, le contenu traduit, les identifiants de connexion ou les réponses brutes du fournisseur. Les échecs d'enregistrement de l'utilisation sont consignés sans interrompre la traduction.