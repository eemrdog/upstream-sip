{{/* vim: set filetype=mustache: */}}
{{- define "eric-fh-alarm-handler.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create chart version as used by the kubernetes label.
*/}}
{{- define "eric-fh-alarm-handler.version" -}}
{{- printf "%s" .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "eric-fh-alarm-handler.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Standard labels of Helm and Kubernetes
*/}}
{{- define "eric-fh-alarm-handler.standard-labels" -}}
app: {{ template "eric-fh-alarm-handler.name" . }}
chart: {{ template "eric-fh-alarm-handler.chart" . }}
release: {{ .Release.Name | quote }}
heritage: {{ .Release.Service }}
app.kubernetes.io/name: {{ template "eric-fh-alarm-handler.name" . }}
app.kubernetes.io/version: {{ template "eric-fh-alarm-handler.version" . }}
app.kubernetes.io/instance: {{ .Release.Name | quote }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end -}}

{{/*
Common labels and custom labels set in values.labels
*/}}
{{- define "eric-fh-alarm-handler.labels" }}
  {{- $standard := include "eric-fh-alarm-handler.standard-labels" . | fromYaml -}}
  {{- $global := (.Values.global).labels -}}
  {{- $service := .Values.labels -}}
  {{- include "eric-fh-alarm-handler.mergeLabels" (dict "location" .Template.Name "sources" (list $standard $global $service)) }}
{{- end -}}

{{/*
Labels for services who support DR-D1125-054
*/}}
{{- define "eric-fh-alarm-handler.ingressAccess.labels" -}}
{{- $g := fromJson (include "eric-fh-alarm-handler.global" .) -}}
{{- $authorizationProxy := fromJson (include "eric-fh-alarm-handler.authz-proxy-values" .) -}}
{{- $redisWriterEnabled := include "eric-fh-alarm-handler.redisAsiWriterEnabled" . -}}
{{- $kafkaEnabled := include "eric-fh-alarm-handler.kafkaEnabled" . -}}
{{ .Values.backend.hostname }}-access: "true"
{{- if eq $redisWriterEnabled "true" }}
{{ .Values.redis.hostname }}-access: "true"
{{- end -}}
{{- if eq $kafkaEnabled "true" }}
{{ .Values.kafka.serviceName }}-access: "true"
{{- end }}
{{- if and $authorizationProxy.enabled .Values.ingress.enabled }}
{{ printf "%s: %q" (include "eric-fh-alarm-handler.authz-proxy-iam-access-label" .) "true" }}
{{- end -}}
{{- if or (has "stream" .Values.log.outputs) (has "applicationLevel" $g.log.outputs) }}
{{ .Values.logshipper.logTransformer.host }}-access: "true"
{{- end }}
{{- end -}}

{{/*
Logshipper labels
*/}}
{{- define "eric-fh-alarm-handler.logshipper-labels" }}
{{- include "eric-fh-alarm-handler.labels" . -}}
{{- end }}

{{/*
Ericsson product information
The annotations are compliant with: DR-HC-064
*/}}
{{- define "eric-fh-alarm-handler.product-info" }}
ericsson.com/product-name: {{ (fromYaml (.Files.Get "eric-product-info.yaml")).productName | quote }}
ericsson.com/product-number: {{ (fromYaml (.Files.Get "eric-product-info.yaml")).productNumber | quote }}
ericsson.com/product-revision: {{ regexReplaceAll "[\\-\\+].+" .Chart.Version "${1}" }}
{{- end -}}

{{/*
Custom annotations set by application engineer
*/}}
{{- define "eric-fh-alarm-handler.custom-annotations" }}
  {{- $global := (.Values.global).annotations -}}
  {{- $service := .Values.annotations -}}
  {{- include "eric-fh-alarm-handler.mergeAnnotations" (dict "location" .Template.Name "sources" (list $global $service)) }}
{{- end -}}

{{/*
Annotations containing both product info and custom annotations
*/}}
{{- define "eric-fh-alarm-handler.annotations" }}
  {{- $productInfoAnnotations := include "eric-fh-alarm-handler.product-info" . | fromYaml -}}
  {{- $customAnnotations := include "eric-fh-alarm-handler.custom-annotations" . | fromYaml -}}
  {{- $roleBindingAnnotations := include "eric-fh-alarm-handler.roleBinding.annotations" . | fromYaml -}}
  {{- include "eric-fh-alarm-handler.mergeAnnotations" (dict "location" .Template.Name "sources" (list $productInfoAnnotations $customAnnotations $roleBindingAnnotations)) }}
{{- end -}}

