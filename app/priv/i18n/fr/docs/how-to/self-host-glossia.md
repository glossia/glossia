%{
  title: "Auto-héberger Glossia",
  summary:
    "Installez Glossia sur votre propre cluster Kubernetes avec le chart Helm inclus, afin que votre équipe exécute le système d'exploitation linguistique sur sa propre infrastructure.",
  category: "guide",
  order: 2
}
---
Glossia est open source sous la [O'Saasy Licence](https://github.com/glossia/glossia/blob/main/LICENSE.md). Vous pouvez l'héberger vous-même, le modifier et l'utiliser pour l'usage interne de votre organisation. La seule chose que la licence n'autorise pas est de proposer à des tiers un produit hébergé ou SaaS qui entre en concurrence avec le service hébergé sur glossia.ai.

Ce guide vous amène d'un cluster Kubernetes vide à une instance Glossia en service.

## Avant de commencer

You'll need:

- Un cluster Kubernetes sur lequel vous pouvez installer des Helm charts (v1.28 ou plus récent)
- `helm` et `kubectl` localement
- Un domaine que vous pouvez pointer vers l'ingress du cluster
- Un fournisseur OpenID Connect ou un relais SMTP pour l'authentification (Glossia les deux prend en charge)

Le Helm chart regroupe Postgres (via [CloudNativePG](https://cloudnative-pg.io/)) et ClickHouse (via l' [opérateur officiel](https://github.com/ClickHouse/clickhouse-operator)) donc vous n'avez pas besoin de bases de données externes. Si vous préférez les utiliser vous-même, les deux peuvent être désactivés dans `values.yaml`.

## Installez les opérateurs

Installez les opérateurs qui correspondent aux composants que vous prévoyez d'activer. Au minimum :

- [CloudNativePG opérateur](https://cloudnative-pg.io/documentation/current/installation_upgrade/) pour la base de données de l'application
- [ClickHouse Kubernetes opérateur](https://github.com/ClickHouse/clickhouse-operator) pour la base de données analytique
- Un contrôleur d'ingress (par exemple [ingress-nginx](https://kubernetes.github.io/ingress-nginx/)" )
- [cert-manager](https://cert-manager.io/) si vous souhaitez le TLS automatique

## Installez le chart Glossia

Clonez le dépôt, puis installez le chart:

```bash
git clone https://github.com/glossia/glossia.git
cd glossia

helm install glossia ./deploy/helm/glossia \
  --namespace glossia --create-namespace \
  --set image.tag=main \
  --set ingress.enabled=true \
  --set ingress.hosts[0].host=glossia.example.com
```

## Fournissez les secrets de l'application

Créez un Secret Kubernetes nommé `glossia-app-env` avec au moins ces clés :

| Clé | Usage |
| --- | --- |
| `GLOSSIA_SECRET_KEY_BASE` | Clé de signature de session de Phoenix |
| `GLOSSIA_METRICS_BEARER_TOKEN` | Protection des jetons Bearer | `/metrics` |
| `GLOSSIA_OPS_AUTH_PASSWORD` | Authentification basique pour `/ops` tableaux de bord |
| `RELEASE_COOKIE` | Cookie de distribution Erlang partagé par chaque pod |
| `GLOSSIA_SMTP_*` | Paramètres de messagerie sortante |

Vous pouvez les provisionner directement, utilisez [Sealed Secrets](https://github.com/bitnami-labs/sealed-secrets), ou reliez le chart à votre gestionnaire de secrets via le [External Secrets Operator](https://external-secrets.io/) intégration décrite dans le README du chart.

## Ce que contient le chart

- L'application web Glossia
- PostgreSQL pour les données de l'application (optionnel, activé par défaut)
- ClickHouse pour l'analyse (optionnel, activé par défaut)
- Travailleurs d'arrière-plan pour les tâches de traduction, qui s'exécutent en tant que Kubernetes Jobs afin de survivre aux déploiements roulants

## Où aller ensuite

- Le [README du Helm chart](https://github.com/glossia/glossia/blob/main/deploy/helm/glossia/README.md) contient la référence complète pour chaque valeur, ainsi que des notes sur les sauvegardes, le stockage d'objets et l'observabilité.
- [Configurer un fournisseur de modèle](/docs/how-to/configure-a-model-provider) une fois l'instance en cours d'exécution afin que les traductions puissent appeler un LLM.
- Signalez les problèmes ou suggérez des améliorations à l'adresse [Dépôt GitHub](https://github.com/glossia/glossia).