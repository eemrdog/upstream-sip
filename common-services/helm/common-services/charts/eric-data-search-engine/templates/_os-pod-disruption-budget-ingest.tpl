{{- define "eric-data-search-engine.os-pod-disruption-budget-ingest" -}}
{{- if .root.Values.podDisruptionBudget -}}
{{- if .root.Values.podDisruptionBudget.ingest -}}
{{- if .root.Values.podDisruptionBudget.ingest.maxUnavailable -}}
{{- if .root.Capabilities.APIVersions.Has "policy/v1/PodDisruptionBudget" }}
apiVersion: policy/v1
{{- else }}
apiVersion: policy/v1beta1
{{- end }}
kind: PodDisruptionBudget
metadata:
  {{- if eq .context "tls" }}
  name: {{ include "eric-data-search-engine.fullname" .root }}-ingest-tls-pdb
  {{- else }}
  name: {{ include "eric-data-search-engine.fullname" .root }}-ingest-pdb
  {{- end }}
  labels: {{- include "eric-data-search-engine.helm-labels" .root | nindent 4 }}
  annotations: {{- include "eric-data-search-engine.annotations" .root | nindent 4 }}
spec:
  maxUnavailable: {{ .root.Values.podDisruptionBudget.ingest.maxUnavailable }}
  selector:
    matchLabels:
      app: {{ include "eric-data-search-engine.fullname" .root | quote }}
      {{- if eq .context "tls" }}
      role: ingest-tls
      {{- else }}
      role: ingest
      {{- end }}
{{- end }}
{{- end }}
{{- end }}
{{ end }}