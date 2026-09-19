{{- define "discourse.name" -}}
{{- default .Chart.Name .Values.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "discourse.labels" -}}
helm.sh/chart: {{ printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
app.kubernetes.io/name: discourse
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end -}}

{{- define "discourse.selectorLabels" -}}
app.kubernetes.io/name: discourse
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end -}}

{{- define "discourse.image" -}}
{{- $image := printf "%s:%s" .Values.image.repository .Values.image.tag -}}
{{- if .Values.image.digest -}}
{{- printf "%s@%s" $image .Values.image.digest -}}
{{- else -}}
{{- $image -}}
{{- end -}}
{{- end -}}

{{- define "discourse.redisImage" -}}
{{- $image := printf "%s:%s" .Values.redis.image.repository .Values.redis.image.tag -}}
{{- if .Values.redis.image.digest -}}
{{- printf "%s@%s" $image .Values.redis.image.digest -}}
{{- else -}}
{{- $image -}}
{{- end -}}
{{- end -}}
