%{
  title: "Auto-héberger Glossia",
  summary:
    "Installez Glossia sur votre propre cluster Kubernetes avec le Helm chart inclus, pour que votre équipe exécute le système d'exploitation linguistique sur sa propre infrastructure.",
  category: "Tutoriel",
  order: 2
}
---
Glossia est open source sous la [Licence O'Saasy](https://github.com/glossia/glossia/blob/main/LICENSE.md). Vous pouvez l'auto-héberger, le modifier et l'utiliser pour un usage interne à votre organisation. La seule chose que la licence n'autorise pas est de le proposer à des tiers en tant que produit ou service hébergé en concurrence avec le service de glossia.ai.

Ce guide vous amène d'un cluster Kubernetes vide à une instance Glossia en cours d'exécution.

## Avant de commencer

Vous aurez besoin de :

- Un cluster Kubernetes sur lequel vous pouvez installer des chartes Helm (v1.28 ou supérieur)
- `helm` et `kubectl` localement
- Un domaine que vous pouvez pointer vers l'ingress du cluster
- Un fournisseur OpenID Connect ou un relais SMTP pour l'authentification (Glossia prend en charge les deux)

La chart Helm inclut Postgres (via [CloudNativePG](https://cloudnative-pg.io/)) et ClickHouse (via le [opérateur officiel](https://github.com/ClickHouse/clickhouse-operator)) de sorte que vous n'ayez pas besoin de bases de données externes. Si vous préférez les fournir vous-même, les deux peuvent être désactivés dans `values.yaml`.

## Installez les opérateurs

Installez les opérateurs correspondant aux composants que vous prévoyez d'activer. Au moins :

- [CloudNativePG opérateur](https://cloudnative-pg.io/documentation/current/installation_upgrade/) pour la base de données d'application
- [opérateur Kubernetes ClickHouse](https://github.com/ClickHouse/clickhouse-operator) pour la base de données analytique
- Un contrôleur d'ingress (par exemple [ingress-nginx](https://kubernetes.github.io/ingress-nginx/))
- [cert-manager](https://cert-manager.io/) si vous souhaitez le TLS automatique

## Installez la charte Glossia

Clonez le dépôt, puis installez la charte :

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

| Clé | Utilité |
| --- | --- |
| `GLOSSIA_SECRET_KEY_BASE` | Clé de signature de session Phoenix |
| `GLOSSIA_METRICS_BEARER_TOKEN` | Protection du jeton Bearer `/metrics` |
| `GLOSSIA_OPS_AUTH_PASSWORD` | Basic-auth pour `/ops` tableaux de bord |
| `RELEASE_COOKIE` | cookie de distribution Erlang partagé par chaque pod |
| `GLOSSIA_SMTP_*` | Paramètres de messagerie sortante |

Vous pouvez provisionner ces éléments directement, utilisez [Sealed Secrets](https://github.com/bitnami-labs/sealed-secrets), ou reliez le chart à votre gestionnaire de secrets via le [External Secrets Operator](https://external-secrets.io/) intégration décrite dans le README du chart.

## Ce qui se trouve dans le chart

- L'application web Glossia
- Postgres pour les données de l'application (optionnel, activé par défaut)
- ClickHouse pour l'analyse (optionnel, activé par défaut)
- Travailleurs en arrière-plan pour les tâches de traduction, qui s'exécutent en tant que Jobs Kubernetes afin de continuer à fonctionner après les déploiements rotatifs.

## Où aller ensuite

- Le [Helm chart README](https://github.com/glossia/glossia/blob/main/deploy/helm/glossia/README.md) contient la référence complète pour chaque valeur, ainsi que des notes sur les sauvegardes, le stockage objet et l'observabilité.
- [Configurer un fournisseur de modèle](/docs/how-to/configure-a-model-provider) une fois l'instance en activité pour que les traductions puissent appeler un LLM.
- Signalez les problèmes ou suggérez des améliorations à [Dépôt GitHub](https://github.com/glossia/glossia).