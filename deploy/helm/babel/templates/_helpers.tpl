{{- define "babel.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "babel.fullname" -}}
{{- if .Values.fullnameOverride -}}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- include "babel.name" . -}}
{{- end -}}
{{- end -}}

{{- define "babel.labels" -}}
helm.sh/chart: {{ .Chart.Name }}-{{ .Chart.Version | replace "+" "_" }}
app.kubernetes.io/name: {{ include "babel.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end -}}

{{- define "babel.selectorLabels" -}}
app.kubernetes.io/name: {{ include "babel.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end -}}

{{- define "babel.image" -}}
{{- if .Values.image.digest -}}
{{- printf "%s@%s" .Values.image.repository .Values.image.digest -}}
{{- else -}}
{{- printf "%s:%s" .Values.image.repository .Values.image.tag -}}
{{- end -}}
{{- end -}}

{{- define "babel.headlessServiceName" -}}
{{ include "babel.fullname" . }}-headless
{{- end -}}

{{- define "babel.headlessServiceFQDN" -}}
{{ include "babel.headlessServiceName" . }}.{{ .Release.Namespace }}.svc.cluster.local
{{- end -}}

{{- define "babel.postgresHost" -}}
{{- if .Values.postgres.host -}}
{{- .Values.postgres.host -}}
{{- else -}}
{{- printf "%s-rw" .Values.postgres.clusterName -}}
{{- end -}}
{{- end -}}
