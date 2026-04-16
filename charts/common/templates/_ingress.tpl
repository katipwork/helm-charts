{{- define "common.ingress" -}}
{{- if .Values.ingress.enabled }}
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: {{ include "common.fullname" . }}
  labels:
    {{- include "common.labels" . | nindent 4 }}
  {{- with .Values.ingress.annotations }}
  annotations:
    {{- toYaml . | nindent 4 }}
  {{- end }}
spec:
  {{- with .Values.ingress.className }}
  ingressClassName: {{ . }}
  {{- end }}
  {{- if .Values.ingress.tls }}
  tls:
    {{- range .Values.ingress.tls }}
    - hosts:
        {{- range .hosts }}
        - {{ . | quote }}
        {{- end }}
      secretName: {{ .secretName }}
    {{- end }}
  {{- end }}
  rules:
    {{- if .Values.ingress.rules }}
    {{- range .Values.ingress.rules }}
    - host: {{ .host | quote }}
      http:
        paths:
          {{- range .paths }}
          - path: {{ .path | default "/" }}
            pathType: {{ .pathType | default "Prefix" }}
            backend:
              service:
                name: {{ include "common.fullname" $ }}
                port:
                  name: http
          {{- end }}
    {{- end }}
    {{- else if .Values.ingress.host }}
    - host: {{ .Values.ingress.host | quote }}
      http:
        paths:
          - path: {{ .Values.ingress.path | default "/" }}
            pathType: {{ .Values.ingress.pathType | default "Prefix" }}
            backend:
              service:
                name: {{ include "common.fullname" . }}
                port:
                  name: http
    {{- end }}
{{- end }}
{{- end }}

{{/*
HTTPRoute สำหรับ Gateway API
*/}}
{{- define "common.httproute" -}}
{{- if .Values.httpRoute.enabled }}
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: {{ include "common.fullname" . }}
  labels:
    {{- include "common.labels" . | nindent 4 }}
  {{- with .Values.httpRoute.annotations }}
  annotations:
    {{- toYaml . | nindent 4 }}
  {{- end }}
spec:
  parentRefs:
    {{- range .Values.httpRoute.parentRefs }}
    - name: {{ .name }}
      {{- with .namespace }}
      namespace: {{ . }}
      {{- end }}
      {{- with .sectionName }}
      sectionName: {{ . }}
      {{- end }}
    {{- end }}
  {{- with .Values.httpRoute.hostnames }}
  hostnames:
    {{- range . }}
    - {{ . | quote }}
    {{- end }}
  {{- end }}
  rules:
    {{- if .Values.httpRoute.rules }}
    {{- range .Values.httpRoute.rules }}
    - matches:
        {{- range .matches }}
        - path:
            type: {{ .pathType | default "PathPrefix" }}
            value: {{ .path | default "/" }}
        {{- end }}
      {{- with .filters }}
      filters:
        {{- toYaml . | nindent 8 }}
      {{- end }}
      backendRefs:
        - name: {{ include "common.fullname" $ }}
          port: {{ $.Values.service.port | default 8080 }}
          {{- with .weight }}
          weight: {{ . }}
          {{- end }}
    {{- end }}
    {{- else }}
    - matches:
        - path:
            type: PathPrefix
            value: /
      backendRefs:
        - name: {{ include "common.fullname" . }}
          port: {{ .Values.service.port | default 8080 }}
    {{- end }}
{{- end }}
{{- end }}
