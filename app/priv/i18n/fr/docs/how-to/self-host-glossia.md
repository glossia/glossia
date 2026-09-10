%{
  title: "Auto-héberger Glossia",
  summary:
    "Installez Glossia sur votre propre cluster Kubernetes avec le Helm chart inclus, afin que votre équipe exécute l'OS linguistique sur sa propre infrastructure.",
  category: "Tutoriel",
  order: 2
}
---
Glossia est open source sous la [O'Saasy License](https://github.com/glossia/glossia/blob/main/LICENSE.md). Vous pouvez l'héberger vous-même, le modifier et l'exécuter pour l'usage interne de votre organisation. La seule chose que la licence ne permet pas est de le proposer à des tiers en tant que produit hébergé ou SaaS en concurrence avec le service hébergé à glossia.ai.

Ce guide vous emmène d'un cluster Kubernetes vide à une instance Glossia opérationnelle.

## Avant de commencer

Vous aurez besoin de :

- Un cluster Kubernetes sur lequel vous pouvez installer des Helm charts (v1.28 ou plus récent)
- `helm` et `kubectl` localement
- Un domaine sur lequel vous pouvez pointer l'ingress du cluster
- Un fournisseur OpenID Connect ou un relais SMTP pour l'authentification (Glossia prend en charge les deux)

Le graphique Helm regroupe Postgres (via [CloudNativePG](https://cloudnative-pg.io/)) et ClickHouse (via le [opérateur officiel](https://github.com/ClickHouse/clickhouse-operator)) afin que vous n'ayez pas besoin de bases de données externes. Si vous préférez les apporter vous-mêmes, les deux peuvent être désactivés dans `values.yaml`.

## Installer les opérateurs

Installez les opérateurs correspondants aux composants que vous souhaitez activer. Au minimum :

- [CloudNativePG opérateur](https://cloudnative-pg.io/documentation/current/installation_upgrade/) pour la base de données d'application
- [opérateur ClickHouse Kubernetes](https://github.com/ClickHouse/clickhouse-operator) pour la base de données analytique
- Un contrôleur d'ingress (par exemple [ingress-nginx](https://kubernetes.github.io/ingress-nginx/))
- [cert-manager](https://cert-manager.io/) si vous souhaitez un TLS automatique

## Installez la chart Glossia

Clonez le référentiel, puis installez la chart :

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
| `GLOSSIA_METRICS_BEARER_TOKEN` | Protection des jetons Bearer | `/metrics` |
| `GLOSSIA_OPS_AUTH_PASSWORD` | Basic-auth pour `/ops` tableaux de bord |
| `RELEASE_COOKIE` | cookie de distribution Erlang partagé par chaque pod |
| `GLOSSIA_SMTP_*` | Paramètres de messagerie sortante |

Vous pouvez provisionner ceux-ci directement, utilisez [Sealed Secrets](https://github.com/bitnami-labs/sealed-secrets), ou reliez le chart à votre gestionnaire de secrets via le [External Secrets Operator](https://external-secrets.io/) l'intégration décrite dans le README du chart.

## Ce qui se trouve dans le chart

- L'application web Glossia
- Postgres pour les données d'application (optionnel, activé par défaut)
- ClickHouse pour l'analyse (optionnel, activé par défaut)
- Travailleurs en arrière-plan pour les tâches de traduction, qui s'exécutent en tant que Jobs Kubernetes pour survivre aux déploiements progressifs

## Où aller ensuite

- Le [Helm chart README](https://github.com/glossia/glossia/blob/main/deploy/helm/glossia/README.md) contient la référence complète pour chaque valeur, plus des notes sur les sauvegardes, le stockage objet et l'observabilité.
- [Configurer un fournisseur de modèle](/docs/how-to/configure-a-model-provider) une fois l'instance en cours d'exécution afin que les traductions puissent appeler un LLM.
- Signalez les problèmes ou suggérez des améliorations à l'adresse [Dépôt GitHub](https://github.com/glossia/glossia).