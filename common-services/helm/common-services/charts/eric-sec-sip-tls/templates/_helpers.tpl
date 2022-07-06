{{/*
Create a map from ".Values.global" with defaults if missing in values file.
This hides defaults from values file.
*/}}
{{ define "eric-sec-sip-tls.global" }}
  {{- $globalDefaults := dict "security" (dict "tls" (dict "enabled" true)) -}}
  {{- $globalDefaults := merge $globalDefaults (dict "nodeSelector" (dict)) -}}
  {{- $globalDefaults := merge $globalDefaults (dict "timezone" "UTC") -}}
  {{- $globalDefaults := merge $globalDefaults (dict "registry" (dict "url" "451278531435.dkr.ecr.us-east-1.amazonaws.com")) -}}
  {{- $globalDefaults := merge $globalDefaults (dict "registry" (dict "imagePullPolicy" "IfNotPresent")) -}}
  {{- $globalDefaults := merge $globalDefaults (dict "pullSecret" "") -}}
  {{- $globalDefaults := merge $globalDefaults (dict "networkPolicy" (dict "enabled" false)) -}}
  {{- $globalDefaults := merge $globalDefaults (dict "annotations" (dict)) -}}
  {{- $globalDefaults := merge $globalDefaults (dict "labels" (dict)) -}}
  {{ if .Values.global }}
    {{- mergeOverwrite $globalDefaults .Values.global | toJson -}}
  {{ else }}
    {{- $globalDefaults | toJson -}}
  {{ end }}
{{ end }}

{{/*
Verifies TLS is enabled globally
*/}}
{{- define "eric-sec-sip-tls.tls.enabled" -}}
{{- $g := fromJson (include "eric-sec-sip-tls.global" .) -}}
{{- $g.security.tls.enabled | toString | lower -}}
{{- end -}}

{{/* vim: set filetype=mustache: */}}
{{/*
Expand the name of the chart.
*/}}
{{- define "eric-sec-sip-tls.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "eric-sec-sip-tls.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create chart version as used by the version label.
*/}}
{{- define "eric-sec-sip-tls.version" -}}
{{- printf "%s" .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create annotation for the product information
*/}}
{{- define "eric-sec-sip-tls.product-info" }}
ericsson.com/product-name: {{ (fromYaml (.Files.Get "eric-product-info.yaml")).productName | quote }}
ericsson.com/product-number: {{ (fromYaml (.Files.Get "eric-product-info.yaml")).productNumber | quote }}
ericsson.com/product-revision: {{ regexReplaceAll "(.*)[+|-].*" .Chart.Version "${1}" | quote }}
{{- end}}

{{/*
The sip image path
*/}}
{{- define "eric-sec-sip-tls.sipPath" }}
    {{- $productInfo := fromYaml (.Files.Get "eric-product-info.yaml") -}}
    {{- $registryUrl := $productInfo.images.sip.registry -}}
    {{- $repoPath := $productInfo.images.sip.repoPath -}}
    {{- $name := $productInfo.images.sip.name -}}
    {{- $tag := $productInfo.images.sip.tag -}}
    {{- if .Values.global -}}
        {{- if .Values.global.registry -}}
            {{- if .Values.global.registry.url -}}
                {{- $registryUrl = .Values.global.registry.url -}}
            {{- end -}}
        {{- end -}}
    {{- end -}}
    {{- if .Values.imageCredentials -}}
        {{- if .Values.imageCredentials.sip -}}
            {{- if .Values.imageCredentials.sip.registry -}}
                {{- if .Values.imageCredentials.sip.registry.url -}}
                    {{- $registryUrl = .Values.imageCredentials.sip.registry.url -}}
                {{- end -}}
            {{- end -}}
            {{- if .Values.imageCredentials.sip.repoPath -}}
                {{- $repoPath = .Values.imageCredentials.sip.repoPath -}}
            {{- end -}}
        {{- end -}}
    {{- end -}}
    {{- if .Values.images -}}
        {{- if .Values.images.sip -}}
            {{- if .Values.images.sip.name -}}
                {{- $name = .Values.images.sip.name -}}
            {{- end -}}
            {{- if .Values.images.sip.tag -}}
                {{- $tag = .Values.images.sip.tag -}}
            {{- end -}}
        {{- end -}}
    {{- end -}}
    {{- if $repoPath -}}
        {{- $repoPath = printf "%s/" $repoPath -}}
    {{- end -}}
    {{- printf "%s/%s%s:%s" $registryUrl $repoPath $name $tag -}}
{{- end -}}

