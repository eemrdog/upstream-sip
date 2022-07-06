
{{- define "eric-log-shipper.filebeat.default-inputs" }}
  {{- if .Values.logshipper.cfgData }}
filebeat.inputs:
    {{- $paths := split "paths:" .Values.logshipper.cfgData -}}
    {{- range $key, $val := $paths }}
      {{- if $val }}
- type: {{ $.Values.logshipper.cfgDataInputType }}
  paths:
        {{- $ns_placeholder := ".RELEASE.NAMESPACE" }}
        {{- if contains $ns_placeholder $val }}
          {{- replace $ns_placeholder (tpl "{{- .Release.Namespace -}}" $) $val | indent 2 -}}
        {{- else }}
          {{- $val | indent 2 -}}
        {{- end }}
  fields_under_root: true
  tail_files: true
  close_timeout: {{ $.Values.logshipper.harvester.closeTimeout | quote }}
  {{- include "eric-log-shipper.harvester.closeFiles" $ | indent 2 }}
      {{- end }}
    {{- end }}
  {{- end }}
{{- end }}

{{- define "eric-log-shipper.filebeat.autodiscover" }}
filebeat.autodiscover:
  providers:
  - type: kubernetes
    {{- if .Values.logshipper.autodiscover.namespace }}
    namespace: {{ include "eric-log-shipper.autodiscover.namespace" . }}
    {{- end }}
    hints.enabled: {{ .Values.logshipper.autodiscover.hints.enabled }}
    {{- if or .Values.logshipper.autodiscover.inclusions .Values.logshipper.autodiscover.exclusions }}
    include_annotations:
      {{- $kubeAnnotationPrefix := "kubernetes.annotations." }}
      {{- $kubeAnnotationPrefixLen := len $kubeAnnotationPrefix }}
      {{- range .Values.logshipper.autodiscover.inclusions }}
        {{- if gt (len .field) $kubeAnnotationPrefixLen }}
          {{- if eq (substr 0 $kubeAnnotationPrefixLen .field) $kubeAnnotationPrefix }}
      - {{ substr $kubeAnnotationPrefixLen (len .field) .field | quote }}
          {{- end }}
        {{- end }}
      {{- end }}
      {{- range .Values.logshipper.autodiscover.exclusions }}
        {{- if gt (len .field) $kubeAnnotationPrefixLen }}
          {{- if eq (substr 0 $kubeAnnotationPrefixLen .field) $kubeAnnotationPrefix }}
      - {{ substr $kubeAnnotationPrefixLen (len .field) .field | quote }}
          {{- end }}
        {{- end }}
      {{- end }}
    {{- end }}
    {{- if .Values.logshipper.autodiscover.hints.enabled }}
    hints.default_config:
      type: container
      paths:
      {{- if .Values.logshipper.autodiscover.hints.paths }}
        {{- toYaml .Values.logshipper.autodiscover.hints.paths | nindent 8 }}
      {{- else }}
        {{- print "At least one path must be specified for 'logshipper.autodiscover.hints.paths'" | fail }}
      {{- end }}
    {{- end }}
    templates:
    {{- if not .Values.logshipper.autodiscover.hints.enabled }}
      - config:
        - type: container
          paths:
          {{- if .Values.logshipper.autodiscover.paths }}
            {{- toYaml .Values.logshipper.autodiscover.paths | nindent 10 }}
          {{- else }}
            {{- print "At least one path must be specified for 'logshipper.autodiscover.paths'" | fail }}
          {{- end }}
    {{- end }}
    {{- if .Values.logshipper.autodiscover.templates }}
      {{- toYaml .Values.logshipper.autodiscover.templates | nindent 6 }}
    {{- end }}
    appenders:
      - type: config
        config:
          fields:
            logplane: {{ .Values.logshipper.autodiscover.logplane | quote }}
          fields_under_root: true
          close_timeout: {{ .Values.logshipper.harvester.closeTimeout | quote }}
          {{- include "eric-log-shipper.harvester.closeFiles" $ | indent 10 }}
        {{- $filtersEnabled := or .Values.logshipper.autodiscover.inclusions .Values.logshipper.autodiscover.exclusions }}
        {{- if or .Values.logshipper.autodiscover.json.enabled $filtersEnabled }}
          processors:
          {{- if .Values.logshipper.autodiscover.json.enabled }}
          - decode_json_fields:
              fields: ["message"]
              target: {{ .Values.logshipper.autodiscover.json.target | quote }}
              max_depth: 1
          {{- end }}
          {{- if $filtersEnabled }}
            {{- include "eric-log-shipper.autodiscover.filters" . | indent 10 }}
          {{- end }}
        {{- end }}
{{- end }}

