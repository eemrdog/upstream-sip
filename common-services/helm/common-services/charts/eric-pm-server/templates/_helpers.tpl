{{/* vim: set filetype=mustache: */}}

{{/*
Create a map from ".Values.global" with defaults if missing in values file.
This hides defaults from values file.
*/}}
{{ define "eric-pm-server.global" }}
  {{- $globalDefaults := dict "security" (dict "tls" (dict "enabled" true)) -}}
  {{- $globalDefaults := merge $globalDefaults (dict "registry" (dict "url" "451278531435.dkr.ecr.us-east-1.amazonaws.com")) -}}
  {{- $globalDefaults := merge $globalDefaults (dict "timezone" "UTC") -}}
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
{{- define "eric-pm-server.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create version
*/}}
{{- define "eric-pm-server.version" -}}
{{- printf "%s" .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "eric-pm-server.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create image pull secrets
*/}}
{{- define "eric-pm-server.pullSecrets" -}}
  {{- if .Values.imageCredentials.pullSecret }}
    {{- print .Values.imageCredentials.pullSecret }}
  {{- else -}}
    {{- $g := fromJson (include "eric-pm-server.global" .) -}}
    {{- if $g.pullSecret }}
      {{- print $g.pullSecret }}
    {{- end -}}
  {{- end -}}
{{- end -}}

{{/*
Create configuration reload url
*/}}
{{- define "eric-pm-server.configmap-reload.webhook" -}}
{{- if .Values.server.prefixURL -}}
{{- printf "http://127.0.0.1:9090/%s/-/reload" .Values.server.prefixURL -}}
{{- else -}}
{{- print "http://127.0.0.1:9090/-/reload" -}}
{{- end -}}
{{- end -}}


{{/*
Define log outputs
Default: stdout
*/}}
{{- define "eric-pm-server.log.outputs" -}}
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
Create a merged set of nodeSelectors from global and service level.
*/}}
{{ define "eric-pm-server.nodeSelector" }}
  {{- $g := fromJson (include "eric-pm-server.global" .) -}}
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

{{- define "eric-pm-server.fsGroup.coordinated" -}}
  {{- $g := fromJson (include "eric-pm-server.global" .) -}}
    {{- if $g -}}
        {{- if $g.fsGroup -}}
            {{- if $g.fsGroup.manual -}}
                {{ $g.fsGroup.manual }}
            {{- else -}}
                {{- if eq $g.fsGroup.namespace true -}}
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

