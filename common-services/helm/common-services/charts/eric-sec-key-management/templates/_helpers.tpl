{{/* vim: set filetype=mustache: */}}
{{/*
Create a map from ".Values.global" with defaults if missing in values file.
This hides defaults from values file.
*/}}
{{ define "eric-sec-key-management.global" }}
  {{- $globalDefaults := dict "nodeSelector" (dict) -}}
  {{- $globalDefaults := merge $globalDefaults (dict "pullSecret" "") -}}
  {{- $globalDefaults := merge $globalDefaults (dict "registry" (dict "imagePullPolicy" "IfNotPresent" )) -}}
  {{- $globalDefaults := merge $globalDefaults (dict "security" (dict "tls" (dict "enabled" true))) -}}
  {{- $globalDefaults := merge $globalDefaults (dict "featureGates" (dict "caBootstrap_v2" false)) -}}
  {{ if .Values.global }}
    {{- mergeOverwrite $globalDefaults .Values.global | toJson -}}
  {{ else }}
    {{- $globalDefaults | toJson -}}
  {{ end }}
{{ end }}

{{/*
Expand the name of the chart.
*/}}
{{- define "eric-sec-key-management.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "eric-sec-key-management.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create chart version as used by the chart label.
*/}}
{{- define "eric-sec-key-management.version" -}}
{{- printf "%s" .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create configmap name based on service version.
This is to ensure that a pod always mounts the right config map version during upgrade and rollback,
where different pods might belong to different controller versions.
*/}}
{{- define "eric-sec-key-management.configMapName" -}}
{{- $suffix :=  regexReplaceAll "(.*)[+|-].*" .Chart.Version "${1}" | sha256sum | substr 0 5 | lower -}}
{{ printf "%s-config-%s" (include "eric-sec-key-management.name" .) $suffix }}
{{- end -}}

{{/*
Create configmap name for job pod.
*/}}
{{- define "eric-sec-key-management.configMapNameJob" -}}
{{ printf "%s-config-job" (include "eric-sec-key-management.name" .) }}
{{- end -}}

{{/*
Create a value of networkPolicy from global and service level.
Service level value is taken into account only if global one is true.
Global default value is false.
*/}}
{{ define "eric-sec-key-management.networkPolicy" }}
  {{- $networkPolicy := false -}}
  {{- if (((.Values.global).networkPolicy).enabled) -}}
    {{- $networkPolicy = .Values.global.networkPolicy.enabled -}}
  {{- end -}}
  {{- if eq $networkPolicy true -}}
    {{- $networkPolicy = .Values.networkPolicy.enabled -}}
  {{- end -}}
  {{- printf "%t" $networkPolicy -}}
{{ end }}