{{/*
Logshipper annotations
*/}}
{{- define "eric-fh-alarm-handler.logshipper-annotations" }}
{{- include "eric-fh-alarm-handler.annotations" . -}}
{{- end }}

{{/*
Annotations for security-policy
*/}}
{{- define "eric-fh-alarm-handler.roleBinding.annotations" }}
ericsson.com/security-policy.type: "restricted/default"
ericsson.com/security-policy.capabilities: ""
{{- end -}}

{{/*
Annotations for metrics for pm server to scrape
Add prometheus.io/scrape: "true" if this is not added via _auth-proxy-helpers.tpl
Use prometheus.io/port2 instead of prometheus.io/port since this is already defined in _auth-proxy-helpers.tpl
*/}}
{{- define "eric-fh-alarm-handler.metrics.annotations" }}
{{- $metricsEnabled := ( .Values.service.endpoints.metrics.enabled | toString | lower) -}}
{{- $metricsTLSOnly := (include "eric-fh-alarm-handler.metrics.server.tlsOnly" .) -}}
{{- $tls := (include "eric-fh-alarm-handler.tls.enabled" .) -}}
{{- $authorizationProxy := fromJson (include "eric-fh-alarm-handler.authz-proxy-values" .) -}}
{{- if eq $metricsEnabled "true" }}
{{- if eq ($authorizationProxy.metrics.enabled | toString) "false" }}
prometheus.io/scrape: "true"
{{- end }}
prometheus.io/port2: {{ include "eric-fh-alarm-handler.metrics.port" . | quote }}
{{- end }}
{{- end -}}

{{/*
App armor annotations for eric-fh-alarm-handler, logshipper, and topic-creator.
NOTE: This implements DR-D1123-127 for the LS sidecar
*/}}
{{- define "eric-fh-alarm-handler.appArmorProfileAnnotations" -}}
{{- $acceptedProfiles := list "unconfined" "runtime/default" "localhost" }}
{{- $commonProfile := dict -}}
{{- if .Values.appArmorProfile.type -}}
  {{- $_ := set $commonProfile "type" .Values.appArmorProfile.type -}}
  {{- if and (eq .Values.appArmorProfile.type "localhost") .Values.appArmorProfile.localhostProfile -}}
    {{- $_ := set $commonProfile "localhostProfile" .Values.appArmorProfile.localhostProfile -}}
  {{- end -}}
{{- end -}}
{{- $containers := list "alarmHandler" "topiccreator" -}}
{{- if has "stream" .Values.log.outputs -}}
  {{- $containers = append $containers "logshipper" -}}
{{- end -}}
{{- $profiles := dict -}}
{{- range $container := $containers -}}
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
    {{- if eq $key "alarmHandler" -}}
      {{- $key = "eric-fh-alarm-handler" -}}
    {{- else if eq $key "topiccreator" -}}
      {{- $key = "topic-creator" -}}
    {{- end }}
    {{- if eq $value.type "localhost" }}
      {{- $localhostProfileList := splitList "/" $value.localhostProfile -}}
      {{- if last $localhostProfileList }}
container.apparmor.security.beta.kubernetes.io/{{ $key }}: "localhost/{{ last $localhostProfileList }}"
      {{- end }}
    {{- else }}
container.apparmor.security.beta.kubernetes.io/{{ $key }}: {{ $value.type }}
    {{- end }}
  {{- end -}}
{{- end -}}
{{- end -}}

{{/*
Create a map from ".Values.global" with defaults if missing in values file.
This hides defaults from values file.
*/}}
{{ define "eric-fh-alarm-handler.global" }}
  {{- $globalDefaults := dict "security" (dict "tls" (dict "enabled" true)) -}}
  {{- $globalDefaults := merge $globalDefaults (dict "security" (dict "policyBinding" (dict "create" false))) -}}
  {{- $globalDefaults := merge $globalDefaults (dict "security" (dict "policyReferenceMap" (dict "default-restricted-security-policy" "default-restricted-security-policy"))) -}}
  {{- $globalDefaults := merge $globalDefaults (dict "nodeSelector" (dict)) -}}
  {{- $globalDefaults := merge $globalDefaults (dict "networkPolicy" (dict "enabled" false)) -}}
  {{- $globalDefaults := merge $globalDefaults (dict "timezone" "UTC") -}}
  {{- $globalDefaults := merge $globalDefaults (dict "registry" (dict "url" "armdocker.rnd.ericsson.se")) -}}
  {{- $globalDefaults := merge $globalDefaults (dict "registry" (dict "pullSecret" (dict))) -}}
  {{- $globalDefaults := merge $globalDefaults (dict "log" (dict "outputs" (list "k8sLevel"))) -}}
  {{ if .Values.global }}
    {{- mergeOverwrite $globalDefaults .Values.global | toJson -}}
  {{ else }}
    {{- $globalDefaults | toJson -}}
  {{ end }}
{{ end }}

