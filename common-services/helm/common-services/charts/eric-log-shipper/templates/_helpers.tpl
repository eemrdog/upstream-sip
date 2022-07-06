{{/* vim: set filetype=mustache: */}}

{{/*
Expand the name of the chart.
*/}}
{{- define "eric-log-shipper.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "eric-log-shipper.fullname" -}}
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
{{- define "eric-log-shipper.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
The logshipper Image path
*/}}
{{ define "eric-log-shipper.logshipperImagePath" }}
    {{- $productInfo := fromYaml (.Files.Get "eric-product-info.yaml") -}}
    {{- $g := fromJson (include "eric-log-shipper.global" .) -}}
    {{- $registryUrl := $g.registry.url | default $productInfo.images.logshipper.registry -}}
    {{- $defaults := dict "imageCredentials" (dict "registry" (dict "url" $registryUrl)) -}}
    {{- $defaults := merge $defaults (dict "images" (dict "logshipper" (dict "name" $productInfo.images.logshipper.name))) -}}
    {{- $defaults := merge $defaults (dict "images" (dict "logshipper" (dict "tag" $productInfo.images.logshipper.tag))) -}}
    {{- $defaults := mergeOverwrite $defaults .Values -}}
    {{- if .Values.imageCredentials.repoPath -}}
       {{/*Left blank to maintain the repoPath from Values file */}}
    {{- else }}
    {{- $defaults := merge $defaults (dict "imageCredentials" (dict "repoPath" $productInfo.images.logshipper.repoPath)) -}}
    {{- end }}
    {{- $registryUrl := $defaults.imageCredentials.registry.url -}}
    {{- $repoPath := $defaults.imageCredentials.repoPath -}}
    {{- $name := $defaults.images.logshipper.name -}}
    {{- $tag := $defaults.images.logshipper.tag -}}
    {{- printf "%s/%s/%s:%s" $registryUrl $repoPath $name $tag -}}
{{- end -}}

{{/*
Merge user-defined annotations with product info (DR-D1121-065, DR-D1121-060)
*/}}
{{- define "eric-log-shipper.annotations" -}}
  {{- $productAnnotations := dict }}
  {{- $_ := set $productAnnotations "ericsson.com/product-name" (fromYaml (.Files.Get "eric-product-info.yaml")).productName }}
  {{- $_ := set $productAnnotations "ericsson.com/product-number" (fromYaml (.Files.Get "eric-product-info.yaml")).productNumber }}
  {{- $_ := set $productAnnotations "ericsson.com/product-revision" (split "-" (.Chart.Version | replace "+" "-" ))._0 }}

  {{- $globalAnn := (.Values.global).annotations -}}
  {{- $serviceAnn := .Values.annotations -}}
  {{- include "eric-log-shipper.mergeAnnotations" (dict "location" .Template.Name "sources" (list $productAnnotations $globalAnn $serviceAnn)) | trim }}
{{- end -}}

{{/*
Merge user-defined labels with kubernetes labels (DR-D1121-068, DR-D1121-060)
*/}}
{{- define "eric-log-shipper.labels" -}}
  {{- $k8sLabels := dict }}
  {{- $_ := set $k8sLabels "app.kubernetes.io/name" (include "eric-log-shipper.name" .) }}
  {{- $_ := set $k8sLabels "app.kubernetes.io/version" (.Chart.Version | replace "+" "_") }}
  {{- $_ := set $k8sLabels "app.kubernetes.io/instance" .Release.Name }}

  {{- $globalLabels := (.Values.global).labels -}}
  {{- $serviceLabels := .Values.labels -}}
  {{- include "eric-log-shipper.mergeLabels" (dict "location" .Template.Name "sources" (list $k8sLabels $globalLabels $serviceLabels)) | trim }}
{{- end -}}

{{/*
Create a map from testInternals with defaults if missing in values file.
This hides defaults from values file.
Version: 1.0
*/}}
{{ define "eric-log-shipper.testInternal" }}
  {{- $tiDefaults := (dict ) -}}
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
{{ define "eric-log-shipper.global" }}
  {{- $globalDefaults := dict "security" (dict "tls" (dict "enabled" true)) -}}
  {{- $globalDefaults := merge $globalDefaults (dict "nodeSelector" (dict)) -}}
  {{- $globalDefaults := merge $globalDefaults (dict "registry" (dict "imagePullPolicy" "IfNotPresent")) -}}
  {{- $globalDefaults := merge $globalDefaults (dict "registry" (dict "url" "armdocker.rnd.ericsson.se")) -}}
  {{- $globalDefaults := merge $globalDefaults (dict "pullSecret") -}}
  {{- $globalDefaults := merge $globalDefaults (dict "timezone" "UTC") -}}
  {{- $globalDefaults := merge $globalDefaults (dict "security" (dict "policyBinding" (dict "create" false))) -}}
  {{- $globalDefaults := merge $globalDefaults (dict "security" (dict "policyReferenceMap" (dict "plc-29c4b823c87a16cad810082eb11106" "plc-29c4b823c87a16cad810082eb11106"))) -}}
  {{- $globalDefaults := merge $globalDefaults (dict "security" (dict "policyReferenceMap" (dict "plc-e393f1841dfc4cbcca713b5a97eb83" "plc-e393f1841dfc4cbcca713b5a97eb83"))) -}}
  {{ if .Values.global }}
    {{- mergeOverwrite $globalDefaults .Values.global | toJson -}}
  {{ else }}
    {{- $globalDefaults | toJson -}}
  {{ end }}
{{ end }}

{{/*
Create a merged set of nodeSelectors from global and service level.
*/}}
{{ define "eric-log-shipper.nodeSelector" }}
  {{- $global := (.Values.global).nodeSelector -}}
  {{- $service := .Values.nodeSelector -}}
  {{- $context := "eric-log-shipper.nodeSelector" -}}
  {{- include "eric-log-shipper.aggregatedMerge" (dict "context" $context "location" .Template.Name "sources" (list $service $global)) | trim -}}
{{ end }}

{{/*
Create a map with internal default values used for testing purposes.
*/}}
{{- define "eric-log-shipper.internal" -}}
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
Deprecated settings
*/}}
{{ define "eric-log-shipper.deprecated" }}
  {{- $deprecated := dict -}}
  {{- mergeOverwrite $deprecated .Values | toJson -}}
{{ end }}

