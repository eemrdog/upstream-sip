{{/* vim: set filetype=mustache: */}}

{{/*
Create a map from ".Values.global" with defaults if missing in values file.
This hides defaults from values file.
*/}}
{{ define "eric-pm-bulk-reporter.global" }}
  {{- $globalDefaults := dict "security" (dict "tls" (dict "enabled" true)) -}}
  {{- $globalDefaults := merge $globalDefaults (dict "registry" (dict "url" "armdocker.rnd.ericsson.se")) -}}
  {{- $globalDefaults := merge $globalDefaults (dict "nodeSelector" (dict)) -}}
  {{ if .Values.global }}
    {{- mergeOverwrite $globalDefaults .Values.global | toJson -}}
  {{ else }}
    {{- $globalDefaults | toJson -}}
  {{ end }}
{{ end }}

{{/*
Expand the name of the chart.
*/}}
{{- define "eric-pm-bulk-reporter.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "eric-pm-bulk-reporter.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create version
*/}}
{{- define "eric-pm-bulk-reporter.version" -}}
{{- printf "%s" .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create image pull secrets
*/}}
{{- define "eric-pm-bulk-reporter.pullSecrets" -}}
  {{- if .Values.imageCredentials.pullSecret }}
    {{- print .Values.imageCredentials.pullSecret }}
  {{- else -}}
    {{- $g := fromJson (include "eric-pm-bulk-reporter.global" .) -}}
    {{- if $g.pullSecret }}
      {{- print $g.pullSecret }}
    {{- end -}}
  {{- end -}}
{{- end -}}

{{/*
Create scheme for ready and livness
*/}}
{{- define "eric-pm-bulk-reporter.scheme" -}}
{{- $g := fromJson (include "eric-pm-bulk-reporter.global" .) -}}
{{- if $g.security.tls.enabled }}
{{- print "HTTPS" }}
{{- else }}
{{- print "HTTP" }}
{{- end }}
{{- end -}}

{{/*
Create a merged set of nodeSelectors from global and service level.
*/}}
{{ define "eric-pm-bulk-reporter.nodeSelector" }}
  {{- $global := (.Values.global).nodeSelector -}}
  {{- $service := .Values.nodeSelector -}}
  {{- $context := "eric-pm-bulk-reporter.nodeSelector" -}}
  {{- include "eric-pm-bulk-reporter.aggregatedMerge" (dict "context" $context "location" .Template.Name "sources" (list $service $global)) | trim -}}
{{ end }}

{{/*
Create IPv4 boolean service/global/<notset>
*/}}
{{- define "eric-pm-bulk-reporter-service.enabled-IPv4" -}}
{{- $g := fromJson (include "eric-pm-bulk-reporter.global" .) -}}
{{- if .Values.service.externalIPv4.enabled | quote -}}
{{- .Values.service.externalIPv4.enabled -}}
{{- else -}}
{{- if $g -}}
{{- if $g.externalIPv4 -}}
{{- if $g.externalIPv4.enabled | quote -}}
{{- $g.externalIPv4.enabled -}}
{{- end -}}
{{- end -}}
{{- end -}}
{{- end -}}
{{- end -}}

{{/*
Define log outputs
Default: stdout
*/}}
{{- define "eric-pm-bulk-reporter.log.outputs" -}}
{{- $redirect := "stdout" -}}
{{- if has "stream" .Values.log.outputs -}}
    {{- $redirect = "file" }}
    {{- if has "stdout" .Values.log.outputs -}}
        {{- $redirect = "all" -}}
    {{- end -}}
{{- end -}}
{{- print $redirect -}}
{{- end -}}

{{/*
Create IPv6 boolean service/global/<notset>
*/}}
{{- define "eric-pm-bulk-reporter-service.enabled-IPv6" -}}
{{- $g := fromJson (include "eric-pm-bulk-reporter.global" .) -}}
{{- if .Values.service.externalIPv6.enabled | quote -}}
{{- .Values.service.externalIPv6.enabled -}}
{{- else -}}
{{- if $g -}}
{{- if $g.externalIPv6 -}}
{{- if $g.externalIPv6.enabled | quote -}}
{{- $g.externalIPv6.enabled -}}
{{- end -}}
{{- end -}}
{{- end -}}
{{- end -}}
{{- end -}}

