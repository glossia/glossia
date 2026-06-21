{{/*
Common labels for chart-owned objects (CephObjectStore, ExternalSecrets,
Ingresses). Subchart objects carry their own labels from their respective
charts.
*/}}
{{- define "observability.labels" -}}
app.kubernetes.io/name: glossia-observability
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/part-of: glossia
helm.sh/chart: {{ .Chart.Name }}-{{ .Chart.Version | replace "+" "_" }}
{{- end -}}

{{/*
Standard nginx basic-auth annotations for the push-endpoint ingresses
(mimir/loki/tempo). The `auth` Secret is the htpasswd file projected
from 1Password via the push-endpoints-auth ExternalSecret.
*/}}
{{- define "observability.pushAuthAnnotations" -}}
nginx.ingress.kubernetes.io/auth-type: basic
nginx.ingress.kubernetes.io/auth-secret: {{ .Values.externalSecrets.pushAuth.secretName }}
nginx.ingress.kubernetes.io/auth-realm: "glossia observability push"
{{- end -}}