{{- define "eric-log-shipper.filebeat.output" }}
{{- $g := fromJson (include "eric-log-shipper.global" .) -}}
{{- $i := fromJson (include "eric-log-shipper.internal" .) -}}
{{- if .Values.logshipper.consoleOutput }}
output.console:
  pretty: true
{{- end }}
{{- if $i.output.file.enabled }}
output.file:
  path: {{ $i.output.file.path }}
  filename: {{ $i.output.file.name }}
{{- end }}
{{- if eq .Values.logshipper.output "searchengine" }}
output.elasticsearch:
  hosts: "{{ .Values.searchengine.host }}:{{ .Values.searchengine.port }}"
{{- else if $i.output.logTransformer.enabled }}
output.logstash:
  {{- if $g.security.tls.enabled }}
  hosts: "{{ .Values.logtransformer.host }}:5044"
  ssl.certificate_authorities: "/run/secrets/ca-certificates/cacertbundle.pem"
  ssl.certificate: "/run/secrets/certificates/clicert.pem"
  ssl.key: "/run/secrets/certificates/cliprivkey.pem"
  ssl.verification_mode: "full"
  ssl.renegotiation: "freely"
  ssl.supported_protocols: ["TLSv1.2"]
  ssl.cipher_suites: []
  {{- else }}
  hosts: "{{ .Values.logtransformer.host }}:{{ .Values.logtransformer.port }}"
  {{- end }}
  bulk_max_size: 2048
  worker: 1
  pipelining: 0
  ttl: 30
{{- end }}
{{- end }}

{{- define "eric-log-shipper.filebeat.settings" }}
filebeat.registry.flush: 5s
logging.level: {{ .Values.logLevel | quote }}
logging.metrics.enabled: false
{{- end }}

{{/*
Returns the namespace that will be used in the autodiscover feature
Kubernetes uses the following regex pattern to validate a namespace name: '[a-z0-9]([-a-z0-9]*[a-z0-9])?'.
So the value to determine if the ".RELEASE.NAMESPACE" should be used or not needs to not be accepted by the regex pattern.
*/}}
{{- define "eric-log-shipper.autodiscover.namespace" -}}
{{- if eq .Values.logshipper.autodiscover.namespace ".RELEASE.NAMESPACE" }}
{{- .Release.Namespace | quote -}}
{{- else }}
{{- .Values.logshipper.autodiscover.namespace | quote -}}
{{- end }}
{{- end -}}

{{/*
Inclusions and exclusions for autodiscover
*/}}
{{- define "eric-log-shipper.autodiscover.filters" }}
- drop_event:
    when:
      or:
    {{- if .Values.logshipper.autodiscover.inclusions }}
        - not.or:
            {{- include "eric-log-shipper.autodiscover.getFilterConditions" (dict "fieldNameValues" .Values.logshipper.autodiscover.inclusions) | indent 12 }}
    {{- end }}
    {{- if .Values.logshipper.autodiscover.exclusions }}
        {{- include "eric-log-shipper.autodiscover.getFilterConditions" (dict "fieldNameValues" .Values.logshipper.autodiscover.exclusions) | indent 8 }}
    {{- end }}
- drop_fields:
    fields:
      - "kubernetes.annotations"
    ignore_missing: true
{{- end }}

{{- define "eric-log-shipper.autodiscover.getFilterConditions" }}
{{- $kubeAnnotationPrefix := "kubernetes.annotations." }}
{{- $kubeAnnotationPrefixLen := len $kubeAnnotationPrefix }}
{{- $kubeLabelPrefix := "kubernetes.labels." }}
{{- $kubeLabelPrefixLen := len $kubeLabelPrefix }}
{{- range .fieldNameValues }}
- equals:
  {{- if hasPrefix $kubeAnnotationPrefix .field }}
    {{- $data := dict "prefix" $kubeAnnotationPrefix "prefixLen" $kubeAnnotationPrefixLen "field" .field "value" .value }}
    {{- include "eric-log-shipper.autodiscover.getFixedFieldNameValue" $data | nindent 4 }}
  {{- else if hasPrefix $kubeLabelPrefix .field }}
    {{- $data := dict "prefix" $kubeLabelPrefix "prefixLen" $kubeLabelPrefixLen "field" .field "value" .value }}
    {{- include "eric-log-shipper.autodiscover.getFixedFieldNameValue" $data | nindent 4 }}
  {{- else }}
    {{ .field }}: {{ .value | quote }}
  {{- end }}
{{- end }}
{{- end }}

{{- define "eric-log-shipper.autodiscover.getFixedFieldNameValue" }}
{{- $name := substr .prefixLen (len .field) .field }}
{{- $fixedName := replace "." "_" $name }}
{{- printf "%s%s: %s" .prefix $fixedName (.value | quote) }}
{{- end }}

{{- define "eric-log-shipper.harvester.closeFiles" -}}
  {{- $ignoreOlder := .Values.logshipper.harvester.ignoreOlder | toString }}
  {{- if not (eq $ignoreOlder "0") }}
    {{- $ignoreOlderValue := substr 0 (sub (len $ignoreOlder) 1 | int) $ignoreOlder }}
    {{- $ignoreOlderUnit := substr (sub (len $ignoreOlder) 1 | int) (len $ignoreOlder) $ignoreOlder}}
    {{- $cleanInactive := print (add $ignoreOlderValue 1) $ignoreOlderUnit }}
ignore_older: {{ $ignoreOlder | quote }}
clean_inactive: {{ $cleanInactive | quote }}
close_removed: false
clean_removed: false
  {{- end }}
{{- end -}}