{{/*
The ca image path
*/}}
{{- define "eric-sec-key-management.caImagePath" }}
    {{- $productInfo := fromYaml (.Files.Get "eric-product-info.yaml") -}}
    {{- $registryUrl := $productInfo.images.ca.registry -}}
    {{- $repoPath := $productInfo.images.ca.repoPath -}}
    {{- $name := $productInfo.images.ca.name -}}
    {{- $tag := $productInfo.images.ca.tag -}}
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
The unsealer image path
*/}}
{{- define "eric-sec-key-management.unsealerImagePath" }}
    {{- $productInfo := fromYaml (.Files.Get "eric-product-info.yaml") -}}
    {{- $registryUrl := $productInfo.images.unsealer.registry -}}
    {{- $repoPath := $productInfo.images.unsealer.repoPath -}}
    {{- $name := $productInfo.images.unsealer.name -}}
    {{- $tag := $productInfo.images.unsealer.tag -}}
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
The bootstrapjob image path
*/}}
{{- define "eric-sec-key-management.bootstrapJobImagePath" }}
    {{- $productInfo := fromYaml (.Files.Get "eric-product-info.yaml") -}}
    {{- $registryUrl := $productInfo.images.bootstrapJob.registry -}}
    {{- $repoPath := $productInfo.images.bootstrapJob.repoPath -}}
    {{- $name := $productInfo.images.bootstrapJob.name -}}
    {{- $tag := $productInfo.images.bootstrapJob.tag -}}
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
The shelter image path
*/}}
{{- define "eric-sec-key-management.shelterImagePath" }}
    {{- $productInfo := fromYaml (.Files.Get "eric-product-info.yaml") -}}
    {{- $registryUrl := $productInfo.images.shelter.registry -}}
    {{- $repoPath := $productInfo.images.shelter.repoPath -}}
    {{- $name := $productInfo.images.shelter.name -}}
    {{- $tag := $productInfo.images.shelter.tag -}}
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
The vault image path
*/}}
{{- define "eric-sec-key-management.vaultImagePath" }}
    {{- $productInfo := fromYaml (.Files.Get "eric-product-info.yaml") -}}
    {{- $registryUrl := $productInfo.images.vault.registry -}}
    {{- $repoPath := $productInfo.images.vault.repoPath -}}
    {{- $name := $productInfo.images.vault.name -}}
    {{- $tag := $productInfo.images.vault.tag -}}
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
The metrics-exporter image path
*/}}
{{- define "eric-sec-key-management.metricsExporterImagePath" }}
    {{- $productInfo := fromYaml (.Files.Get "eric-product-info.yaml") -}}
    {{- $registryUrl := $productInfo.images.metrics.registry -}}
    {{- $repoPath := $productInfo.images.metrics.repoPath -}}
    {{- $name := $productInfo.images.metrics.name -}}
    {{- $tag := $productInfo.images.metrics.tag -}}
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
Create image pull secrets
*/}}
{{- define "eric-sec-key-management.imagePullSecrets" -}}
{{- $g := fromJson (include "eric-sec-key-management.global" .) -}}
{{- $globalPullSecret := $g.pullSecret -}}
    {{- if .Values.global -}}
        {{- if .Values.global.pullSecret -}}
            {{- $globalPullSecret = .Values.global.pullSecret -}}
        {{- end -}}
    {{- end -}}
    {{- if .Values.imageCredentials -}}
        {{- if .Values.imageCredentials.pullSecret -}}
             {{- $globalPullSecret = .Values.imageCredentials.pullSecret -}}
        {{- end -}}
    {{- end -}}
    {{- print $globalPullSecret -}}
{{- end -}}

{{/*
Create image pull policy
*/}}
{{- define "eric-sec-key-management.imagePullPolicy" -}}
{{- $g := fromJson (include "eric-sec-key-management.global" .) -}}
{{- $globalRegistryImagePullPolicy := $g.registry.imagePullPolicy -}}
    {{- if .Values.global -}}
        {{- if .Values.global.registry -}}
            {{- if .Values.global.registry.imagePullPolicy -}}
                {{- $globalRegistryImagePullPolicy = .Values.global.registry.imagePullPolicy -}}
            {{- end -}}
        {{- end -}}
    {{- end -}}
    {{- if .Values.imageCredentials -}}
        {{- if .Values.imageCredentials.registry -}}
            {{- if .Values.imageCredentials.registry.imagePullPolicy -}}
                {{- $globalRegistryImagePullPolicy = .Values.imageCredentials.registry.imagePullPolicy -}}
            {{- end -}}
        {{- end -}}
    {{- end -}}
    {{- print $globalRegistryImagePullPolicy -}}
{{- end -}}

{{/*
Create ca resource limits attributes
*/}}
{{- define "eric-sec-key-management.ca-resource-limits" -}}
{{- if index .Values.resources.ca.limits.memory -}}
memory: {{ .Values.resources.ca.limits.memory | quote }}
{{- end }}
{{- if index .Values.resources.ca.limits.cpu }}
cpu: {{ .Values.resources.ca.limits.cpu | quote }}
{{- end }}
{{- if index .Values.resources.ca.limits "ephemeral-storage" }}
ephemeral-storage: {{ index .Values.resources.ca.limits "ephemeral-storage" | quote }}
{{- end }}
{{- end -}}

{{/*
Create ca resource requests attributes
*/}}
{{- define "eric-sec-key-management.ca-resource-requests" -}}
{{- if index .Values.resources.ca.requests.memory -}}
memory: {{ .Values.resources.ca.requests.memory | quote }}
{{- end }}
{{- if index .Values.resources.ca.requests.cpu }}
cpu: {{ .Values.resources.ca.requests.cpu | quote }}
{{- end }}
{{- if index .Values.resources.ca.requests "ephemeral-storage" }}
ephemeral-storage: {{ index .Values.resources.ca.requests "ephemeral-storage" | quote }}
{{- end }}
{{- end -}}