{{/*
Verifies TLS is enabled globally
*/}}
{{- define "eric-fh-alarm-handler.tls.enabled" -}}
{{- $g := fromJson (include "eric-fh-alarm-handler.global" .) -}}
{{- $g.security.tls.enabled | toString | lower }}
{{- end -}}

{{/*
If network policies are enabled
*/}}
{{- define "eric-fh-alarm-handler.networkpolicies.enabled" -}}
{{- $g := fromJson (include "eric-fh-alarm-handler.global" .) -}}
{{- and $g.networkPolicy.enabled .Values.networkPolicy.enabled }}
{{- end -}}

{{/*
The eric-fh-alarm-handler image path (DR-D1121-067)
*/}}
{{- define "eric-fh-alarm-handler.imagePath" }}
    {{- $productInfo := fromYaml (.Files.Get "eric-product-info.yaml") -}}
    {{- $registryUrl := index $productInfo "images" "alarmhandler" "registry" -}}
    {{- $repoPath := index $productInfo "images" "alarmhandler" "repoPath" -}}
    {{- $name := index $productInfo "images" "alarmhandler" "name" -}}
    {{- $tag := index $productInfo "images" "alarmhandler" "tag" -}}
    {{- if .Values.global -}}
        {{- if .Values.global.registry -}}
            {{- if .Values.global.registry.url -}}
                {{- $registryUrl = .Values.global.registry.url -}}
            {{- end -}}
        {{- end -}}
    {{- end -}}
    {{- if .Values.imageCredentials -}}
        {{- if index .Values "imageCredentials" "alarmhandler" -}}
            {{- if index .Values "imageCredentials" "alarmhandler" "registry" -}}
                {{- if index .Values "imageCredentials" "alarmhandler" "registry" "url" -}}
                    {{- $registryUrl = index .Values "imageCredentials" "alarmhandler" "registry" "url" -}}
                {{- end -}}
            {{- end -}}
            {{- if not (kindIs "invalid" (index .Values "imageCredentials" "alarmhandler" "repoPath")) -}}
                {{- $repoPath = index .Values "imageCredentials" "alarmhandler" "repoPath" -}}
            {{- end -}}
        {{- end -}}
        {{- if index .Values "imageCredentials" "eric-fh-alarm-handler" -}}
            {{- if index .Values "imageCredentials" "eric-fh-alarm-handler" "registry" -}}
                {{- if index .Values "imageCredentials" "eric-fh-alarm-handler" "registry" "url" -}}
                    {{- $registryUrl = index .Values "imageCredentials" "eric-fh-alarm-handler" "registry" "url" -}}
                {{- end -}}
            {{- end -}}
            {{- if not (kindIs "invalid" (index .Values "imageCredentials" "eric-fh-alarm-handler" "repoPath")) -}}
                {{- $repoPath = index .Values "imageCredentials" "eric-fh-alarm-handler" "repoPath" -}}
            {{- end -}}
        {{- end -}}
    {{- end -}}
    {{- if $repoPath -}}
        {{- $repoPath = printf "%s/" $repoPath -}}
    {{- end -}}
    {{- printf "%s/%s%s:%s" $registryUrl $repoPath $name $tag -}}
{{- end -}}

{{/*
Create resources fragment.
*/}}
{{- define "eric-fh-alarm-handler.resources.alarmhandler" -}}
{{- $resources := index .Values "resources" "alarmhandler" -}}
{{- toYaml $resources -}}
{{- end -}}

{{/*
Create image pull secret
*/}}
{{- define "eric-fh-alarm-handler.pullSecrets" -}}
{{- $pullSecret := "" -}}
{{- if .Values.global -}}
    {{- if .Values.global.pullSecret -}}
            {{- $pullSecret = .Values.global.pullSecret -}}
    {{- end -}}
{{- end -}}
{{- if .Values.imageCredentials -}}
    {{- if .Values.imageCredentials.pullSecret -}}
            {{- $pullSecret = .Values.imageCredentials.pullSecret -}}
    {{- end -}}
{{- end -}}
{{- print $pullSecret -}}
{{- end -}}

