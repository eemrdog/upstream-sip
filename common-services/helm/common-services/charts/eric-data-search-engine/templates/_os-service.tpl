{{- define "eric-data-search-engine.os-service" -}}
{{- $g := fromJson (include "eric-data-search-engine.global" .root ) }}
kind: Service
apiVersion: v1
metadata:
  {{- if eq .context "tls" }}
  name: {{ include "eric-data-search-engine.fullname" .root }}-tls
  {{- else }}
  name: {{ include "eric-data-search-engine.fullname" .root }}
  {{- end }}
  labels: {{- include "eric-data-search-engine.helm-labels" .root | nindent 4 }}
  annotations:
    {{- $metricsAnn := dict -}}
    {{- if and (.root.Values.metrics.enabled) $g.security.tls.enabled }}
      {{- $_ := set $metricsAnn "prometheus.io/scrape" (.root.Values.metrics.enabled | toString) -}}
      {{- $_ := set $metricsAnn "prometheus.io/port" "9115" -}}
      {{- $_ := set $metricsAnn "prometheus.io/scheme" "https" -}}
    {{- end }}
    {{- $commonAnn := include "eric-data-search-engine.annotations" .root | fromYaml }}
    {{- include "eric-data-search-engine.mergeAnnotations" (dict "location" .root.Template.Name "sources" (list $commonAnn $metricsAnn)) | trim | nindent 4 }}
spec:
  {{- if $g.internalIPFamily }}
  ipFamilies: [{{ $g.internalIPFamily | quote }}]
  {{- end }}
  selector:
    app: {{ include "eric-data-search-engine.fullname" .root | quote }}
    component: eric-data-search-engine
    {{- if eq .context "tls" }}
    role: ingest-tls
    {{- else }}
    role: ingest
    {{- end }}
  type: ClusterIP
  ports:
  - name: rest
    port: 9200
    protocol: TCP
  {{- if .root.Values.metrics.enabled }}
  {{- if $g.security.tls.enabled }}
  - name: metrics-tls
    port: 9115
    protocol: TCP
  {{- else }}
  - name: metrics
    port: 9114
    protocol: TCP
  {{- end }}
  {{- end }}
{{ end }}
