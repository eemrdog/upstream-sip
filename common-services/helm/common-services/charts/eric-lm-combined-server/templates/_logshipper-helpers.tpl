{{/*
Template of Log Shipper sidecar
Version: 7.2.0-20
*/}}

{{/*
Create a map from ".Values.global" with defaults if missing in values file.
This hides defaults from values file.
*/}}
{{- define "eric-lm-combined-server.logshipper-global" -}}
  {{- $productInfo := fromYaml (.Files.Get "eric-product-info.yaml") -}}
  {{- $globalDefaults := dict "timezone" "UTC" -}}
  {{- $globalDefaults := merge $globalDefaults (dict "security" (dict "tls" (dict "enabled" true))) -}}
  {{- $globalDefaults := merge $globalDefaults (dict "registry" (dict "imagePullPolicy" "IfNotPresent" )) -}}
  {{- $globalDefaults := merge $globalDefaults (dict "registry" (dict "url" $productInfo.images.logShipper.registry )) -}}
  {{- if .Values.global }}
    {{- mergeOverwrite $globalDefaults .Values.global | toJson -}}
  {{- else -}}
    {{- $globalDefaults | toJson -}}
  {{- end -}}
{{- end -}}

{{/*
Create a map with internal default values used for testing purposes.
*/}}
{{- define "eric-lm-combined-server.logshipper-internal" -}}
  {{- $internal := dict "internal" (dict "output" (dict "file" (dict "enabled" false))) -}}
  {{- $internal := merge $internal (dict "output" (dict "file" (dict "path" "/logs"))) -}}
  {{- $internal := merge $internal (dict "output" (dict "file" (dict "name" "filebeat.output"))) -}}
  {{- $internal := merge $internal (dict "output" (dict "logTransformer" (dict "enabled" true))) -}}
  {{ if .Values.internal }}
    {{- mergeOverwrite $internal .Values.internal | toJson -}}
  {{ else }}
    {{- $internal | toJson -}}
  {{ end }}
{{- end -}}

{{/*
Create a default fully qualified app name.
NOTE: Using eric-lm-combined-server's definition
*/}}
{{- define "eric-lm-combined-server.logshipper-service-fullname" -}}
{{ include "eric-lm-combined-server.name" . }}
{{- end -}}

{{/*
Expand the name of the chart.
NOTE: Using eric-lm-combined-server's definition
*/}}
{{- define "eric-lm-combined-server.logshipper-name" -}}
{{ include "eric-lm-combined-server.name" . }}
{{- end -}}

{{/*
Create kubernetes.io name and version
*/}}
{{- define "eric-lm-combined-server.logshipper-labels" }}
app.kubernetes.io/name: {{ include "eric-lm-combined-server.name" . | quote }}
app.kubernetes.io/version: {{ include "eric-lm-combined-server.chart-version" . | quote }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- if .Values.labels }}
{{ toYaml .Values.labels }}
{{- end }}
{{- end }}


