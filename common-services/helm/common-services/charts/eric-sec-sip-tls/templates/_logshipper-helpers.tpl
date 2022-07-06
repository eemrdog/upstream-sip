{{/*
Template of Log Shipper sidecar
Version: 9.3.0-24
*/}}

{{/*
Create a map from ".Values.global" with defaults if missing in values file.
This hides defaults from values file.
*/}}
{{- define "eric-sec-sip-tls.logshipper-global" -}}
  {{- $productInfo := fromYaml (.Files.Get "eric-product-info.yaml") -}}
  {{- $globalDefaults := dict "timezone" "UTC" -}}
  {{- $globalDefaults := merge $globalDefaults (dict "security" (dict "tls" (dict "enabled" true))) -}}
  {{- $globalDefaults := merge $globalDefaults (dict "registry" (dict "imagePullPolicy" "IfNotPresent" )) -}}
  {{- if $productInfo -}}
    {{- $globalDefaults := merge $globalDefaults (dict "registry" (dict "url" $productInfo.images.logshipper.registry )) -}}
  {{- else -}}
    {{- $globalDefaults := merge $globalDefaults (dict "registry" (dict "url" "armdocker.rnd.ericsson.se" )) -}}
  {{- end -}}
  {{- if .Values.global }}
    {{- mergeOverwrite $globalDefaults .Values.global | toJson -}}
  {{- else -}}
    {{- $globalDefaults | toJson -}}
  {{- end -}}
{{- end -}}

