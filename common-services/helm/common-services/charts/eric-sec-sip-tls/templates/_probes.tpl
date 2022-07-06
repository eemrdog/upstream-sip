{{/*
Various probes parameters
*/}}

{{/*
sip-tls container probes parameters
*/}}

{{- define "eric-sec-sip-tls.sip-tls.probes" -}}
{{- if and ( ge .Capabilities.KubeVersion.Major "1" ) ( ge .Capabilities.KubeVersion.Minor "18" ) }}
startupProbe:
  exec:
    command: ["/sip-tls/sip-tls-ready.sh"]
  initialDelaySeconds: {{ index .Values "probes" "sip-tls" "startupProbe" "initialDelaySeconds" }}
  timeoutSeconds: {{ index .Values "probes" "sip-tls" "startupProbe" "timeoutSeconds" }}
  periodSeconds: {{ index .Values "probes" "sip-tls" "startupProbe" "periodSeconds" }}
  failureThreshold: {{ index .Values "probes" "sip-tls" "startupProbe" "failureThreshold" }}
  successThreshold: {{ index .Values "probes" "sip-tls" "startupProbe" "successThreshold" }}
{{- end }}
livenessProbe:
  exec:
    command: ["/sip-tls/sip-tls-alive.sh"]
  # In line with the retry-wrapper parameters in k8s_utils and vault_utils
  # I.e. retry-wrapper has time to perform retries before liveness probe
  # kills the container.
  initialDelaySeconds: {{index .Values "probes" "sip-tls" "livenessProbe" "initialDelaySeconds" }}
  timeoutSeconds: {{ index .Values "probes" "sip-tls" "livenessProbe" "timeoutSeconds" }}
  periodSeconds: {{ index .Values "probes" "sip-tls" "livenessProbe" "periodSeconds" }}
  failureThreshold: {{ index .Values "probes" "sip-tls" "livenessProbe" "failureThreshold" }}
  successThreshold: {{ index .Values "probes" "sip-tls" "livenessProbe" "successThreshold" }}
readinessProbe:
  exec:
    command: ["/sip-tls/sip-tls-ready.sh"]
  initialDelaySeconds: {{ index .Values "probes" "sip-tls" "readinessProbe" "initialDelaySeconds" }}
  timeoutSeconds: {{ index .Values "probes" "sip-tls" "readinessProbe" "timeoutSeconds" }}
  periodSeconds: {{ index .Values "probes" "sip-tls" "readinessProbe" "periodSeconds" }}
  failureThreshold: {{ index .Values "probes" "sip-tls" "readinessProbe" "failureThreshold" }}
  successThreshold: {{ index .Values "probes" "sip-tls" "readinessProbe" "successThreshold" }}
{{- end -}}

{{/*
sip-tls-supervisor container probes parameters
*/}}

{{- define "eric-sec-sip-tls.sip-tls-supervisor.probes" -}}
{{- if and ( ge .Capabilities.KubeVersion.Major "1" ) ( ge .Capabilities.KubeVersion.Minor "18" ) }}
startupProbe:
  exec:
    command: ["/sip-tls-supervisor/sip-tls-supervisor-ready.sh"]
  initialDelaySeconds: {{ index .Values "probes" "sip-tls-supervisor" "startupProbe" "initialDelaySeconds" }}
  timeoutSeconds: {{ index .Values "probes" "sip-tls-supervisor" "startupProbe" "timeoutSeconds" }}
  periodSeconds: {{ index .Values "probes" "sip-tls-supervisor" "startupProbe" "periodSeconds" }}
  failureThreshold: {{ index .Values "probes" "sip-tls-supervisor" "startupProbe" "failureThreshold" }}
  successThreshold: {{ index .Values "probes" "sip-tls-supervisor" "startupProbe" "successThreshold" }}
{{- end }}
livenessProbe:
  exec:
    command: ["/sip-tls-supervisor/sip-tls-supervisor-alive.sh"]
  # Must be aligned with the internal watch dog certificate initial delay.
  initialDelaySeconds: {{ index .Values "probes" "sip-tls-supervisor" "livenessProbe" "initialDelaySeconds" }}
  timeoutSeconds: {{ index .Values "probes" "sip-tls-supervisor" "livenessProbe" "timeoutSeconds" }}
  periodSeconds: {{ index .Values "probes" "sip-tls-supervisor" "livenessProbe" "periodSeconds" }}
  failureThreshold: {{ index .Values "probes" "sip-tls-supervisor" "livenessProbe" "failureThreshold" }}
  successThreshold: {{ index .Values "probes" "sip-tls-supervisor" "livenessProbe" "successThreshold" }}
readinessProbe:
  exec:
    command: ["/sip-tls-supervisor/sip-tls-supervisor-ready.sh"]
  initialDelaySeconds: {{ index .Values "probes" "sip-tls-supervisor" "readinessProbe" "initialDelaySeconds" }}
  timeoutSeconds: {{ index .Values "probes" "sip-tls-supervisor" "readinessProbe" "timeoutSeconds" }}
  periodSeconds: {{ index .Values "probes" "sip-tls-supervisor" "readinessProbe" "periodSeconds" }}
  failureThreshold: {{ index .Values "probes" "sip-tls-supervisor" "readinessProbe" "failureThreshold" }}
  successThreshold: {{ index .Values "probes" "sip-tls-supervisor" "readinessProbe" "successThreshold" }}
{{- end -}}