{{/*
Deprecation notices
*/}}
{{- define "eric-log-shipper.deprecation-notices" }}
  {{- $d := fromJson (include "eric-log-shipper.deprecated" .) -}}
{{- end }}

{{/*
Define eric-log-shipper.podSeccompProfile
*/}}
{{- define "eric-log-shipper.podSeccompProfile" -}}
{{- if and .Values.seccompProfile .Values.seccompProfile.type }}
seccompProfile:
  type: {{ .Values.seccompProfile.type }}
  {{- if eq .Values.seccompProfile.type "Localhost" }}
  localhostProfile: {{ .Values.seccompProfile.localhostProfile }}
  {{- end }}
{{- end }}
{{- end -}}

{{/*
Define eric-log-shipper.contSeccompProfile
*/}}
{{- define "eric-log-shipper.contSeccompProfile" -}}
{{- if and .Values.seccompProfile.logshipper .Values.seccompProfile.logshipper.type }}
seccompProfile:
  type: {{ .Values.seccompProfile.logshipper.type }}
  {{- if eq .Values.seccompProfile.logshipper.type "Localhost" }}
  localhostProfile: {{ .Values.seccompProfile.logshipper.localhostProfile }}
  {{- end }}
{{- end }}
{{- end -}}

Define eric-log-shipper.appArmorProfileAnnotation
*/}}
{{- define "eric-log-shipper.appArmorProfileAnnotation" -}}
{{- $acceptedProfiles := list "unconfined" "runtime/default" "localhost" }}
{{- $commonProfile := dict -}}
{{- if .Values.appArmorProfile.type -}}
  {{- $_ := set $commonProfile "type" .Values.appArmorProfile.type -}}
  {{- if and (eq .Values.appArmorProfile.type "localhost") .Values.appArmorProfile.localhostProfile -}}
    {{- $_ := set $commonProfile "localhostProfile" .Values.appArmorProfile.localhostProfile -}}
  {{- end -}}
{{- end -}}
{{- $profiles := dict -}}
{{- range $container := list "logshipper" -}}
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
