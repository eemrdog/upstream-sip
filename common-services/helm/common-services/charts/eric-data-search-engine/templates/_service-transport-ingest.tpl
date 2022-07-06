{{- define "eric-data-search-engine.service-transport-ingest" -}}
kind: Service
apiVersion: v1
metadata:
  {{- if eq .context "tls" }}
  name: {{ include "eric-data-search-engine.fullname" .root }}-transport-ingest-tls
  {{- else }}
  name: {{ include "eric-data-search-engine.fullname" .root }}-transport-ingest
  {{- end }}
  labels: {{- include "eric-data-search-engine.helm-labels" .root | nindent 4 }}
  annotations: {{- include "eric-data-search-engine.annotations" .root | nindent 4 }}
spec:
  publishNotReadyAddresses: true
  selector:
    app: {{ include "eric-data-search-engine.fullname" .root | quote }}
    component: eric-data-search-engine
    {{- if eq .context "tls" }}
    role: ingest-tls
    {{- else }}
    role: ingest
    {{- end }}
  clusterIP: None
  type: ClusterIP
  ports:
  - name: transport
    port: 9300
    protocol: TCP
{{ end }}