{{/*
Define Message Bus server
*/}}
{{- define "eric-pm-bulk-reporter-service.msgbus" -}}
{{- $g := fromJson (include "eric-pm-bulk-reporter.global" .) -}}
{{- $msgbusport := int .Values.thresholdReporter.kafkaPort -}}
{{- if .Values.security.tls.messageBusKF.enabled -}}
    {{- if $g -}}
        {{- if $g.security -}}
            {{- if $g.security.tls -}}
                {{- if hasKey $g.security.tls "enabled" -}}
                    {{- if $g.security.tls.enabled -}}
                        {{- $msgbusport = int .Values.thresholdReporter.kafkaTlsPort -}}
                    {{- end -}}
                {{- end -}}
            {{- end -}}
        {{- end -}}
    {{- end -}}
{{- end -}}
{{- printf "%s:%d" .Values.thresholdReporter.kafkaHostname $msgbusport | quote -}}
{{- end -}}

{{- define "eric-pm-bulk-reporter.fsGroup.coordinated" -}}
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
Define Kubernetes labels
*/}}
{{- define "eric-pm-bulk-reporter.kubernetes-labels" }}
  app.kubernetes.io/name: {{ template "eric-pm-bulk-reporter.name" . }}
  app.kubernetes.io/version: {{ template "eric-pm-bulk-reporter.version" . }}
  app.kubernetes.io/instance: {{ .Release.Name | quote }}
{{- end -}}

{{- define "eric-pm-bulk-reporter.meta-labels" }}
  {{- $static := dict -}}
  {{- $_ := set $static "app" (include "eric-pm-bulk-reporter.name" .) -}}
  {{- $_ := set $static "release" (.Release.Name | toString) -}}
  {{- $kubernetes := include "eric-pm-bulk-reporter.kubernetes-labels" . | fromYaml -}}
  {{- $global := (.Values.global).labels -}}
  {{- $service := .Values.labels -}}
  {{- include "eric-pm-bulk-reporter.mergeLabels" (dict "location" (.Template.Name) "sources" (list $static $kubernetes $global $service)) | trim }}
{{- end}}

{{- define "eric-pm-bulk-reporter.labels" -}}
  {{- $static := dict -}}
  {{- $_ := set $static "chart" (include "eric-pm-bulk-reporter.chart" .) -}}
  {{- $_ := set $static "heritage" (.Release.Service | toString) -}}
  {{- $meta := include "eric-pm-bulk-reporter.meta-labels" . | fromYaml -}}
  {{- include "eric-pm-bulk-reporter.mergeLabels" (dict "location" (.Template.Name) "sources" (list $static $meta)) | trim }}
{{- end -}}

{{/*
Logshipper labels
*/}}
{{- define "eric-pm-bulk-reporter.logshipper-labels" }}
{{- include "eric-pm-bulk-reporter.labels" . -}}
{{- end }}

{{/*
  DR-D1123-124: Create security policy.
*/}}
{{- define "eric-pm-bulk-reporter.securityPolicy.annotations" -}}
# Automatically generated annotations for documentation purposes.
{{- end -}}

{{/*
Define helm-annotations
*/}}
{{- define "eric-pm-bulk-reporter.helm-annotations" }}
  ericsson.com/product-name: {{ (fromYaml (.Files.Get "eric-product-info.yaml")).productName | quote }}
  ericsson.com/product-number: {{ (fromYaml (.Files.Get "eric-product-info.yaml")).productNumber | quote }}
  ericsson.com/product-revision: {{regexReplaceAll "(.*)[+-].*" .Chart.Version "${1}" }}
{{- end}}

