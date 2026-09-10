%{
  title: "Auto-héberger Glossia",
  summary:
    "Installez Glossia sur votre propre cluster Kubernetes avec le chart Helm inclus, afin que votre équipe exécute le système d'exploitation linguistique sur sa propre infrastructure.",
  category: "Tutoriel",
  order: 2
}
---
Glossia est open source sous la [Licence O'Saasy](https://github.com/glossia/glossia/blob/main/LICENSE.md). Vous pouvez l'héberger vous-même, le modifier et l'utiliser pour une utilisation interne à votre organisation. La seule chose que la licence n'autorise pas est de le proposer à des tiers sous forme de produit hébergé ou SaaS qui rivalise avec le service hébergé de glossia.ai.

Ce guide vous amène d'un cluster Kubernetes vide à une instance de Glossia fonctionnelle.

## Avant de commencer

Il vous faudra :

- Un cluster Kubernetes sur lequel vous pouvez installer des Helm charts (v1.28 ou plus récent)
- `helm` et `kubectl` localement
- Un domaine que vous pouvez rediriger vers l'ingress du cluster
- Un fournisseur OpenID Connect ou un relais SMTP pour l'authentification (Glossia prend en charge les deux)

Le Helm chart regroupe Postgres (via [CloudNativePG](https://cloudnative-pg.io/)) et ClickHouse (via le [opérateur officiel](https://github.com/ClickHouse/clickhouse-operator)) alors vous n'avez pas besoin de bases de données externes. Si vous préférez apporter les vôtres, les deux peuvent être désactivés dans `values.yaml`.

## Installer les opérateurs

Installez les opérateurs qui correspondent aux composants que vous prévoyez d'activer. Au minimum :

- [Opérateur CloudNativePG](https://cloudnative-pg.io/documentation/current/installation_upgrade/) pour la base de données d'application
- [Opérateur ClickHouse Kubernetes](https://github.com/ClickHouse/clickhouse-operator) pour la base de données analytique
- Un contrôleur d'ingress (par exemple [ingress-nginx](https://kubernetes.github.io/ingress-nginx/))
- [cert-manager](https://cert-manager.io/) si vous souhaitez un TLS automatique

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

| Clé | Utilisation |
| --- | --- |
| `GLOSSIA_SECRET_KEY_BASE` | Clé de signature de session Phoenix |
| `GLOSSIA_METRICS_BEARER_TOKEN` | Protection du jeton Bearer `/metrics` |
| `GLOSSIA_OPS_AUTH_PASSWORD` | Authentification basique pour `/ops` tableaux de bord |
| `RELEASE_COOKIE` | Cookie de distribution Erlang partagé par chaque pod |
| `GLOSSIA_SMTP_*` | Paramètres de messagerie sortante |

Vous pouvez provisionner ces éléments directement, utilisez [Sealed Secrets](https://github.com/bitnami-labs/sealed-secrets), ou connectez le graphique à votre gestionnaire de secrets via le [External Secrets Operator](https://external-secrets.io/) l'intégration décrite dans la README du graphique.

## Ce qui se trouve dans le graphique

- L'application web Glossia
- Postgres pour les données de l'application (facultatif, activé par défaut)
- ClickHouse pour l'analyse (facultatif, activé par défaut)
- Workers en arrière-plan pour les tâches de traduction, qui s'exécutent en tant que Jobs Kubernetes afin de persister au-delà des déploiements progressifs.

## Où aller ensuite

- Le [README du Helm chart](https://github.com/glossia/glossia/blob/main/deploy/helm/glossia/README.md) contient la référence complète pour chaque valeur, ainsi que des notes concernant les sauvegardes, le stockage objet et l'observabilité.
- [Configurer un fournisseur de modèle](/docs/how-to/configure-a-model-provider) après que l'instance soit en cours d'exécution pour que les traductions puissent invoquer un LLM.
- Signalez les problèmes ou suggérez des améliorations à l'adresse [Dépôt GitHub](https://github.com/glossia/glossia).