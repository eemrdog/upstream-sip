
{{/*
Create a map from global values with defaults if not in the values file.
*/}}
{{ define "eric-ctrl-bro.globalMap" }}
{{- $globalDefaults := dict "timezone" "UTC" -}}
{{- $globalDefaults := merge $globalDefaults (dict "security" (dict "tls" (dict "enabled" true))) -}}
{{- $globalDefaults := merge $globalDefaults (dict "security" (dict "policyBinding" (dict "create" false))) -}}
{{- $globalDefaults := merge $globalDefaults (dict "security" (dict "policyReferenceMap" (dict "default-restricted-security-policy" "default-restricted-security-policy"))) -}}
{{- $globalDefaults := merge $globalDefaults (dict "registry" (dict "imagePullPolicy" "IfNotPresent")) -}}
{{ if .Values.global }}
{{- mergeOverwrite $globalDefaults .Values.global | toJson -}}
{{ else }}
{{- $globalDefaults | toJson -}}
{{ end }}
{{ end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "eric-ctrl-bro.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}


{{/*
Chart version.
*/}}
{{- define "eric-ctrl-bro.version" -}}
{{- printf "%s" .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Template for tolerations.
*/}}
{{- define "eric-ctrl-bro.tolerations" -}}
  {{- $myList := list -}}
  {{- if .Values.osmn.enabled -}}
  {{- $tolDict := dict -}}
  {{- $tolDict := set $tolDict "key" "node.kubernetes.io/not-ready" -}}
  {{- $tolDict := set $tolDict "operator" "Exists" -}}
  {{- $tolDict := set $tolDict "effect" "NoExecute" -}}
  {{- $tolDict := set $tolDict "tolerationSeconds" 0 -}}
  {{- $myList = append $myList $tolDict -}}
  {{- $tolDict := dict -}}
  {{- $tolDict := set $tolDict "key" "node.kubernetes.io/unreachable" -}}
  {{- $tolDict := set $tolDict "operator" "Exists" -}}
  {{- $tolDict := set $tolDict "effect" "NoExecute" -}}
  {{- $tolDict := set $tolDict "tolerationSeconds" 0 -}}
  {{- $myList = append $myList $tolDict -}}
  {{- end -}}

  {{- range $key, $val := .Values.tolerations -}}
  {{- $keyTol := index $val "key" | trim -}}
  {{- if or (eq $keyTol "node.kubernetes.io/not-ready") (eq $keyTol "node.kubernetes.io/unreachable") }}
  {{- $tolSeconds := index $val "tolerationSeconds" | default 0 -}}
  {{- range $toleration := $myList -}}
  {{- $defTol := index $toleration "key" | trim -}}
  {{- if eq $defTol $keyTol -}}
  {{-   $toleration := unset $toleration "tolerationSeconds" -}}
  {{-   $toleration := set $toleration "tolerationSeconds" $tolSeconds -}}
  {{- end -}}
  {{- end -}}
 {{- else -}}
  {{- $myList = append $myList $val -}}
  {{- end -}}
  {{- end -}}
  {{- if $myList }}
  {{ $myList | toYaml }}
  {{- end -}}
{{- end -}}

{{/*
Expand the name of the chart.
*/}}
{{- define "eric-ctrl-bro.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Standard labels of Helm and Kubernetes.
*/}}
{{- define "eric-ctrl-bro.standard-labels" }}
app.kubernetes.io/instance: {{.Release.Name | quote }}
app.kubernetes.io/managed-by: {{ .Release.Service | quote }}
app.kubernetes.io/name: {{ template "eric-ctrl-bro.name" . }}
app.kubernetes.io/version: {{ template  "eric-ctrl-bro.version" . }}
chart: {{ template "eric-ctrl-bro.chart" . }}
{{- end }}

{{/*
Ericsson product info values.
*/}}
{{- define "eric-ctrl-bro.productName" -}}
{{- $productInfo := fromYaml (.Files.Get "eric-product-info.yaml") -}}
{{- printf "%s" $productInfo.productName -}}
{{- end -}}
{{- define "eric-ctrl-bro.productNumber" -}}
{{- $productInfo := fromYaml (.Files.Get "eric-product-info.yaml") -}}
{{- printf "%s" $productInfo.productNumber -}}
{{- end -}}

{{/*
Ericsson pod priority.
*/}}
{{- define "eric-ctrl-bro.priority" -}}
{{- $priority:= .Values.podPriority }}
{{- $priorityPod:= index $priority (include "eric-ctrl-bro.name" .) }}
{{- if $priorityPod }}
{{- $classname:= index $priorityPod "priorityClassName" }}
{{- if $classname }}
{{- printf "%s" $classname }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Ericsson pod resources.
*/}}
{{- define "eric-ctrl-bro.resources" -}}
requests:
{{- if index .Values.resources.backupAndRestore.requests "cpu" }}
  cpu: {{ index .Values.resources.backupAndRestore.requests "cpu" | quote -}}
{{- end -}}
{{- if index .Values.resources.backupAndRestore.requests "memory" }}
  memory: {{ index .Values.resources.backupAndRestore.requests "memory" | quote -}}
{{- end }}
{{- if index .Values.resources.backupAndRestore.requests "ephemeral-storage" }}
  ephemeral-storage: {{ index .Values.resources.backupAndRestore.requests "ephemeral-storage" | quote -}}
{{- end }}
limits:
{{- if index .Values.resources.backupAndRestore.limits "cpu" }}
  cpu: {{ index .Values.resources.backupAndRestore.limits "cpu" | quote -}}
{{- end -}}
{{- if index .Values.resources.backupAndRestore.limits "memory" }}
  memory: {{ index .Values.resources.backupAndRestore.limits "memory" | quote -}}
{{- end -}}
{{- if index .Values.resources.backupAndRestore.limits "ephemeral-storage" }}
  ephemeral-storage: {{ index .Values.resources.backupAndRestore.limits "ephemeral-storage" | quote -}}
{{- end }}
{{- end -}}

{{/*
Create a user defined label (DR-D1121-068, DR-D1121-060).
*/}}
{{ define "eric-ctrl-bro.config-labels" }}
  {{- $global := (.Values.global).labels -}}
  {{- $service := .Values.labels -}}
  {{- include "eric-ctrl-bro.mergeLabels" (dict "location" .Template.Name "sources" (list $global $service)) -}}
{{- end }}

{{/*
Merged labels for default, which includes standard-labels and config-labels.
*/}}
{{- define "eric-ctrl-bro.labels" -}}
  {{- $standard := include "eric-ctrl-bro.standard-labels" . | fromYaml -}}
  {{- $config := include "eric-ctrl-bro.config-labels" . | fromYaml -}}
  {{- include "eric-ctrl-bro.mergeLabels" (dict "location" .Template.Name "sources" (list $standard $config)) | trim }}
{{- end -}}

{{/*
Create a user defined annotation (DR-D1121-065, DR-D1121-060).
*/}}
{{ define "eric-ctrl-bro.config-annotations" }}
  {{- $global := (.Values.global).annotations -}}
  {{- $service := .Values.annotations -}}
  {{- include "eric-ctrl-bro.mergeAnnotations" (dict "location" .Template.Name "sources" (list $global $service)) -}}
{{- end }}

{{/*
Ericsson product information annotations
*/}}
{{- define "eric-ctrl-bro.product-info" -}}
ericsson.com/product-name: "{{ template "eric-ctrl-bro.productName" . }}"
ericsson.com/product-number: "{{ template "eric-ctrl-bro.productNumber" . }}"
ericsson.com/product-revision: "{{ regexReplaceAll "(.*)[+].*" .Chart.Version "${1}" }}"
{{- end -}}

{{/*
Merged annotations for default, which includes product-info and config-annotations.
*/}}
{{- define "eric-ctrl-bro.annotations" }}
  {{- $productInfo := include "eric-ctrl-bro.product-info" . | fromYaml -}}
  {{- $config := include "eric-ctrl-bro.config-annotations" . | fromYaml -}}
  {{- include "eric-ctrl-bro.mergeAnnotations" (dict "location" .Template.Name "sources" (list $productInfo $config)) | trim }}
{{- end }}

{{/*
Comma separated list of product numbers
*/}}
{{- define "eric-ctrl-bro.productNumberList" }}
{{- range $i, $e := .Values.bro.productNumberList -}}
{{- if eq $i 0 -}}{{- printf " " -}}{{- else -}}{{- printf "," -}}{{- end -}}{{- . -}}
{{- end -}}
{{- end -}}

{{/*
livenessProbeConfig
*/}}
{{- define "eric-ctrl-bro.livenessProbeConfig" }}
periodSeconds : {{ .Values.probes.backupAndRestore.livenessProbe.periodSeconds }}
failureThreshold : {{ .Values.probes.backupAndRestore.livenessProbe.failureThreshold }}
initialDelaySeconds : {{ .Values.probes.backupAndRestore.livenessProbe.initialDelaySeconds }}
timeoutSeconds : {{ .Values.probes.backupAndRestore.livenessProbe.timeoutSeconds }}
{{- end -}}


{{/*
LivenessProbe
*/}}
{{- define "eric-ctrl-bro.livenessProbe" }}
{{- if eq (include "eric-ctrl-bro.globalSecurity" .) "true" -}}
    {{- if eq .Values.service.endpoints.restActions.tls.enforced "required" -}}
        {{- if eq .Values.service.endpoints.restActions.tls.verifyClientCertificate "required" -}}
                      exec:
            command:
              - sh
              - -c
              - |
                grep -Rq Healthy /healthStatus/broLiveHealth.json && rm -rf /healthStatus/broLiveHealth.json
        {{- else -}}
                    httpGet:
            path: /v1/health
            port: {{ .Values.bro.restTlsPort }}
            scheme: HTTPS
        {{- end -}}
    {{- else -}}
                  httpGet:
            path: /v1/health
            port: {{ .Values.bro.restPort }}
    {{- end -}}
{{- else -}}
              httpGet:
            path: /v1/health
            port: {{ .Values.bro.restPort }}
{{- end -}}
{{- end -}}

{{/*
readinessProbeConfig
*/}}
{{- define "eric-ctrl-bro.readinessProbeConfig" }}
periodSeconds : {{ .Values.probes.backupAndRestore.readinessProbe.periodSeconds }}
failureThreshold : {{ .Values.probes.backupAndRestore.readinessProbe.failureThreshold }}
successThreshold : {{ .Values.probes.backupAndRestore.readinessProbe.successThreshold }}
initialDelaySeconds : {{ .Values.probes.backupAndRestore.readinessProbe.initialDelaySeconds }}
timeoutSeconds : {{ .Values.probes.backupAndRestore.readinessProbe.timeoutSeconds }}
{{- end -}}

{{/*
ReadinessProbe
*/}}
{{- define "eric-ctrl-bro.readinessProbe" }}
{{- if eq (include "eric-ctrl-bro.globalSecurity" .) "true" -}}
    {{- if eq .Values.service.endpoints.restActions.tls.enforced "required" -}}
        {{- if eq .Values.service.endpoints.restActions.tls.verifyClientCertificate "required" -}}
                      exec:
            command:
              - sh
              - -c
              - |
                grep -Rq Healthy /healthStatus/broReadyHealth.json && rm -rf /healthStatus/broReadyHealth.json
        {{- else -}}
                    httpGet:
            path: /v1/health
            port: {{ .Values.bro.restTlsPort }}
            scheme: HTTPS
        {{- end -}}
    {{- else -}}
                  httpGet:
            path: /v1/health
            port: {{ .Values.bro.restPort }}
    {{- end -}}
{{- else -}}
              httpGet:
            path: /v1/health
            port: {{ .Values.bro.restPort }}
{{- end -}}
{{- end -}}

{{/*
Global Security
*/}}
{{- define "eric-ctrl-bro.globalSecurity" -}}
{{- $g := fromJson (include "eric-ctrl-bro.globalMap" .) -}}
{{ index $g.security.tls "enabled" }}
{{- end -}}

{{/*
PM Server Security Enabled
*/}}
{{- define "eric-ctrl-bro.pmServerSecurityType" -}}
{{- if eq .Values.service.endpoints.scrape.pm.tls.enforced "required" -}}
    {{- if eq .Values.service.endpoints.scrape.pm.tls.verifyClientCertificate "required" -}}
        need
    {{- else -}}
        want
    {{- end -}}
{{- else -}}
    all
{{- end -}}
{{- end -}}

{{/*
CMM Notification Server Security Enabled
*/}}
{{- define "eric-ctrl-bro.cmmNotifServer" -}}
{{- if eq .Values.service.endpoints.cmmHttpNotif.tls.enforced "required" -}}
    {{- if eq .Values.service.endpoints.cmmHttpNotif.tls.verifyClientCertificate "required" -}}
        need
    {{- else -}}
        want
    {{- end -}}
{{- else -}}
    all
{{- end -}}
{{- end -}}

{{/*
configmap volumes + additional volumes
*/}}
{{- define "eric-ctrl-bro.volumes" -}}
- name: health-status-volume
  emptyDir: {}
- name: writeable-tmp-volume
  emptyDir: {}
- name: {{ template "eric-ctrl-bro.name" . }}-logging
  configMap:
    defaultMode: 0444
    name: {{ template "eric-ctrl-bro.name" . }}-logging
{{- if eq .Values.osmn.enabled true }}
- name: {{ template "eric-ctrl-bro.name" . }}-object-store-secret
  secret:
    secretName: {{ .Values.osmn.credentials.secretName }}
{{- end }}
{{- if (eq (include "eric-ctrl-bro.globalSecurity" .) "true") }}
- name: {{ template "eric-ctrl-bro.name" . }}-server-cert
  secret:
    secretName: {{ template "eric-ctrl-bro.name" . }}-server-cert
- name: {{ template "eric-ctrl-bro.name" . }}-ca
  secret:
    secretName: {{ template "eric-ctrl-bro.name" . }}-ca
- name: {{ template "eric-ctrl-bro.name" . }}-siptls-root-ca
  secret:
    secretName: {{ template "eric-ctrl-bro.eric-sec-sip-tls.name" . }}-trusted-root-cert
{{- if eq .Values.metrics.enabled true }}
- name: eric-pm-server-ca
  secret:
    secretName: {{ template "eric-ctrl-bro.pm-server.name" . }}-ca
{{- end }}
{{- with . }}
{{- $logstreaming := include "eric-ctrl-bro.logstreaming" . | fromYaml }}
{{- if has "tcp" (get $logstreaming "logOutput") }}
- name: {{ template "eric-ctrl-bro.name" . }}-lt-client-cert
  secret:
    secretName: {{ template "eric-ctrl-bro.name" . }}-lt-client-certificate
{{- end }}
{{- end }}
{{- if .Values.bro.enableConfigurationManagement }}
- name: eric-cmm-tls-client-ca
  secret:
    secretName: {{ template "eric-ctrl-bro.eric-cm-mediator.name" . }}-tls-client-ca-secret
- name: eric-cmyp-server-ca
  secret:
    secretName: {{ template "eric-ctrl-bro.eric-cm-yang-provider.name" . }}-ca-secret
- name: {{ template "eric-ctrl-bro.name" . }}-cmm-client-cert
  secret:
    secretName: {{ template "eric-ctrl-bro.name" . }}-cmm-client-secret
{{- end }}
{{- if .Values.bro.enableNotifications }}
{{- if .Values.kafka.enabled }}
- name: {{ template "eric-ctrl-bro.name" . }}-mbkf-client-cert
  secret:
    secretName: {{ template "eric-ctrl-bro.name" . }}-mbkf-client-secret
{{- end }}
{{- if .Values.keyValueDatabaseRd.enabled }}
- name: {{ template "eric-ctrl-bro.name" . }}-kvdb-rd-client-cert
  secret:
    secretName: {{ template "eric-ctrl-bro.name" . }}-kvdb-rd-client-secret
{{- end }}
{{- end }}
{{- end }}
- name: {{ template "eric-ctrl-bro.name" . }}-serviceproperties
  configMap:
    defaultMode: 0444
    name: {{ template "eric-ctrl-bro.name" . }}-serviceproperties
{{ if .Values.volumes -}}
{{ .Values.volumes -}}
{{ end -}}
{{ end -}}

{{/*
configmap volumemounts + additional volume mounts
*/}}
{{- define "eric-ctrl-bro.volumeMounts" -}}
- name: health-status-volume
  mountPath: /healthStatus
- name: writeable-tmp-volume
  mountPath: /temp
- name: {{ template "eric-ctrl-bro.name" . }}-logging
  mountPath: "{{ .Values.bro.logging.logDirectory }}"
- name: {{ template "eric-ctrl-bro.name" . }}-serviceproperties
  mountPath: "/opt/ericsson/br/application.properties"
  subPath: "application.properties"
{{- if eq .Values.osmn.enabled true }}
- name: {{ template "eric-ctrl-bro.name" . }}-object-store-secret
  mountPath: "/run/sec/certs/objectstore/credentials"
{{- end }}
{{- if (eq (include "eric-ctrl-bro.globalSecurity" .) "true") }}
- name: {{ template "eric-ctrl-bro.name" . }}-server-cert
  mountPath: "/run/sec/certs/server"
- name: {{ template "eric-ctrl-bro.name" . }}-ca
  mountPath: "/run/sec/cas/broca/"
- name: {{ template "eric-ctrl-bro.name" . }}-siptls-root-ca
  readOnly: true
  mountPath: /run/sec/cas/siptls
{{- if eq .Values.metrics.enabled true }}
- name: eric-pm-server-ca
  readOnly: true
  mountPath: /run/sec/cas/pm
{{- end }}
{{- with . }}
{{- $logstreaming := include "eric-ctrl-bro.logstreaming" . | fromYaml }}
{{- if has "tcp" (get $logstreaming "logOutput") }}
- name: {{ template "eric-ctrl-bro.name" . }}-lt-client-cert
  readOnly: true
  mountPath: /run/sec/certs/logtransformer
{{- end }}
{{- end }}
{{- if .Values.bro.enableConfigurationManagement }}
- name: eric-cmm-tls-client-ca
  mountPath: "/run/sec/certs/cmmserver/ca"
- name: eric-cmyp-server-ca
  readOnly: true
  mountPath: /run/sec/cas/cmyp
- name: {{ template "eric-ctrl-bro.name" . }}-cmm-client-cert
  mountPath: "/run/sec/certs/cmmserver"
{{- end }}
{{- if .Values.bro.enableNotifications }}
{{- if .Values.kafka.enabled }}
- name: {{ template "eric-ctrl-bro.name" . }}-mbkf-client-cert
  readOnly: true
  mountPath: /run/sec/certs/mbkfserver
{{- end }}
{{- if .Values.keyValueDatabaseRd.enabled }}
- name: {{ template "eric-ctrl-bro.name" . }}-kvdb-rd-client-cert
  readOnly: true
  mountPath: /run/sec/certs/kvdbrdserver
{{- end }}
{{- end }}
{{- end }}
{{ if .Values.volumeMounts -}}
{{ .Values.volumeMounts -}}
{{ end -}}
{{ end -}}

{{/*
Volume mount name used for StatefulSet.
*/}}
{{- define "eric-ctrl-bro.persistence.persistentVolumeClaim.name" -}}
  {{- printf "%s" "backup-data" -}}
{{- end -}}

{{/*
Create the name of the service account to use. BRO needs the service account (containing cm-key) to access the KMS and decrypt the password.
*/}}
{{- define "eric-ctrl-bro.serviceAccountName" -}}
{{ include "eric-ctrl-bro.name" . }}-cm-key
{{- end -}}

{{- define "eric-ctrl-bro.pullpolicy" -}}
{{- $g := fromJson (include "eric-ctrl-bro.globalMap" .) -}}
{{- $defaultPolicy := index $g.registry "imagePullPolicy" -}}
imagePullPolicy: {{ default $defaultPolicy .Values.imageCredentials.registry.imagePullPolicy | quote }}
{{- end -}}

{{- define "eric-ctrl-bro.image.repoPath" -}}
{{- $productInfo := fromYaml (.Files.Get "eric-product-info.yaml") -}}
{{- $defaultRepoPath := $productInfo.images.backupAndRestore.repoPath -}}
{{- if .Values.imageCredentials -}}
  {{- default $defaultRepoPath .Values.imageCredentials.repoPath -}}
{{- else -}}
  {{- printf "%s" $defaultRepoPath }}
{{- end -}}
{{- end -}}

{{- define "eric-ctrl-bro.image.path" -}}
{{- $productInfo := fromYaml (.Files.Get "eric-product-info.yaml") -}}
{{- if .Values.imageCredentials.repoPath -}}
  {{- include "eric-ctrl-bro.image.repoPath" . }}/{{ $productInfo.images.backupAndRestore.name }}:{{ $productInfo.images.backupAndRestore.tag }}
{{- else -}}
  {{ $productInfo.images.backupAndRestore.name }}:{{ $productInfo.images.backupAndRestore.tag }}
{{- end -}}
{{- end -}}

{{- define "eric-ctrl-bro.pullsecret" -}}
{{- if .Values.imageCredentials }}
  {{- if .Values.imageCredentials.pullSecret }}
      imagePullSecrets:
        - name: {{ .Values.imageCredentials.pullSecret | quote}}
  {{- else if .Values.global -}}
      {{- if .Values.global.pullSecret }}
      imagePullSecrets:
        - name: {{ .Values.global.pullSecret | quote }}
      {{- end -}}
  {{- end }}
{{- else if .Values.global -}}
  {{- if .Values.global.pullSecret }}
      imagePullSecrets:
        - name: {{ .Values.global.pullSecret | quote }}
  {{- end -}}
{{- end }}
{{- end -}}

{{- define "eric-ctrl-bro.image.registry" -}}
{{- $productInfo := fromYaml (.Files.Get "eric-product-info.yaml") -}}
{{- $registry := $productInfo.images.backupAndRestore.registry -}}
{{- if .Values.global -}}
  {{- if .Values.global.registry -}}
    {{- if .Values.global.registry.url -}}
      {{- $registry = .Values.global.registry.url -}}
    {{- end -}}
  {{- end -}}
{{- end -}}
{{- if .Values.imageCredentials -}}
  {{- if .Values.imageCredentials.registry -}}
    {{- if .Values.imageCredentials.registry.url -}}
      {{- $registry = .Values.imageCredentials.registry.url -}}
    {{- end -}}
  {{- end -}}
{{- end -}}
{{- printf "%s" $registry -}}
{{- end -}}

{{- define "eric-ctrl-bro.image" -}}
"{{- include "eric-ctrl-bro.image.registry" . -}}/{{- include "eric-ctrl-bro.image.path" . }}"
{{- end -}}

{{/*
Return the GRPC port set via global parameter if it's set, otherwise 3000
*/}}
{{- define "eric-ctrl-bro.globalBroGrpcServicePort"}}
{{- if .Values.global -}}
    {{- if .Values.global.adpBR -}}
        {{- .Values.global.adpBR.broGrpcServicePort | default 3000 -}}
    {{- else -}}
        3000
    {{- end -}}
{{- else -}}
    3000
{{- end -}}
{{- end -}}

{{/*
Return the brLabelKey set via global parameter if it's set, otherwise adpbrlabelkey
*/}}
{{- define "eric-ctrl-bro.globalBrLabelKey"}}
{{- if .Values.global -}}
    {{- if .Values.global.adpBR -}}
        {{- .Values.global.adpBR.brLabelKey | default "adpbrlabelkey" -}}
    {{- else -}}
        adpbrlabelkey
    {{- end -}}
{{- else -}}
    adpbrlabelkey
{{- end -}}
{{- end -}}

{{/*
Create a merged set of nodeSelectors from global and service level.
*/}}
{{- define "eric-ctrl-bro.nodeSelector" }}
  {{- $global := (.Values.global).nodeSelector -}}
  {{- $service := .Values.nodeSelector -}}
  {{- include "eric-ctrl-bro.aggregatedMerge" (dict "context" "eric-ctrl-bro.nodeSelector" "location" .Template.Name "sources" (list $global $service)) }}
{{- end }}

{{/*
Return the fsgroup set via global parameter if it's set, otherwise 10000
*/}}
{{- define "eric-ctrl-bro.fsGroup.coordinated" -}}
{{- if .Values.global -}}
    {{- if .Values.global.fsGroup -}}
        {{- if .Values.global.fsGroup.manual -}}
            {{ .Values.global.fsGroup.manual }}
        {{- else -}}
            {{- if eq .Values.global.fsGroup.namespace true -}}
                 # The 'default' defined in the Security Policy will be used.
            {{- else -}}
                10000
            {{- end -}}
        {{- end -}}
    {{- else -}}
        10000
    {{- end -}}
{{- else -}}
    10000
{{- end -}}
{{- end -}}

{{/*
Issuer for LT client cert
*/}}
{{- define "eric-ctrl-bro.certificate-authorities.eric-log-transformer" -}}
{{- if .Values.service.endpoints.lt -}}
  {{- if .Values.service.endpoints.lt.tls -}}
    {{- if .Values.service.endpoints.lt.tls.issuer -}}
      {{- .Values.service.endpoints.lt.tls.issuer -}}
    {{- else -}}
      eric-log-transformer
    {{- end -}}
  {{- else -}}
    eric-log-transformer
  {{- end -}}
{{- else -}}
  eric-log-transformer
{{- end -}}
{{- end -}}

{{/*
Issuer for MBKF client cert
*/}}
{{- define "eric-ctrl-bro.certificate-authorities.message-bus-kf" -}}
{{- if .Values.kafka -}}
  {{- if .Values.kafka.hostname -}}
    {{ .Values.kafka.hostname }}
  {{- else -}}
    eric-data-message-bus-kf-client
  {{- end -}}
{{- else -}}
  eric-data-message-bus-kf-client
{{- end -}}
{{- end -}}

{{- define "eric-ctrl-bro.eric-sec-sip-tls.name" -}}
{{- if .Values.sipTls -}}
  {{- if .Values.sipTls.host -}}
    {{ .Values.sipTls.host }}
  {{- else -}}
    eric-sec-sip-tls
  {{- end -}}
{{- else -}}
  eric-sec-sip-tls
{{- end -}}
{{- end -}}

{{- define "eric-ctrl-bro.eric-cm-mediator.name" -}}
{{- if .Values.cmm -}}
  {{- if .Values.cmm.host -}}
    {{ .Values.cmm.host }}
  {{- else -}}
    eric-cm-mediator
  {{- end -}}
{{- else -}}
  eric-cm-mediator
{{- end -}}
{{- end -}}

{{- define "eric-ctrl-bro.eric-cm-yang-provider.name" -}}
{{- if .Values.cmyang -}}
  {{- if .Values.cmyang.host -}}
    {{ .Values.cmyang.host }}
  {{- else -}}
    eric-cm-yang-provider
  {{- end -}}
{{- else -}}
  eric-cm-yang-provider
{{- end -}}
{{- end -}}

{{- define "eric-ctrl-bro.pm-server.name" -}}
{{- if .Values.pm -}}
  {{- if .Values.pm.host -}}
    {{ .Values.pm.host }}
  {{- else -}}
    eric-pm-server
  {{- end -}}
{{- else -}}
  eric-pm-server
{{- end -}}
{{- end -}}

{{/*
Issuer for KVDB RD client cert
*/}}
{{- define "eric-ctrl-bro.certificate-authorities.kvdbrd" -}}
{{- if .Values.keyValueDatabaseRd -}}
  {{- if .Values.keyValueDatabaseRd.hostname -}}
    {{ .Values.keyValueDatabaseRd.hostname }}
  {{- else -}}
    eric-data-key-value-database-rd-operand
  {{- end -}}
{{- else -}}
  eric-data-key-value-database-rd-operand
{{- end -}}
{{- end -}}

{{/*
Service logging level. Preference order is log.level, bro.logging.level, default of "info"
log.level left purposefully unset in default values.yaml to avoid NBC
*/}}
{{- define "eric-ctrl-bro.log.level" -}}
{{- if .Values.log.level -}}
  {{ .Values.log.level }}
{{- else -}}
  {{- if .Values.bro.logging.level -}}
    {{ .Values.bro.logging.level }}
  {{- else -}}
    info
  {{- end -}}
{{- end -}}
{{- end -}}

{{/*
Service logging root level. Preference order is log.rootLevel, bro.logging.rootLevel, default of "info"
log.rootLevel left purposefully unset in default values.yaml to avoid NBC
*/}}
{{- define "eric-ctrl-bro.log.rootLevel" -}}
{{- if .Values.log.rootLevel -}}
  {{ .Values.log.rootLevel }}
{{- else -}}
  {{- if .Values.bro.logging.rootLevel -}}
    {{ .Values.bro.logging.rootLevel }}
  {{- else -}}
    info
  {{- end -}}
{{- end -}}
{{- end -}}

{{/*
Service logging log4j2 level. Preference order is log.log4j2Level, bro.logging.log4j2Level, default of "info"
log.log4j2Level left purposefully unset in default values.yaml to avoid NBC
*/}}
{{- define "eric-ctrl-bro.log.log4j2Level" -}}
{{- if .Values.log.log4j2Level -}}
  {{ .Values.log.log4j2Level }}
{{- else -}}
  {{- if .Values.bro.logging.log4j2Level -}}
    {{ .Values.bro.logging.log4j2Level }}
  {{- else -}}
    info
  {{- end -}}
{{- end -}}
{{- end -}}

{{/*
Defines time in milliseconds before channel timeout for SFTP client.
*/}}
{{- define "eric-ctrl-bro.sftpTimeout" -}}
{{- if .Values.sftpTimeout -}}
    {{ .Values.sftpTimeout }}
{{- else -}}
    5000
{{- end -}}
{{- end -}}

{{/*
Create a merged set of parameters for log streaming from global and service level.
Expectation is that the user calls fromYaml on the other side, e.g.
  {{ $data := include "eric-ctrl-bro.logstreaming" . | fromYaml }}
  port={{ $data.logtransformer.port | quote }}
*/}}
{{ define "eric-ctrl-bro.logstreaming" }}
  {{- $globalValues := dict }}
  {{- $globalValues = merge $globalValues (dict "logOutput" (list)) -}}
  {{- $globalValues = merge $globalValues (dict "logtransformer" (dict "host" "eric-log-transformer")) -}}
  {{- $globalValues = merge $globalValues (dict "logtransformer" (dict "port" "5015")) -}}


{{/*
The ordering here is relevant, as we want local settings for host to be overridden by global host settings. The outputs
streams are merged in such a way that the order in which the merge occurs is irrelevant
*/}}
  {{- if .Values.log -}}
    {{- if .Values.log.outputs -}}
      {{- $globalValues = mergeOverwrite $globalValues (dict "logOutput" (uniq (concat .Values.log.outputs (get $globalValues "logOutput")))) -}}
    {{- end -}}
  {{- end -}}
  {{- if .Values.logtransformer -}}
    {{- $globalValues = mergeOverwrite $globalValues (dict "logtransformer" (dict "host" .Values.logtransformer.host)) -}}
  {{- end -}}

  {{- if .Values.global -}}
    {{- if .Values.global.logOutput }}
      {{- $globalValues = mergeOverwrite $globalValues (dict "logOutput" (uniq (concat .Values.global.logOutput (get $globalValues "logOutput")))) -}}
     {{- end }}
    {{- if .Values.global.logtransformer }}
      {{- $globalValues = mergeOverwrite $globalValues (dict "logtransformer" (dict "host" .Values.global.logtransformer.host)) -}}
    {{- end }}
  {{- end -}}

  {{- if (eq (include "eric-ctrl-bro.globalSecurity" .) "true") -}}
    {{- $globalValues = mergeOverwrite $globalValues (dict "logtransformer" (dict "port" .Values.logtransformer.tlsPort)) -}}
  {{- else -}}
   {{- $globalValues = mergeOverwrite $globalValues (dict "logtransformer" (dict "port" .Values.logtransformer.port)) -}}
  {{- end -}}
  {{ toJson $globalValues -}}
{{ end }}

{{/*
Define the security-policy reference
{{- define "eric-ctrl-bro.securityPolicy.reference" -}}
{{- $policyreference := index .Values "global" "security" "policyReferenceMap" "default-restricted-security-policy" -}}
{{- end -}}
*/}}

{{/*
Define the security-policy annotations
{{- define "eric-ctrl-bro.securityPolicy.annotations" -}}
ericsson.com/security-policy.name: "restricted/default"
ericsson.com/security-policy.privileged: "false"
ericsson.com/security-policy.capabilities: "N/A"
{{- end -}}
*/}}

{{/*
Defines the appArmor profile annotation for the BRO container.
The configuration can be set per container, but it applies to all containers
when the container name is ommited.
*/}}
{{- define "eric-ctrl-bro.appArmorAnnotation" }}
{{- if .Values.appArmorProfile }}
{{- $profile := .Values.appArmorProfile }}
{{- $containerName := (include "eric-ctrl-bro.name" .)}}
{{- if index $profile $containerName }}
{{- $profile = index $profile $containerName }}
{{- end }}
{{- include "eric-ctrl-bro.getAppArmorAnnotationFromProfile" (dict "profile" $profile "containerName" $containerName)}}
{{- end }}
{{- end }}

{{/*
Gets the appArmor annotation for the BRO container
from the appArmor profile object
*/}}
{{- define "eric-ctrl-bro.getAppArmorAnnotationFromProfile" }}
{{- $profile := index . "profile" }}
{{- $containerName := index . "containerName" }}
{{- if $profile.type}}
{{- $appArmorProfile := lower $profile.type }}
{{- if eq "runtime/default" $appArmorProfile}}
container.apparmor.security.beta.kubernetes.io/{{ $containerName }}: "runtime/default"
{{- else if eq "unconfined" $appArmorProfile}}
container.apparmor.security.beta.kubernetes.io/{{ $containerName }}: "unconfined"
{{- else if eq "localhost" $appArmorProfile}}
{{- $localHostProfile := $profile.localhostProfile }}
{{- if $localHostProfile }}
{{- $localHostProfileList := (splitList "/" $localHostProfile)}}
{{- if (last $localHostProfileList) }}
container.apparmor.security.beta.kubernetes.io/{{ $containerName }}: "localhost/{{ (last $localHostProfileList) }}"
{{- end }}
{{- end }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Defines the Seccomp security context for the BRO container.
The configuration can be set per container, but it applies to all containers
when the container name is ommited.
*/}}
{{- define "eric-ctrl-bro.secCompSecurityContext" }}
{{- if .Values.seccompProfile }}
{{- $profile := .Values.seccompProfile }}
{{- $containerName := (include "eric-ctrl-bro.name" .)}}
{{- if index $profile $containerName }}
{{- $profile = index $profile $containerName }}
{{- end }}
{{- include "eric-ctrl-bro.getSeccompSecurityContextFromProfile" (dict "profile" $profile)}}
{{- end }}
{{- end }}

{{/*
Gets the Seccomp security context for the BRO container
from the Seccomp profile object.
*/}}
{{- define "eric-ctrl-bro.getSeccompSecurityContextFromProfile" }}
{{- $profile := index . "profile" }}
{{- if $profile.type}}
{{- $seccompProfile := lower $profile.type }}
{{- if eq "runtimedefault" $seccompProfile}}
seccompProfile:
  type: RuntimeDefault
{{- else if eq "unconfined" $seccompProfile}}
seccompProfile:
  type: Unconfined
{{- else if eq "localhost" $seccompProfile}}
{{- if $profile.localhostProfile }}
seccompProfile:
  type: Localhost
  localhostProfile: {{ $profile.localhostProfile }}
{{- end }}
{{- end }}
{{- end }}
{{- end }}