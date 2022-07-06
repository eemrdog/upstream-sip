{{- define "eric-data-search-engine.es-pod-disruption-budget-ingest" -}}
{{- if .root.Values.podDisruptionBudget -}}
{{- if .root.Values.podDisruptionBudget.ingest -}}
{{- if .root.Values.podDisruptionBudget.ingest.maxUnavailable -}}
apiVersion: policy/v1
kind: PodDisruptionBudget
metadata:
  {{- if eq .context "tls" }}
  name: {{ include "eric-data-search-engine.fullname" .root }}-ingest-tls-pdb
  {{- else }}
  name: {{ include "eric-data-search-engine.fullname" .root }}-ingest-pdb
  {{- end }}
  {{- include "eric-data-search-engine.helm-labels" .root | indent 2 }}
  annotations:
    {{- include "eric-data-search-engine.annotations" .root | indent 4 }}
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