{{/*
Create a map with internal default values used for testing purposes.
*/}}
{{- define "eric-sec-sip-tls.logshipper-internal" -}}
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
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "eric-sec-sip-tls.logshipper-service-fullname" -}}
{{- if .Values.fullnameOverride -}}
  {{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
  {{- $name := default .Chart.Name .Values.nameOverride -}}
{{- printf "%s" $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}

{{/*
Expand the name of the chart.
*/}}
{{- define "eric-sec-sip-tls.logshipper-name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create product name, version and revision
*/}}
{{- define "eric-sec-sip-tls.logshipper-product-info" -}}
ericsson.com/logshipper-product-name: "Log Shipper"
ericsson.com/logshipper-product-number: "CXU 101 0642"
ericsson.com/logshipper-product-revision: "9.3.0"
{{- end -}}

{{/*
Create kubernetes.io name and version
*/}}
{{- define "eric-sec-sip-tls.logshipper-labels" }}
app.kubernetes.io/name: {{ include "eric-sec-sip-tls.name" . | quote }}
app.kubernetes.io/version: {{ .Chart.Version | replace "+" "_" }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Parameterize and service specific image path
*/}}
{{- define "eric-sec-sip-tls.logshipper-image" }}
{{- $productInfo := fromYaml (.Files.Get "eric-product-info.yaml") }}
{{- $registry := default $productInfo.images.logshipper.registry (default (((.Values).global).registry).url (default (((.Values).imageCredentials).registry).url ((((.Values).imageCredentials).logshipper).registry).url)) }}
{{- $repoPath := default $productInfo.images.logshipper.repoPath (default ((.Values).imageCredentials).repoPath (((.Values).imageCredentials).logshipper).repoPath) }}
{{- $name := $productInfo.images.logshipper.name }}
{{- $tag := default $productInfo.images.logshipper.tag (default (((.Values).images).logshipper).tag) }}
{{- printf "%s/%s/%s:%s" $registry $repoPath $name $tag }}
{{- end }}

{{/*
seccompProfile for logshipper container
*/}}
{{- define "eric-sec-sip-tls.LsSeccompProfile" -}}
{{- $default := fromJson (include "eric-sec-sip-tls.logshipper-default-value" .) }}
{{- if and $default.seccompProfile.logshipper $default.seccompProfile.logshipper.type }}
seccompProfile:
  type: {{ $default.seccompProfile.logshipper.type }}
  {{- if eq $default.seccompProfile.logshipper.type "Localhost" }}
  localhostProfile: {{ $default.seccompProfile.logshipper.localhostProfile }}
  {{- end }}
{{- end }}
{{- end -}}

{{/*
Log Shipper sidecar container spec
*/}}
{{- define "eric-sec-sip-tls.logshipper-container" -}}
{{- $g := fromJson (include "eric-sec-sip-tls.logshipper-global" .) }}
{{- $default := fromJson (include "eric-sec-sip-tls.logshipper-default-value" .) }}
- name: "logshipper"
  imagePullPolicy: {{ or $default.imageCredentials.logshipper.registry.imagePullPolicy $g.registry.imagePullPolicy }}
  image: {{ include "eric-sec-sip-tls.logshipper-image" . }}
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
    {{ include "eric-sec-sip-tls.LsSeccompProfile" . | indent 4 }}
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
    value: {{ include "eric-sec-sip-tls.logshipper-service-fullname" . }}
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
      {{- if $default.resources.logshipper.limits.cpu }}
      cpu: {{ $default.resources.logshipper.limits.cpu  | quote }}
      {{- end }}
      {{- if $default.resources.logshipper.limits.memory }}
      memory: {{ $default.resources.logshipper.limits.memory  | quote }}
      {{- end }}
      {{- if index $default.resources.logshipper.limits "ephemeral-storage" }}
      ephemeral-storage: {{ index $default.resources.logshipper.limits "ephemeral-storage"  | quote }}
      {{- end }}
    requests:
      {{- if $default.resources.logshipper.requests.cpu }}
      cpu: {{ $default.resources.logshipper.requests.cpu  | quote }}
      {{- end }}
      {{- if $default.resources.logshipper.requests.memory }}
      memory: {{ $default.resources.logshipper.requests.memory  | quote }}
      {{- end }}
      {{- if index $default.resources.logshipper.requests "ephemeral-storage" }}
      ephemeral-storage: {{ index $default.resources.logshipper.requests "ephemeral-storage"  | quote }}
      {{- end }}
  volumeMounts:
  - name: "eric-log-shipper-storage-path"
    mountPath: {{ $default.logshipper.storagePath | quote }}
  - name: "{{ include "eric-sec-sip-tls.logshipper-service-fullname" . }}-logshipper-cfg"
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
{{- define "eric-sec-sip-tls.logshipper-storage-path" }}
{{- $default := fromJson (include "eric-sec-sip-tls.logshipper-default-value" .) }}
- name: "eric-log-shipper-storage-path"
  mountPath: {{ $default.logshipper.storagePath | quote }}
{{- end -}}


{{/*
Log Shipper sidecar related volumes
*/}}
{{- define "eric-sec-sip-tls.logshipper-volume" -}}
{{- $g := fromJson (include "eric-sec-sip-tls.logshipper-global" .) }}
{{- $default := fromJson (include "eric-sec-sip-tls.logshipper-default-value" .) }}
- name: "eric-log-shipper-storage-path"
  emptyDir:
  {{- if $default.logshipper.storageAllocation }}
    sizeLimit: {{ $default.logshipper.storageAllocation | quote }}
  {{- end }}
  {{- if $default.logshipper.storageMedium }}
    medium: {{ $default.logshipper.storageMedium | quote }}
  {{- end }}
- name: "{{ include "eric-sec-sip-tls.logshipper-service-fullname" . }}-logshipper-cfg"
  configMap:
    name: "{{ include "eric-sec-sip-tls.logshipper-service-fullname" . }}-logshipper-cfg"
{{- if $g.security.tls.enabled }}
- name: "server-ca-certificate"
  secret:
    secretName: "eric-sec-sip-tls-trusted-root-cert"
    optional: true
- name: "lt-client-cert"
  secret:
    secretName: "{{ include "eric-sec-sip-tls.logshipper-service-fullname" . }}-lt-client-cert"
    optional: true
{{- end }}
{{- end -}}

{{- define "eric-sec-sip-tls.logshipper-default-value" -}}
  {{- $productInfo := fromYaml (.Files.Get "eric-product-info.yaml") -}}
  {{- $default := dict "probes" (dict "logshipper" (dict "livenessProbe" (dict "initialDelaySeconds" 1 ))) -}}
  {{- $default := merge $default (dict "probes" (dict "logshipper" (dict "livenessProbe" (dict "timeoutSeconds" 10 )))) -}}
  {{- $default := merge $default (dict "probes" (dict "logshipper" (dict "livenessProbe" (dict "periodSeconds" 10 )))) -}}
  {{- $default := merge $default (dict "probes" (dict "logshipper" (dict "livenessProbe" (dict "failureThreshold" 3 )))) -}}
  {{- $default := merge $default (dict "imageCredentials" (dict "logshipper" (dict "registry" (dict "url" )))) -}}
  {{- $default := merge $default (dict "imageCredentials" (dict "logshipper" (dict "registry" (dict "imagePullPolicy" )))) -}}
  {{- if $productInfo -}}
    {{- $default := merge $default (dict "imageCredentials" (dict "logshipper" (dict "repoPath" $productInfo.images.logshipper.repoPath ))) -}}
    {{- $default := merge $default (dict "images" (dict "logshipper" (dict "name" $productInfo.images.logshipper.name ))) -}}
    {{- $default := merge $default (dict "images" (dict "logshipper" (dict "tag" $productInfo.images.logshipper.tag ))) -}}
  {{- else -}}
    {{- $default := merge $default (dict "imageCredentials" (dict "logshipper" (dict "repoPath" "proj-adp-log-released" ))) -}}
    {{- $default := merge $default (dict "images" (dict "logshipper" (dict "name" "eric-log-shipper" ))) -}}
    {{- $default := merge $default (dict "images" (dict "logshipper" (dict "tag" "9.3.0-24" ))) -}}
  {{- end -}}
  {{- $default := merge $default (dict "logshipper" (dict "runAndExit" false )) -}}
  {{- $default := merge $default (dict "logshipper" (dict "shutdownDelay" 10 )) -}}
  {{- $default := merge $default (dict "logshipper" (dict "storagePath" "/logs" )) -}}
  {{- $default := merge $default (dict "logshipper" (dict "storageMedium" "" )) -}}
  {{- $default := merge $default (dict "logshipper" (dict "harvester" (dict "closeTimeout" "5m" ))) -}}
  {{- $default := merge $default (dict "logshipper" (dict "harvester" (dict "logData" (dict)))) -}}
  {{- $default := merge $default (dict "logshipper" (dict "logtransformer" (dict "host" "eric-log-transformer" ))) -}}
  {{- $default := merge $default (dict "logshipper" (dict "logplane" "adp-app-logs")) -}}
  {{- $default := merge $default (dict "log" (dict "logshipper" (dict "level" "info" ))) -}}
  {{- $default := merge $default (dict "seccompProfile" (dict "logshipper" (dict "type" "" ))) -}}
  {{- $default := merge $default (dict "seccompProfile" (dict "logshipper" (dict "localhostProfile" "" ))) -}}
  {{- $default := mergeOverwrite $default .Values -}}
  {{- $default | toJson -}}
{{- end -}}