{{/*
Create unsealer resource limits attributes
*/}}
{{- define "eric-sec-key-management.unsealer-resource-limits" -}}
{{- if index .Values.resources.unsealer.limits.memory -}}
memory: {{ .Values.resources.unsealer.limits.memory | quote }}
{{- end }}
{{- if index .Values.resources.unsealer.limits.cpu }}
cpu: {{ .Values.resources.unsealer.limits.cpu | quote }}
{{- end }}
{{- if index .Values.resources.unsealer.limits "ephemeral-storage" }}
ephemeral-storage: {{ index .Values.resources.unsealer.limits "ephemeral-storage" | quote }}
{{- end }}
{{- end -}}

{{/*
Create unsealer resource requests attributes
*/}}
{{- define "eric-sec-key-management.unsealer-resource-requests" -}}
{{- if index .Values.resources.unsealer.requests.memory -}}
memory: {{ .Values.resources.unsealer.requests.memory | quote }}
{{- end }}
{{- if index .Values.resources.unsealer.requests.cpu }}
cpu: {{ .Values.resources.unsealer.requests.cpu | quote }}
{{- end }}
{{- if index .Values.resources.unsealer.requests "ephemeral-storage" }}
ephemeral-storage: {{ index .Values.resources.unsealer.requests "ephemeral-storage" | quote }}
{{- end }}
{{- end -}}

{{/*
Create bootstrap job resource limits attributes
*/}}
{{- define "eric-sec-key-management.bootstrapjob-resource-limits" -}}
{{- if index .Values.resources.bootstrapJob.limits.memory -}}
memory: {{ .Values.resources.bootstrapJob.limits.memory | quote }}
{{- end }}
{{- if index .Values.resources.bootstrapJob.limits.cpu }}
cpu: {{ .Values.resources.bootstrapJob.limits.cpu | quote }}
{{- end }}
{{- if index .Values.resources.bootstrapJob.limits "ephemeral-storage" }}
ephemeral-storage: {{ index .Values.resources.bootstrapJob.limits "ephemeral-storage" | quote }}
{{- end }}
{{- end -}}

{{/*
Create bootstrap job resource requests attributes
*/}}
{{- define "eric-sec-key-management.bootstrapjob-resource-requests" -}}
{{- if index .Values.resources.bootstrapJob.requests.memory -}}
memory: {{ .Values.resources.bootstrapJob.requests.memory | quote }}
{{- end }}
{{- if index .Values.resources.bootstrapJob.requests.cpu }}
cpu: {{ .Values.resources.bootstrapJob.requests.cpu | quote }}
{{- end }}
{{- if index .Values.resources.bootstrapJob.requests "ephemeral-storage" }}
ephemeral-storage: {{ index .Values.resources.bootstrapJob.requests "ephemeral-storage" | quote }}
{{- end }}
{{- end -}}

{{/*
Create shelter resource limits attributes
*/}}
{{- define "eric-sec-key-management.shelter-resource-limits" -}}
{{- if index .Values.resources.shelter.limits.memory -}}
memory: {{ .Values.resources.shelter.limits.memory | quote }}
{{- end }}
{{- if index .Values.resources.shelter.limits.cpu }}
cpu: {{ .Values.resources.shelter.limits.cpu | quote }}
{{- end }}
{{- if index .Values.resources.shelter.limits "ephemeral-storage" }}
ephemeral-storage: {{ index .Values.resources.shelter.limits "ephemeral-storage" | quote }}
{{- end }}
{{- end -}}

{{/*
Create shelter resource requests attributes
*/}}
{{- define "eric-sec-key-management.shelter-resource-requests" -}}
{{- if index .Values.resources.shelter.requests.memory -}}
memory: {{ .Values.resources.shelter.requests.memory | quote }}
{{- end }}
{{- if index .Values.resources.shelter.requests.cpu }}
cpu: {{ .Values.resources.shelter.requests.cpu | quote }}
{{- end }}
{{- if index .Values.resources.shelter.requests "ephemeral-storage" }}
ephemeral-storage: {{ index .Values.resources.shelter.requests "ephemeral-storage" | quote }}
{{- end }}
{{- end -}}

