{{/* vim: set filetype=mustache: */}}
{{/*
Expand the name of the chart.
*/}}
{{- define "eric-cm-mediator.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Get the name of the notifier.
*/}}
{{- define "eric-cm-mediator-notifier.name" -}}
{{ template "eric-cm-mediator.name" . }}-notifier
{{- end -}}

{{/*
Create chart version as used by the kubernetes label.
*/}}
{{- define "eric-cm-mediator.version" -}}
{{- printf "%s" .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "eric-cm-mediator.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create full image path
*/}}
{{- define "eric-cm-mediator.imagePath" -}}
{{- $root := index . "root" -}}
{{- $image := index . "image" -}}
{{- $files := index . "files" -}}
{{- $productInfo := fromYaml ($files.Get "eric-product-info.yaml") -}}
{{- $registryUrl := index $productInfo "images" $image "registry" -}}
{{- $repoPath := index $productInfo "images" $image "repoPath" -}}
{{- $tag := index $productInfo "images" $image "tag" -}}
{{- if $root.global -}}
    {{- if $root.global.registry -}}
        {{- if $root.global.registry.url -}}
            {{- $registryUrl = $root.global.registry.url -}}
        {{- end -}}
    {{- end -}}
{{- end -}}
{{- if $root.imageCredentials.registry.url -}}
    {{- $registryUrl = $root.imageCredentials.registry.url -}}
{{- end -}}
{{- if kindIs "invalid" $root.imageCredentials.repoPath -}}
    {{- $repoPath = index $productInfo "images" $image "repoPath" -}}
{{- else -}}
    {{- $repoPath = $root.imageCredentials.repoPath -}}
{{- end -}}
{{- $imagePath := printf "%s/%s/%s:%s" $registryUrl $repoPath $image $tag -}}
{{- print (regexReplaceAll "[/]+" $imagePath "/") -}}
{{- end -}}

{{/*
Create image pull policy, service level parameter takes precedence
*/}}
{{- define "eric-cm-mediator.pullPolicy" -}}
{{- $pullPolicy := "IfNotPresent" -}}
{{- if .Values.global -}}
    {{- if .Values.global.registry -}}
        {{- if .Values.global.registry.imagePullPolicy -}}
            {{- $pullPolicy = .Values.global.registry.imagePullPolicy -}}
        {{- end -}}
    {{- end -}}
{{- end -}}
{{- if .Values.imageCredentials.registry.imagePullPolicy -}}
    {{- $pullPolicy = .Values.imageCredentials.registry.imagePullPolicy -}}
{{- end -}}
{{- print $pullPolicy -}}
{{- end -}}

{{/*
Create image pull secret, service level parameter takes precedence
*/}}
{{- define "eric-cm-mediator.pullSecret" -}}
{{- $pullSecret := "" -}}
{{- if .Values.global -}}
    {{- if .Values.global.pullSecret -}}
        {{- $pullSecret = .Values.global.pullSecret -}}
    {{- end -}}
{{- end -}}
{{- if .Values.imageCredentials.pullSecret -}}
    {{- $pullSecret = .Values.imageCredentials.pullSecret -}}
{{- end -}}
{{- print $pullSecret -}}
{{- end -}}

{{/*
Define nodeSelector
*/}}
{{- define "eric-cm-mediator.nodeSelector" -}}
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
    {{- toYaml $nodeSelector | indent 8 | trim -}}
{{- end -}}
{{- end -}}

{{/*
Define timezone
*/}}
{{- define "eric-cm-mediator.timezone" -}}
{{- $timezone := "UTC" -}}
{{- if .Values.global -}}
    {{- if .Values.global.timezone -}}
        {{- $timezone = .Values.global.timezone -}}
    {{- end -}}
{{- end -}}
{{- print $timezone | quote -}}
{{- end -}}

{{/*
Define TLS, note: returns boolean as string
*/}}
{{- define "eric-cm-mediator.tls" -}}
{{- $cmmtls := true -}}
{{- if .Values.global -}}
    {{- if .Values.global.security -}}
        {{- if .Values.global.security.tls -}}
            {{- if hasKey .Values.global.security.tls "enabled" -}}
                {{- $cmmtls = .Values.global.security.tls.enabled -}}
            {{- end -}}
        {{- end -}}
    {{- end -}}
{{- end -}}
{{- $cmmtls -}}
{{- end -}}

