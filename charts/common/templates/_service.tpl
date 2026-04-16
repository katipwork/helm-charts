{{- define "common.service" -}}
apiVersion: v1
kind: Service
metadata:
  name: {{ include "common.fullname" . }}
  labels:
    {{- include "common.labels" . | nindent 4 }}
  {{- with .Values.service.annotations }}
  annotations:
    {{- toYaml . | nindent 4 }}
  {{- end }}
spec:
  type: {{ .Values.service.type | default "ClusterIP" }}
  selector:
    {{- include "common.selectorLabels" . | nindent 4 }}
  ports:
    - name: http
      port: {{ .Values.service.port | default 8080 }}
      targetPort: http
      protocol: TCP
      {{- if and (eq (.Values.service.type | default "ClusterIP") "NodePort") .Values.service.nodePort }}
      nodePort: {{ .Values.service.nodePort }}
      {{- end }}
  {{- with .Values.service.extraPorts }}
  {{- range . }}
    - name: {{ .name }}
      port: {{ .port }}
      targetPort: {{ .targetPort | default .name }}
      protocol: {{ .protocol | default "TCP" }}
  {{- end }}
  {{- end }}
{{- end }}

{{/*
Headless service สำหรับ StatefulSet
*/}}
{{- define "common.service.headless" -}}
apiVersion: v1
kind: Service
metadata:
  name: {{ include "common.fullname" . }}-headless
  labels:
    {{- include "common.labels" . | nindent 4 }}
spec:
  type: ClusterIP
  clusterIP: None
  selector:
    {{- include "common.selectorLabels" . | nindent 4 }}
  ports:
    - name: http
      port: {{ .Values.service.port | default 8080 }}
      targetPort: http
      protocol: TCP
{{- end }}