{{/*
Create vault resource limits attributes
*/}}
{{- define "eric-sec-key-management.vault-resource-limits" -}}
{{- if index .Values.resources.vault.limits.memory -}}
memory: {{ .Values.resources.vault.limits.memory | quote }}
{{- end }}
{{- if index .Values.resources.vault.limits.cpu }}
cpu: {{ .Values.resources.vault.limits.cpu | quote }}
{{- end }}
{{- if index .Values.resources.vault.limits "ephemeral-storage" }}
ephemeral-storage: {{ index .Values.resources.vault.limits "ephemeral-storage" | quote }}
{{- end }}
{{- end -}}

{{/*
Create vault resource requests attributes
*/}}
{{- define "eric-sec-key-management.vault-resource-requests" -}}
{{- if index .Values.resources.vault.requests.memory -}}
memory: {{ .Values.resources.vault.requests.memory | quote }}
{{- end }}
{{- if index .Values.resources.vault.requests.cpu }}
cpu: {{ .Values.resources.vault.requests.cpu | quote }}
{{- end }}
{{- if index .Values.resources.vault.requests "ephemeral-storage" }}
ephemeral-storage: {{ index .Values.resources.vault.requests "ephemeral-storage" | quote }}
{{- end }}
{{- end -}}

{{/*
Create metrics-exporter resource limits attributes
*/}}
{{- define "eric-sec-key-management.metrics-exporter-resource-limits" -}}
{{- if index .Values "resources" "metrics" "limits" "memory" -}}
memory: {{ index .Values "resources" "metrics" "limits" "memory" | quote }}
{{- end }}
{{- if index .Values "resources" "metrics" "limits" "cpu" }}
cpu: {{ index .Values "resources" "metrics" "limits" "cpu" | quote }}
{{- end }}
{{- if index .Values "resources" "metrics" "limits" "ephemeral-storage" }}
ephemeral-storage: {{ index .Values "resources" "metrics" "limits" "ephemeral-storage" | quote }}
{{- end }}
{{- end -}}

{{/*
Create metrics-exporter resource requests attributes
*/}}
{{- define "eric-sec-key-management.metrics-exporter-resource-requests" -}}
{{- if index .Values "resources" "metrics" "requests" "memory" -}}
memory: {{ index .Values "resources" "metrics" "requests" "memory" | quote }}
{{- end }}
{{- if index .Values "resources" "metrics" "requests" "cpu" }}
cpu: {{ index .Values "resources" "metrics" "requests" "cpu" | quote }}
{{- end }}
{{- if index .Values "resources" "metrics" "requests" "ephemeral-storage" }}
ephemeral-storage: {{ index .Values "resources" "metrics" "requests" "ephemeral-storage" | quote }}
{{- end }}
{{- end -}}

{{/*
Create metrics liveness probe attributes
*/}}
{{- define "eric-sec-key-management.metrics-liveness" -}}
initialDelaySeconds: {{ .Values.probes.metrics.livenessProbe.initialDelaySeconds }}
failureThreshold: {{ .Values.probes.metrics.livenessProbe.failureThreshold }}
periodSeconds: {{ .Values.probes.metrics.livenessProbe.periodSeconds }}
timeoutSeconds: {{ .Values.probes.metrics.livenessProbe.timeoutSeconds }}
{{- end -}}

{{/*
Create metrics readiness probe attributes
*/}}
{{- define "eric-sec-key-management.metrics-readiness" -}}
initialDelaySeconds: {{ .Values.probes.metrics.readinessProbe.initialDelaySeconds }}
failureThreshold: {{ .Values.probes.metrics.readinessProbe.failureThreshold }}
periodSeconds: {{ .Values.probes.metrics.readinessProbe.periodSeconds }}
successThreshold: {{ .Values.probes.metrics.readinessProbe.successThreshold }}
timeoutSeconds: {{ .Values.probes.metrics.readinessProbe.timeoutSeconds }}
{{- end -}}

