%{
  title: "Auto-héberger Glossia",
  summary:
    "Installez Glossia sur votre propre cluster Kubernetes avec le Helm chart inclus, afin que votre équipe exécute l'OS linguistique sur son infrastructure.",
  category: "Guide",
  order: 2
}
---
Glossia est open source sous la [Licence O'Saasy](https://github.com/glossia/glossia/blob/main/LICENSE.md). Vous pouvez l'héberger vous-même, le modifier et l'utiliser pour votre usage interne au sein de l'organisation. La seule chose que la licence n'autorise pas est de la proposer à des tiers sous la forme d'un produit hébergé ou SaaS concurrençant le service sur glossia.ai.

Ce guide vous emmène d'un cluster Kubernetes vide à une instance Glossia opérationnelle.

## Avant de commencer

Il vous faut :

- Un cluster Kubernetes sur lequel vous pouvez installer des charts Helm (v1.28 ou supérieur)
- `helm` et `kubectl` localement
- Un domaine que vous pouvez pointer vers l'ingress du cluster
- Un fournisseur OpenID Connect ou un relais SMTP pour l'authentification (Glossia supporte les deux)

Le Helm chart regroupe Postgres (via [CloudNativePG](https://cloudnative-pg.io/)) et ClickHouse (via le [opérateur officiel](https://github.com/ClickHouse/clickhouse-operator)) afin que vous n'ayez pas besoin de bases de données externes. Si vous préférez les apporter vous-même, les deux peuvent être désactivés dans `values.yaml`.

## Installez les opérateurs

Installez les opérateurs correspondant aux composants que vous prévoyez d'activer. Au minimum :

- [opérateur CloudNativePG](https://cloudnative-pg.io/documentation/current/installation_upgrade/) pour la base de données d'application
- [opérateur ClickHouse Kubernetes](https://github.com/ClickHouse/clickhouse-operator) pour la base de données analytique
- Un contrôleur d'ingress (par exemple [ingress-nginx](https://kubernetes.github.io/ingress-nginx/))
- [cert-manager](https://cert-manager.io/) si vous souhaitez du TLS automatique

## Installez le chart Glossia

Clonez le dépôt, puis installez le chart :

```bash
git clone https://github.com/glossia/glossia.git
cd glossia

helm install glossia ./deploy/helm/glossia \
  --namespace glossia --create-namespace \
  --set image.tag=main \
  --set ingress.enabled=true \
  --set ingress.hosts[0].host=glossia.example.com
```

## Fournissez les secrets d'application

Créez un Secret Kubernetes nommé `glossia-app-env` Avec au moins ces clés :

| Clé | Utilisation |
| --- | --- |
| `GLOSSIA_SECRET_KEY_BASE` | Clé de signature de session Phoenix |
| `GLOSSIA_METRICS_BEARER_TOKEN` | Protection des jetons Bearer `/metrics` |
| `GLOSSIA_OPS_AUTH_PASSWORD` | Basic-auth pour `/ops` tableaux de bord |
| `RELEASE_COOKIE` | Cookie de distribution Erlang partagé par chaque pod |
| `GLOSSIA_SMTP_*` | Paramètres de messagerie sortante |

Vous pouvez les provisionner directement, utilisez [Sealed Secrets](https://github.com/bitnami-labs/sealed-secrets), ou connectez le chart à votre gestionnaire de secrets via le [External Secrets Operator](https://external-secrets.io/) , l'intégration décrite dans le README du chart.

## Ce qui se trouve dans le chart

- L'application web Glossia
- Postgres pour les données de l'application (optionnel, activé par défaut)
- ClickHouse pour l'analyse (optionnel, activé par défaut)
- Travailleurs de fond pour les tâches de traduction, qui s'exécutent en tant que Jobs Kubernetes afin qu'ils survivent aux déploiements roulants.

## Où aller ensuite

- Le [Helm chart README](https://github.com/glossia/glossia/blob/main/deploy/helm/glossia/README.md) contient la référence complète pour chaque valeur, ainsi que des notes sur les sauvegardes, le stockage d'objets et l'observabilité.
- [Configurer un fournisseur de modèle](/docs/how-to/configure-a-model-provider) une fois que l'instance est en service afin que les traductions puissent appeler un LLM.
- Signalez des problèmes ou suggérez des améliorations à [Dépôt GitHub](https://github.com/glossia/glossia).