%{
  title: "Héberger Glossia vous-même",
  summary:
    "Installez Glossia sur votre propre cluster Kubernetes avec le chart Helm inclus, afin que votre équipe fasse tourner l'OS des langues sur sa propre infrastructure.",
  category: "Guide",
  order: 2
}
---
Glossia est open source sous la [Licence O'Saasy](https://github.com/glossia/glossia/blob/main/LICENSE.md)\<span class="glossia"\>". Vous pouvez l'héberger vous-même, le modifier et l'exécuter pour l'usage interne de votre organisation. La seule chose que la licence ne permet pas est de l'offrir à des tiers sous forme de produit hébergé ou SaaS en concurrence avec le service hébergé sur glossia.ai.\</span\>

Ce guide vous amène d'un cluster Kubernetes vide à une instance Glossia opérationnelle.

## Avant de commencer

Vous aurez besoin de :

- Un cluster Kubernetes sur lequel vous pouvez installer des charts Helm (v1.28 ou plus récent)
- `helm` et `kubectl` localement
- Un domaine que vous pouvez pointer vers l'ingress du cluster
- Un fournisseur OpenID Connect ou un relais SMTP pour l'authentification (Glossia supporte les deux)

Le Helm chart regroupe Postgres (via [CloudNativePG](https://cloudnative-pg.io/)) et ClickHouse (via le [opérateur officiel](https://github.com/ClickHouse/clickhouse-operator)) donc vous n'avez pas besoin de bases de données externes. Si vous préférez les amener vous-même, les deux peuvent être désactivés dans `values.yaml`.

## Installez les opérateurs

Installez les opérateurs qui correspondent aux composants que vous prévoyez d'activer. Minimum :

- [Opérateur CloudNativePG](https://cloudnative-pg.io/documentation/current/installation_upgrade/) pour la base de données d'application
- [Opérateur ClickHouse Kubernetes](https://github.com/ClickHouse/clickhouse-operator) pour la base de données analytique
- Un contrôleur d'ingress (par exemple [ingress-nginx](https://kubernetes.github.io/ingress-nginx/))
- [cert-manager](https://cert-manager.io/) si vous souhaitez une TLS automatique

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

## Fournissez les secrets de l'application

Créez un Secret Kubernetes nommé `glossia-app-env` avec au moins ces clés :

| Clé | Usage |
| --- | --- |
| `GLOSSIA_SECRET_KEY_BASE` | clé de signature de session Phoenix |
| `GLOSSIA_METRICS_BEARER_TOKEN` | protection des jetons Bearer | `/metrics` |
| `GLOSSIA_OPS_AUTH_PASSWORD` | Authentification de base pour `/ops` tableaux de bord |
| `RELEASE_COOKIE` | cookie de distribution Erlang partagé par chaque pod |
| `GLOSSIA_SMTP_*` | Paramètres de messagerie sortante |

Vous pouvez provisionner ces éléments directement, utiliser [Sealed Secrets](https://github.com/bitnami-labs/sealed-secrets), ou connectez le chart à votre gestionnaire de secrets via l' [External Secrets Operator](https://external-secrets.io/) d'intégration décrite dans le README du chart.

## Ce qui se trouve dans le chart

- L'application web Glossia
- Postgres pour les données d'application (facultatif, activé par défaut)
- ClickHouse pour les analyses (facultatif, activé par défaut)
- Travailleurs de fond pour les tâches de traduction, exécutés en tant que jobs Kubernetes afin de survivre aux déploiements progressifs.

## Où aller ensuite

- Le [README du Helm chart](https://github.com/glossia/glossia/blob/main/deploy/helm/glossia/README.md) contient la référence complète pour chaque valeur, ainsi que des notes sur les sauvegardes, le stockage objet et l'observabilité.
- [Configurer un fournisseur de modèle](/docs/how-to/configure-a-model-provider) dès que l'instance est en cours d'exécution afin que les traductions puissent appeler un LLM.
- Signalez les problèmes ou suggérez des améliorations à [Dépôt GitHub](https://github.com/glossia/glossia).