{{/*
Create shelter liveness probe attributes
*/}}
{{- define "eric-sec-key-management.shelter-liveness" -}}
{{- $startupProbe := semverCompare ">=1.18-0" (printf "%s.%s" .Capabilities.KubeVersion.Major (trimSuffix "+" .Capabilities.KubeVersion.Minor)) -}}
{{- if not $startupProbe -}}
initialDelaySeconds: {{ .Values.probes.shelter.livenessProbe.initialDelaySeconds }}
{{- end }}
failureThreshold: {{ .Values.probes.shelter.livenessProbe.failureThreshold }}
periodSeconds: {{ .Values.probes.shelter.livenessProbe.periodSeconds }}
timeoutSeconds: {{ .Values.probes.shelter.livenessProbe.timeoutSeconds }}
{{- end -}}

{{/*
Create shelter readiness probe attributes
*/}}
{{- define "eric-sec-key-management.shelter-readiness" -}}
initialDelaySeconds: {{ .Values.probes.shelter.readinessProbe.initialDelaySeconds }}
failureThreshold: {{ .Values.probes.shelter.readinessProbe.failureThreshold }}
periodSeconds: {{ .Values.probes.shelter.readinessProbe.periodSeconds }}
successThreshold: {{ .Values.probes.shelter.readinessProbe.successThreshold }}
timeoutSeconds: {{ .Values.probes.shelter.readinessProbe.timeoutSeconds }}
{{- end -}}

{{/*
Create shelter startup probe attributes
*/}}
{{- define "eric-sec-key-management.shelter-startup" -}}
initialDelaySeconds: {{ .Values.probes.shelter.startupProbe.initialDelaySeconds }}
failureThreshold: {{ .Values.probes.shelter.startupProbe.failureThreshold }}
periodSeconds: {{ .Values.probes.shelter.startupProbe.periodSeconds }}
timeoutSeconds: {{ .Values.probes.shelter.startupProbe.timeoutSeconds }}
{{- end -}}

{{/*
Create vault liveness probe attributes
*/}}
{{- define "eric-sec-key-management.vault-liveness" -}}
{{- $startupProbe := semverCompare ">=1.18-0" (printf "%s.%s" .Capabilities.KubeVersion.Major (trimSuffix "+" .Capabilities.KubeVersion.Minor)) -}}
{{- if not $startupProbe -}}
initialDelaySeconds: {{ .Values.probes.vault.livenessProbe.initialDelaySeconds }}
{{- end }}
failureThreshold: {{ .Values.probes.vault.livenessProbe.failureThreshold }}
periodSeconds: {{ .Values.probes.vault.livenessProbe.periodSeconds }}
timeoutSeconds: {{ .Values.probes.vault.livenessProbe.timeoutSeconds }}
{{- end -}}

{{/*
Create vault readiness probe attributes
*/}}
{{- define "eric-sec-key-management.vault-readiness" -}}
initialDelaySeconds: {{ .Values.probes.vault.readinessProbe.initialDelaySeconds }}
failureThreshold: {{ .Values.probes.vault.readinessProbe.failureThreshold }}
periodSeconds: {{ .Values.probes.vault.readinessProbe.periodSeconds }}
successThreshold: {{ .Values.probes.vault.readinessProbe.successThreshold }}
timeoutSeconds: {{ .Values.probes.vault.readinessProbe.timeoutSeconds }}
{{- end -}}

{{/*
Create vault startup probe attributes
*/}}
{{- define "eric-sec-key-management.vault-startup" -}}
initialDelaySeconds: {{ .Values.probes.vault.startupProbe.initialDelaySeconds }}
failureThreshold: {{ .Values.probes.vault.startupProbe.failureThreshold }}
periodSeconds: {{ .Values.probes.vault.startupProbe.periodSeconds }}
timeoutSeconds: {{ .Values.probes.vault.startupProbe.timeoutSeconds }}
{{- end -}}

{{/*
Create annotation for the product information
*/}}
{{- define "eric-sec-key-management.product-info" }}
ericsson.com/product-name: {{ (fromYaml (.Files.Get "eric-product-info.yaml")).productName | quote }}
ericsson.com/product-number: {{ (fromYaml (.Files.Get "eric-product-info.yaml")).productNumber | quote }}
ericsson.com/product-revision: {{ regexReplaceAll "(.*)[+|-].*" .Chart.Version "${1}" | quote }}
{{- end }}