{{/*
Define annotations
*/}}
{{- define "eric-pm-bulk-reporter.annotations" -}}
  {{- $helm := include "eric-pm-bulk-reporter.helm-annotations" . | fromYaml -}}
  {{- $global := (.Values.global).annotations -}}
  {{- $service := .Values.annotations -}}
  {{- include "eric-pm-bulk-reporter.mergeAnnotations" (dict "location" (.Template.Name) "sources" (list $helm $global $service)) | trim }}
{{- end -}}

{{- define "eric-pm-bulk-reporter.imagePath" }}
    {{- $productInfo := fromYaml (.Files.Get "eric-product-info.yaml") -}}
    {{- $image := (get $productInfo.images .imageName) -}}
    {{- $registryUrl := $image.registry -}}
    {{- $repoPath := $image.repoPath -}}
    {{- $name := $image.name -}}
    {{- $tag := $image.tag -}}
    {{- $g := fromJson (include "eric-pm-bulk-reporter.global" .) -}}
    {{- if or .Values.imageCredentials.registry.url $g.registry.url -}}
        {{- $registryUrl = or .Values.imageCredentials.registry.url $g.registry.url -}}
    {{- end -}}
    {{- if .Values.imageCredentials.repoPath -}}
        {{- $repoPath = .Values.imageCredentials.repoPath -}}
    {{- end -}}
    {{- if .Values.imageCredentials -}}
        {{- if hasKey .Values.imageCredentials .imageName -}}
            {{- $credImage := get .Values.imageCredentials .imageName }}
            {{- if $credImage.registry -}}
                {{- if $credImage.registry.url -}}
                    {{- $registryUrl = $credImage.registry.url -}}
                {{- end -}}
            {{- end -}}
            {{- if not (kindIs "invalid" $credImage.repoPath) -}}
                {{- $repoPath = $credImage.repoPath -}}
            {{- end -}}
        {{- end -}}
        {{- if not (kindIs "invalid" .Values.imageCredentials.repoPath) -}}
            {{- $repoPath = .Values.imageCredentials.repoPath -}}
        {{- end -}}
    {{- end -}}
    {{- if $repoPath -}}
        {{- $repoPath = printf "%s/" $repoPath -}}
    {{- end -}}
    {{- if .Values.images -}}
      {{- if hasKey .Values.images .imageName -}}
          {{- $deprecatedImageParam := get .Values.images .imageName }}
          {{- if $deprecatedImageParam.name }}
              {{- $name = $deprecatedImageParam.name -}}
          {{- end -}}
          {{- if $deprecatedImageParam.tag }}
              {{- $tag = $deprecatedImageParam.tag -}}
          {{- end -}}
      {{- end -}}
    {{- end -}}
    {{- printf "%s/%s%s:%s" $registryUrl $repoPath $name $tag -}}
{{- end -}}
{{/*
Define eric-pm-bulk-reporter.resources
*/}}
{{- define "eric-pm-bulk-reporter.resources" -}}
{{- if .limits }}
  limits:
  {{- if .limits.cpu }}
    cpu: {{ .limits.cpu | quote }}
  {{- end -}}
  {{- if (index .limits "ephemeral-storage") }}
    ephemeral-storage: {{ index .limits "ephemeral-storage" | quote }}
  {{- end -}}
  {{- if .limits.memory }}
    memory: {{ .limits.memory | quote }}
  {{- end -}}
{{- end -}}
{{- if .requests }}
  requests:
  {{- if .requests.cpu }}
    cpu: {{ .requests.cpu | quote }}
  {{- end -}}
  {{- if (index .requests "ephemeral-storage") }}
    ephemeral-storage: {{ index .requests "ephemeral-storage" | quote }}
  {{- end -}}
  {{- if .requests.memory }}
    memory: {{ .requests.memory | quote }}
  {{- end -}}
{{- end -}}
{{- end -}}


