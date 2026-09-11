%{
  title: "Glossia selbst hosten",
  summary:
    "Installieren Sie Glossia auf Ihrem eigenen Kubernetes-Cluster mit dem mitgelieferten Helm-Chart, damit Ihr Team das Sprach-OS auf seiner eigenen Infrastruktur betreibt.",
  category: "Anleitung",
  order: 2
}
---
Glossia ist Open Source unter der [O'Saasy License](https://github.com/glossia/glossia/blob/main/LICENSE.md). Sie können es selbst hosten, es modifizieren und für den internen Gebrauch Ihrer Organisation nutzen. Das einzige, was die Lizenz nicht erlaubt, ist es als gehostetes oder SaaS-Produkt anzubieten, das mit dem gehosteten Service auf glossia.ai konkurriert.

Diese Anleitung bringt Sie von einem leeren Kubernetes-Cluster zu einer laufenden Glossia-Instanz.

## Bevor Sie beginnen

Sie benötigen:

- Ein Kubernetes-Cluster, auf dem Sie Helm-Charts installieren können (v1.28 oder neuer)
- `helm` und `kubectl` lokal
- Eine Domain, auf die Sie den Cluster-Ingress verweisen können
- Ein OpenID Connect-Anbieter oder ein SMTP-Relay zur Authentifizierung (Glossia unterstützt beides)

Der Helm-Chart bündelt Postgres (über [CloudNativePG](https://cloudnative-pg.io/)) und ClickHouse (über den [offiziellen Operator](https://github.com/ClickHouse/clickhouse-operator)) so benötigen Sie keine externen Datenbanken. Wenn Sie es lieber selbst erledigen möchten, können beide in `values.yaml`.

## Installieren Sie die Operatoren

Installieren Sie die Operatoren, die zu den Komponenten passen, die Sie aktivieren möchten. Mindestens:

- [CloudNativePG-Operator](https://cloudnative-pg.io/documentation/current/installation_upgrade/) für die Anwendungsdatenbank
- [ClickHouse Kubernetes Operator](https://github.com/ClickHouse/clickhouse-operator) für die Analytikdatenbank
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
| --- | --- |
| `GLOSSIA_SECRET_KEY_BASE` | Phoenix-Session-Signierungsschlüssel |
| `GLOSSIA_METRICS_BEARER_TOKEN` | Bearer-Token-Schutz `/metrics` |
| `GLOSSIA_OPS_AUTH_PASSWORD` | Basic-auth für `/ops` Dashboards |
| `RELEASE_COOKIE` | Erlang-Verteilungs-Cookie, das von jedem Pod geteilt wird |
| `GLOSSIA_SMTP_*` | Einstellungen für ausgehende E-Mails |

Sie können diese direkt bereitstellen, verwenden [Sealed Secrets](https://github.com/bitnami-labs/sealed-secrets), oder verbinde das Chart mit deinem Secret Manager über die [External Secrets Operator](https://external-secrets.io/) Integration, die in der Chart-README beschrieben ist.

## Was im Chart enthalten ist

- Die Glossia Webanwendung
- Postgres für Anwendungsdaten (optional, standardmäßig aktiviert)
- ClickHouse für Analytik (optional, standardmäßig aktiviert)
- Hintergrundprozesse für Übersetzungsjobs, die als Kubernetes Jobs ausgeführt werden, sodass sie über Rolling Deploys hinausleben.

## Wo geht es als Nächstes?

- Der [Helm chart README](https://github.com/glossia/glossia/blob/main/deploy/helm/glossia/README.md) enthält die vollständige Referenz für jeden Wert, einschließlich Anmerkungen zu Backups, Objektspeicher und Observability.
- [Konfigurieren Sie einen Modellanbieter](/docs/how-to/configure-a-model-provider) sobald die Instanz läuft, damit Übersetzungen einen LLM aufrufen können.
- Melden Sie Probleme oder schlagen Sie Verbesserungen vor, unter [GitHub-Repository](https://github.com/glossia/glossia).