{{/*
Define Kafka Message Bus server
*/}}
{{- define "eric-cm-mediator.kafka" -}}
{{- $port := int .Values.kafka.tlsPort -}}
{{- if .Values.global -}}
    {{- if .Values.global.security -}}
        {{- if .Values.global.security.tls -}}
            {{- if hasKey .Values.global.security.tls "enabled" -}}
                {{- if not .Values.global.security.tls.enabled -}}
                    {{- $port = int .Values.kafka.port -}}
                {{- end -}}
            {{- end -}}
        {{- end -}}
    {{- end -}}
{{- end -}}
{{- printf "%s:%d" .Values.kafka.hostname $port | quote -}}
{{- end -}}

{{/*
Define Redis server
*/}}
{{- define "eric-cm-mediator.redis" -}}
{{- $port := int .Values.redis.tlsPort -}}
{{- if .Values.global -}}
    {{- if .Values.global.security -}}
        {{- if .Values.global.security.tls -}}
            {{- if hasKey .Values.global.security.tls "enabled" -}}
                {{- if not .Values.global.security.tls.enabled -}}
                    {{- $port = int .Values.redis.port -}}
                {{- end -}}
            {{- end -}}
        {{- end -}}
    {{- end -}}
{{- end -}}
{{- printf "%s:%d" .Values.redis.hostname $port | quote -}}
{{- end -}}

{{/*
Define CM backend server
*/}}
{{- define "eric-cm-mediator.dbbackend" -}}
{{- $backendType := "" -}}
{{- $dbName := "" -}}
{{- $backendHostname := "" -}}
{{- $backendPort := "" -}}
{{- if .Values.exilis.cm.enabled }}
    {{- $backendType = .Values.backend.type -}}
    {{- $dbName = .Values.exilis.cm.storage.dbname -}}
    {{- $backendHostname = .Values.exilis.cm.storage.hostname -}}
    {{- $backendPort = .Values.exilis.cm.storage.port -}}
{{- else }}
    {{- $backendType = .Values.backend.type -}}
    {{- $dbName = .Values.backend.dbname -}}
    {{- $backendHostname = .Values.backend.hostname -}}
    {{- $backendPort = .Values.backend.port -}}
{{- end }}
{{- if eq (include "eric-cm-mediator.tls" .) "true" }}
    {{- printf "%s dbname=%s user=$(CM_BACKEND_USERNAME) host=%s port=%d" $backendType $dbName $backendHostname (int $backendPort) | quote -}}
{{- else }}
    {{- printf "%s dbname=%s user=$(CM_BACKEND_USERNAME) password=$(CM_BACKEND_PASSWORD) host=%s port=%d" $backendType $dbName $backendHostname (int $backendPort) | quote -}}
{{- end -}}
{{- end -}}

{{/*
Define container level securityContext
*/}}
{{- define "eric-cm-mediator.containerSecurityContext" -}}
allowPrivilegeEscalation: false
privileged: false
readOnlyRootFilesystem: true
runAsNonRoot: true
capabilities:
  drop:
    - all
{{- end -}}

{{/*
Define RoleBinding value, note: returns boolean as string
*/}}
{{- define "eric-cm-mediator.roleBinding" -}}
{{- $cmmrolebinding := false -}}
{{- if .Values.global -}}
    {{- if .Values.global.security -}}
        {{- if .Values.global.security.policyBinding -}}
            {{- if hasKey .Values.global.security.policyBinding "create" -}}
                {{- $cmmrolebinding = .Values.global.security.policyBinding.create -}}
            {{- end -}}
        {{- end -}}
    {{- end -}}
{{- end -}}
{{- $cmmrolebinding -}}
{{- end -}}

{{/*
Define reference to SecurityPolicy
*/}}
{{- define "eric-cm-mediator.securityPolicyReference" -}}
{{- $cmmpolicyreference := "default-restricted-security-policy" -}}
{{- if .Values.global -}}
    {{- if .Values.global.security -}}
        {{- if .Values.global.security.policyReferenceMap -}}
            {{- if hasKey .Values.global.security.policyReferenceMap "default-restricted-security-policy" -}}
                {{- $cmmpolicyreference = index .Values "global" "security" "policyReferenceMap" "default-restricted-security-policy" -}}
            {{- end -}}
        {{- end -}}
    {{- end -}}
{{- end -}}
{{- $cmmpolicyreference -}}
{{- end -}}

