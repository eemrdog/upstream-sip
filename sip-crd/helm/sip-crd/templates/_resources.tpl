{{/*
Various resources parameters
*/}}

{{/*
crdjob container resources parameters
*/}}

{{- define "eric-sec-sip-tls-crd.crdjob.resources" -}}
resources:
  requests:
    memory: {{ .Values.resources.crdjob.requests.memory | quote }}
    cpu: {{ .Values.resources.crdjob.requests.cpu | quote }}
    {{- if index .Values "resources" "crdjob" "requests" "ephemeral-storage" }}
    ephemeral-storage: {{ index .Values "resources" "crdjob" "requests" "ephemeral-storage" | quote }}
    {{- end }}
  limits:
    memory: {{ .Values.resources.crdjob.limits.memory | quote }}
    cpu: {{ .Values.resources.crdjob.limits.cpu | quote }}
    {{- if index .Values "resources" "crdjob" "limits" "ephemeral-storage" }}
    ephemeral-storage: {{ index .Values "resources" "crdjob" "limits" "ephemeral-storage" | quote }}
    {{- end }}
{{- end -}}}