{{/*
Create pull policy for eric-fh-alarm-handler
*/}}
{{- define "eric-fh-alarm-handler.ImagePullPolicy" -}}
{{- $imagePullPolicy := "IfNotPresent" -}}
{{- if .Values.global -}}
    {{- if .Values.global.registry -}}
        {{- if .Values.global.registry.imagePullPolicy -}}
            {{- $imagePullPolicy = .Values.global.registry.imagePullPolicy -}}
        {{- end -}}
    {{- end -}}
{{- end -}}
{{- if .Values.imageCredentials -}}
    {{- if index .Values "imageCredentials" "alarmhandler" "registry" -}}
        {{- if index .Values "imageCredentials" "alarmhandler" "registry" "imagePullPolicy" -}}
            {{- $imagePullPolicy = index .Values "imageCredentials" "alarmhandler" "registry" "imagePullPolicy" -}}
        {{- end -}}
    {{- end -}}
{{- if index .Values "imageCredentials" "eric-fh-alarm-handler" -}}
        {{- if index .Values "imageCredentials" "eric-fh-alarm-handler" "registry" -}}
            {{- if index .Values "imageCredentials" "eric-fh-alarm-handler" "registry" "imagePullPolicy" -}}
                {{- $imagePullPolicy = index .Values "imageCredentials" "eric-fh-alarm-handler" "registry" "imagePullPolicy" -}}
            {{- end -}}
        {{- end -}}
    {{- end -}}
{{- end -}}
{{- print $imagePullPolicy -}}
{{- end -}}

{{/*
Define timezone
*/}}
{{- define "eric-fh-alarm-handler.timezone" -}}
{{- $timezone := "UTC" -}}
{{- if .Values.global -}}
    {{- if .Values.global.timezone -}}
        {{- $timezone = .Values.global.timezone -}}
    {{- end -}}
{{- end -}}
{{- print $timezone | quote -}}
{{- end -}}

{{/*
Define seccompprofile for the entire AH pod
NOTE: This partially implements DR-D1123-128 for the LS sidecar
*/}}
{{- define "eric-fh-alarm-handler.podSeccompProfile" -}}
{{- if and .Values.seccompProfile .Values.seccompProfile.type -}}
seccompProfile:
  type: {{ .Values.seccompProfile.type }}
{{- if eq .Values.seccompProfile.type "Localhost" }}
  localhostProfile: {{ .Values.seccompProfile.localhostProfile  }}
{{- end -}}
{{- end -}}
{{- end -}}

{{/*
Define seccompProfile for topic creator
*/}}
{{- define "eric-fh-alarm-handler.topicCreator.seccompProfile" -}}
{{- if .Values.seccompProfile -}}
{{- if and .Values.seccompProfile.topiccreator .Values.seccompProfile.topiccreator.type }}
seccompProfile:
  type: {{ .Values.seccompProfile.topiccreator.type }}
{{- if eq .Values.seccompProfile.topiccreator.type "Localhost" }}
  localhostProfile: {{ .Values.seccompProfile.topiccreator.localhostProfile }}
{{- end -}}
{{- end -}}
{{- end -}}
{{- end -}}

{{/*
Define seccompProfile for alarm handler
*/}}
{{- define "eric-fh-alarm-handler.alarmHandler.seccompProfile" -}}
{{- if .Values.seccompProfile -}}
{{- if and .Values.seccompProfile.alarmHandler .Values.seccompProfile.alarmHandler.type }}
seccompProfile:
  type: {{ .Values.seccompProfile.alarmHandler.type }}
{{- if eq .Values.seccompProfile.alarmHandler.type "Localhost" }}
  localhostProfile: {{ .Values.seccompProfile.alarmHandler.localhostProfile }}
{{- end -}}
{{- end -}}
{{- end -}}
{{- end -}}

{{/*
Define nodeSelector
*/}}
{{- define "eric-fh-alarm-handler.nodeSelector" -}}
  {{- $global := (.Values.global).nodeSelector -}}
  {{- $service := .Values.nodeSelector -}}
  {{- $context := "eric-fh-alarm-handler.nodeSelector" -}}
  {{- include "eric-fh-alarm-handler.aggregatedMerge" (dict "context" $context "location" .Template.Name "sources" (list $service $global)) | trim -}}
{{- end -}}

{{/*
Define podAntiAffinity
*/}}
{{- define "eric-fh-alarm-handler.podAntiAffinity" -}}
{{- if eq .Values.affinity.podAntiAffinity "hard" -}}
requiredDuringSchedulingIgnoredDuringExecution:
- labelSelector:
    matchExpressions:
    - key: app
      operator: In
      values:
      - {{ template "eric-fh-alarm-handler.name" . }}
  topologyKey: "kubernetes.io/hostname"
{{- else if eq .Values.affinity.podAntiAffinity "soft" -}}
preferredDuringSchedulingIgnoredDuringExecution:
- weight: 100
  podAffinityTerm:
    labelSelector:
      matchExpressions:
      - key: app
        operator: In
        values:
        - {{ template "eric-fh-alarm-handler.name" . }}
    topologyKey: "kubernetes.io/hostname"
{{- end -}}
{{- end -}}