{{/*
Merge user-defined annotations with product info (DR-D1121-065, DR-D1121-060).
*/}}
{{- define "eric-sec-key-management.annotations" -}}
  {{- $productInfo := include "eric-sec-key-management.product-info" . | fromYaml -}}
  {{- $globalAnn := (.Values.global).annotations -}}
  {{- $serviceAnn := .Values.annotations -}}
  {{- include "eric-sec-key-management.mergeAnnotations" (dict "location" .Template.Name "sources" (list $productInfo $globalAnn $serviceAnn)) | trim }}
{{- end -}}

{{/*
Logshipper annotations
*/}}
{{- define "eric-sec-key-management.logshipper-annotations" }}
{{- println "" -}}
{{- include "eric-sec-key-management.annotations" . -}}
{{- end }}

{{/*
Merge user-defined labels with product labels (DR-D1121-068, DR-D1121-060).
*/}}
{{- define "eric-sec-key-management.labels" -}}
  {{- $productLabels := include "eric-sec-key-management.product-labels" . | fromYaml -}}
  {{- $globalLabels := (.Values.global).labels -}}
  {{- $serviceLabels := .Values.labels -}}
  {{- include "eric-sec-key-management.mergeLabels" (dict "location" .Template.Name "sources" (list $productLabels $globalLabels $serviceLabels)) | trim }}
{{- end -}}

{{/*
Logshipper labels
*/}}
{{- define "eric-sec-key-management.logshipper-labels" }}
{{- println "" -}}
{{- include "eric-sec-key-management.labels" . -}}
{{- end }}

{{/*
Create a merged set of nodeSelectors from global and service level.
*/}}
{{ define "eric-sec-key-management.nodeSelector" }}
  {{- $g := fromJson (include "eric-sec-key-management.global" .) -}}
  {{- $global := $g.nodeSelector -}}
  {{- $service := .Values.nodeSelector -}}
  {{- include "eric-sec-key-management.aggregatedMerge" (dict "context" "nodeSelector" "location" .Template.Name "sources" (list $global $service)) | trim -}}
{{ end }}

{{/*
Create the fsGroup
This hides the way how the fsGroup value becomes assigned.
*/}}
{{- define "eric-sec-key-management.fsGroup.coordinated" -}}
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

{{- define "eric-sec-key-management.log-redirect-param" -}}
{{- $logStdout    := has "stdout" .Values.log.outputs -}}
{{- $logStream    := has "stream" .Values.log.outputs -}}
{{- if and $logStream $logStdout -}}
    "all"
{{- else if $logStream -}}
    "file"
{{- else -}}
    "stdout"
{{- end -}}
{{- end -}}

{{/*
Define Security Policy Role Binding creation condition, note: returns boolean as string
*/}}
{{- define "eric-sec-key-management.securityPolicyRoleBinding" -}}
{{- $psprolebinding := false -}}
{{- if .Values.global -}}
    {{- if .Values.global.security -}}
        {{- if .Values.global.security.policyBinding -}}
            {{- if hasKey .Values.global.security.policyBinding "create" -}}
               {{- $psprolebinding = .Values.global.security.policyBinding.create -}}
           {{- end -}}
        {{- end -}}
    {{- end -}}
{{- end -}}
{{- $psprolebinding -}}
{{- end -}}

{{/*
Define reference to Security Policy mapping
*/}}
{{- define "eric-sec-key-management.securityPolicyReference" -}}
{{- $securitypolicyreference := "default-restricted-security-policy" -}}
{{- if .Values.global -}}
    {{- if .Values.global.security -}}
        {{- if .Values.global.security.policyReferenceMap -}}
            {{- if hasKey .Values.global.security.policyReferenceMap "default-restricted-security-policy" -}}
                {{- $securitypolicyreference = index .Values "global" "security" "policyReferenceMap" "default-restricted-security-policy" -}}
            {{- end -}}
        {{- end -}}
    {{- end -}}
{{- end -}}
{{- $securitypolicyreference -}}
{{- end -}}

{{- define "eric-sec-key-management.securityPolicy.annotations" -}}
ericsson.com/security-policy.type: "restricted/default"
ericsson.com/security-policy.capabilities: ""
{{- end -}}

