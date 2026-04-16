{{- define "common.secret" -}}
{{- if .Values.secret.enabled }}
apiVersion: v1
kind: Secret
metadata:
  name: {{ include "common.fullname" . }}
  labels:
    {{- include "common.labels" . | nindent 4 }}
  {{- with .Values.secret.annotations }}
  annotations:
    {{- toYaml . | nindent 4 }}
  {{- end }}
type: {{ .Values.secret.type | default "Opaque" }}
{{- if .Values.secret.data }}
data:
  {{- range $key, $value := .Values.secret.data }}
  {{ $key }}: {{ $value | b64enc | quote }}
  {{- end }}
{{- end }}
{{- if .Values.secret.stringData }}
stringData:
  {{- toYaml .Values.secret.stringData | nindent 2 }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Checksum annotation helper สำหรับ Secret
*/}}
{{- define "common.secret.checksum" -}}
{{- if .Values.secret.enabled }}
checksum/secret: {{ include (print $.Template.BasePath "/secret.yaml") . | sha256sum }}
{{- end }}
{{- end }}