{{/* Folder where the fault alarm mapping will be */}}
{{- define "eric-fh-alarm-handler.faultmappings.mountFolder" }}
    {{- printf "%s" "/etc/faultmappings" -}}
{{- end }}

{{- define "eric-fh-alarm-handler.rootFolder" }}
    {{- printf "%s" "/" -}}
{{- end }}

{{/* Name of log level config map */}}
{{- define "eric-fh-alarm-handler.logLevel.ConfigmapName" }}
    {{- template "eric-fh-alarm-handler.name" . }}-loglevel
{{- end }}

{{/* Folder where the log level configmap will be mounted */}}
{{- define "eric-fh-alarm-handler.loglevel.mountFolder" }}
    {{- printf "%s" "/home/service/log" -}}
{{- end }}

{{/* Set KAFKA_ASI_WRITER_ENABLED based on the value of alarmhandler.asi.writer */}}
{{- define "eric-fh-alarm-handler.kafkaAsiWriterEnabled" }}
    {{- eq (.Values.alarmhandler.asi.writer | toString | lower ) "kafka" -}}
{{- end }}

{{/* Set REDIS_WRITER_ENABLED based on the value of alarmhandler.asi.writer */}}
{{- define "eric-fh-alarm-handler.redisAsiWriterEnabled" }}
    {{- eq (.Values.alarmhandler.asi.writer | toString | lower ) "redis" -}}
{{- end }}

{{/* Set KAFKA_ENABLED to true if alamhandler.asi.writer=kafka or kafka.fiReaderEnabled is set to true*/}}
{{- define "eric-fh-alarm-handler.kafkaEnabled" }}
    {{- (or (eq (.Values.kafka.fiReaderEnabled | toString ) "true") (eq (include "eric-fh-alarm-handler.kafkaAsiWriterEnabled" .) "true")) -}}
{{- end }}

{{/*----------------------------------------------------------------*/}}
{{/*-----Methods for logging and log redirection--------------------*/}}
{{/*----------------------------------------------------------------*/}}

{{/*
Define filepath to file which will be watched for log level changes
*/}}
{{- define "eric-fh-alarm-handler.logcontrol" -}}
{{- print "/home/service/logcontrol.json" | quote -}}
{{- end -}}

{{/*
Define logRedirect
Mapping between log.outputs and logshipper redirect parameter
*/}}
{{- define "eric-fh-alarm-handler.logRedirect" -}}
{{- $logRedirect := "file" -}}
{{- if .Values.log -}}
        {{- if .Values.log.outputs -}}
            {{- if (and (has "stream" .Values.log.outputs) (has "stdout" .Values.log.outputs)) -}}
                {{- $logRedirect = "all" -}}
            {{- else if (and (not (has "stream" .Values.log.outputs)) (has "stdout" .Values.log.outputs)) -}}
                {{- $logRedirect = "stdout" -}}
            {{- end -}}
        {{- end -}}
{{- end -}}
{{- print $logRedirect -}}
{{- end -}}

{{/*
Define logOutputsBoth
Env variable used when both stdout and stream outputs should be used
*/}}
{{- define "eric-fh-alarm-handler.logOutputsBoth" -}}
{{- $logOutputsBoth := "false" -}}
{{- if .Values.log -}}
        {{- if .Values.log.outputs -}}
            {{- if (and (has "stream" .Values.log.outputs) (has "stdout" .Values.log.outputs)) -}}
                {{- $logOutputsBoth = "true" -}}
            {{- end -}}
        {{- end -}}
{{- end -}}
{{- print $logOutputsBoth -}}
{{- end -}}

{{/*----------------------------------------------------------------*/}}
{{/*-----Methods for defining security policies---------------------*/}}
{{/*----------------------------------------------------------------*/}}

{{- define "eric-fh-alarm-handler.securityPolicy.reference" -}}
{{- $g := fromJson (include "eric-fh-alarm-handler.global" .) }}
{{- $policyName := "" -}}
    {{- if $g.security -}}
        {{- if $g.security.policyReferenceMap -}}
            {{- if index $g "security" "policyReferenceMap" "default-restricted-security-policy" -}}
                {{ $policyName = index $g "security" "policyReferenceMap" "default-restricted-security-policy" }}
            {{- end -}}
        {{- end -}}
    {{- end -}}
{{- $policyName := default "default-restricted-security-policy" $policyName -}}
{{- $policyName -}}
{{- end -}}

{{/*----------------------------------------------------------------*/}}
{{/*-----Templates for ingress--------------------------------------*/}}
{{/*----------------------------------------------------------------*/}}