{{/*
Log Shipper sidecar container spec
*/}}
{{- define "eric-lm-combined-server.logshipper-container" -}}
{{- $g := fromJson (include "eric-lm-combined-server.logshipper-global" .) }}
{{- $default := fromJson (include "eric-lm-combined-server.logshipper-default-value" .) }}
{{- $repoPath := $default.imageCredentials.logshipper.repoPath -}}
{{- if $repoPath -}}
        {{- $repoPath = printf "%s/" $repoPath -}}
{{- end -}}
- name: "logshipper"
  imagePullPolicy: {{ or $default.imageCredentials.logshipper.registry.imagePullPolicy $g.registry.imagePullPolicy }}
  image: "{{ or $default.imageCredentials.logshipper.registry.url $g.registry.url }}/{{ $repoPath }}{{ $default.images.logshipper.name }}:{{ $default.images.logshipper.tag }}"
  args:
    - /opt/filebeat/init.sh
  securityContext:
    allowPrivilegeEscalation: false
    privileged: false
    readOnlyRootFilesystem: true
    runAsNonRoot: true
    capabilities:
      drop:
        - "all"
  env:
  - name: TZ
    value: {{ $g.timezone | quote }}
  - name: LOG_LEVEL
    value: {{ $default.log.logshipper.level | quote | upper }}
  - name: DEPLOYMENT_TYPE
    value: "SIDECAR"
  - name: TLS_ENABLED
  {{- if $g.security.tls.enabled }}
    value: "true"
  {{- else }}
    value: "false"
  {{- end }}
  - name: RUN_AND_EXIT
  {{- if $default.logshipper.runAndExit }}
    value: "true"
  {{- else }}
    value: "false"
  {{- end }}
  - name : SHUTDOWN_DELAY
    value: {{ $default.logshipper.shutdownDelay | quote }}
  - name: LOG_PATH
    value: {{ $default.logshipper.storagePath | quote }}
  - name: POD_NAME
    valueFrom:
      fieldRef:
        fieldPath: metadata.name
  - name: NAMESPACE
    valueFrom:
      fieldRef:
        fieldPath: metadata.namespace
  - name: POD_UID
    valueFrom:
      fieldRef:
        fieldPath: metadata.uid
  - name: NODE_NAME
    valueFrom:
      fieldRef:
        fieldPath: spec.nodeName
  - name: SERVICE_ID
    value: {{ include "eric-lm-combined-server.logshipper-service-fullname" . }}
  - name: CONTAINER_NAME
    value: logshipper
  livenessProbe:
    exec:
      command:
        - "/bin/bash"
        - "-c"
        - "[[ ! -f {{ $default.logshipper.storagePath }}/data/started ]] || exec pgrep -l filebeat"
    initialDelaySeconds: {{ $default.probes.logshipper.livenessProbe.initialDelaySeconds }}
    timeoutSeconds: {{ $default.probes.logshipper.livenessProbe.timeoutSeconds }}
    periodSeconds: {{ $default.probes.logshipper.livenessProbe.periodSeconds }}
    failureThreshold: {{ $default.probes.logshipper.livenessProbe.failureThreshold }}
  resources:
    limits:
      cpu: {{ $default.resources.logshipper.limits.cpu  | quote }}
      memory: {{ $default.resources.logshipper.limits.memory  | quote }}
    requests:
      cpu: {{ $default.resources.logshipper.requests.cpu  | quote }}
      memory: {{ $default.resources.logshipper.requests.memory  | quote }}
  volumeMounts:
  - name: "eric-log-shipper-storage-path"
    mountPath: {{ $default.logshipper.storagePath | quote }}
  - name: "{{ include "eric-lm-combined-server.logshipper-service-fullname" . }}-logshipper-cfg"
    mountPath: "/etc/filebeat/filebeat.yml"
    subPath: "filebeat.yml"
    readOnly: true
  {{- if $g.security.tls.enabled }}
  - name: "server-ca-certificate"
    mountPath: "/run/secrets/ca-certificates/"
    readOnly: true
  - name: "lt-client-cert"
    mountPath: "/run/secrets/certificates/"
    readOnly: true
  {{- end }}
{{- end -}}

{{/*
Share logs volume mount path
*/}}
{{- define "eric-lm-combined-server.logshipper-storage-path" }}
{{- $default := fromJson (include "eric-lm-combined-server.logshipper-default-value" .) }}
- name: "eric-log-shipper-storage-path"
  mountPath: {{ $default.logshipper.storagePath | quote }}
{{- end -}}


{{/*
Log Shipper sidecar related volumes
*/}}
{{- define "eric-lm-combined-server.logshipper-volume" -}}
{{- $g := fromJson (include "eric-lm-combined-server.logshipper-global" .) }}
{{- $default := fromJson (include "eric-lm-combined-server.logshipper-default-value" .) }}
- name: "eric-log-shipper-storage-path"
  emptyDir:
  {{- if $default.logshipper.storageAllocation }}
    sizeLimit: {{ $default.logshipper.storageAllocation | quote }}
  {{- end }}
  {{- if $default.logshipper.storageMedium }}
    medium: {{ $default.logshipper.storageMedium | quote }}
  {{- end }}
- name: "{{ include "eric-lm-combined-server.logshipper-service-fullname" . }}-logshipper-cfg"
  configMap:
    name: "{{ include "eric-lm-combined-server.logshipper-service-fullname" . }}-logshipper-cfg"
{{- if $g.security.tls.enabled }}
- name: "server-ca-certificate"
  secret:
    secretName: "eric-sec-sip-tls-trusted-root-cert"
    optional: true
- name: "lt-client-cert"
  secret:
    secretName: "{{ include "eric-lm-combined-server.logshipper-service-fullname" . }}-lt-client-cert"
    optional: true
{{- end }}
{{- end -}}

