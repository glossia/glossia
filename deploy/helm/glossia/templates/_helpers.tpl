{{- define "glossia.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "glossia.fullname" -}}
{{- if .Values.fullnameOverride -}}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- include "glossia.name" . -}}
{{- end -}}
{{- end -}}

{{- define "glossia.labels" -}}
helm.sh/chart: {{ .Chart.Name }}-{{ .Chart.Version | replace "+" "_" }}
app.kubernetes.io/name: {{ include "glossia.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end -}}

{{- define "glossia.selectorLabels" -}}
app.kubernetes.io/name: {{ include "glossia.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end -}}

{{- define "glossia.image" -}}
{{- if .Values.image.digest -}}
{{- printf "%s@%s" .Values.image.repository .Values.image.digest -}}
{{- else -}}
{{- printf "%s:%s" .Values.image.repository .Values.image.tag -}}
{{- end -}}
{{- end -}}

{{- define "glossia.smolanalyticsName" -}}
{{- printf "%s-smolanalytics" (include "glossia.fullname" .) | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "glossia.smolanalyticsImage" -}}
{{- if .Values.smolanalytics.image.digest -}}
{{- printf "%s@%s" .Values.smolanalytics.image.repository .Values.smolanalytics.image.digest -}}
{{- else -}}
{{- printf "%s:%s" .Values.smolanalytics.image.repository .Values.smolanalytics.image.tag -}}
{{- end -}}
{{- end -}}

{{- define "glossia.hermesName" -}}
{{- printf "%s-hermes" (include "glossia.fullname" .) | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "glossia.hermesImage" -}}
{{- if .Values.hermes.image.digest -}}
{{- printf "%s@%s" .Values.hermes.image.repository .Values.hermes.image.digest -}}
{{- else -}}
{{- printf "%s:%s" .Values.hermes.image.repository .Values.hermes.image.tag -}}
{{- end -}}
{{- end -}}

{{- define "glossia.bifrostName" -}}
{{- printf "%s-bifrost" (include "glossia.fullname" .) | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "glossia.bifrostImage" -}}
{{- if .Values.bifrost.image.digest -}}
{{- printf "%s@%s" .Values.bifrost.image.repository .Values.bifrost.image.digest -}}
{{- else -}}
{{- printf "%s:%s" .Values.bifrost.image.repository .Values.bifrost.image.tag -}}
{{- end -}}
{{- end -}}

{{- define "glossia.hermesGrafanaMCPImage" -}}
{{- if .Values.hermes.observability.image.digest -}}
{{- printf "%s@%s" .Values.hermes.observability.image.repository .Values.hermes.observability.image.digest -}}
{{- else -}}
{{- printf "%s:%s" .Values.hermes.observability.image.repository .Values.hermes.observability.image.tag -}}
{{- end -}}
{{- end -}}

{{- define "glossia.bifrostConfig" -}}
{{- if .Values.bifrost.config }}
{{ .Values.bifrost.config | toPrettyJson | nindent 4 }}
{{- else -}}
{{- $config := dict "$schema" "https://www.getbifrost.ai/schema" }}
{{- if .Values.bifrost.sourceOfTruth }}{{- $_ := set $config "source_of_truth" .Values.bifrost.sourceOfTruth }}{{- end }}
{{- if .Values.bifrost.envLabel }}{{- $_ := set $config "env_label" .Values.bifrost.envLabel }}{{- end }}
{{- if .Values.bifrost.setupToken }}{{- $_ := set $config "setup_token" .Values.bifrost.setupToken }}{{- end }}
{{- if and .Values.bifrost.authConfig.enabled .Values.bifrost.authConfig.usernameKey .Values.bifrost.authConfig.passwordKey }}
{{- $_ := set $config "auth_config" (dict "admin_username" (printf "env.%s" .Values.bifrost.authConfig.usernameKey) "admin_password" (printf "env.%s" .Values.bifrost.authConfig.passwordKey) "is_enabled" true) }}
{{- end }}
{{ toPrettyJson $config }}
{{- end -}}
{{- end -}}

{{- define "glossia.headlessServiceName" -}}
{{ include "glossia.fullname" . }}-headless
{{- end -}}

{{- define "glossia.headlessServiceFQDN" -}}
{{ include "glossia.headlessServiceName" . }}.{{ .Release.Namespace }}.svc.cluster.local
{{- end -}}

{{- define "glossia.postgresHost" -}}
{{- if .Values.postgres.host -}}
{{- .Values.postgres.host -}}
{{- else -}}
{{- printf "%s-rw" .Values.postgres.clusterName -}}
{{- end -}}
{{- end -}}

{{- define "glossia.clickhouseHost" -}}
{{- if .Values.clickhouse.host -}}
{{- .Values.clickhouse.host -}}
{{- else -}}
{{- printf "%s-clickhouse-headless" .Values.clickhouse.clusterName -}}
{{- end -}}
{{- end -}}

{{- define "glossia.flameServiceAccountName" -}}
{{- if .Values.flame.serviceAccount.create -}}
{{- default (include "glossia.fullname" .) .Values.flame.serviceAccount.name -}}
{{- else -}}
{{- default "default" .Values.flame.serviceAccount.name -}}
{{- end -}}
{{- end -}}

{{- define "glossia.mailRelayEnv" -}}
{{- if .Values.mailRelay.enabled -}}
- name: GLOSSIA_SMTP_HOST
  value: {{ required "mailRelay.host is required when mailRelay.enabled=true" .Values.mailRelay.host | quote }}
- name: GLOSSIA_SMTP_PORT
  value: {{ .Values.mailRelay.port | quote }}
- name: GLOSSIA_SMTP_TLS
  value: {{ .Values.mailRelay.tls | quote }}
- name: GLOSSIA_SMTP_AUTH
  value: {{ .Values.mailRelay.auth | quote }}
{{- end -}}
{{- end -}}
