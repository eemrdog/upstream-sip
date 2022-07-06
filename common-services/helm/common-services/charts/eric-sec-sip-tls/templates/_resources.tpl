{{/*
Various resources parameters
*/}}

{{/*
sip-tls-init container resources parameters
*/}}

{{- define "eric-sec-sip-tls.sip-tls-init.resources" -}}
resources:
  requests:
    memory: {{ index .Values "resources" "sip-tls-init" "requests" "memory" | quote }}
    cpu: {{ index .Values "resources" "sip-tls-init" "requests" "cpu" | quote }}
    {{- if index .Values "resources" "sip-tls-init" "requests" "ephemeral-storage" }}
    ephemeral-storage: {{ index .Values "resources" "sip-tls-init" "requests" "ephemeral-storage" | quote }}
    {{- end }}
  limits:
    memory: {{ index .Values "resources" "sip-tls-init" "limits" "memory" | quote }}
    cpu: {{ index .Values "resources" "sip-tls-init" "limits" "cpu" | quote }}
    {{- if index .Values "resources" "sip-tls-init" "limits" "ephemeral-storage" }}
    ephemeral-storage: {{ index .Values "resources" "sip-tls-init" "limits" "ephemeral-storage" | quote }}
    {{- end }}
{{- end -}}

{{/*
sip-tls container resources parameters
*/}}

{{- define "eric-sec-sip-tls.sip-tls.resources" -}}
resources:
  requests:
    memory: {{ index .Values "resources" "sip-tls" "requests" "memory" | quote }}
    cpu: {{ index .Values "resources" "sip-tls" "requests" "cpu" | quote }}
    {{- if index .Values "resources" "sip-tls" "requests" "ephemeral-storage" }}
    ephemeral-storage: {{ index .Values "resources" "sip-tls" "requests" "ephemeral-storage" | quote }}
    {{- end }}
  limits:
    memory: {{ index .Values "resources" "sip-tls" "limits" "memory" | quote }}
    cpu: {{ index .Values "resources" "sip-tls" "limits" "cpu" | quote }}
    {{- if index .Values "resources" "sip-tls" "limits" "ephemeral-storage" }}
    ephemeral-storage: {{ index .Values "resources" "sip-tls" "limits" "ephemeral-storage" | quote }}
    {{- end }}
{{- end -}}

{{/*
sip-tls-supervisor container resources parameters
*/}}

{{- define "eric-sec-sip-tls.sip-tls-supervisor.resources" -}}
resources:
  requests:
    memory: {{ index .Values "resources" "sip-tls-supervisor" "requests" "memory" | quote }}
    cpu: {{ index .Values "resources" "sip-tls-supervisor" "requests" "cpu" | quote }}
    {{- if index .Values "resources" "sip-tls-supervisor" "requests" "ephemeral-storage" }}
    ephemeral-storage: {{ index .Values "resources" "sip-tls-supervisor" "requests" "ephemeral-storage" | quote }}
    {{- end }}
  limits:
    memory: {{ index .Values "resources" "sip-tls-supervisor" "limits" "memory" | quote }}
    cpu: {{ index .Values "resources" "sip-tls-supervisor" "limits" "cpu" | quote }}
    {{- if index .Values "resources" "sip-tls-supervisor" "limits" "ephemeral-storage" }}
    ephemeral-storage: {{ index .Values "resources" "sip-tls-supervisor" "limits" "ephemeral-storage" | quote }}
    {{- end }}
{{- end -}}