{{/*
ClientCertificate Resource declaration file for TLS between logshipper and logtransformer
*/}}
{{- define "eric-lm-combined-server.logshipper-tls-cert-lt-client" -}}
{{- $default := fromJson (include "eric-lm-combined-server.logshipper-default-value" .) -}}
{{- $g := fromJson (include "eric-lm-combined-server.logshipper-global" .) -}}
{{- if $g.security.tls.enabled -}}
apiVersion: "siptls.sec.ericsson.com/v1"
kind: "InternalCertificate"
metadata:
  name: "{{ include "eric-lm-combined-server.logshipper-service-fullname" . }}-lt-client-cert"
  labels:
    {{- include "eric-lm-combined-server.logshipper-labels" . | indent 4 }}
  annotations:
    {{- include "eric-lm-combined-server.annotations" . | indent 4 }}
spec:
  kubernetes:
    generatedSecretName: "{{ include "eric-lm-combined-server.logshipper-service-fullname" . }}-lt-client-cert"
    certificateName: "clicert.pem"
    privateKeyName: "cliprivkey.pem"
  certificate:
    subject:
      cn: {{ include "eric-lm-combined-server.logshipper-service-fullname" . | quote }}
    issuer:
      reference: "{{ $default.logshipper.logtransformer.host }}-input-ca-cert"
    extendedKeyUsage:
      tlsClientAuth: true
      tlsServerAuth: false
{{- end -}}
{{- end -}}

{{- define "eric-lm-combined-server.logshipper-default-value" -}}
  {{- $productInfo := fromYaml (.Files.Get "eric-product-info.yaml") -}}
  {{- $repoPath := $productInfo.images.logShipper.repoPath -}}
  {{- $name := $productInfo.images.logShipper.name -}}
  {{- $tag := $productInfo.images.logShipper.tag -}}
  {{- $default := dict "probes" (dict "logshipper" (dict "livenessProbe" (dict "initialDelaySeconds" 1 ))) -}}
  {{- $default := merge $default (dict "probes" (dict "logshipper" (dict "livenessProbe" (dict "timeoutSeconds" 10 )))) -}}
  {{- $default := merge $default (dict "probes" (dict "logshipper" (dict "livenessProbe" (dict "periodSeconds" 10 )))) -}}
  {{- $default := merge $default (dict "probes" (dict "logshipper" (dict "livenessProbe" (dict "failureThreshold" 3 )))) -}}
  {{- $default := merge $default (dict "imageCredentials" (dict "logshipper" (dict "registry" (dict "url" )))) -}}
  {{- $default := merge $default (dict "imageCredentials" (dict "logshipper" (dict "registry" (dict "imagePullPolicy" )))) -}}
  {{- $default := merge $default (dict "imageCredentials" (dict "logshipper" (dict "repoPath" $repoPath ))) -}}
  {{- $default := merge $default (dict "images" (dict "logshipper" (dict "name" $name ))) -}}
  {{- $default := merge $default (dict "images" (dict "logshipper" (dict "tag" $tag ))) -}}
  {{- $default := merge $default (dict "resources" (dict "logshipper" (dict "requests" (dict "memory" "25Mi" )))) -}}
  {{- $default := merge $default (dict "resources" (dict "logshipper" (dict "requests" (dict "cpu" "50m" )))) -}}
  {{- $default := merge $default (dict "resources" (dict "logshipper" (dict "limits" (dict "memory" "50Mi" )))) -}}
  {{- $default := merge $default (dict "resources" (dict "logshipper" (dict "limits" (dict "cpu" "100m" )))) -}}
  {{- $default := merge $default (dict "logshipper" (dict "runAndExit" false )) -}}
  {{- $default := merge $default (dict "logshipper" (dict "shutdownDelay" 10 )) -}}
  {{- $default := merge $default (dict "logshipper" (dict "storagePath" "/logs" )) -}}
  {{- $default := merge $default (dict "logshipper" (dict "storageMedium" "" )) -}}
  {{- $default := merge $default (dict "logshipper" (dict "harvester" (dict "closeTimeout" "5m" ))) -}}
  {{- $default := merge $default (dict "logshipper" (dict "harvester" (dict "logData" (dict)))) -}}
  {{- $default := merge $default (dict "logshipper" (dict "logtransformer" (dict "host" "eric-log-transformer" ))) -}}
  {{- $default := merge $default (dict "logshipper" (dict "logplane" "adp-app-logs")) -}}
  {{- $default := merge $default (dict "log" (dict "logshipper" (dict "level" "info" ))) -}}
  {{- mergeOverwrite $default .Values | toJson -}}
{{- end -}}
