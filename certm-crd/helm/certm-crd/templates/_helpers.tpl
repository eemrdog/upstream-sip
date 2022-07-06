{{/* vim: set filetype=mustache: */}}
{{/*
Expand the name of the chart.
*/}}
{{- define "eric-sec-certm-crd.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "eric-sec-certm-crd.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create chart version as used by the version label.
*/}}
{{- define "eric-sec-certm-crd.version" -}}
{{- printf "%s" .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Product annotations.
*/}}
{{- define "eric-sec-certm-crd.product-info" }}
ericsson.com/product-name: {{ (fromYaml (.Files.Get "eric-product-info.yaml")).productName | quote }}
ericsson.com/product-number: {{ (fromYaml (.Files.Get "eric-product-info.yaml")).productNumber | quote }}
ericsson.com/product-revision: {{regexReplaceAll "(.*)[+-].*" .Chart.Version "${1}" }}
{{- end }}

{{/*
The crdjob image path (DR-D1121-067)
*/}}
{{- define "eric-sec-certm-crd.crdjob.imagePath" }}
    {{- $productInfo := fromYaml (.Files.Get "eric-product-info.yaml") -}}
    {{- $registryUrl := $productInfo.images.crdjob.registry -}}
    {{- $repoPath := $productInfo.images.crdjob.repoPath -}}
    {{- $name := $productInfo.images.crdjob.name -}}
    {{- $tag := $productInfo.images.crdjob.tag -}}
    {{- if .Values.global -}}
        {{- if .Values.global.registry -}}
            {{- if .Values.global.registry.url -}}
                {{- $registryUrl = .Values.global.registry.url -}}
            {{- end -}}
        {{- end -}}
    {{- end -}}
    {{- if .Values.imageCredentials -}}
        {{- if .Values.imageCredentials.registry -}}
	          {{- if .Values.imageCredentials.registry.url -}}
                {{- $registryUrl = .Values.imageCredentials.registry.url -}}
            {{- end -}}
        {{- end -}}
        {{- if not (kindIs "invalid" .Values.imageCredentials.repoPath) -}}
            {{- $repoPath = .Values.imageCredentials.repoPath -}}
        {{- end -}}
    {{- end -}}
    {{- if $repoPath -}}
        {{- $repoPath = printf "%s/" $repoPath -}}
    {{- end -}}
    {{- printf "%s/%s%s:%s" $registryUrl $repoPath $name $tag -}}
{{- end -}}

{{/*
Define timezone
Default: UTC
*/}}
{{- define "eric-sec-certm-crd.timezone" -}}
{{- $timezone := "UTC" -}}
{{- if .Values.global -}}
    {{- if .Values.global.timezone -}}
        {{- $timezone = .Values.global.timezone -}}
    {{- end -}}
{{- end -}}
{{- print $timezone -}}
{{- end -}}

{{/*
Create image registry url
Default: armdocker.rnd.ericsson.se
*/}}
{{- define "eric-sec-certm-crd.registryUrl" -}}
{{- $url := "armdocker.rnd.ericsson.se" -}}
{{- if .Values.imageCredentials.registry.url -}}
    {{- $url = .Values.imageCredentials.registry.url -}}
{{- else if .Values.global -}}
    {{- if .Values.global.registry -}}
        {{- if .Values.global.registry.url -}}
            {{- $url = .Values.global.registry.url -}}
        {{- end -}}
    {{- end -}}
{{- end -}}
{{- print $url -}}
{{- end -}}

{{/*
Create image pull secret, service level parameter takes precedence.
Default:
*/}}
{{- define "eric-sec-certm-crd.pullSecret" -}}
{{- $pullSecret := "" -}}
{{- if .Values.imageCredentials.pullSecret -}}
    {{- $pullSecret = .Values.imageCredentials.pullSecret -}}
{{- else -}}
    {{- if .Values.global -}}
        {{- if .Values.global.pullSecret -}}
            {{- $pullSecret = .Values.global.pullSecret -}}
        {{- end -}}
    {{- end -}}
{{- end -}}
{{- print $pullSecret -}}
{{- end -}}

{{/*
Create image pull policy, service level parameter takes precedence.
Default: 'IfNotPresent'
*/}}
{{- define "eric-sec-certm-crd.pullPolicy" -}}
{{- $pullPolicy := "IfNotPresent" -}}
{{- if .Values.imageCredentials.registry.imagePullPolicy -}}
    {{- $pullPolicy = .Values.imageCredentials.registry.imagePullPolicy -}}
{{- else -}}
    {{- if .Values.global -}}
        {{- if .Values.global.registry -}}
            {{- if .Values.global.registry.imagePullPolicy -}}
                {{- $pullPolicy = .Values.global.registry.imagePullPolicy -}}
            {{- end -}}
        {{- end -}}
    {{- end -}}
{{- end -}}
{{- print $pullPolicy -}}
{{- end -}}

