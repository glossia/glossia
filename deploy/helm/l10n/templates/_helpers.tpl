{{- define "l10n.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "l10n.fullname" -}}
{{- if .Values.fullnameOverride -}}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- include "l10n.name" . -}}
{{- end -}}
{{- end -}}

{{- define "l10n.labels" -}}
helm.sh/chart: {{ .Chart.Name }}-{{ .Chart.Version | replace "+" "_" }}
app.kubernetes.io/name: {{ include "l10n.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end -}}

{{- define "l10n.selectorLabels" -}}
app.kubernetes.io/name: {{ include "l10n.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end -}}
