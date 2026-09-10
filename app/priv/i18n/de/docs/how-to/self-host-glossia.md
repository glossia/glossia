%{
  title: "Glossia selbst hosten",
  summary:
    "Installieren Sie Glossia in Ihrem eigenen Kubernetes-Cluster mit dem beiliegenden Helm-Chart, damit Ihr Team das Sprach-Betriebssystem auf Ihrer eigenen Infrastruktur betreibt.",
  category: "Anleitung",
  order: 2
}
---
Glossia ist Open Source unter der [O'Saasy-Lizenz](https://github.com/glossia/glossia/blob/main/LICENSE.md). Sie können es selbst Hosten, es modifizieren und für den internen Einsatz Ihrer Organisation nutzen. Das einzige, was die Lizenz nicht erlaubt, ist es, es an Dritte als gehostetes oder SaaS-Produkt anzubieten, das dem gehosteten Dienst auf glossia.ai Konkurrenz macht.

Diese Anleitung führt Sie von einem leeren Kubernetes-Cluster zu einer laufenden Glossia-Instanz.

## Bevor Sie beginnen

Sie benötigen:

- Einen Kubernetes-Cluster, auf dem Sie Helm-Charts installieren können (v1.28 oder neuer)
- `helm` und `kubectl` lokal
- Eine Domain, die Sie auf den Cluster-Ingress verweisen können
- Ein OpenID Connect-Provider oder SMTP-Relay zur Authentifizierung (Glossia unterstützt beides)

Die Helm-Chart bündelt Postgres (über [CloudNativePG](https://cloudnative-pg.io/), und ClickHouse (über den [offiziellen Operator](https://github.com/ClickHouse/clickhouse-operator)) sodass Sie keine externen Datenbanken benötigen. Falls Sie diese lieber selbst bereitstellen, können beide deaktiviert werden in `values.yaml`.

## Operatoren installieren

Installieren Sie die Operatoren, die zu den Komponenten passen, die Sie aktivieren möchten. Mindestens:

- [CloudNativePG Operator](https://cloudnative-pg.io/documentation/current/installation_upgrade/) für die App-Datenbank
- [ClickHouse Kubernetes Operator](https://github.com/ClickHouse/clickhouse-operator) für die Analytics-Datenbank
- Ein Ingress-Controller (beispielsweise [ingress-nginx](https://kubernetes.github.io/ingress-nginx/))
- [cert-manager](https://cert-manager.io/) wenn Sie automatisches TLS wünschen

## Installieren Sie den Glossia Chart

Klonen Sie das Repository, installieren Sie dann den Chart:

```bash
git clone https://github.com/glossia/glossia.git
cd glossia

helm install glossia ./deploy/helm/glossia \
  --namespace glossia --create-namespace \
  --set image.tag=main \
  --set ingress.enabled=true \
  --set ingress.hosts[0].host=glossia.example.com
```

## Bereitstellen Sie die App-Secrets

Erstellen Sie ein Kubernetes Secret namens `glossia-app-env` mit mindestens diesen Schlüsseln:

| Schlüssel | Zweck |
| --- | |
| `GLOSSIA_SECRET_KEY_BASE` | Schlüssel zur Phoenix-Sitzungssignierung |
| `GLOSSIA_METRICS_BEARER_TOKEN` | Schutz des Bearer-Tokens `/metrics` |
| `GLOSSIA_OPS_AUTH_PASSWORD` | Basic-Auth für `/ops` Dashboards |
| `RELEASE_COOKIE` | Erlang-Verteilung-Cookie, das von jedem Pod geteilt wird |
| `GLOSSIA_SMTP_*` | Einstellungen für ausgehende E-Mails |

Sie können diese direkt bereitstellen, verwenden Sie [Sealed Secrets](https://github.com/bitnami-labs/sealed-secrets), oder verbinde die Chart mit deinem Geheimnismanager über die [External Secrets Operator](https://external-secrets.io/) Integration, die in der Chart README beschrieben wird.

## Was in der Chart enthalten ist

- Die Glossia Webanwendung
- Postgres für Anwendungsdaten (optional, standardmäßig aktiv)
- ClickHouse für Analysen (optional, standardmäßig aktiv)
- Hintergrundarbeiter für Übersetzungsjobs, die als Kubernetes-Jobs ausgeführt werden, so dass sie rollierende Bereitstellungen überstehen

## Wo geht es weiter

- Die [Helm chart README](https://github.com/glossia/glossia/blob/main/deploy/helm/glossia/README.md) enthält die vollständige Referenz für jeden Wert, sowie Hinweise zu Backups, Object Storage und Observability.
- [Modellanbieter konfigurieren](/docs/how-to/configure-a-model-provider) sobald die Instanz läuft, damit Übersetzungen einen LLM aufrufen können.
- Probleme melden oder Verbesserungen vorschlagen unter dem [GitHub-Repositorie](https://github.com/glossia/glossia).