{{/*
Define nodeSelector
*/}}
{{- define "eric-sec-certm-crd.nodeSelector" -}}
{{- $nodeSelector := dict -}}
{{- if .Values.global -}}
    {{- if .Values.global.nodeSelector -}}
        {{- $nodeSelector = .Values.global.nodeSelector -}}
    {{- end -}}
{{- end -}}
{{- if .Values.nodeSelector }}
    {{- range $key, $localValue := .Values.nodeSelector -}}
      {{- if hasKey $nodeSelector $key -}}
          {{- $globalValue := index $nodeSelector $key -}}
          {{- if ne $globalValue $localValue -}}
            {{- printf "nodeSelector \"%s\" is specified in both global (%s: %s) and service level (%s: %s) with differing values which is not allowed." $key $key $globalValue $key $localValue | fail -}}
          {{- end -}}
      {{- end -}}
    {{- end -}}
    {{- $nodeSelector = merge $nodeSelector .Values.nodeSelector -}}
{{- end -}}
{{- if $nodeSelector -}}
    {{ toYaml $nodeSelector | trim | indent 8 }}
{{- end -}}
{{- end -}}

{{/*
Define the common annotations
*/}}
{{- define "eric-sec-certm-crd.annotations" -}}
{{- include "eric-sec-certm-crd.product-info" . }}
{{- if .Values.annotations }}
{{ toYaml .Values.annotations}}
{{- end }}
{{- end -}}

{{/*
Define the annotations for security-policy
*/}}
{{- define "eric-sec-certm-crd.securityPolicy.annotations" -}}
# Automatically generated annotations for documentation purposes.
ericsson.com/security-policy.type: "restricted/default"
ericsson.com/security-policy.capabilities: ""
{{- end -}}

{{/*
Define the labels
*/}}
{{- define "eric-sec-certm-crd.labels" }}
{{- include "eric-sec-certm-crd.product-labels" . }}
{{- if .Values.labels }}
{{ toYaml .Values.labels}}
{{- end }}
{{- end -}}

{{/*
Define the role reference for security policy
*/}}
{{- define "eric-sec-certm-crd.securityPolicy.reference" -}}
  {{- if .Values.global -}}
    {{- if .Values.global.security -}}
      {{- if .Values.global.security.policyReferenceMap -}}
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

{{- define "eric-sec-certm-crd.crdjob.resources" -}}
  {{- if .Values.resources -}}
    {{- if .Values.resources.crdjob -}}
resources:
      {{- if .Values.resources.crdjob.limits -}}
        {{- if or .Values.resources.crdjob.limits.cpu .Values.resources.crdjob.limits.memory (index .Values.resources.crdjob.limits "ephemeral-storage") }}
  limits:
          {{- if .Values.resources.crdjob.limits.cpu }}
    cpu: {{ .Values.resources.crdjob.limits.cpu | quote }}
          {{- end }}
          {{- if .Values.resources.crdjob.limits.memory }}
    memory: {{ .Values.resources.crdjob.limits.memory | quote }}
          {{- end }}
          {{- if index .Values.resources.crdjob.limits "ephemeral-storage" }}
    ephemeral-storage: {{ index .Values.resources.crdjob.limits "ephemeral-storage" | quote }}
          {{- end }}
        {{- end }}
      {{- end -}}
      {{- if .Values.resources.crdjob.requests -}}
        {{- if or .Values.resources.crdjob.requests.cpu .Values.resources.crdjob.requests.memory (index .Values.resources.crdjob.requests "ephemeral-storage") }}
  requests:
          {{- if .Values.resources.crdjob.requests.cpu }}
    cpu: {{ .Values.resources.crdjob.requests.cpu | quote }}
          {{- end }}
          {{- if .Values.resources.crdjob.requests.memory }}
    memory: {{ .Values.resources.crdjob.requests.memory | quote }}
          {{- end }}
          {{- if index .Values.resources.crdjob.requests "ephemeral-storage" }}
    ephemeral-storage: {{ index .Values.resources.crdjob.requests "ephemeral-storage" | quote }}
          {{- end }}
        {{- end }}
      {{- end -}}
    {{- end -}}
  {{- end -}}
{{- end -}}

{{/*
Define terminationGracePeriodSeconds
*/}}
{{- define "eric-sec-certm-crd.terminationGracePeriodSeconds" -}}
{{- $terminationGracePeriodSeconds := 30 -}}
{{- if gt (int (index .Values "terminationGracePeriodSeconds" "eric-sec-certm-crd")) 0 }}
  {{- $terminationGracePeriodSeconds = int (index .Values "terminationGracePeriodSeconds" "eric-sec-certm-crd") -}}
{{- end }}
{{- print $terminationGracePeriodSeconds -}}
{{- end -}}

{{/*
Get Kubernetes version
*/}}
{{- define "eric-sec-certm-crd.KubernetesVersion" -}}
{{- $version := "" -}}
{{- if .Capabilities.KubeVersion.Version -}}
    {{- $version = .Capabilities.KubeVersion.Version -}}
{{- else -}}
    {{- $version = .Capabilities.KubeVersion.GitVersion -}}
{{- end -}}
{{- print $version -}}
{{- end -}}