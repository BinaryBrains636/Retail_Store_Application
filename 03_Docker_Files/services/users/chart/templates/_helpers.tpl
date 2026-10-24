{{/* vim: set filetype=mustache: */}}
{{/*
Expand the name of the chart.
*/}}
{{- define "users.name" -}}
{{- default "users" .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "users.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default "users" .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "users.chart" -}}
{{- printf "%s-%s" "users" .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "users.labels" -}}
helm.sh/chart: {{ include "users.chart" . }}
{{ include "users.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "users.selectorLabels" -}}
app.kubernetes.io/name: {{ include "users.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/component: service
app.kubernetes.io/owner: retail-store-sample
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "users.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "users.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Create the name of the config map to use
*/}}
{{- define "users.configMapName" -}}
{{- if .Values.configMap.create }}
{{- default (include "users.fullname" .) .Values.configMap.name }}
{{- else }}
{{- default "default" .Values.configMap.name }}
{{- end }}
{{- end }}

{{/* podAnnotations */}}
{{- define "users.podAnnotations" -}}
{{- if or .Values.metrics.enabled .Values.podAnnotations }}
{{- $podAnnotations := .Values.podAnnotations}}
{{- $metricsAnnotations := .Values.metrics.podAnnotations}}
{{- $allAnnotations := merge $podAnnotations $metricsAnnotations}}
{{- toYaml $allAnnotations }}
{{- end }}
{{- end -}}

{{- define "users.postgresql.fullname" -}}
{{- include "users.fullname" . }}-postgresql
{{- end -}}

{{/*
Common labels for postgresql
*/}}
{{- define "users.postgresql.labels" -}}
helm.sh/chart: {{ include "users.chart" . }}
{{ include "users.postgresql.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels for postgresql
*/}}
{{- define "users.postgresql.selectorLabels" -}}
app.kubernetes.io/name: {{ include "users.fullname" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/component: postgresql
app.kubernetes.io/owner: retail-store-sample
{{- end }}
