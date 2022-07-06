{{/* vim: set filetype=mustache: */}}

{{/*
Create a map from ".Values.global" with defaults if missing in values file.
This hides defaults from values file.
*/}}
{{ define "eric-pm-bulk-reporter.global" }}
  {{- $globalDefaults := dict "security" (dict "tls" (dict "enabled" true)) -}}
  {{- $globalDefaults := merge $globalDefaults (dict "registry" (dict "url" "451278531435.dkr.ecr.us-east-1.amazonaws.com")) -}}
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
  {{- $g := fromJson (include "eric-pm-bulk-reporter.global" .) -}}
  {{- if .Values.nodeSelector -}}
    {{- range $key, $localValue := .Values.nodeSelector -}}
      {{- if hasKey $g.nodeSelector $key -}}
          {{- $globalValue := index $g.nodeSelector $key -}}
          {{- if ne $globalValue $localValue -}}
            {{- printf "nodeSelector \"%s\" is specified in both global (%s: %s) and service level (%s: %s) with differing values which is not allowed." $key $key $globalValue $key $localValue | fail -}}
          {{- end -}}
      {{- end -}}
    {{- end -}}
    {{- toYaml (merge $g.nodeSelector .Values.nodeSelector) | trim -}}
  {{- else -}}
    {{- toYaml $g.nodeSelector | trim -}}
  {{- end -}}
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

{{- define "eric-pm-bulk-reporter.meta-labels" }}
app.kubernetes.io/name: {{ template "eric-pm-bulk-reporter.name" . }}
app.kubernetes.io/version: {{ template "eric-pm-bulk-reporter.version" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app: {{ template "eric-pm-bulk-reporter.name" . }}
release: {{ .Release.Name }}
{{- if .Values.labels }}
{{ toYaml .Values.labels }}
{{- end }}
{{- end}}

{{- define "eric-pm-bulk-reporter.labels" -}}
app.kubernetes.io/name: {{ template "eric-pm-bulk-reporter.name" . }}
app.kubernetes.io/version: {{ template "eric-pm-bulk-reporter.version" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app: {{ template "eric-pm-bulk-reporter.name" . }}
chart: {{ template "eric-pm-bulk-reporter.chart" . }}
release: {{ .Release.Name }}
heritage: {{ .Release.Service }}
{{- if .Values.labels }}
{{ toYaml .Values.labels }}
{{- end }}
{{- end -}}

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
{{- include "eric-pm-bulk-reporter.helm-annotations" . }}
{{- if .Values.annotations }}
{{ toYaml .Values.annotations | indent 2 }}
{{- end }}
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
