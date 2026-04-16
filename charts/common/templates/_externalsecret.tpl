{{- define "common.externalsecret" -}}
{{- if .Values.externalSecret.enabled }}
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: {{ include "common.fullname" . }}
  labels:
    {{- include "common.labels" . | nindent 4 }}
  {{- with .Values.externalSecret.annotations }}
  annotations:
    {{- toYaml . | nindent 4 }}
  {{- end }}
spec:
  refreshInterval: {{ .Values.externalSecret.refreshInterval | default "1h" }}
  secretStoreRef:
    name: {{ .Values.externalSecret.secretStoreRef.name }}
    kind: {{ .Values.externalSecret.secretStoreRef.kind | default "ClusterSecretStore" }}
  target:
    name: {{ .Values.externalSecret.target.name | default (include "common.fullname" .) }}
    creationPolicy: {{ .Values.externalSecret.target.creationPolicy | default "Owner" }}
    {{- with .Values.externalSecret.target.template }}
    template:
      {{- toYaml . | nindent 6 }}
    {{- end }}
  {{- if .Values.externalSecret.dataFrom }}
  dataFrom:
    {{- range .Values.externalSecret.dataFrom }}
    - extract:
        key: {{ .key }}
        {{- with .version }}
        version: {{ . }}
        {{- end }}
        {{- with .property }}
        property: {{ . }}
        {{- end }}
    {{- end }}
  {{- else if .Values.externalSecret.data }}
  data:
    {{- range .Values.externalSecret.data }}
    - secretKey: {{ .secretKey }}
      remoteRef:
        key: {{ .remoteRef.key }}
        {{- with .remoteRef.property }}
        property: {{ . }}
        {{- end }}
        {{- with .remoteRef.version }}
        version: {{ . }}
        {{- end }}
    {{- end }}
  {{- end }}
{{- end }}
{{- end }}