{{/*
The supervisor image path
*/}}
{{- define "eric-sec-sip-tls.supervisorPath" }}
    {{- $productInfo := fromYaml (.Files.Get "eric-product-info.yaml") -}}
    {{- $registryUrl := $productInfo.images.supervisor.registry -}}
    {{- $repoPath := $productInfo.images.supervisor.repoPath -}}
    {{- $name := $productInfo.images.supervisor.name -}}
    {{- $tag := $productInfo.images.supervisor.tag -}}
    {{- if .Values.global -}}
        {{- if .Values.global.registry -}}
            {{- if .Values.global.registry.url -}}
                {{- $registryUrl = .Values.global.registry.url -}}
            {{- end -}}
        {{- end -}}
    {{- end -}}
    {{- if .Values.imageCredentials -}}
        {{- if .Values.imageCredentials.supervisor -}}
            {{- if .Values.imageCredentials.supervisor.registry -}}
                {{- if .Values.imageCredentials.supervisor.registry.url -}}
                    {{- $registryUrl = .Values.imageCredentials.supervisor.registry.url -}}
                {{- end -}}
            {{- end -}}
            {{- if .Values.imageCredentials.supervisor.repoPath -}}
                {{- $repoPath = .Values.imageCredentials.supervisor.repoPath -}}
            {{- end -}}
        {{- end -}}
    {{- end -}}
    {{- if .Values.images -}}
        {{- if .Values.images.supervisor -}}
            {{- if .Values.images.supervisor.name -}}
                {{- $name = .Values.images.supervisor.name -}}
            {{- end -}}
            {{- if .Values.images.supervisor.tag -}}
                {{- $tag = .Values.images.supervisor.tag -}}
            {{- end -}}
        {{- end -}}
    {{- end -}}
    {{- if $repoPath -}}
        {{- $repoPath = printf "%s/" $repoPath -}}
    {{- end -}}
    {{- printf "%s/%s%s:%s" $registryUrl $repoPath $name $tag -}}
{{- end -}}

{{/*
The init image path
*/}}
{{- define "eric-sec-sip-tls.initPath" }}
    {{- $productInfo := fromYaml (.Files.Get "eric-product-info.yaml") -}}
    {{- $registryUrl := $productInfo.images.init.registry -}}
    {{- $repoPath := $productInfo.images.init.repoPath -}}
    {{- $name := $productInfo.images.init.name -}}
    {{- $tag := $productInfo.images.init.tag -}}
    {{- if .Values.global -}}
        {{- if .Values.global.registry -}}
            {{- if .Values.global.registry.url -}}
                {{- $registryUrl = .Values.global.registry.url -}}
            {{- end -}}
        {{- end -}}
    {{- end -}}
    {{- if .Values.imageCredentials -}}
        {{- if .Values.imageCredentials.init -}}
            {{- if .Values.imageCredentials.init.registry -}}
                {{- if .Values.imageCredentials.init.registry.url -}}
                    {{- $registryUrl = .Values.imageCredentials.init.registry.url -}}
                {{- end -}}
            {{- end -}}
            {{- if .Values.imageCredentials.init.repoPath -}}
                {{- $repoPath = .Values.imageCredentials.init.repoPath -}}
            {{- end -}}
        {{- end -}}
    {{- end -}}
    {{- if .Values.images -}}
        {{- if .Values.images.init -}}
            {{- if .Values.images.init.name -}}
                {{- $name = .Values.images.init.name -}}
            {{- end -}}
            {{- if .Values.images.init.tag -}}
                {{- $tag = .Values.images.init.tag -}}
            {{- end -}}
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
{{- define "eric-sec-sip-tls.pullSecrets" -}}
    {{- $globalPullSecret := "" -}}
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
Create image pull policy for sip image
*/}}
{{- define "eric-sec-sip-tls.sip.imagePullPolicy" -}}
    {{- $globalRegistryImagePullPolicy := "IfNotPresent" -}}
    {{- if .Values.global -}}
        {{- if .Values.global.registry -}}
            {{- if .Values.global.registry.imagePullPolicy -}}
                {{- $globalRegistryImagePullPolicy = .Values.global.registry.imagePullPolicy -}}
            {{- end -}}
        {{- end -}}
    {{- end -}}
    {{- if .Values.imageCredentials -}}
        {{- if .Values.imageCredentials.sip -}}
            {{- if .Values.imageCredentials.sip.registry -}}
                {{- if .Values.imageCredentials.sip.registry.imagePullPolicy -}}
                    {{- $globalRegistryImagePullPolicy = .Values.imageCredentials.sip.registry.imagePullPolicy -}}
                {{- end -}}
            {{- end -}}
        {{- end -}}
    {{- end -}}
    {{- print $globalRegistryImagePullPolicy -}}
{{- end -}}