{{/*
Define log output, ignore invalid values in logOutput list.
Fall back to stdout if no valid log output is specified
*/}}
{{- define "eric-cm-mediator.logOutput" -}}
{{- $stream := "" -}}
{{- $stdout := "" -}}
{{- if (has "stream" .Values.cmm.logOutput) -}}
    {{- $stream = "tcp" -}}
{{- else }}
    {{- $stdout = "console" -}}
{{- end -}}
{{- if (has "stdout" .Values.cmm.logOutput) -}}
    {{- $stdout = "console" -}}
{{- end -}}
{{- printf "%s,%s" $stdout $stream | trimAll "," | quote -}}
{{- end -}}

{{/*
Define Log Transformer
*/}}
{{- define "eric-cm-mediator.logtransformer" -}}
{{- $logPort := .Values.logtransformer.jsonPort -}}
{{- if eq (include "eric-cm-mediator.tls" .) "true" }}
    {{- $logPort = .Values.logtransformer.tlsJsonPort -}}
{{- end -}}
{{- printf "%s:%d" .Values.logtransformer.hostname (int $logPort) | quote -}}
{{- end -}}

{{/*
Define Exilis CM Backend
*/}}
{{- define "eric-cm-mediator.exilis.cmbackend" -}}
{{- $port := .Values.exilis.cm.backend.port -}}
{{- if eq (include "eric-cm-mediator.tls" .) "true" }}
    {{- $port = .Values.exilis.cm.backend.tlsPort -}}
{{- end -}}
{{- printf "%s:%d" .Values.exilis.cm.backend.hostname (int $port) | quote -}}
{{- end -}}

{{/*
Define Exilis CM Data Transformer JSON
*/}}
{{- define "eric-cm-mediator.exilis.transformer" -}}
{{- $port := .Values.exilis.cm.transformer.port -}}
{{- if eq (include "eric-cm-mediator.tls" .) "true" }}
    {{- $port = .Values.exilis.cm.transformer.tlsPort -}}
{{- end -}}
{{- printf "%s:%d" .Values.exilis.cm.transformer.hostname (int $port) | quote -}}
{{- end -}}

{{/*
Define Exilis CM Yang Provider
*/}}
{{- define "eric-cm-mediator.exilis.yangprovider" -}}
{{- $port := .Values.exilis.cm.yangprovider.port -}}
{{- if eq (include "eric-cm-mediator.tls" .) "true" }}
    {{- $port = .Values.exilis.cm.yangprovider.tlsPort -}}
{{- end -}}
{{- printf "%s:%d" .Values.exilis.cm.yangprovider.hostname (int $port) | quote -}}
{{- end -}}

{{/*
Define Labels
*/}}
{{- define "eric-cm-mediator.labels" -}}
app.kubernetes.io/name: {{ template "eric-cm-mediator.name" . }}
app.kubernetes.io/version: {{ template "eric-cm-mediator.version" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
helm.sh/chart: {{ template "eric-cm-mediator.chart" . }}
{{- if .Values.labels }}
{{ toYaml .Values.labels }}
{{- end }}
{{- end -}}

{{/*
Define standard annotations
*/}}
{{- define "eric-cm-mediator.helm-annotations" }}
ericsson.com/product-name: {{ (fromYaml (.Files.Get "eric-product-info.yaml")).productName | quote }}
ericsson.com/product-number: {{ (fromYaml (.Files.Get "eric-product-info.yaml")).productNumber | quote }}
ericsson.com/product-revision: {{ .Chart.AppVersion | quote }}
{{- end }}

{{/*
Define annotations
*/}}
{{- define "eric-cm-mediator.annotations" -}}
{{- include "eric-cm-mediator.helm-annotations" . }}
{{- if .Values.annotations }}
{{ toYaml .Values.annotations }}
{{- end }}
{{- end -}}

{{/*
Define metrics annotations
*/}}
{{- define "eric-cm-mediator.metrics" -}}
prometheus.io/scrape: "true"
{{- if eq (include "eric-cm-mediator.tls" .) "true" }}
prometheus.io/scheme: "https"
{{- end }}
prometheus.io/port: "5005"
prometheus.io/path: "/cm/metrics"
{{- end -}}

{{/*
Define podAntiAffinity
*/}}
{{- define "eric-cm-mediator.podAntiAffinity" -}}
{{- if eq .Values.affinity.podAntiAffinity "hard" -}}
requiredDuringSchedulingIgnoredDuringExecution:
- labelSelector:
    matchExpressions:
    - key: app
      operator: In
      values:
      - {{ template "eric-cm-mediator.name" . }}
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
        - {{ template "eric-cm-mediator.name" . }}
    topologyKey: "kubernetes.io/hostname"
{{- else -}}
{{ fail "A valid .Values.affinity.podAntiAffinity entry required!" }}
{{- end -}}
{{- end -}}