{{- define "eric-pm-server.labels" -}}
{{- include "eric-pm-server.selectorLabels" . }}
app.kubernetes.io/name: {{ template "eric-pm-server.name" . }}
app.kubernetes.io/version: {{ template "eric-pm-server.version" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app: {{ template "eric-pm-server.name" . }}
chart: {{ template "eric-pm-server.chart" . }}
component: {{ .Values.server.name | quote }}
heritage: {{ .Release.Service }}
release: {{ .Release.Name }}
{{- if .Values.labels }}
{{ toYaml .Values.labels }}
{{- end }}
{{- end -}}

{{/*
Selector labels.
*/}}
{{- define "eric-pm-server.selectorLabels" }}
component: {{ .Values.server.name | quote }}
app: {{ template "eric-pm-server.name" . }}
release: {{ .Release.Name }}
{{- if eq (include "eric-pm-server.needInstanceLabelSelector" .) "true" }}
app.kubernetes.io/instance: {{ .Release.Name | quote }}
{{- end -}}
{{- end }}
{{- define "eric-pm-server.needInstanceLabelSelector" }}
    {{- $needInstanceLabelSelector := false -}}
    {{- if .Release.IsInstall }}
        {{- $needInstanceLabelSelector = true -}}
    {{- else if .Release.IsUpgrade }}
        {{- $pmSs := (lookup "apps/v1" "StatefulSet" .Release.Namespace (include "eric-pm-server.name" .)) -}}
        {{- if $pmSs -}}
            {{- if hasKey $pmSs.spec.selector.matchLabels "app.kubernetes.io/instance" -}}
                {{- $needInstanceLabelSelector = true -}}
            {{- end -}}
        {{- end -}}
    {{- end -}}
    {{- $needInstanceLabelSelector -}}
{{- end }}


{{/*
    DR-D1123-124: Create security policy.
*/}}
{{- define "eric-pm-server.securityPolicy.reference" -}}
  {{- $g := fromJson (include "eric-pm-server.global" .) -}}
  {{- if $g -}}
    {{- if $g.security -}}
      {{- if $g.security.policyReferenceMap -}}
        {{ $mapped := index .Values "global" "security" "policyReferenceMap" "default-restricted-security-policy" }}
        {{- if $mapped -}}
          {{ $mapped }}
        {{- else -}}
          default-restricted-security-policy
        {{- end -}}
      {{- else -}}
        default-restricted-security-policy
      {{- end -}}
    {{- else -}}
      default-restricted-security-policy
    {{- end -}}
  {{- else -}}
    default-restricted-security-policy
  {{- end -}}
{{- end -}}

{{- define "eric-pm-server.securityPolicy.annotations" -}}
# Automatically generated annotations for documentation purposes.
{{- end -}}

{{/*
Define helm-annotations
*/}}
{{- define "eric-pm-server.helm-annotations" }}
  ericsson.com/product-name: {{ (fromYaml (.Files.Get "eric-product-info.yaml")).productName | quote }}
  ericsson.com/product-number: {{ (fromYaml (.Files.Get "eric-product-info.yaml")).productNumber | quote }}
  ericsson.com/product-revision: {{regexReplaceAll "(.*)[+].*" .Chart.Version "${1}" }}
{{- end}}

{{/*
Define annotations
*/}}
{{- define "eric-pm-server.annotations" -}}
{{- include "eric-pm-server.helm-annotations" . }}
{{- if .Values.annotations }}
{{ toYaml .Values.annotations | indent 2 }}
{{- end }}
{{- end -}}

{{- define "eric-pm-server.imagePath" }}
    {{- $productInfo := fromYaml (.Files.Get "eric-product-info.yaml") -}}
    {{- $image := (get $productInfo.images .imageName) -}}
    {{- $registryUrl := $image.registry -}}
    {{- $repoPath := $image.repoPath -}}
    {{- $name := $image.name -}}
    {{- $tag := $image.tag -}}
    {{- $g := fromJson (include "eric-pm-server.global" .) -}}
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
  Create eric-pm-server.serviceaccountname
*/}}
{{- define "eric-pm-server.serviceaccountname" -}}
{{- $g := fromJson (include "eric-pm-server.global" .) -}}
{{- if $g }}
  {{- if $g.security }}
    {{- if $g.security.policyBinding }}
      {{- if $g.security.policyBinding.create }}
        {{- if $g.security.policyReferenceMap }}
          {{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
        {{- else  if .Values.rbac.appMonitoring.enabled }}
          {{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
        {{- else if .Values.server.serviceAccountName }}
          {{- print .Values.server.serviceAccountName }}
        {{- end }}
      {{- else if .Values.rbac.appMonitoring.enabled }}
        {{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
      {{- else if .Values.server.serviceAccountName }}
        {{- print .Values.server.serviceAccountName }}
      {{- end }}
  {{- else  if .Values.rbac.appMonitoring.enabled }}
    {{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
  {{- else if .Values.server.serviceAccountName }}
    {{- print .Values.server.serviceAccountName }}
  {{- end }}
  {{- else if .Values.rbac.appMonitoring.enabled }}
    {{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
  {{- else if .Values.server.serviceAccountName }}
    {{- print .Values.server.serviceAccountName }}
  {{- end }}
  {{- else if .Values.rbac.appMonitoring.enabled }}
    {{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
  {{- else if .Values.server.serviceAccountName }}
    {{- print .Values.server.serviceAccountName }}
{{- end }}
{{- end -}}

{{/*
Define eric-pm-server.resources
*/}}
{{- define "eric-pm-server.resources" -}}
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