{{/*
Backend for the nginx ingress, dependent on which API version is used,
and if global tls is enabled.
*/}}
{{- define "eric-fh-alarm-handler.ingress.backend" -}}
{{- $g := fromJson (include "eric-fh-alarm-handler.global" .) }}
{{- if .Capabilities.APIVersions.Has "networking.k8s.io/v1/Ingress" -}}
backend:
  service:
    name: {{ include "eric-fh-alarm-handler.name" . }}
    port:
{{- if $g.security.tls.enabled }}
      number: {{ include "eric-fh-alarm-handler.restapi.server.tls.port" . }}
{{- else }}
      number: {{ include "eric-fh-alarm-handler.restapi.server.port" . }}
{{- end -}}
{{- else if .Capabilities.APIVersions.Has "networking.k8s.io/v1beta1" -}}
backend:
  serviceName: {{ include "eric-fh-alarm-handler.name" . }}
{{- if $g.security.tls.enabled }}
  servicePort: {{ include "eric-fh-alarm-handler.restapi.server.tls.port" . }}
{{- else }}
  servicePort: {{ include "eric-fh-alarm-handler.restapi.server.port" . }}
{{- end -}}
{{- else -}}
{{- printf "Neither 'networking.k8s.io/v1' nor 'networking.k8s.io/v1beta1' are found, no api available for creating Ingress." | fail -}}
{{- end -}}
{{- end -}}

{{/*
Annotations for TLS settings between the nginx ingress and the Alarm Handler service.
*/}}
{{- define "eric-fh-alarm-handler.ingress.tls.annotations" }}
{{- $g := fromJson (include "eric-fh-alarm-handler.global" .) }}
{{- if $g.security.tls.enabled -}}
nginx.ingress.kubernetes.io/backend-protocol: "HTTPS"
{{- else -}}
nginx.ingress.kubernetes.io/backend-protocol: "HTTP"
{{- end }}
{{- end }}

{{/*
Annotations for validating the external client from the nginx ingress.
*/}}
{{- define "eric-fh-alarm-handler.ingress.clientverification.annotations" }}
{{- $g := fromJson (include "eric-fh-alarm-handler.global" .) }}
{{- if $g.security.tls.enabled -}}
{{- if eq .Values.ingress.tls.verifyClientCertificate true -}}
nginx.ingress.kubernetes.io/auth-tls-verify-client: "on"
nginx.ingress.kubernetes.io/auth-tls-secret: {{ .Values.ingress.certificates.caSecret | default (printf "%s-external-ca-certificate-secret" (include "eric-fh-alarm-handler.name" .)) | quote }}
{{- else -}}
nginx.ingress.kubernetes.io/auth-tls-verify-client: "off"
{{- end }}
{{- end }}
{{- end }}

{{/*
API version to use in ingress depending on K8s version.
*/}}
{{ define "eric-fh-alarm-handler.ingress.apiversion" }}
{{- if .Capabilities.APIVersions.Has "networking.k8s.io/v1/Ingress" -}}
networking.k8s.io/v1
{{- else if .Capabilities.APIVersions.Has "networking.k8s.io/v1beta1" -}}
networking.k8s.io/v1beta1
{{- else -}}
{{- printf "Neither 'networking.k8s.io/v1' nor 'networking.k8s.io/v1beta1' are found, no api available for creating Ingress." | fail -}}
{{- end }}
{{- end -}}

{{/*----------------------------------------------------------------*/}}
{{/*-----Templates for metrics--------------------------------------*/}}
{{/*----------------------------------------------------------------*/}}

{{/* Metrics server listening port */}}
{{- define "eric-fh-alarm-handler.metrics.port" }}
    {{- .Values.service.endpoints.metrics.port -}}
{{- end }}

{{/* Checks if the metrics server is enabled */}}
{{- define "eric-fh-alarm-handler.metrics.server.enabled" }}
    {{- .Values.service.endpoints.metrics.enabled -}}
{{- end }}

{{/* Checks if the TLS is required for the metrics server */}}
{{- define "eric-fh-alarm-handler.metrics.server.tlsOnly" }}
{{- eq .Values.service.endpoints.metrics.tls.enforced "required" -}}
{{- end }}

{{/* Checks if the metrics server needs to verify the clients */}}
{{- define "eric-fh-alarm-handler.metrics.server.tls.verifyClientCertificate" }}
{{- eq .Values.service.endpoints.metrics.tls.verifyClientCertificate "required" -}}
{{- end }}

{{/* PM Server client subject alternative name */}}
{{- define "eric-fh-alarm-handler.metrics.client.subAltNameDN" }}
    {{- printf "%s" "certified-scrape-target" -}}
{{- end }}

