{{/* vim: set filetype=mustache: */}}

{{/*
Expand the name of the chart.
*/}}
{{- define "eric-data-search-engine.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "eric-data-search-engine.version" -}}
{{- printf "%s" .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "eric-data-search-engine.fullname" -}}
{{- if .Values.fullnameOverride -}}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- printf "%s" $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}

{{/*
Create Search Engine Service Name
*/}}
{{- define "eric-data-search-engine.fullname.host" -}}
{{- $g := fromJson (include "eric-data-search-engine.global" .) -}}
{{- if and $g.security.tls.enabled }}
    {{- printf "%s-tls" (include "eric-data-search-engine.fullname" .) -}}
{{- else -}}
    {{- printf "%s" (include "eric-data-search-engine.fullname" .) -}}
{{- end }}
{{- end -}}

{{/*
Create Search Engine host address
*/}}
{{- define "eric-data-search-engine-elasticsearch-host" -}}
{{- $g := fromJson (include "eric-data-search-engine.global" .) -}}
{{- if $g.security.tls.enabled -}}
  {{- printf "%s-tls:%d" .Values.searchengine.host 9200 -}}
{{- else -}}
  {{- printf "%s:%d" .Values.searchengine.host 9200 -}}
{{- end -}}
{{- end -}}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "eric-data-search-engine.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create image url
*/}}

{{- define "eric-data-search-engine.image-registry-url" }}
    {{- $productInfo := fromYaml (.Files.Get "eric-product-info.yaml") -}}
    {{- $g := fromJson (include "eric-data-search-engine.global" .) -}}
    {{- $registryUrl := $g.registry.url | default $productInfo.images.searchengine.registry -}}
    {{- $defaults := dict "imageCredentials" (dict "registry" (dict "url" $registryUrl)) -}}
    {{- $defaults := merge $defaults (dict "imageCredentials" (dict "repoPath" $productInfo.images.searchengine.repoPath)) -}}
    {{- $defaults := merge $defaults (dict "images" (dict "searchengine" (dict "name" $productInfo.images.searchengine.name))) -}}
    {{- $defaults := merge $defaults (dict "images" (dict "searchengine" (dict "tag" $productInfo.images.searchengine.tag))) -}}
    {{- $defaults := mergeOverwrite $defaults .Values -}}
    {{- $defaults := merge $defaults (dict "imageCredentials" (dict "searchengine" (dict "registry" (dict "url" $defaults.imageCredentials.registry.url)))) -}}
    {{- $defaults := merge $defaults (dict "imageCredentials" (dict "searchengine" (dict "repoPath" $defaults.imageCredentials.repoPath))) -}}
    {{- $defaults := mergeOverwrite $defaults .Values -}}
    {{- $registryUrl := $defaults.imageCredentials.searchengine.registry.url -}}
    {{- $repoPath := $defaults.imageCredentials.searchengine.repoPath -}}
    {{- $name := $defaults.images.searchengine.name -}}
    {{- $tag := $defaults.images.searchengine.tag -}}
    {{- printf "%s/%s/%s:%s" $registryUrl $repoPath $name $tag -}}
{{- end -}}

{{- define "eric-data-search-engine.metrics.image-registry-url" }}
    {{- $productInfo := fromYaml (.Files.Get "eric-product-info.yaml") -}}
    {{- $g := fromJson (include "eric-data-search-engine.global" .) -}}
    {{- $registryUrl := $g.registry.url | default $productInfo.images.metrics.registry -}}
    {{- $defaults := dict "imageCredentials" (dict "registry" (dict "url" $registryUrl)) -}}
    {{- $defaults := merge $defaults (dict "imageCredentials" (dict "repoPath" $productInfo.images.metrics.repoPath)) -}}
    {{- $defaults := merge $defaults (dict "images" (dict "metrics" (dict "name" $productInfo.images.metrics.name))) -}}
    {{- $defaults := merge $defaults (dict "images" (dict "metrics" (dict "tag" $productInfo.images.metrics.tag))) -}}
    {{- $defaults := mergeOverwrite $defaults .Values -}}
    {{- $defaults := merge $defaults (dict "imageCredentials" (dict "metrics" (dict "registry" (dict "url" $defaults.imageCredentials.registry.url)))) -}}
    {{- $defaults := merge $defaults (dict "imageCredentials" (dict "metrics" (dict "repoPath" $defaults.imageCredentials.repoPath))) -}}
    {{- $defaults := mergeOverwrite $defaults .Values -}}
    {{- $registryUrl := $defaults.imageCredentials.metrics.registry.url -}}
    {{- $repoPath := $defaults.imageCredentials.metrics.repoPath -}}
    {{- $name := $defaults.images.metrics.name -}}
    {{- $tag := $defaults.images.metrics.tag -}}
    {{- printf "%s/%s/%s:%s" $registryUrl $repoPath $name $tag -}}
{{- end -}}

