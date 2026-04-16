{{- define "common.configmap" -}}
{{- if .Values.configMap.enabled }}
apiVersion: v1
kind: ConfigMap
metadata:
  name: {{ include "common.fullname" . }}
  labels:
    {{- include "common.labels" . | nindent 4 }}
  {{- with .Values.configMap.annotations }}
  annotations:
    {{- toYaml . | nindent 4 }}
  {{- end }}
data:
  {{- if .Values.configMap.data }}
  {{- toYaml .Values.configMap.data | nindent 2 }}
  {{- end }}
  {{- if .Values.configMap.files }}
  {{- range $filename, $content := .Values.configMap.files }}
  {{ $filename }}: |
    {{- $content | nindent 4 }}
  {{- end }}
  {{- end }}
{{- end }}
{{- end }}

{{/*
Checksum annotation helper — ใช้ใน Deployment/StatefulSet
เพื่อ force rolling restart เมื่อ ConfigMap เปลี่ยน
*/}}
{{- define "common.configmap.checksum" -}}
{{- if .Values.configMap.enabled }}
checksum/config: {{ include (print $.Template.BasePath "/configmap.yaml") . | sha256sum }}
{{- end }}
{{- end }}