{{/*
Define the apparmor annotation creation based on input profile and container name
*/}}
{{- define "eric-sec-key-management.getApparmorAnnotation" -}}
{{- $profile := index . "profile" -}}
{{- $containerName := index . "ContainerName" -}}
{{- if $profile.type -}}
{{- if eq "runtime/default" (lower $profile.type) }}
container.apparmor.security.beta.kubernetes.io/{{ $containerName }}: "runtime/default"
{{- else if eq "unconfined" (lower $profile.type) }}
container.apparmor.security.beta.kubernetes.io/{{ $containerName }}: "unconfined"
{{- else if eq "localhost" (lower $profile.type) }}
{{- if $profile.localhostProfile }}
{{- $localhostProfileList := (splitList "/" $profile.localhostProfile) -}}
{{- if (last $localhostProfileList) }}
container.apparmor.security.beta.kubernetes.io/{{ $containerName }}: "localhost/{{ (last $localhostProfileList ) }}"
{{- end }}
{{- end }}
{{- end -}}
{{- end -}}
{{- end -}}

{{/*
Define the apparmor annotation for kms-ca container
*/}}
{{- define "eric-sec-key-management.kms-ca.appArmorAnnotations" -}}
{{- if .Values.appArmorProfile -}}
{{- $profile := .Values.appArmorProfile -}}
{{- if index .Values.appArmorProfile "kms-ca" -}}
{{- $profile = index .Values.appArmorProfile "kms-ca" }}
{{- end -}}
{{- include "eric-sec-key-management.getApparmorAnnotation" (dict "profile" $profile "ContainerName" "kms-ca") }}
{{- end -}}
{{- end -}}

{{/*
Define the apparmor annotation for kms-mon container
*/}}
{{- define "eric-sec-key-management.kms-mon.appArmorAnnotations" -}}
{{- if .Values.appArmorProfile -}}
{{- $profile := .Values.appArmorProfile -}}
{{- if index .Values.appArmorProfile "kms-mon" -}}
{{- $profile = index .Values.appArmorProfile "kms-mon" }}
{{- end -}}
{{- include "eric-sec-key-management.getApparmorAnnotation" (dict "profile" $profile "ContainerName" "kms-mon") }}
{{- end -}}
{{- end -}}

{{/*
Define the apparmor annotation for kms container
*/}}
{{- define "eric-sec-key-management.kms.appArmorAnnotations" -}}
{{- if .Values.appArmorProfile -}}
{{- $profile := .Values.appArmorProfile -}}
{{- if index .Values.appArmorProfile "kms" -}}
{{- $profile = index .Values.appArmorProfile "kms" }}
{{- end -}}
{{- include "eric-sec-key-management.getApparmorAnnotation" (dict "profile" $profile "ContainerName" "kms") }}
{{- end -}}
{{- end -}}

{{/*
Define the apparmor annotation for shelter container
*/}}
{{- define "eric-sec-key-management.shelter.appArmorAnnotations" -}}
{{- if .Values.appArmorProfile -}}
{{- $profile := .Values.appArmorProfile -}}
{{- if index .Values.appArmorProfile "shelter" -}}
{{- $profile = index .Values.appArmorProfile "shelter" }}
{{- end -}}
{{- include "eric-sec-key-management.getApparmorAnnotation" (dict "profile" $profile "ContainerName" "shelter") }}
{{- end -}}
{{- end -}}

{{/*
Define the apparmor annotation for eric-sec-key-management-metrics container
*/}}
{{- define "eric-sec-key-management.eric-sec-key-management-metrics.appArmorAnnotations" -}}
{{- if .Values.appArmorProfile -}}
{{- $profile := .Values.appArmorProfile -}}
{{- if index .Values.appArmorProfile "eric-sec-key-management-metrics" -}}
{{- $profile = index .Values.appArmorProfile "eric-sec-key-management-metrics" }}
{{- end -}}
{{- include "eric-sec-key-management.getApparmorAnnotation" (dict "profile" $profile "ContainerName" "eric-sec-key-management-metrics") }}
{{- end -}}
{{- end -}}