{{- define "eric-data-search-engine.bragent.image-registry-url" }}
    {{- $productInfo := fromYaml (.Files.Get "eric-product-info.yaml") -}}
    {{- $g := fromJson (include "eric-data-search-engine.global" .) -}}
    {{- $registryUrl := $g.registry.url | default $productInfo.images.bragent.registry -}}
    {{- $defaults := dict "imageCredentials" (dict "registry" (dict "url" $registryUrl)) -}}
    {{- $defaults := merge $defaults (dict "imageCredentials" (dict "repoPath" $productInfo.images.bragent.repoPath)) -}}
    {{- $defaults := merge $defaults (dict "images" (dict "bragent" (dict "name" $productInfo.images.bragent.name))) -}}
    {{- $defaults := merge $defaults (dict "images" (dict "bragent" (dict "tag" $productInfo.images.bragent.tag))) -}}
    {{- $defaults := mergeOverwrite $defaults .Values -}}
    {{- $defaults := merge $defaults (dict "imageCredentials" (dict "bragent" (dict "registry" (dict "url" $defaults.imageCredentials.registry.url)))) -}}
    {{- $defaults := merge $defaults (dict "imageCredentials" (dict "bragent" (dict "repoPath" $defaults.imageCredentials.repoPath))) -}}
    {{- $defaults := mergeOverwrite $defaults .Values -}}
    {{- $registryUrl := $defaults.imageCredentials.bragent.registry.url -}}
    {{- $repoPath := $defaults.imageCredentials.bragent.repoPath -}}
    {{- $name := $defaults.images.bragent.name -}}
    {{- $tag := $defaults.images.bragent.tag -}}
    {{- printf "%s/%s/%s:%s" $registryUrl $repoPath $name $tag -}}
{{- end -}}

{{- define "eric-data-search-engine.tlsproxy.image-registry-url" }}
    {{- $productInfo := fromYaml (.Files.Get "eric-product-info.yaml") -}}
    {{- $g := fromJson (include "eric-data-search-engine.global" .) -}}
    {{- $registryUrl := $g.registry.url | default $productInfo.images.tlsproxy.registry -}}
    {{- $defaults := dict "imageCredentials" (dict "registry" (dict "url" $registryUrl)) -}}
    {{- $defaults := merge $defaults (dict "imageCredentials" (dict "repoPath" $productInfo.images.tlsproxy.repoPath)) -}}
    {{- $defaults := merge $defaults (dict "images" (dict "tlsproxy" (dict "name" $productInfo.images.tlsproxy.name))) -}}
    {{- $defaults := merge $defaults (dict "images" (dict "tlsproxy" (dict "tag" $productInfo.images.tlsproxy.tag))) -}}
    {{- $defaults := mergeOverwrite $defaults .Values -}}
    {{- $defaults := merge $defaults (dict "imageCredentials" (dict "tlsproxy" (dict "registry" (dict "url" $defaults.imageCredentials.registry.url)))) -}}
    {{- $defaults := merge $defaults (dict "imageCredentials" (dict "tlsproxy" (dict "repoPath" $defaults.imageCredentials.repoPath))) -}}
    {{- $defaults := mergeOverwrite $defaults .Values -}}
    {{- $registryUrl := $defaults.imageCredentials.tlsproxy.registry.url -}}
    {{- $repoPath := $defaults.imageCredentials.tlsproxy.repoPath -}}
    {{- $name := $defaults.images.tlsproxy.name -}}
    {{- $tag := $defaults.images.tlsproxy.tag -}}
    {{- printf "%s/%s/%s:%s" $registryUrl $repoPath $name $tag -}}
{{- end -}}

{{/*
Create agent name
*/}}
{{- define "eric-data-search-engine.agentname" -}}
{{ template "eric-data-search-engine.name" . }}-agent
{{- end -}}

