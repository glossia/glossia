%{
  title: "Glossia selbst hosten",
  summary:
    "Installieren Sie Glossia auf Ihrem eigenen Kubernetes-Cluster mit dem mitgelieferten Helm-Chart, damit Ihr Team das Sprach-OS auf Ihrer eigenen Infrastruktur betreibt.",
  category: "Anleitung",
  order: 2
}
---
Glossia ist Open Source unter der [O'Saasy-Lizenz](https://github.com/glossia/glossia/blob/main/LICENSE.md). Sie können es selbst hosten, modifizieren und für den internen Einsatz in Ihrer Organisation verwenden. Das einzige, was die Lizenz nicht erlaubt, ist das Angebot an Dritte als gehostetes oder SaaS-Produkt, das mit dem gehosteten Service auf glossia.ai konkurriert.

Dieser Leitfaden führt Sie von einem leeren Kubernetes-Cluster zu einer laufenden Glossia-Instanz.

## Bevor Sie beginnen

Sie benötigen:

- Ein Kubernetes-Cluster, auf dem Sie Helm-Charts installieren können (v1.28 oder neuer)
- `helm` und `kubectl` lokal
- Eine Domäne, auf die Sie den Cluster-Ingress verweisen können
- Ein OpenID Connect-Provider oder SMTP-Relay für die Authentifizierung (Glossia unterstützt beides)

Das Helm-Chart bündelt Postgres (über [CloudNativePG](https://cloudnative-pg.io/)) und ClickHouse (über den [offiziellen Operator](https://github.com/ClickHouse/clickhouse-operator)) sodass Sie keine externen Datenbanken benötigen. Wenn Sie lieber Ihre eigenen bereitstellen möchten, können beide deaktiviert werden in `values.yaml`.

## Installieren Sie die Operatoren

Installieren Sie die Operatoren, die zu den Komponenten passen, die Sie aktivieren möchten. Mindestens:

- [CloudNativePG-Operator](https://cloudnative-pg.io/documentation/current/installation_upgrade/) für die App-Datenbank
- [ClickHouse-Kubernetes-Operator](https://github.com/ClickHouse/clickhouse-operator) für die Analytics-Datenbank
- Ein Ingress-Controller (beispielsweise [ingress-nginx](https://kubernetes.github.io/ingress-nginx/))
- [cert-manager](https://cert-manager.io/) wenn Sie automatische TLS wünschen

## Installieren Sie das Glossia-Chart

Klonen Sie das Repository, installieren Sie dann das Chart:

```bash
git clone https://github.com/glossia/glossia.git
cd glossia

helm install glossia ./deploy/helm/glossia \
  --namespace glossia --create-namespace \
  --set image.tag=main \
  --set ingress.enabled=true \
  --set ingress.hosts[0].host=glossia.example.com
```

## Geben Sie die App-Secrets ein

Erstellen Sie ein Kubernetes Secret namens `glossia-app-env` mindestens folgende Schlüssel:

| Schlüssel | Zweck |
| --- | --- |
| `GLOSSIA_SECRET_KEY_BASE` | Phoenix-Sitzungs-Signaturschlüssel |
| `GLOSSIA_METRICS_BEARER_TOKEN` | Bearer-Token-Schutz | `/metrics` |
| `GLOSSIA_OPS_AUTH_PASSWORD` | Basic-Auth für `/ops` Dashboards |
| `RELEASE_COOKIE` | Von jedem Pod geteiltes Erlang-Verteilungs-Cookie |
| `GLOSSIA_SMTP_*` | Einstellungen für ausgehende E-Mails |

Sie können diese direkt provisionieren, verwenden [Sealed Secrets](https://github.com/bitnami-labs/sealed-secrets), oder verbinde das Chart mit deinem Secret Manager über die [External Secrets Operator](https://external-secrets.io/) Integration beschrieben in der Chart README.

## Was im Chart enthalten ist

- Die Glossia Webanwendung
- Postgres für Anwendungsdaten (optional, standardmäßig aktiviert)
- ClickHouse für Analytik (optional, standardmäßig aktiviert)
- Hintergrundworker für Übersetzungsjobs, die als Kubernetes-Jobs ausgeführt werden, damit sie über rollierende Bereitstellungen hinaus laufen

## Wo geht es weiter?

- Das [Helm chart README](https://github.com/glossia/glossia/blob/main/deploy/helm/glossia/README.md) enthält die vollständige Referenz für jeden Wert sowie Hinweise zu Backups, Objektspeicher und Observability.
- [Modellanbieter konfigurieren](/docs/how-to/configure-a-model-provider) sobald die Instanz läuft, damit Übersetzungen einen LLM aufrufen können.
- Melden Sie Probleme oder schlagen Sie Verbesserungen auf der [GitHub-Repository](https://github.com/glossia/glossia).