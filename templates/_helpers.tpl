{{/*
Nombre base del chart.
*/}}
{{- define "generic-app.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Nombre completo (fullname) de los recursos.
- Si fullnameOverride está seteado, se usa tal cual.
- Si el release ya contiene el nombre del chart, no se duplica.
*/}}
{{- define "generic-app.fullname" -}}
{{- if .Values.fullnameOverride -}}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- if contains $name .Release.Name -}}
{{- .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}
{{- end -}}

{{/*
Chart name + version (para la label helm.sh/chart).
*/}}
{{- define "generic-app.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Labels comunes a todos los recursos.
*/}}
{{- define "generic-app.labels" -}}
helm.sh/chart: {{ include "generic-app.chart" . }}
{{ include "generic-app.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end -}}

{{/*
Selector labels (estables: no deben cambiar entre releases).
*/}}
{{- define "generic-app.selectorLabels" -}}
app.kubernetes.io/name: {{ include "generic-app.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end -}}

{{/*
Nombre del ServiceAccount a usar.
*/}}
{{- define "generic-app.serviceAccountName" -}}
{{- if .Values.serviceAccount.create -}}
{{- default (include "generic-app.fullname" .) .Values.serviceAccount.name -}}
{{- else -}}
{{- default "default" .Values.serviceAccount.name -}}
{{- end -}}
{{- end -}}

{{/*
Nombre del ConfigMap de env.
*/}}
{{- define "generic-app.configMapName" -}}
{{- printf "%s-config" (include "generic-app.fullname" .) -}}
{{- end -}}

{{/*
Nombre del Secret de env.
*/}}
{{- define "generic-app.secretName" -}}
{{- printf "%s-secret" (include "generic-app.fullname" .) -}}
{{- end -}}

{{/*
Nombre de los recursos de MongoDB.
*/}}
{{- define "generic-app.mongodb.fullname" -}}
{{- printf "%s-%s" (include "generic-app.fullname" .) .Values.mongodb.serviceName | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Selector labels de MongoDB.
*/}}
{{- define "generic-app.mongodb.selectorLabels" -}}
app.kubernetes.io/name: {{ include "generic-app.name" . }}-mongodb
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/component: database
{{- end -}}
