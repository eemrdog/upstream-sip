{{/*
Create a map from ".Values.global" with defaults if missing in values file.
This hides defaults from values file.
*/}}
{{ define "eric-data-search-engine-curator.global" }}
  {{- $globalDefaults := dict "security" (dict "tls" (dict "enabled" true)) -}}
  {{- $globalDefaults := merge $globalDefaults (dict "nodeSelector" (dict)) -}}
  {{- $globalDefaults := merge $globalDefaults (dict "registry" (dict "imagePullPolicy" "IfNotPresent")) -}}
  {{- $globalDefaults := merge $globalDefaults (dict "registry" (dict "url" "armdocker.rnd.ericsson.se")) -}}
  {{- $globalDefaults := merge $globalDefaults (dict "pullSecret") -}}
  {{- $globalDefaults := merge $globalDefaults (dict "timezone" "UTC") -}}
  {{- $globalDefaults := merge $globalDefaults (dict "security" (dict "policyBinding" (dict "create" false))) -}}
  {{- $globalDefaults := merge $globalDefaults (dict "security" (dict "policyReferenceMap" (dict "default-restricted-security-policy" "default-restricted-security-policy"))) -}}
  {{ if .Values.global }}
    {{- mergeOverwrite $globalDefaults .Values.global | toJson -}}
  {{ else }}
    {{- $globalDefaults | toJson -}}
  {{ end }}
{{ end }}

{{/*
Deprecated settings
*/}}
{{ define "eric-data-search-engine-curator.deprecated" }}
  {{- $deprecated := dict -}}
  {{- mergeOverwrite $deprecated .Values | toJson -}}
{{ end }}

{{/*
Deprecation notices
*/}}
{{- define "eric-data-search-engine-curator.deprecation-notices" }}
  {{- $d := fromJson (include "eric-data-search-engine-curator.deprecated" .) -}}
{{- end }}

{{/*
Create a merged set of nodeSelectors from global and service level.
*/}}
{{ define "eric-data-search-engine-curator.nodeSelector" }}
  {{- $global := (.Values.global).nodeSelector -}}
  {{- $service := .Values.nodeSelector -}}
  {{- $context := "eric-data-search-engine-curator.nodeSelector" -}}
  {{- include "eric-data-search-engine-curator.aggregatedMerge" (dict "context" $context "location" .Template.Name "sources" (list $global $service)) | trim -}}
{{ end }}

{{/*
Expand the name of the chart.
*/}}
{{- define "eric-data-search-engine-curator.name" -}}
  {{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "eric-data-search-engine-curator.fullname" -}}
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
{{- define "eric-data-search-engine-curator.chart" -}}
  {{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create image url
*/}}

{{- define "eric-data-search-engine-curator.image-registry-url" }}
    {{- $productInfo := fromYaml (.Files.Get "eric-product-info.yaml") -}}
    {{- $g := fromJson (include "eric-data-search-engine-curator.global" .) -}}
    {{- $registryUrl := $g.registry.url | default $productInfo.images.curator.registry -}}
    {{- $defaults := dict "imageCredentials" (dict "registry" (dict "url" $registryUrl)) -}}
    {{- $defaults := merge $defaults (dict "imageCredentials" (dict "repoPath" $productInfo.images.curator.repoPath)) -}}
    {{- $defaults := merge $defaults (dict "images" (dict "curator" (dict "name" $productInfo.images.curator.name))) -}}
    {{- $defaults := merge $defaults (dict "images" (dict "curator" (dict "tag" $productInfo.images.curator.tag))) -}}
    {{- $defaults := mergeOverwrite $defaults .Values -}}
    {{- $defaults := merge $defaults (dict "imageCredentials" (dict "curator" (dict "registry" (dict "url" $defaults.imageCredentials.registry.url)))) -}}
    {{- $defaults := merge $defaults (dict "imageCredentials" (dict "curator" (dict "repoPath" $defaults.imageCredentials.repoPath))) -}}
    {{- $defaults := mergeOverwrite $defaults .Values -}}
    {{- $registryUrl := $defaults.imageCredentials.curator.registry.url -}}
    {{- $repoPath := $defaults.imageCredentials.curator.repoPath -}}
    {{- $name := $defaults.images.curator.name -}}
    {{- $tag := $defaults.images.curator.tag -}}
    {{- printf "%s/%s/%s:%s" $registryUrl $repoPath $name $tag -}}
{{- end -}}

{{/*
Create product name, version and revision
*/}}
{{- define "eric-data-search-engine-curator.product-info" }}
ericsson.com/product-name: {{ (fromYaml (.Files.Get "eric-product-info.yaml")).productName | quote }}
ericsson.com/product-number: {{ (fromYaml (.Files.Get "eric-product-info.yaml")).productNumber | quote }}
ericsson.com/product-revision: {{ (split "-" (.Chart.Version | replace "+" "-" ))._0 | quote }}
{{- end }}

{{/*
Default merged annotations
*/}}
{{- define "eric-data-search-engine-curator.annotations" }}
  {{- $base := include "eric-data-search-engine-curator.product-info" . | fromYaml -}}
  {{- $global := (.Values.global).annotations -}}
  {{- $service := .Values.annotations -}}
  {{ include "eric-data-search-engine-curator.mergeAnnotations" (dict "location" .Template.Name "sources" (list $base $global $service)) }}
{{- end }}

{{/*
Create kubernetes.io name and version
*/}}
{{- define "eric-data-search-engine-curator.k8sLabels" -}}
app.kubernetes.io/name: {{ include "eric-data-search-engine-curator.name" . | quote }}
app.kubernetes.io/version: {{ .Chart.Version | replace "+" "_" | quote }}
app.kubernetes.io/instance: {{ .Release.Name | quote }}
{{- end -}}

{{/*
Default merged labels
*/}}
{{- define "eric-data-search-engine-curator.labels" -}}
  {{- $base := include "eric-data-search-engine-curator.k8sLabels" . | fromYaml -}}
  {{- $global := (.Values.global).labels -}}
  {{- $service := .Values.labels -}}
  {{- include "eric-data-search-engine-curator.mergeLabels" (dict "location" .Template.Name "sources" (list $base $global $service)) }}
{{- end -}}

{{- define "eric-data-search-engine-curator.logshipper-labels" -}}
  {{- include "eric-data-search-engine-curator.labels" . }}
{{- end -}}

{{/*
Create a map from testInternals with defaults if missing in values file.
This hides defaults from values file.
Version: 1.0
*/}}
{{ define "eric-data-search-engine-curator.testInternal" }}
  {{- $tiDefaults := (dict ) -}}
  {{ if .Values.testInternal }}
    {{- mergeOverwrite $tiDefaults .Values.testInternal | toJson -}}
  {{ else }}
    {{- $tiDefaults | toJson -}}
  {{ end }}
{{ end }}

{{/*
Create Search Engine host address.
*/}}
{{- define "eric-data-search-engine-curator.elasticsearch-host" -}}
  {{- $g := fromJson (include "eric-data-search-engine-curator.global" .) -}}
  {{- if $g.security.tls.enabled -}}
    {{- printf "%s-tls" .Values.searchengine.host -}}
  {{- else -}}
    {{- printf "%s" .Values.searchengine.host -}}
  {{- end -}}
{{- end -}}
