{{/* vim: set filetype=mustache: */}}

{{/*
Expand the name of the chart.
*/}}
{{- define "eric-log-transformer.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "eric-log-transformer.fullname" -}}
{{- if .Values.fullnameOverride -}}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- printf "%s" $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "eric-log-transformer.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{ define "eric-log-transformer.transformer-path" }}
  {{- $productInfo := fromYaml (.Files.Get "eric-product-info.yaml") -}}
  {{- $g := fromJson (include "eric-log-transformer.global" .) -}}
  {{- $registryUrl := $g.registry.url | default $productInfo.images.logtransformer.registry -}}
  {{- $defaults := dict "imageCredentials" (dict "registry" (dict "url" $registryUrl)) -}}
  {{- $defaults := merge $defaults (dict "imageCredentials" (dict "repoPath" $productInfo.images.logtransformer.repoPath)) -}}
  {{- $defaults := merge $defaults (dict "images" (dict "logtransformer" (dict "name" $productInfo.images.logtransformer.name))) -}}
  {{- $defaults := merge $defaults (dict "images" (dict "logtransformer" (dict "tag" $productInfo.images.logtransformer.tag))) -}}
  {{- $defaults := mergeOverwrite $defaults .Values -}}
  {{- $registryUrl := $defaults.imageCredentials.registry.url -}}
  {{- $repoPath := $defaults.imageCredentials.repoPath -}}
  {{- $name := $defaults.images.logtransformer.name -}}
  {{- $tag := $defaults.images.logtransformer.tag -}}
  {{- printf "%s/%s/%s:%s" $registryUrl $repoPath $name $tag -}}
{{- end -}}

{{/*
Create kubernetes.io name and version
*/}}
{{- define "eric-log-transformer.k8sLabels" -}}
app.kubernetes.io/name: {{ include "eric-log-transformer.name" . }}
app.kubernetes.io/version: {{ .Chart.Version | replace "+" "_" }}
app.kubernetes.io/instance: {{ .Release.Name | quote }}
{{- end -}}

{{/*
Common labels
*/}}
{{- define "eric-log-transformer.labels" -}}
  {{- $k8sLabels := include "eric-log-transformer.k8sLabels" . | fromYaml -}}
  {{- $globalLabels := (.Values.global).labels -}}
  {{- $serviceLabels := .Values.labels -}}
  {{- include "eric-log-transformer.mergeLabels" (dict "location" .Template.Name "sources" (list $k8sLabels $globalLabels $serviceLabels)) | trim }}
{{- end -}}

{{/*
Logshipper labels
*/}}
{{- define "eric-log-transformer.logshipper-labels" }}
{{- println "" -}}
{{- include "eric-log-transformer.labels" . -}}
{{- end }}

{{/*
Create Search Engine host address
*/}}
{{- define "eric-log-transformer.elasticsearch-host" -}}
{{- $g := fromJson (include "eric-log-transformer.global" .) -}}
{{- if $g.security.tls.enabled -}}
  {{- printf "%s-tls:%d" .Values.searchengine.host 9200 -}}
{{- else -}}
  {{- printf "%s:%d" .Values.searchengine.host 9200 -}}
{{- end -}}
{{- end -}}

{{- define "eric-log-transformer.beats-tls-config-options" -}}
{{- $d := fromJson (include "eric-log-transformer.deprecated" .) }}
{{- if not $d.security.tls.eda }}
ssl_certificate => "/opt/logstash/resource/srvcert.pem"
ssl_key => "/opt/logstash/resource/srvpriv_p8.key"
ssl_certificate_authorities => ["/run/secrets/ca-certificates/client-cacertbundle.pem"]
{{- else }}
ssl_certificate => "/run/secrets/eda-certificates/cert.pem"
ssl_key => "/run/secrets/eda-certificates/key.pem"
ssl_certificate_authorities => ["/run/secrets/eda-certificates/ca-cert.pem"]
{{- end }}
ssl => true
client_inactivity_timeout => 300
ssl_handshake_timeout => 10000
ssl_verify_mode => "force_peer"
tls_max_version => "1.2"
tls_min_version => "1.2"
{{- end -}}

{{/*
Creating secret volume for TLS between LT and LS
Creating Secret Volumes for Server Certificate and Client CA Certificate
*/}}
{{- define "eric-log-transformer.tls-volume" }}
- name: "server-certificate"
  secret:
    secretName: {{ include "eric-log-transformer.fullname" . }}-server-cert
- name: "client-ca-certificate"
  secret:
    secretName: {{ include "eric-log-transformer.fullname" . }}-client-ca
{{- end -}}

{{/*
Creating secret volume for EDA TLS
*/}}
{{- define "eric-log-transformer.eda-tls-volume" }}
- name: "eda-certificates"
  secret:
    secretName: {{ include "eric-log-transformer.fullname" . }}-server-cert
{{- end -}}

{{/*
Creating volume mount for EDA TLS
*/}}
{{- define "eric-log-transformer.eda-tls-volumemount" }}
- name: "eda-certificates"
  mountPath: "/run/secrets/eda-certificates/"
  readOnly: true
{{- end -}}

{{- define "eric-log-transformer.tcp-eda-tls-config-options" -}}
{{- $d := fromJson (include "eric-log-transformer.deprecated" .) }}
{{- if $d.security.tls.eda }}
ssl_cert => "/run/secrets/eda-certificates/cert.pem"
ssl_key => "/run/secrets/eda-certificates/key.pem"
ssl_certificate_authorities => ["/run/secrets/eda-certificates/ca-cert.pem"]
ssl_enable => true
ssl_verify => true
{{- end }}
{{- end -}}

{{/*
Creating volume mount for TLS between LT and LS
Creating volumeMounts for Server certificate and Client CA certificate
*/}}
{{- define "eric-log-transformer.tls-volumemount" }}
- name: "server-certificate"
  mountPath: "/run/secrets/certificates/"
  readOnly: true
- name: "client-ca-certificate"
  mountPath: "/run/secrets/ca-certificates/"
  readOnly: true
{{- end -}}

{{/*
Create a map from testInternals with defaults if missing in values file.
This hides defaults from values file.
Version: 1.0
*/}}
{{ define "eric-log-transformer.testInternal" }}
  {{- $tiDefaults := (dict "env" (dict) ) -}}
  {{ if .Values.testInternal }}
    {{- mergeOverwrite $tiDefaults .Values.testInternal | toJson -}}
  {{ else }}
    {{- $tiDefaults | toJson -}}
  {{ end }}
{{ end }}

{{/*
Create a map from ".Values.global" with defaults if missing in values file.
This hides defaults from values file.
*/}}
{{ define "eric-log-transformer.global" }}
  {{- $globalDefaults := dict "security" (dict "tls" (dict "enabled" true)) -}}
  {{- $globalDefaults := merge $globalDefaults (dict "nodeSelector" (dict)) -}}
  {{- $globalDefaults := merge $globalDefaults (dict "registry" (dict "imagePullPolicy" "IfNotPresent")) -}}
  {{- $globalDefaults := merge $globalDefaults (dict "registry" (dict "url" "armdocker.rnd.ericsson.se")) -}}
  {{- $globalDefaults := merge $globalDefaults (dict "registry" (dict "pullSecret")) -}}
  {{- $globalDefaults := merge $globalDefaults (dict "pullSecret") -}}
  {{- $globalDefaults := merge $globalDefaults (dict "networkPolicy" (dict "enabled" false)) -}}
  {{- $globalDefaults := merge $globalDefaults (dict "timezone" "UTC") -}}
  {{- $globalDefaults := merge $globalDefaults (dict "internalIPFamily" "") -}}
  {{- $globalDefaults := merge $globalDefaults (dict "security" (dict "policyBinding" (dict "create" false))) -}}
  {{- $globalDefaults := merge $globalDefaults (dict "security" (dict "policyReferenceMap" (dict "default-restricted-security-policy" "default-restricted-security-policy"))) -}}
  {{ if .Values.global }}
    {{- mergeOverwrite $globalDefaults .Values.global | toJson -}}
  {{ else }}
    {{- $globalDefaults | toJson -}}
  {{ end }}
{{ end }}

{{/*
Deprecated settings.
*/}}
{{ define "eric-log-transformer.deprecated" }}
  {{- $deprecated := dict "security" (dict "tls" (dict "logshipper" (dict "enabled" false))) -}}
  {{- mergeOverwrite $deprecated .Values | toJson -}}
{{ end }}

{{/*
Deprecation notices
*/}}
{{- define "eric-log-transformer.deprecation-notices" -}}
  {{- $d := fromJson (include "eric-log-transformer.deprecated" .) -}}
  {{- if $d.security.tls.logshipper.enabled }}
    {{ printf "'security.tls.logshipper.enabled' is deprecated as of release 4.6.0" }}
  {{- end }}
{{- end }}

{{- define "eric-log-transformer.pod-anti-affinity" }}
affinity:
  podAntiAffinity:
  {{- if eq .Values.affinity.podAntiAffinity "hard" }}
    requiredDuringSchedulingIgnoredDuringExecution:
      - labelSelector:
          matchExpressions:
            - key: "app"
              operator: "In"
              values:
                - {{ include "eric-log-transformer.fullname" . | quote }}
        topologyKey: "kubernetes.io/hostname"
  {{- else if eq .Values.affinity.podAntiAffinity  "soft" }}
    preferredDuringSchedulingIgnoredDuringExecution:
      - weight: 100
        podAffinityTerm:
          labelSelector:
            matchExpressions:
              - key: "app"
                operator: "In"
                values:
                  - {{ include "eric-log-transformer.fullname" . | quote }}
          topologyKey: "kubernetes.io/hostname"
  {{- end -}}
{{- end -}}

{{/*
Returns the redirection method for stdout-redirect.
*/}}
{{ define "eric-log-transformer.redirection" }}
{{- $redirect := "stdout" }}
{{- if has "stream" .Values.log.outputs }}
  {{- $redirect = "file" }}
  {{- if has "stdout" .Values.log.outputs }}
    {{- $redirect = "all" }}
  {{- end }}
{{- end }}
{{- printf "%s" $redirect }}
{{- end -}}

{{/*
Create a merged set of nodeSelectors from global and service level.
*/}}
{{ define "eric-log-transformer.nodeSelector" }}
  {{- $g := fromJson (include "eric-log-transformer.global" .) -}}
  {{- $global := $g.nodeSelector -}}
  {{- $service := .Values.nodeSelector -}}
  {{- include "eric-log-transformer.aggregatedMerge" (dict "context" "nodeSelector" "location" .Template.Name "sources" (list $global $service)) }}
{{ end }}

{{/*
Create asymmetric-key-certificate-name for lumberjack output.
*/}}
{{- define "eric-log-transformer.lumberjack-output-asymmetric-cert" -}}
{{- printf "%s/%s" .Values.egress.lumberjack.certificates.asymmetricKeyCertificateName .Values.egress.lumberjack.certificates.asymmetricKeyCertificateName -}}
{{- end -}}

{{- define "eric-log-transformer.lumberjack-certificate-path" -}}
{{- if .Values.egress.lumberjack.certificates.asymmetricKeyCertificateName }}
  {{- printf "/run/secrets/lumberjackOutput-certs/tls.crt" -}}
{{- end }}
{{- if .Values.egress.lumberjack.certificates.trustedCertificateListName -}}
  {{- printf "/run/secrets/lumberjackOutput-cacerts/trustedcert" -}}
{{- end }}
{{- end -}}

{{- define "eric-log-transformer.total-queue-size" -}}
  {{- $sizePerPipeline := max 128 .Values.queue.sizePerPipeline -}}
  {{- $totalSize := add $sizePerPipeline 10 -}}
  {{- $totalSize = add $totalSize $sizePerPipeline -}}
  {{- if .Values.egress.syslog.enabled -}}
    {{- $totalSize = add $totalSize $sizePerPipeline -}}
  {{- end -}}
  {{- if .Values.egress.lumberjack.enabled -}}
    {{- range .Values.egress.lumberjack.remoteHosts -}}
      {{- $totalSize = add $totalSize $sizePerPipeline -}}
    {{- end }}
  {{- end -}}
  {{- if .Values.config.output -}}
    {{- range .Values.config.output -}}
      {{- $totalSize = add $totalSize $sizePerPipeline -}}
    {{- end -}}
  {{- end -}}
  {{- printf "%dMi" $totalSize -}}
{{- end -}}

{{- define "eric-log-transformer.logshipper-context" -}}
  {{- $logplane := default "adp-app-logs" .Values.log.logplane.default -}}
  {{- $transformer := dict "logplane" (default $logplane .Values.log.logplane.logtransformer) -}}
  {{- $transformer := merge $transformer (dict "multiline" (dict "pattern" "^(\\[[0-9]{4}-[0-9]{2}-[0-9]{2})|(\\{\"version)|(^[A-Z])")) -}}
  {{- $transformer := merge $transformer (dict "multiline" (dict "negate" "true")) -}}
  {{- $transformer := merge $transformer (dict "multiline" (dict "match" "after")) -}}
  {{- $transformer := merge $transformer (dict "subPaths" (list "logtransformer.log*")) -}}
  {{- $tlsproxy := dict "logplane" (default $logplane .Values.log.logplane.tlsproxy ) -}}
  {{- $tlsproxy := merge $tlsproxy (dict "subPaths" (list "tlsproxy.log*")) -}}
  {{- $metrics := dict "logplane" (default $logplane .Values.log.logplane.metrics) -}}
  {{- $metrics := merge $metrics (dict "subPaths" (list "metrics.log*")) -}}
  {{- $logshipperContext :=  (dict "Values" (dict "logshipper" (dict "storagePath" "/logs/"))) -}}
  {{- $logshipperContext := merge $logshipperContext (dict "Values" (dict "logshipper" (dict "logplane" .Values.log.logplane.default))) -}}
  {{- $logshipperContext := merge $logshipperContext (dict "Values" (dict "logshipper" (dict "storageAllocation" "123Mi"))) -}}
  {{- $logshipperContext := merge $logshipperContext (dict "Values" (dict "logshipper" (dict "harvester" (dict "closeTimeout" "5m")))) -}}
  {{- $logshipperContext := merge $logshipperContext (dict "Values" (dict "logshipper" (dict "harvester" (dict "logData" (list $transformer $tlsproxy $metrics))))) -}}
  {{- $logshipperContext := merge $logshipperContext (dict "Values" (dict "logshipper" (dict "logtransformer" (dict "host" "eric-log-transformer"))))  -}}
  {{- $logshipperContext | toJson -}}
{{ end }}

{{- define "eric-log-transformer.product-info" }}
ericsson.com/product-name: {{ (fromYaml (.Files.Get "eric-product-info.yaml")).productName | quote }}
ericsson.com/product-number: {{ (fromYaml (.Files.Get "eric-product-info.yaml")).productNumber | quote }}
ericsson.com/product-revision: {{ (split "-" (.Chart.Version | replace "+" "-" ))._0 | quote }}
{{- end}}

{{/*
Common annotations
*/}}
{{- define "eric-log-transformer.annotations" -}}
  {{- $productInfo := include "eric-log-transformer.product-info" . | fromYaml -}}
  {{- $globalAnn := (.Values.global).annotations -}}
  {{- $serviceAnn :=  .Values.annotations -}}
  {{- include "eric-log-transformer.mergeAnnotations" (dict "location" .Template.Name "sources" (list $productInfo $globalAnn $serviceAnn)) | trim }}
{{- end -}}

{{/*
Logshipper annotations
*/}}
{{- define "eric-log-transformer.logshipper-annotations" }}
{{- println "" -}}
{{- include "eric-log-transformer.annotations" . -}}
{{- end }}

{{ define "eric-log-transformer.metrics-path" }}
  {{- $productInfo := fromYaml (.Files.Get "eric-product-info.yaml") -}}
  {{- $g := fromJson (include "eric-log-transformer.global" .) -}}
  {{- $registryUrl := $g.registry.url | default $productInfo.images.metrics.registry -}}
  {{- $defaults := dict "imageCredentials" (dict "registry" (dict "url" $registryUrl)) -}}
  {{- $defaults := merge $defaults (dict "imageCredentials" (dict "repoPath" $productInfo.images.metrics.repoPath)) -}}
  {{- $defaults := merge $defaults (dict "images" (dict "metrics" (dict "name" $productInfo.images.metrics.name))) -}}
  {{- $defaults := merge $defaults (dict "images" (dict "metrics" (dict "tag" $productInfo.images.metrics.tag))) -}}
  {{- $defaults := mergeOverwrite $defaults .Values -}}
  {{- $registryUrl := $defaults.imageCredentials.registry.url -}}
  {{- $repoPath := $defaults.imageCredentials.repoPath -}}
  {{- $name := $defaults.images.metrics.name -}}
  {{- $tag := $defaults.images.metrics.tag -}}
  {{- printf "%s/%s/%s:%s" $registryUrl $repoPath $name $tag -}}
{{- end -}}

{{ define "eric-log-transformer.tlsproxy-path" }}
  {{- $productInfo := fromYaml (.Files.Get "eric-product-info.yaml") -}}
  {{- $g := fromJson (include "eric-log-transformer.global" .) -}}
  {{- $registryUrl := $g.registry.url | default $productInfo.images.tlsproxy.registry -}}
  {{- $defaults := dict "imageCredentials" (dict "registry" (dict "url" $registryUrl)) -}}
  {{- $defaults := merge $defaults (dict "imageCredentials" (dict "repoPath" $productInfo.images.tlsproxy.repoPath)) -}}
  {{- $defaults := merge $defaults (dict "images" (dict "tlsproxy" (dict "name" $productInfo.images.tlsproxy.name))) -}}
  {{- $defaults := merge $defaults (dict "images" (dict "tlsproxy" (dict "tag" $productInfo.images.tlsproxy.tag))) -}}
  {{- $defaults := mergeOverwrite $defaults .Values -}}
  {{- $registryUrl := $defaults.imageCredentials.registry.url -}}
  {{- $repoPath := $defaults.imageCredentials.repoPath -}}
  {{- $name := $defaults.images.tlsproxy.name -}}
  {{- $tag := $defaults.images.tlsproxy.tag -}}
  {{- printf "%s/%s/%s:%s" $registryUrl $repoPath $name $tag -}}
{{- end -}}

{{ define "eric-log-transformer.exclusion-filter-rules" }}
  {{- range $index, $exclusion := . }}
      {{- if $exclusion.logplane }}
        {{- if eq $index 0 }}
        if [logplane] == {{ $exclusion.logplane | quote }} {
        {{- else }}
        else if [logplane] == {{ $exclusion.logplane | quote }} {
        {{- end}}
      {{- end }}
        {{- range $i, $rules := .rules }}
          {{- if $rules.field }}
          {{- if eq $i 0 }}
            {{- if $rules.value }}
          if {{ $rules.field }} == {{ $rules.value | quote }} {
            {{- else if $rules.contains }}
          if {{ $rules.contains | quote }} in {{ $rules.field }} {
            {{- else if $rules.pattern }}
          if {{ $rules.field }}  =~ {{ $rules.pattern | squote }} {
            {{- end }}
          {{- else }}
            {{- if $rules.value }}
          else if {{ $rules.field }} == {{ $rules.value | quote }} {
            {{- else if $rules.contains }}
          else if {{ $rules.contains | quote }} in {{ $rules.field }} {
            {{- else if $rules.pattern }}
          else if {{ $rules.field }}  =~ {{ $rules.pattern | squote }} {
            {{- end }}
          {{- end }}
          {{- if or ($rules.value) ($rules.contains) ($rules.pattern) }}
            drop{}
          }
          {{- end }}
          {{- end }}
        {{- end }}
        {{- if $exclusion.logplane }}
        }
        {{- end }}
  {{- end }}
{{- end -}}

{{ define "eric-log-transformer.inclusion-filter-rules" }}
  {{- if .}}
    {{- range $i, $rules := . }}
      {{- if $rules.field }}
        {{- if eq $i 0 }}
           {{- if $rules.value }}
      if {{ $rules.field }} == {{ $rules.value | quote }}
           {{- else if $rules.contains }}
      if {{ $rules.contains | quote }} in {{ $rules.field }}
           {{- else if $rules.pattern }}
      if {{ $rules.field }} =~ {{ $rules.pattern | squote }}
           {{- end }}
        {{- else }}
           {{- if $rules.value }}
      or {{ $rules.field }} == {{ $rules.value | quote }}
           {{- else if $rules.contains }}
      or {{ $rules.contains | quote }} in {{ $rules.field }}
           {{- else if $rules.pattern }}
      or {{ $rules.field }} =~ {{ $rules.pattern | squote }}
           {{- end }}
        {{- end}}
      {{- end}}
    {{- end}}
      {
  {{- end}}
{{- end -}}

{{/*
Get the pm metrics port.
*/}}
{{- define "eric-log-transformer-pm-server-port" -}}
  {{- $g := fromJson (include "eric-log-transformer.global" .) -}}
  {{- if $g.security.tls.enabled -}}
    9115
  {{- else -}}
    9114
  {{- end -}}
{{- end -}}

{{/*
   Get the pm metrics host name
*/}}
{{- define "eric-log-transformer-pm-server-hostname" -}}
  {{ .Values.metrics.pmServer }}
{{- end -}}

{{/*
Get the ls daemon port and ls sidecar port
*/}}
{{- define "eric-log-transformer-ls-port" -}}
  {{- $g := fromJson (include "eric-log-transformer.global" .) -}}
  {{- if $g.security.tls.enabled -}}
    5044
  {{- else -}}
    5045
  {{- end -}}
{{- end -}}

{{/*
   Get the ls daemon host name
*/}}
{{- define "eric-log-transformer-ls-hostname" -}}
  {{ .Values.logshipper.hostname }}
{{- end -}}

{{/*
Get the syslog server port.
*/}}
{{- define "eric-log-transformer-syslog-server-port" -}}
  {{- $g := fromJson (include "eric-log-transformer.global" .) -}}
  {{- if $g.security.tls.enabled -}}
    5015
  {{- else -}}
    5014
  {{- end -}}
{{- end -}}

{{/*
Get the json input port.
*/}}
{{- define "eric-log-transformer-json-input-port" -}}
  {{- $g := fromJson (include "eric-log-transformer.global" .) -}}
  {{- if $g.security.tls.enabled -}}
    5024
  {{- else -}}
    5025
  {{- end -}}
{{- end -}}

{{/*
Get the http input port.
*/}}
{{- define "eric-log-transformer-http-input-port" -}}
  {{- $g := fromJson (include "eric-log-transformer.global" .) -}}
  {{- if $g.security.tls.enabled -}}
    9443
  {{- else -}}
    9080
  {{- end -}}
{{- end -}}

{/*
eric-log-transformer Labels for Network Policies
*/}}
{{- define "eric-log-transformer.peer.labels" -}}
  {{- if (has "stream" .Values.log.outputs) -}}
    eric-log-transformer-access: "true"
  {{- end -}}
{{- end -}}

{{/*
Define eric-log-transformer.appArmorProfileAnnotation
*/}}
{{- define "eric-log-transformer.appArmorProfileAnnotation" -}}
{{- $containerList := list "logtransformer" -}}
{{- $g := fromJson (include "eric-log-transformer.global" .) -}}
{{- if and .Values.metrics.enabled $g.security.tls.enabled -}}
  {{- $containerList = append $containerList "metrics" -}}
  {{- $containerList = append $containerList "tlsproxy" -}}
{{- end -}}
{{- if (has "stream" .Values.log.outputs) -}}
  {{- $containerList = append $containerList "logshipper" -}}
{{- end -}}
{{- $acceptedProfiles := list "unconfined" "runtime/default" "localhost" }}
{{- $commonProfile := dict -}}
{{- if .Values.appArmorProfile.type -}}
  {{- $_ := set $commonProfile "type" .Values.appArmorProfile.type -}}
  {{- if and (eq .Values.appArmorProfile.type "localhost") .Values.appArmorProfile.localhostProfile -}}
    {{- $_ := set $commonProfile "localhostProfile" .Values.appArmorProfile.localhostProfile -}}
  {{- end -}}
{{- end -}}
{{- $profiles := dict -}}
{{- range $container := $containerList -}}
  {{- if and (hasKey $.Values.appArmorProfile $container) (index $.Values.appArmorProfile $container "type") -}}
    {{- $_ := set $profiles $container (index $.Values.appArmorProfile $container) -}}
  {{- else -}}
    {{- $_ := set $profiles $container $commonProfile -}}
  {{- end -}}
{{- end -}}
{{- range $key, $value := $profiles -}}
  {{- if $value.type -}}
    {{- if not (has $value.type $acceptedProfiles) -}}
      {{- fail (printf "Unsupported appArmor profile type: %s, use one of the supported profiles %s" $value.type $acceptedProfiles) -}}
    {{- end -}}
    {{- if and (eq $value.type "localhost") (empty $value.localhostProfile) -}}
      {{- fail "The 'localhost' appArmor profile requires a profile name to be provided in localhostProfile parameter." -}}
    {{- end }}
container.apparmor.security.beta.kubernetes.io/{{ $key }}: {{ $value.type }}{{ eq $value.type "localhost" | ternary (printf "/%s" $value.localhostProfile) ""  }}
  {{- end -}}
{{- end -}}
{{- end }}

{{/*
Define eric-log-transformer.podSeccompProfile
*/}}
{{- define "eric-log-transformer.podSeccompProfile" -}}
{{- if and .Values.seccompProfile .Values.seccompProfile.type }}
seccompProfile:
  type: {{ .Values.seccompProfile.type }}
  {{- if eq .Values.seccompProfile.type "Localhost" }}
  localhostProfile: {{ .Values.seccompProfile.localhostProfile }}
  {{- end }}
{{- end }}
{{- end -}}

{{/*
Define eric-log-transformer.contLtSeccompProfile
*/}}
{{- define "eric-log-transformer.contLtSeccompProfile" -}}
{{- if and .Values.seccompProfile.logtransformer .Values.seccompProfile.logtransformer.type }}
seccompProfile:
  type: {{ .Values.seccompProfile.logtransformer.type }}
  {{- if eq .Values.seccompProfile.logtransformer.type "Localhost" }}
  localhostProfile: {{ .Values.seccompProfile.logtransformer.localhostProfile }}
  {{- end }}
{{- end }}
{{- end -}}

{{/*
Define eric-log-transformer.contMetricsSeccompProfile
*/}}
{{- define "eric-log-transformer.contMetricsSeccompProfile" -}}
{{- if and .Values.seccompProfile.metrics .Values.seccompProfile.metrics.type }}
seccompProfile:
  type: {{ .Values.seccompProfile.metrics.type }}
  {{- if eq .Values.seccompProfile.metrics.type "Localhost" }}
  localhostProfile: {{ .Values.seccompProfile.metrics.localhostProfile }}
  {{- end }}
{{- end }}
{{- end -}}

{{/*
Define eric-log-transformer.contTlsproxySeccompProfile
*/}}
{{- define "eric-log-transformer.contTlsproxySeccompProfile" -}}
{{- if and .Values.seccompProfile.tlsproxy .Values.seccompProfile.tlsproxy.type }}
seccompProfile:
  type: {{ .Values.seccompProfile.tlsproxy.type }}
  {{- if eq .Values.seccompProfile.tlsproxy.type "Localhost" }}
  localhostProfile: {{ .Values.seccompProfile.tlsproxy.localhostProfile }}
  {{- end }}
{{- end }}
{{- end -}}