{{/* Metrics port name */}}
{{- define "eric-fh-alarm-handler.metrics.portName" }}
{{- $metricsTLSOnly := (include "eric-fh-alarm-handler.metrics.server.tlsOnly" .) -}}
{{- $tls := (include "eric-fh-alarm-handler.tls.enabled" .) -}}
{{- if and (eq $tls "true") (eq $metricsTLSOnly "true") }}
        {{- printf "%s" "metric-port-tls" -}}
{{- else }}
        {{- printf "%s" "metric-port" -}}
{{- end }}
{{- end }}

{{/*----------------------------------------------------------------*/}}
{{/*-----Templates for probes---------------------------------------*/}}
{{/*----------------------------------------------------------------*/}}

{{/* Probes server listening port */}}
{{- define "eric-fh-alarm-handler.probes.port" }}
    {{- printf "%d" 7000 -}}
{{- end }}

{{/* K8s client probes scheme HTTP | HTTPS */}}
{{- define "eric-fh-alarm-handler.probes.scheme" }}
{{- $tls := (include "eric-fh-alarm-handler.tls.enabled" .) -}}
{{- if (eq $tls "true") }}
    {{- printf "%s" "HTTPS" -}}
{{- else }}
    {{- printf "%s" "HTTP" -}}
{{- end }}
{{- end }}

{{/* Checks if the TLS is required for the probes server */}}
{{- define "eric-fh-alarm-handler.probes.server.tlsOnly" }}
{{- eq .Values.service.endpoints.probes.tls.enforced "required" -}}
{{- end }}

{{/*----------------------------------------------------------------*/}}
{{/*-----Templates for AAL rest API----------------------------------*/}}
{{/*----------------------------------------------------------------*/}}

{{/* restapi server listening single port */}}
{{- define "eric-fh-alarm-handler.restapi.server.single.port" }}
{{- $g := fromJson (include "eric-fh-alarm-handler.global" .) -}}
    {{- if $g.security.tls.enabled -}}
    {{- include "eric-fh-alarm-handler.restapi.server.tls.port" . -}}
    {{- else }}
    {{- include "eric-fh-alarm-handler.restapi.server.port" . -}}
    {{- end }}
{{- end }}

{{- define "eric-fh-alarm-handler.restapi.server.port" }}
    {{- printf "%d" 5005 -}}
{{- end }}

{{/* restapi server listening tls port */}}
{{- define "eric-fh-alarm-handler.restapi.server.tls.port" }}
    {{- printf "%d" 5006 -}}
{{- end }}

{{/* Checks if the restapi server needs to enforce tls */}}
{{- define "eric-fh-alarm-handler.restapi.server.tlsOnly" }}
{{- eq .Values.service.endpoints.restapi.tls.enforced "required" -}}
{{- end }}

{{/* Checks if the restapi server needs to verify the clients */}}
{{- define "eric-fh-alarm-handler.restapi.server.tls.verifyClientCertificate" }}
{{- eq .Values.service.endpoints.restapi.tls.verifyClientCertificate "required" -}}
{{- end }}

{{/*----------------------------------------------------------------*/}}
{{/*-----Templates for FI rest API-----------------------------------*/}}
{{/*----------------------------------------------------------------*/}}

{{/* If the FI API is enabled */}}
{{- define "eric-fh-alarm-handler.rest.fi.api.enabled" }}
    {{- eq (.Values.alarmhandler.rest.fi.api.enabled | toString) "true" -}}
{{- end }}

{{/* FI HTTP listening port */}}
{{- define "eric-fh-alarm-handler.rest.fi.server.httpPort" }}
    {{- printf "%d" 6005 -}}
{{- end }}

{{/* FI HTTPS listening tls port */}}
{{- define "eric-fh-alarm-handler.rest.fi.server.httpsPort" }}
    {{- printf "%d" 6006 -}}
{{- end }}

{{/* If the FI API HTTP is enabled */}}
{{- define "eric-fh-alarm-handler.fiAPI.httpEnabled" }}
    {{- if eq (include "eric-fh-alarm-handler.rest.fi.api.enabled" .) "true" -}}
        {{- $tls := (include "eric-fh-alarm-handler.tls.enabled" .) -}}
        {{- or (eq $tls "false") (eq (.Values.service.endpoints.fiapi.tls.enforced | toString) "optional") -}}
    {{- else }}
        {{- printf "false" -}}
    {{- end }}
{{- end }}

