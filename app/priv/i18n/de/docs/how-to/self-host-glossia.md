%{
  title: "Glossia selbst hosten",
  summary:
    "Installieren Sie Glossia in Ihrem eigenen Kubernetes-Cluster mit dem mitgelieferten Helm-Chart, sodass Ihr Team das Sprach-OS auf seiner eigenen Infrastruktur betreibt.",
  category: "Anleitung",
  order: 2
}
---
Glossia ist Open Source unter der [O'Saasy License](https://github.com/glossia/glossia/blob/main/LICENSE.md). Sie können es selbst hosten, modifizieren und für den internen Einsatz in Ihrer Organisation nutzen. Das einzige, was die Lizenz nicht erlaubt, ist, es Dritten als gehostetes oder SaaS-Produkt anzubieten, das mit dem gehosteten Dienst von glossia.ai konkurriert.

Diese Anleitung führt Sie von einem leeren Kubernetes-Cluster zu einer laufenden Glossia-Instanz.

## Bevor Sie beginnen

Sie benötigen:

- Ein Kubernetes-Cluster, auf dem Sie Helm-Charts installieren können (v1.28 oder neuer)
- `helm` und `kubectl` lokal
- Eine Domain, die Sie auf den Cluster-Ingress verweisen können
- Ein OpenID Connect-Provider oder SMTP-Relay zur Authentifizierung (Glossia unterstützt beides)

Das Helm-Chart bündelt Postgres (über [CloudNativePG](https://cloudnative-pg.io/)) und ClickHouse (über den [offiziellen Operator](https://github.com/ClickHouse/clickhouse-operator)) sodass Sie keine externen Datenbanken benötigen. Wenn Sie lieber Ihre eigenen beisteuern möchten, können beide in deaktiviert werden `values.yaml`"

## Installieren Sie die Operatoren

Installieren Sie die Operatoren, die zu den Komponenten passen, die Sie aktivieren möchten. Mindestens:

- [CloudNativePG-Operator](https://cloudnative-pg.io/documentation/current/installation_upgrade/) für die App-Datenbank
- [ClickHouse Kubernetes-Operator](https://github.com/ClickHouse/clickhouse-operator) für die Analytics-Datenbank
- Ein Ingress-Controller (zum Beispiel [ingress-nginx](https://kubernetes.github.io/ingress-nginx/))
- [cert-manager](https://cert-manager.io/) falls Sie automatische TLS wünschen

## Installieren Sie das Glossia-Chart

Klonen Sie das Repository und installieren Sie dann das Chart:

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

Erstellen Sie ein Kubernetes Secret namens `glossia-app-env` mit mindestens diesen Schlüsseln:

| Schlüssel | Zweck |
| --- | --- |
| `GLOSSIA_SECRET_KEY_BASE` | Phoenix-Sitzungs-Signierungsschlüssel |
| `GLOSSIA_METRICS_BEARER_TOKEN` | Bearer-Token-Schutz | `/metrics` |
| `GLOSSIA_OPS_AUTH_PASSWORD` | Basic-Auth für `/ops` Dashboards |
| `RELEASE_COOKIE` | Erlang-Verteilungs-Cookie, das von jedem Pod geteilt wird |
| `GLOSSIA_SMTP_*` | Outbound-E-Mail-Einstellungen |

Sie können diese direkt bereitstellen, verwenden [Sealed Secrets](https://github.com/bitnami-labs/sealed-secrets), oder verbinde das Chart mit deinem Secret Manager über die [External Secrets Operator](https://external-secrets.io/) die Integration, die im Chart README beschrieben wird.

## Was sich im Chart befindet.

- Die Glossia Webanwendung.
- Postgres für Anwendungsdaten (optional, standardmäßig aktiviert)
- ClickHouse für Analytik (optional, standardmäßig aktiviert)
- Hintergrundarbeiter für Übersetzungsaufgaben, die als Kubernetes Jobs ausgeführt werden, sodass sie rollierende Bereitstellungen überdauern.

## Wo geht es weiter?

- Das [Helm chart README](https://github.com/glossia/glossia/blob/main/deploy/helm/glossia/README.md) enthält die vollständige Referenz für jeden Wert, sowie Hinweise zu Backups, Object Storage und Observability.
- [Konfigurieren Sie einen Modellanbieter](/docs/how-to/configure-a-model-provider) sobald die Instanz läuft, damit Übersetzungen ein LLM aufrufen können.
- Melden Sie Probleme oder schlagen Sie Verbesserungen unter dem [GitHub-Repository](https://github.com/glossia/glossia).