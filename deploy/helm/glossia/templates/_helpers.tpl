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

{{- define "glossia.headlessServiceName" -}}
{{ include "glossia.fullname" . }}-headless
{{- end -}}

{{- define "glossia.headlessServiceFQDN" -}}
{{ include "glossia.headlessServiceName" . }}.{{ .Release.Namespace }}.svc.cluster.local
{{- end -}}