{{/* If the AAL API HTTP is enabled
It should be enabled if the global TLS value is false or if
.Values.service.endpoints.restapi.tls.enforced is optional
*/}}
{{- define "eric-fh-alarm-handler.aalAPI.httpEnabled" }}
    {{- $tls := (include "eric-fh-alarm-handler.tls.enabled" .) -}}
    {{- or (not (eq $tls "true")) (eq .Values.service.endpoints.restapi.tls.enforced "optional") -}}
{{- end }}

{{/* If the FI API HTTPS is enabled */}}
{{- define "eric-fh-alarm-handler.fiAPI.httpsEnabled" }}
    {{- $tls := (include "eric-fh-alarm-handler.tls.enabled" .) -}}
    {{- and (eq (include "eric-fh-alarm-handler.rest.fi.api.enabled" .) "true") (eq $tls "true") -}}
{{- end }}

{{/* If the AAL API HTTP is enabled
It should be enabled if the global TLS value is true
*/}}
{{- define "eric-fh-alarm-handler.aalAPI.httpsEnabled" }}
    {{- $tls := (include "eric-fh-alarm-handler.tls.enabled" .) -}}
    {{- eq $tls "true" -}}
{{- end }}

{{/*----------------------------------------------------------------*/}}
{{/*-----Functions (including helpers) related to deprecations-----*/}}
{{/*---------------------------------------------------------------*/}}

{{/* Deprecation notices */}}
{{/* Remember to clean this section occasionally */}}
{{- define "eric-fh-alarm-handler.deprecation.notices" }}
  {{- if (index .Values "imageCredentials" "eric-fh-alarm-handler-rest") }}
    {{- if (index .Values "imageCredentials" "eric-fh-alarm-handler-rest" "registry") }}
      {{- range $k, $_ := (index .Values "imageCredentials" "eric-fh-alarm-handler-rest" "registry") }}
        {{- printf "'imageCredentials.eric-fh-alarm-handler-rest.%s' is deprecated as of release 7.1.0, the input value will be discarded.\n" $k }}
      {{- end }}
    {{- end }}
    {{- if (index .Values "imageCredentials" "eric-fh-alarm-handler-rest" "repoPath") }}
      {{- printf "'imageCredentials.eric-fh-alarm-handler-rest.repoPath' is deprecated as of release 7.1.0, the input value will be discarded.\n" }}
    {{- end }}
  {{- end }}
  {{- if (index .Values "images") }}
    {{- if (index .Values "images" "eric-fh-alarm-handler-rest") }}
      {{- range $k, $_ := (index .Values "images" "eric-fh-alarm-handler-rest") }}
        {{- printf "'images.eric-fh-alarm-handler-rest.%s' is deprecated as of release 7.1.0, the input value will be discarded.\n" $k }}
      {{- end }}
    {{- end }}
  {{- end }}
  {{- if .Values.readinessProbe.logshipper }}
    {{- range $k, $_ := (index .Values.readinessProbe.logshipper) }}
      {{- printf "'readinessProbe.logshipper.%s' is deprecated as of release 7.2.0, the input value will be discarded.\n" $k }}
    {{- end }}
  {{- end }}
  {{- if .Values.probes.alarmHandler.livenessProbe.initialDelaySeconds }}
      {{- printf "'probes.alarmHandler.livenessProbe.initialDelaySeconds' is deprecated as of k8s 1.20, the input value will be discarded.\n" }}
  {{- end }}
  {{- if .Values.probes.alarmHandler.readinessProbe.initialDelaySeconds }}
      {{- printf "'probes.alarmHandler.readinessProbe.initialDelaySeconds' is deprecated as of k8s 1.20, the input value will be discarded.\n" }}
  {{- end }}
{{- end }}

{{/* Selects the largest of two resource values. Assumes that both values have same (if any) suffix */}}
{{- define "eric-fh-alarm-handler.util.select.largest.value" -}}
  {{- $arg1 := include "eric-fh-alarm-handler.util.remove.suffix" (dict "arg" .arg1) -}}
  {{- $arg2 := include "eric-fh-alarm-handler.util.remove.suffix" (dict "arg" .arg2) -}}
  {{- if ge ($arg1 | float64) ($arg2 | float64) -}}
    {{- .arg1 -}}
  {{- else -}}
    {{- .arg2 -}}
  {{- end -}}
{{- end -}}

{{/* Remove suffix (if present) in resource values */}}
{{- define "eric-fh-alarm-handler.util.remove.suffix" -}}
  {{ $arg := print .arg }}
  {{- $suffix := regexReplaceAll "[0-9]" $arg "" }}
  {{- if empty $suffix -}}
    {{- $arg -}}
  {{- else -}}
    {{- regexReplaceAll "[A-Za-z]" $arg "" -}}
  {{- end -}}
{{- end -}}