{{/*
Create a map from testInternals with defaults if missing in values file.
This hides defaults from values file.
Version: 1.0
*/}}
{{ define "eric-data-search-engine.testInternal" }}
  {{- $tiDefaults := (dict ) -}}
  {{ if .Values.testInternal }}
    {{- mergeOverwrite $tiDefaults .Values.testInternal | toJson -}}
  {{ else }}
    {{- $tiDefaults | toJson -}}
  {{ end }}
{{ end }}

{{/*
Create a map from .Values.global with defaults if missing in values file.
This hides defaults from values file.
*/}}
{{ define "eric-data-search-engine.global" }}
  {{- $globalDefaults := dict "security" (dict "tls" (dict "enabled" true)) -}}
  {{- $globalDefaults := merge $globalDefaults (dict "registry" (dict "imagePullPolicy" "IfNotPresent")) -}}
  {{- $globalDefaults := merge $globalDefaults (dict "registry" (dict "url" "451278531435.dkr.ecr.us-east-1.amazonaws.com")) -}}
  {{- $globalDefaults := merge $globalDefaults (dict "pullSecret") -}}
  {{- $globalDefaults := merge $globalDefaults (dict "timezone" "UTC") -}}
  {{- $globalDefaults := merge $globalDefaults (dict "nodeSelector" (dict)) -}}
  {{- $globalDefaults := merge $globalDefaults (dict "internalIPFamily" "") -}}
  {{- $globalDefaults := merge $globalDefaults (dict "fsGroup" (dict)) -}}
  {{- $globalDefaults := merge $globalDefaults (dict "security" (dict "policyBinding" (dict "create" false))) -}}
  {{- $globalDefaults := merge $globalDefaults (dict "security" (dict "policyReferenceMap" (dict "default-restricted-security-policy" "default-restricted-security-policy"))) -}}
  {{- $globalDefaults := merge $globalDefaults (dict "security" (dict "policyReferenceMap" (dict "plc-9c20871f9bf62c7b09fd0c684ac651" "plc-9c20871f9bf62c7b09fd0c684ac651"))) -}}
  {{- $globalDefaults := merge $globalDefaults (dict "security" (dict "policyReferenceMap" (dict "plc-f60f72ea252a60cb7a179b9553c0c9" "plc-f60f72ea252a60cb7a179b9553c0c9"))) -}}
  {{ if .Values.global }}
    {{- mergeOverwrite $globalDefaults .Values.global | toJson -}}
  {{ else }}
    {{- $globalDefaults | toJson -}}
  {{ end }}
{{ end }}

{{- define "eric-data-search-engine.deprecation-notices" -}}
{{- $g := fromJson (include "eric-data-search-engine.global" .) }}
{{- end }}

{{- define "eric-data-search-engine.pod-anti-affinity" }}
affinity:
  podAntiAffinity:
  {{- if eq .root.Values.affinity.podAntiAffinity "hard" }}
    requiredDuringSchedulingIgnoredDuringExecution:
      - labelSelector:
          matchExpressions:
            - key: "app"
              operator: "In"
              values:
                - {{ include "eric-data-search-engine.fullname" .root | quote }}
            - key: "role"
              operator: "In"
              values:
                - {{ .context | quote }}
        topologyKey: "kubernetes.io/hostname"
  {{- else if eq .root.Values.affinity.podAntiAffinity "soft" }}
    preferredDuringSchedulingIgnoredDuringExecution:
      - weight: 100
        podAffinityTerm:
          labelSelector:
            matchExpressions:
              - key: "app"
                operator: "In"
                values:
                  - {{ include "eric-data-search-engine.fullname" .root | quote }}
              - key: "role"
                operator: "In"
                values:
                  - {{ .context | quote }}
          topologyKey: "kubernetes.io/hostname"
  {{- end -}}
{{- end -}}

{{/*
Create a merged set of nodeSelectors from global and service level.
*/}}
{{- define "eric-data-search-engine.nodeSelector" }}
{{- $g := fromJson (include "eric-data-search-engine.global" .root) -}}
  {{- $localNodeSelectorForContext := index .root.Values.nodeSelector .context -}}
  {{- if $localNodeSelectorForContext -}}
    {{- range $key, $localValue := $localNodeSelectorForContext -}}
        {{- if hasKey $g.nodeSelector $key -}}
          {{- $globalValue := index $g.nodeSelector $key -}}
          {{- if ne $globalValue $localValue -}}
            {{- printf "nodeSelector \"%s\" is specified in both global (%s: %s) and service level (%s: %s) with differing values which is not allowed." $key $key $globalValue $key $localValue | fail -}}
          {{- end -}}
        {{- end -}}
    {{- end -}}
    {{- toYaml (merge $g.nodeSelector $localNodeSelectorForContext) | trim -}}
  {{- else -}}
    {{- toYaml $g.nodeSelector | trim -}}
  {{- end -}}
{{- end -}}