{{/*
Create image pull policy for supervisor image
*/}}
{{- define "eric-sec-sip-tls.supervisor.imagePullPolicy" -}}
    {{- $globalRegistryImagePullPolicy := "IfNotPresent" -}}
    {{- if .Values.global -}}
        {{- if .Values.global.registry -}}
            {{- if .Values.global.registry.imagePullPolicy -}}
                {{- $globalRegistryImagePullPolicy = .Values.global.registry.imagePullPolicy -}}
            {{- end -}}
        {{- end -}}
    {{- end -}}
    {{- if .Values.imageCredentials -}}
        {{- if .Values.imageCredentials.supervisor -}}
            {{- if .Values.imageCredentials.supervisor.registry -}}
                {{- if .Values.imageCredentials.supervisor.registry.imagePullPolicy -}}
                    {{- $globalRegistryImagePullPolicy = .Values.imageCredentials.supervisor.registry.imagePullPolicy -}}
                {{- end -}}
            {{- end -}}
        {{- end -}}
    {{- end -}}
    {{- print $globalRegistryImagePullPolicy -}}
{{- end -}}

{{/*
Create image pull policy for init image
*/}}
{{- define "eric-sec-sip-tls.init.imagePullPolicy" -}}
    {{- $globalRegistryImagePullPolicy := "IfNotPresent" -}}
    {{- if .Values.global -}}
        {{- if .Values.global.registry -}}
            {{- if .Values.global.registry.imagePullPolicy -}}
                {{- $globalRegistryImagePullPolicy = .Values.global.registry.imagePullPolicy -}}
            {{- end -}}
        {{- end -}}
    {{- end -}}
    {{- if .Values.imageCredentials -}}
        {{- if .Values.imageCredentials.init -}}
            {{- if .Values.imageCredentials.init.registry -}}
                {{- if .Values.imageCredentials.init.registry.imagePullPolicy -}}
                    {{- $globalRegistryImagePullPolicy = .Values.imageCredentials.init.registry.imagePullPolicy -}}
                {{- end -}}
            {{- end -}}
        {{- end -}}
    {{- end -}}
    {{- print $globalRegistryImagePullPolicy -}}
{{- end -}}


{{/*
Create a merged set of nodeSelectors from global and service level.
If there is overlap (same key with different values) of global and service level nodeSelector, an error will be thrown.
*/}}
{{ define "eric-sec-sip-tls.nodeSelector" }}
  {{- $g := fromJson (include "eric-sec-sip-tls.global" .) -}}
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
Create the fsGroup value according to DR-D1123-123.
*/}}
{{- define "eric-sec-sip-tls.fsGroup.coordinated" -}}
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
Define the role reference for security-policy
*/}}
{{- define "eric-sec-sip-tls.securityPolicy.reference" -}}
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

{{/*
Define the annotations for security-policy
*/}}
{{- define "eric-sec-sip-tls.securityPolicy.annotations" -}}
ericsson.com/security-policy.name: "restricted/default"
ericsson.com/security-policy.privileged: "false"
ericsson.com/security-policy.capabilities: "N/A"
{{- end -}}