{{/*
 CA Secret provided by PM Server
*/}}
{{- define "eric-pm-bulk-reporter.pmSecretName" -}}
  {{- if .Values.pmServer.pmServiceName -}}
    {{- .Values.pmServer.pmServiceName -}}
  {{- else -}}
    eric-pm-server
  {{- end -}}
{{- end -}}

{{/*
Get the metrics port.
*/}}
{{- define "eric-pm-bulk-reporter.metrics-port" -}}
  {{- $g := fromJson (include "eric-pm-bulk-reporter.global" .) -}}
  {{- if $g.security.tls.enabled -}}
    9089
  {{- else -}}
    9090
  {{- end -}}
{{- end -}}

{{/*
Get the metrics scheme.
*/}}
{{- define "eric-pm-bulk-reporter.protmetheus-io-scheme" -}}
  {{- $g := fromJson (include "eric-pm-bulk-reporter.global" .) -}}
  {{- if $g.security.tls.enabled -}}
    {{- print "https" -}}
  {{- else -}}
    {{- print "http" -}}
  {{- end -}}
{{- end -}}

{{/*
PM bulk reporter Labels for Network Policies
*/}}
{{- define "eric-pm-bulk-reporter.peer.labels" -}}
{{- if (has "stream" .Values.log.outputs) -}}
{{ .Values.logshipper.logtransformer.host }}-access: "true"
{{- end }}
{{ .Values.security.tls.cmMediator.serviceName }}-access: "true"
{{ .Values.security.tls.pmServer.serviceName }}-access: "true"
{{ .Values.security.tls.objectStorage.serviceName }}-access: "true"
{{ .Values.security.keyManagement.serviceName }}-access: "true"
{{- if .Values.trace.enabled }}
{{ .Values.trace.agent.host }}-access: "true"
{{- end }}
{{- if .Values.thresholdReporter.enabled }}
{{ .Values.thresholdReporter.kafkaHostname }}-access: "true"
{{ .Values.thresholdReporter.alarmHandlerHostname }}-access: "true"
{{- end }}
{{- end -}}

{{/*
Define eric-pm-bulk-reporter.appArmorProfileAnnotation
*/}}
{{- define "eric-pm-bulk-reporter.appArmorProfileAnnotation" -}}
{{- $acceptedProfiles := list "unconfined" "runtime/default" "localhost" }}
{{- $commonProfile := dict -}}
{{- if .Values.appArmorProfile.type -}}
  {{- $_ := set $commonProfile "type" .Values.appArmorProfile.type -}}
  {{- if and (eq .Values.appArmorProfile.type "localhost") .Values.appArmorProfile.localhostProfile -}}
    {{- $_ := set $commonProfile "localhostProfile" .Values.appArmorProfile.localhostProfile -}}
  {{- end -}}
{{- end -}}
{{- $profiles := dict -}}
{{- range $container := list "eric-pm-br-initcontainer" "eric-pm-bulk-reporter" "eric-pm-alarm-reporter" "eric-pm-sftp" "logshipper" -}}
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
{{- end -}}

{{/*
Define podPriority check
*/}}
{{- define "eric-pm-bulk-reporter.podpriority" }}
{{- if .Values.podPriority }}
  {{- if index .Values.podPriority "eric-pm-bulk-reporter" -}}
    {{- if (index .Values.podPriority "eric-pm-bulk-reporter" "priorityClassName") }}
      priorityClassName: {{ index .Values.podPriority "eric-pm-bulk-reporter" "priorityClassName" | quote }}
    {{- end }}
  {{- end }}
{{- end }}
{{- end }}

{{/*
Define eric-pm-bulk-reporter.podSeccompProfile
*/}}
{{- define "eric-pm-bulk-reporter.podSeccompProfile" -}}
{{- if and .Values.seccompProfile .Values.seccompProfile.type }}
seccompProfile:
  type: {{ .Values.seccompProfile.type }}
  {{- if eq .Values.seccompProfile.type "Localhost" }}
  localhostProfile: {{ .Values.seccompProfile.localhostProfile }}
  {{- end }}
{{- end }}
{{- end -}}