{{/*
Define the apparmor annotation for logshipper container
*/}}
{{- define "eric-sec-key-management.logshipper.appArmorAnnotations" -}}
{{- if .Values.appArmorProfile -}}
{{- $profile := .Values.appArmorProfile -}}
{{- if index .Values.appArmorProfile "logshipper" -}}
{{- $profile = index .Values.appArmorProfile "logshipper" }}
{{- end -}}
{{- include "eric-sec-key-management.getApparmorAnnotation" (dict "profile" $profile "ContainerName" "logshipper") }}
{{- end -}}
{{- end -}}

{{/*
Define the seccomp security context creation based on input profile (no container name needed since it is already in the containers security profile)
*/}}
{{- define "eric-sec-key-management.getSeccompSecurityContext" -}}
{{- $profile := index . "profile" -}}
{{- if $profile.type -}}
{{- if eq "runtimedefault" (lower $profile.type) }}
seccompProfile:
  type: RuntimeDefault
{{- else if eq "unconfined" (lower $profile.type) }}
seccompProfile:
  type: Unconfined
{{- else if eq "localhost" (lower $profile.type) }}
seccompProfile:
  type: Localhost
  localhostProfile: {{ $profile.localhostProfile }}
{{- end }}
{{- end -}}
{{- end -}}

{{/*
Define the seccomp security context for kms-ca container
*/}}
{{- define "eric-sec-key-management.kms-ca.seccompProfile" -}}
{{- if .Values.seccompProfile }}
{{- $profile := .Values.seccompProfile }}
{{- if index .Values.seccompProfile "kms-ca" }}
{{- $profile = index .Values.seccompProfile "kms-ca" }}
{{- end }}
{{- include "eric-sec-key-management.getSeccompSecurityContext" (dict "profile" $profile) }}
{{- end -}}
{{- end -}}

{{/*
Define the seccomp security context for kms-mon container
*/}}
{{- define "eric-sec-key-management.kms-mon.seccompProfile" -}}
{{- if .Values.seccompProfile }}
{{- $profile := .Values.seccompProfile }}
{{- if index .Values.seccompProfile "kms-mon" }}
{{- $profile = index .Values.seccompProfile "kms-mon" }}
{{- end }}
{{- include "eric-sec-key-management.getSeccompSecurityContext" (dict "profile" $profile) }}
{{- end -}}
{{- end -}}

{{/*
Define the seccomp security context for kms container
*/}}
{{- define "eric-sec-key-management.kms.seccompProfile" -}}
{{- if .Values.seccompProfile }}
{{- $profile := .Values.seccompProfile }}
{{- if index .Values.seccompProfile "kms" }}
{{- $profile = index .Values.seccompProfile "kms" }}
{{- end }}
{{- include "eric-sec-key-management.getSeccompSecurityContext" (dict "profile" $profile) }}
{{- end -}}
{{- end -}}

{{/*
Define the seccomp security context for shelter container
*/}}
{{- define "eric-sec-key-management.shelter.seccompProfile" -}}
{{- if .Values.seccompProfile }}
{{- $profile := .Values.seccompProfile }}
{{- if index .Values.seccompProfile "shelter" }}
{{- $profile = index .Values.seccompProfile "shelter" }}
{{- end }}
{{- include "eric-sec-key-management.getSeccompSecurityContext" (dict "profile" $profile) }}
{{- end -}}
{{- end -}}

{{/*
Define the seccomp security context for eric-sec-key-management-metrics container
*/}}
{{- define "eric-sec-key-management.eric-sec-key-management-metrics.seccompProfile" -}}
{{- if .Values.seccompProfile }}
{{- $profile := .Values.seccompProfile }}
{{- if index .Values.seccompProfile "eric-sec-key-management-metrics" }}
{{- $profile = index .Values.seccompProfile "eric-sec-key-management-metrics" }}
{{- end }}
{{- include "eric-sec-key-management.getSeccompSecurityContext" (dict "profile" $profile) }}
{{- end -}}
{{- end -}}

{{/*
Define the seccomp security context for logshipper container
*/}}
{{- define "eric-sec-key-management.logshipper.seccompProfile" -}}
{{- if .Values.seccompProfile }}
{{- $profile := .Values.seccompProfile }}
{{- if index .Values.seccompProfile "logshipper" }}
{{- $profile = index .Values.seccompProfile "logshipper" }}
{{- end }}
{{- include "eric-sec-key-management.getSeccompSecurityContext" (dict "profile" $profile) }}
{{- end -}}
{{- end -}}