{{/*
Create a merged set of labels from global and service level.
If there is overlap (same key with different values) of global and service level labels, an error will be thrown.
*/}}
{{- define "eric-sec-sip-tls.merged-labels" -}}
  {{- $g := fromJson (include "eric-sec-sip-tls.global" .) -}}

  {{/* If local and global has the same key but different values, print error */}}
  {{- if .Values.labels -}}
    {{- range $key, $localValue := .Values.labels -}}
      {{- if hasKey $g.labels $key -}}
        {{- $globalValue := index $g.labels $key -}}
        {{- if ne $globalValue $localValue -}}
          {{- printf "label \"%s\" is specified on both a global (%s: %s) and service level (%s: %s) with differing values, which is not allowed." $key $key $globalValue $key $localValue | fail -}}
        {{- end -}}
      {{- end -}}
    {{- end -}}

    {{/* Merge local and global labels */}}
    {{- toYaml (merge $g.labels .Values.labels) | trim -}}
  {{- else -}}
    {{- if $g.labels -}}
      {{/* Print global labels */}}
      {{- toYaml $g.labels | trim -}}
    {{- end -}}
  {{- end -}}
{{- end -}}

{{/*
Define the labels
*/}}
{{- define "eric-sec-sip-tls.labels" }}
{{- include "eric-sec-sip-tls.product-labels" . -}}
{{- if (include "eric-sec-sip-tls.merged-labels" .) -}}
    {{- include "eric-sec-sip-tls.merged-labels" . | nindent 0 -}}
{{- end -}}
{{- end -}}

{{/*
Create a merged set of annotations from global and service level.
If there is overlap (same key with different values) of global and service level annotations, an error will be thrown.
*/}}
{{- define "eric-sec-sip-tls.merged-annotations" -}}
  {{- $g := fromJson (include "eric-sec-sip-tls.global" .) -}}

  {{/* If local and global has the same key but different values, print error */}}
  {{- if .Values.annotations -}}
    {{- range $key, $localValue := .Values.annotations -}}
      {{- if hasKey $g.annotations $key -}}
        {{- $globalValue := index $g.annotations $key -}}
        {{- if ne $globalValue $localValue -}}
          {{- printf "annotation \"%s\" is specified on both a global (%s: %s) and service level (%s: %s) with differing values, which is not allowed." $key $key $globalValue $key $localValue | fail -}}
        {{- end -}}
      {{- end -}}
    {{- end -}}

    {{/* Merge local and global annotations */}}
    {{- toYaml (merge $g.annotations .Values.annotations) | trim -}}
  {{- else -}}
    {{- if $g.annotations -}}
      {{/* Print global annotations */}}
      {{- toYaml $g.annotations | trim -}}
    {{- end -}}
  {{- end -}}
{{- end -}}

{{/*
Define the common annotations
*/}}
{{- define "eric-sec-sip-tls.annotations" -}}
{{- include "eric-sec-sip-tls.product-info" . -}}
{{- if (include "eric-sec-sip-tls.merged-annotations" .) -}}
    {{- include "eric-sec-sip-tls.merged-annotations" . | nindent 0 -}}
{{- end -}}
{{- end -}}

{{/*
Create timezone
Default: UTC
*/}}
{{- define "eric-sec-sip-tls.timezone" -}}
{{- $timezone := "UTC" -}}
{{- if .Values.global -}}
    {{- if .Values.global.timezone -}}
        {{- $timezone = .Values.global.timezone -}}
    {{- end -}}
{{- end -}}
{{- print $timezone -}}
{{- end -}}

{{/*
Define affinity
*/}}
{{- define "eric-sec-sip-tls.affinity" -}}
{{- if eq .Values.affinity.podAntiAffinity "hard" -}}
affinity:
  podAntiAffinity:
    requiredDuringSchedulingIgnoredDuringExecution:
    - labelSelector:
        matchExpressions:
        - key: app
          operator: In
          values:
          - {{ template "eric-sec-sip-tls.name" . }}
      topologyKey: "kubernetes.io/hostname"
{{- else if eq .Values.affinity.podAntiAffinity "soft" -}}
affinity:
  podAntiAffinity:
    preferredDuringSchedulingIgnoredDuringExecution:
    - weight: 100
      podAffinityTerm:
        labelSelector:
          matchExpressions:
          - key: app
            operator: In
            values:
            - {{ template "eric-sec-sip-tls.name" . }}
        topologyKey: "kubernetes.io/hostname"
{{- end -}}
{{- end -}}

{{/*
Create security context
*/}}
{{- define "eric-sec-sip-tls.securityContext" -}}
securityContext:
  allowPrivilegeEscalation: false
  privileged: false
  readOnlyRootFilesystem: true
  runAsNonRoot: true
  capabilities:
    drop:
      - all
{{- end -}}