{{- define "eric-data-search-engine.fsGroup.coordinated" -}}
{{- $g := fromJson (include "eric-data-search-engine.global" .) -}}
    {{- if $g.fsGroup.manual -}}
        {{ $g.fsGroup.manual }}
    {{- else if $g.fsGroup.namespace -}}
        {{- print "# The 'default' defined in the Security Policy will be used." -}}
    {{- else -}}
        10000
    {{- end -}}
{{- end -}}

{{- define "eric-data-search-engine.log-redirect" -}}
  {{- if has "stream" .Values.log.outputs -}}
    {{- if has "stdout" .Values.log.outputs -}}
      {{- "all" -}}
    {{- else -}}
      {{- "file" -}}
    {{- end -}}
  {{- else -}}
    {{- "stdout" -}}
  {{- end -}}
{{- end -}}

{{- define "eric-data-search-engine.resources" -}}
  {{- $resources := dict -}}
  {{- range $index, $context := . }}
    {{- $cpu := index $context "cpu" -}}
    {{- $memory := index $context "memory" -}}
    {{- $ephemeralStorage := index $context "ephemeral-storage" -}}
    {{- if $cpu -}}
      {{- $resources := merge $resources (dict $index (dict "cpu" $cpu)) -}}
    {{- end -}}
    {{- if $memory -}}
      {{- $resources := merge $resources (dict $index (dict "memory" $memory)) -}}
    {{- end -}}
    {{- if $ephemeralStorage -}}
      {{- $resources := merge $resources (dict $index (dict "ephemeral-storage" $ephemeralStorage)) -}}
    {{- end -}}
  {{- end }}
  {{- toYaml $resources -}}
{{- end -}}

{{- define "eric-data-search-engine.selectorLabels.master" }}
app: {{ include "eric-data-search-engine.fullname" . | quote }}
{{- if eq (include "eric-data-search-engine.needInstanceLabelSelector.master" .) "true" }}
app.kubernetes.io/instance: {{ .Release.Name | quote }}
{{- end -}}
{{- end -}}

{{- define "eric-data-search-engine.needInstanceLabelSelector.master" }}
    {{- $needInstanceLabelSelector := false -}}
    {{- if .Release.IsInstall }}
        {{- $needInstanceLabelSelector = true -}}
    {{- else if .Release.IsUpgrade }}
        {{- $name := print (include "eric-data-search-engine.fullname" .) "-master" -}}
        {{- $seSs := (lookup "apps/v1" "StatefulSet" .Release.Namespace $name) -}}
        {{- if $seSs -}}
            {{- if hasKey $seSs.spec.selector.matchLabels "app.kubernetes.io/instance" -}}
            {{- $needInstanceLabelSelector = true -}}
            {{- end -}}
        {{- end -}}
    {{- end -}}
    {{- $needInstanceLabelSelector -}}
{{- end }}

{{- define "eric-data-search-engine.selectorLabels.data" }}
app: {{ include "eric-data-search-engine.fullname" . | quote }}
{{- if eq (include "eric-data-search-engine.needInstanceLabelSelector.data" .) "true" }}
app.kubernetes.io/instance: {{ .Release.Name | quote }}
{{- end -}}
{{- end -}}

{{- define "eric-data-search-engine.needInstanceLabelSelector.data" }}
    {{- $needInstanceLabelSelector := false -}}
    {{- if .Release.IsInstall }}
        {{- $needInstanceLabelSelector = true -}}
    {{- else if .Release.IsUpgrade }}
        {{- $name := print (include "eric-data-search-engine.fullname" .) "-data" -}}
        {{- $seSs := (lookup "apps/v1" "StatefulSet" .Release.Namespace $name) -}}
        {{- if $seSs -}}
            {{- if hasKey $seSs.spec.selector.matchLabels "app.kubernetes.io/instance" -}}
            {{- $needInstanceLabelSelector = true -}}
            {{- end -}}
        {{- end -}}
    {{- end -}}
    {{- $needInstanceLabelSelector -}}
{{- end }}
