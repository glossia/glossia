%{
  title: "Glossia selbst hosten",
  summary:
    "Installiere Glossia auf deinem eigenen Kubernetes-Cluster mit der mitgelieferten Helm-Chart, damit dein Team das Sprach-Betriebssystem auf seiner eigenen Infrastruktur betreibt.",
  category: "Anleitung",
  order: 2
}
---
Glossia ist Open-Source unter der [O'Saasy-Lizenz](https://github.com/glossia/glossia/blob/main/LICENSE.md). Sie können es selbst hosten, modifizieren und für die interne Nutzung Ihrer Organisation betreiben. Das einzige, was die Lizenz nicht erlaubt, ist es an Dritte als gehostetes oder SaaS-Produkt anzubieten, das mit dem gehosteten Dienst auf glossia.ai konkurriert.

Dieser Leitfaden führt Sie von einem leeren Kubernetes-Cluster zu einer laufenden Glossia-Instanz.

## Bevor Sie beginnen

Sie benötigen:

- Ein Kubernetes-Cluster, auf dem Sie Helm-Charts installieren können (v1.28 oder newer)
- `helm` und `kubectl` lokal
- Eine Domain, auf die Sie für den Cluster-Ingress verweisen können
- Ein OpenID Connect-Provider oder SMTP-Relay für die Authentifizierung (Glossia unterstützt beides)

Das Helm-Chart bündelt Postgres (via [CloudNativePG](https://cloudnative-pg.io/)" ) und ClickHouse (via den [offiziellen Operator](https://github.com/ClickHouse/clickhouse-operator)" ) sodass Sie keine externen Datenbanken benötigen. Wenn Sie Ihre eigenen lieber bereitstellen möchten, können beide in deaktiviert werden `values.yaml`.

## Installieren Sie die Operatoren

Installieren Sie die Operatoren, die zu den Komponenten passen, die Sie aktivieren möchten. Mindestens:

- [CloudNativePG-Operator](https://cloudnative-pg.io/documentation/current/installation_upgrade/) für die App-Datenbank
- [ClickHouse Kubernetes-Operator](https://github.com/ClickHouse/clickhouse-operator) für die Analytik-Datenbank
- Ein Ingress-Controller (zum Beispiel [ingress-nginx](https://kubernetes.github.io/ingress-nginx/))
- [cert-manager](https://cert-manager.io/) wenn Sie automatische TLS wünschen

## Installieren Sie das Glossia-Chart

Klonen Sie das Repository, installieren Sie anschließend das Chart:

```bash
git clone https://github.com/glossia/glossia.git
cd glossia

helm install glossia ./deploy/helm/glossia \
  --namespace glossia --create-namespace \
  --set image.tag=main \
  --set ingress.enabled=true \
  --set ingress.hosts[0].host=glossia.example.com
```

## Geben Sie die App-Geheimnisse ein

Erstellen Sie ein Kubernetes-Secret namens `glossia-app-env` mindestens mit folgenden Schlüsseln:

| Schlüssel | Zweck |
| --- | --- |
| `GLOSSIA_SECRET_KEY_BASE` | Phoenix Sitzungssignierungsschlüssel |
| `GLOSSIA_METRICS_BEARER_TOKEN` | Schutz des Bearer-Tokens `/metrics` |
| `GLOSSIA_OPS_AUTH_PASSWORD` | Basic-auth für `/ops` Dashboards |
| `RELEASE_COOKIE` | Erlang-Verteilungs-Cookie, von jedem Pod geteilt |
| `GLOSSIA_SMTP_*` | Ausgehende E-Mail-Einstellungen |

Sie können diese direkt bereitstellen, nutzen [Sealed Secrets](https://github.com/bitnami-labs/sealed-secrets), oder binden Sie das Chart an Ihren Secrets Manager über das [External Secrets Operator](https://external-secrets.io/) Integration beschrieben im Chart-README.

## Was im Chart enthalten ist.

- Die Glossia-Webanwendung.
- Postgres für Anwendungsdaten (optional, standardmäßig aktiviert)
- ClickHouse für Analytik (optional, standardmäßig aktiviert)
- Hintergrund-Worker für Übersetzungsaufgaben, die als Kubernetes-Jobs ausgeführt werden, sodass sie rollierende Bereitstellungen überdauern.

## Als Nächstes

- Die [Helm chart README](https://github.com/glossia/glossia/blob/main/deploy/helm/glossia/README.md) enthält die vollständige Referenz für jeden Wert, sowie Hinweise zu Backups, Object Storage und Observability.
- [Modellprovider konfigurieren](/docs/how-to/configure-a-model-provider) sobald die Instanz läuft, damit Übersetzungen einen LLM aufrufen können.
- Melden Sie Probleme oder schlagen Sie Verbesserungen unter [GitHub-Repository](https://github.com/glossia/glossia).