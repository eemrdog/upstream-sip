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
Get the metrics port of cm mediator.
*/}}
{{- define "eric-cm-mediator.metrics-port" -}}
5005
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
Define nodeSelector (to be deprecated)
While this is not deprecated it takes priority over the updated implementation below
*/}}
{{- define "eric-cm-mediator.nodeSelector.general" -}}
{{- $nodeSelector := dict -}}
{{- if .Values.global -}}
    {{- if .Values.global.nodeSelector -}}
        {{- $nodeSelector = .Values.global.nodeSelector -}}
    {{- end -}}
{{- end -}}
{{- if .Values.nodeSelector }}
    {{- $pods := list "eric-cm-mediator" "eric-cm-mediator-notifier" "eric-cm-key-init" -}}
    {{- $nodeSelectorLocal := .Values.nodeSelector -}}
    {{- range $pod := $pods -}}
        {{- $nodeSelectorLocal = omit $nodeSelectorLocal $pod -}}
    {{- end -}}
    {{- range $key, $localValue := $nodeSelectorLocal -}}
        {{- if hasKey $nodeSelector $key -}}
            {{- $globalValue := index $nodeSelector $key -}}
            {{- if ne $globalValue $localValue -}}
              {{- printf "nodeSelector \"%s\" is specified in both global (%s: %s) and service level (%s: %s) with differing values which is not allowed." $key $key $globalValue $key $localValue | fail -}}
            {{- end -}}
        {{- end -}}
    {{- end -}}
    {{- $nodeSelector = merge $nodeSelector $nodeSelectorLocal -}}
{{- end -}}
{{- if $nodeSelector -}}
    {{- toYaml $nodeSelector | nindent 8 | trim -}}
{{- end -}}
{{- end -}}

{{/*
Define nodeSelector per workload, align to DR-D1120-045-AD
*/}}
{{- define "eric-cm-mediator.nodeSelectorFunc" -}}
{{- $podName := .podName }}
{{- $nodeSelector := dict -}}
{{- if .Values.global -}}
    {{- if .Values.global.nodeSelector -}}
        {{- $nodeSelector = .Values.global.nodeSelector -}}
    {{- end -}}
{{- end -}}
{{- if .Values.nodeSelector }}
    {{- if index .Values.nodeSelector $podName }}
        {{- range $key, $localValue := index .Values.nodeSelector $podName -}}
          {{- if hasKey $nodeSelector $key -}}
              {{- $globalValue := index $nodeSelector $key -}}
              {{- if ne $globalValue $localValue -}}
                {{- printf "nodeSelector \"%s\" is specified for pod %s in both global (%s: %s) and service level (%s: %s) with differing values which is not allowed." $key $podName $key $globalValue $key $localValue | fail -}}
              {{- end -}}
          {{- end -}}
        {{- end -}}
        {{- $nodeSelector = merge $nodeSelector (index .Values.nodeSelector $podName) -}}
    {{- end -}}
{{- end -}}
{{- if $nodeSelector -}}
    {{- toYaml $nodeSelector | nindent 8 | trim -}}
{{- end -}}
{{- end -}}

{{/*
Define nodeSelector for CM Mediator
*/}}
{{- define "eric-cm-mediator.nodeSelector" -}}
{{ include "eric-cm-mediator.nodeSelectorFunc" (dict "Values" .Values "podName" "eric-cm-mediator") -}}
{{- end -}}

{{/*
Define nodeSelector for CM Mediator Notifier
*/}}
{{- define "eric-cm-mediator-notifier.nodeSelector" -}}
{{ include "eric-cm-mediator.nodeSelectorFunc" (dict "Values" .Values "podName" "eric-cm-mediator-notifier") -}}
{{- end -}}

{{/*
Define nodeSelector for CM Key Init Job
*/}}
{{- define "eric-cm-mediator-key-init.nodeSelector" -}}
{{ include "eric-cm-mediator.nodeSelectorFunc" (dict "Values" .Values "podName" "eric-cm-key-init") -}}
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
{{- $cmmLabels := dict }}
{{- $_ := set $cmmLabels "app.kubernetes.io/name" (include "eric-cm-mediator.name" .) }}
{{- $_ := set $cmmLabels "app.kubernetes.io/version" (include "eric-cm-mediator.version" .) }}
{{- $_ := set $cmmLabels "app.kubernetes.io/instance" .Release.Name }}
{{- $_ := set $cmmLabels "app.kubernetes.io/managed-by" .Release.Service }}
{{- $_ := set $cmmLabels "helm.sh/chart" (include "eric-cm-mediator.chart" .) }}

{{- $globalLabels := (.Values.global).labels -}}
{{- $serviceLabels := .Values.labels -}}
{{- include "eric-cm-mediator.mergeLabels" (dict "location" .Template.Name "sources" (list $cmmLabels $globalLabels $serviceLabels)) | trim }}
{{- end -}}

{{- define "eric-cm-mediator.pod.labels" -}}
{{- $podLabelsDict := dict }}
{{- $_ := set $podLabelsDict "app" (include "eric-cm-mediator.name" . | toString) }}
{{- $_ := set $podLabelsDict "release" .Release.Name }}

{{- $peerLabels := include "eric-cm-mediator.peer.labels" . | fromYaml -}}
{{- $baseLabels := include "eric-cm-mediator.labels" . | fromYaml -}}
{{- include "eric-cm-mediator.mergeLabels" (dict "location" .Template.Name "sources" (list $podLabelsDict $peerLabels $baseLabels)) | trim}}
{{- end -}}

{{- define "eric-cm-mediator-notifier.pod.labels" -}}
{{- $podLabelsDict := dict }}
{{- $_ := set $podLabelsDict "app" (include "eric-cm-mediator-notifier.name" . | toString) }}

{{- $peerLabels := include "eric-cm-mediator-notifier.peer.labels" . | fromYaml -}}
{{- $baseLabels := include "eric-cm-mediator.labels" . | fromYaml  -}}
{{- include "eric-cm-mediator.mergeLabels" (dict "location" .Template.Name "sources" (list $podLabelsDict $peerLabels $baseLabels)) | trim }}
{{- end -}}


{{/*
Generate labels helper function
*/}}
{{- define "eric-cm-mediator.generate-peer-labels" -}}
{{- $peers := index . "peers" -}}
{{- $peerLabels := dict }}
{{- range $_, $peer := $peers }}
    {{- $_ := set $peerLabels ((list $peer "access") | join "-") "true" -}}
{{- end }}
{{- toYaml $peerLabels }}
{{- end -}}

{{/*
CM Mediator Labels for Network Policies
*/}}
{{- define "eric-cm-mediator.peer.labels" -}}
{{- $peers := list }}
{{- if (has "stream" .Values.cmm.logOutput) -}}
    {{- $peers = append $peers .Values.logtransformer.hostname }}
{{- end }}
{{- if .Values.exilis.cm.enabled }}
    {{- $peers = append $peers .Values.exilis.cm.backend.hostname }}
    {{- $peers = append $peers .Values.exilis.cm.storage.hostname }}
    {{- $peers = append $peers .Values.exilis.cm.transformer.hostname }}
    {{- $peers = append $peers .Values.exilis.cm.yangprovider.hostname }}
{{- else }}
    {{- $peers = append $peers .Values.backend.hostname }}
{{- end }}
{{- template "eric-cm-mediator.generate-peer-labels" (dict "peers" $peers) }}
{{- end -}}

{{/*
Define CM Notifier Labels for Network Policies
*/}}
{{- define "eric-cm-mediator-notifier.peer.labels" -}}
{{- $peers := list }}
{{- if .Values.exilis.cm.enabled }}
    {{- $peers = append $peers .Values.exilis.cm.storage.hostname }}
{{- else }}
    {{- $peers = append $peers .Values.backend.hostname }}
{{- end }}
{{- if (has "stream" .Values.cmm.logOutput) }}
    {{- $peers = append $peers .Values.logtransformer.hostname }}
{{- end }}
{{- if .Values.redis.hostname }}
    {{- $peers = append $peers .Values.redis.hostname }}
{{- end }}
{{- if .Values.kafka.hostname }}
    {{- $peers = append $peers .Values.kafka.hostname }}
{{- end }}
{{- template "eric-cm-mediator.generate-peer-labels" (dict "peers" $peers) }}
{{- end -}}

{{/*
Define CM Key Init Labels for Network Policies
*/}}
{{- define "eric-cm-mediator-job-cmkey.peer.labels" -}}
{{- $peers := list }}
{{- $peers = append $peers .Values.cmkey.kms.hostname }}
{{- if (has "stream" .Values.cmm.logOutput) -}}
    {{- $peers = append $peers .Values.logtransformer.hostname }}
{{- end }}
{{- template "eric-cm-mediator.generate-peer-labels" (dict "peers" $peers) }}
{{- end -}}

{{/*
Define annotations
*/}}
{{- define "eric-cm-mediator.baseAnnotations" -}}
{{- $cmmAnnotations := dict }}
{{- $_ := set $cmmAnnotations "ericsson.com/product-name" (fromYaml (.Files.Get "eric-product-info.yaml")).productName | quote }}
{{- $_ := set $cmmAnnotations "ericsson.com/product-number" (fromYaml (.Files.Get "eric-product-info.yaml")).productNumber | quote }}
{{- $_ := set $cmmAnnotations "ericsson.com/product-revision" .Chart.AppVersion | quote }}

{{- $globalAnnotations := (.Values.global).annotations -}}
{{- $serviceAnnotations := .Values.annotations -}}
{{- include "eric-cm-mediator.mergeAnnotations" (dict "location" .Template.Name "sources" (list $cmmAnnotations $globalAnnotations $serviceAnnotations)) | trim }}
{{- end -}}

{{/*
Define Cm Mediator and CM Notifier annotations
*/}}
{{- define "eric-cm-mediator.podAnnotations" -}}
{{- $cmmAnnotations := dict }}
{{- if index .Values "bandwidth" "eric-cm-mediator" "maxEgressRate" }}
{{- $_ := set $cmmAnnotations "kubernetes.io/egress-bandwidth" (toYaml ( index .Values "bandwidth" "eric-cm-mediator" "maxEgressRate")) | quote }}
{{- end -}}

{{- $baseAnnotations := include "eric-cm-mediator.baseAnnotations" . | fromYaml -}}
{{- include "eric-cm-mediator.mergeAnnotations" (dict "location" .Template.Name "sources" (list $cmmAnnotations $baseAnnotations)) | trim }}
{{- end -}}

{{- define "eric-cm-mediator-notifier.podAnnotations" -}}
{{- $cmmAnnotations := dict }}
{{- if index .Values "bandwidth" "eric-cm-mediator-notifier" "maxEgressRate" }}
{{- $_ := set $cmmAnnotations "kubernetes.io/egress-bandwidth" (toYaml ( index .Values "bandwidth" "eric-cm-mediator-notifier" "maxEgressRate")) | quote }}
{{- end -}}

{{- $baseAnnotations := include "eric-cm-mediator.baseAnnotations" . | fromYaml -}}
{{- include "eric-cm-mediator.mergeAnnotations" (dict "location" .Template.Name "sources" (list $cmmAnnotations $baseAnnotations)) | trim }}
{{- end -}}

{{- define "eric-cm-mediator.pod.annotations" -}}
{{- $metricsAnnotations := include "eric-cm-mediator.metrics" . | fromYaml -}}
{{- $podAnnotations := include "eric-cm-mediator.podAnnotations" . | fromYaml -}}
{{- $appArmorAnnotationsInit := include "eric-cm-mediator.appArmorAnnotations" ( dict "containerName" "eric-cm-mediator-init-container" "valueContainerKey" "eric-cm-mediator-init" "Values" .Values ) | fromYaml  }}
{{- $appArmorAnnotationsMediator:= include "eric-cm-mediator.appArmorAnnotations" ( dict "containerName" "eric-cm-mediator" "valueContainerKey" "eric-cm-mediator" "Values" .Values ) | fromYaml  }}
{{- include "eric-cm-mediator.mergeAnnotations" (dict "location" .Template.Name "sources" (list $metricsAnnotations $podAnnotations $appArmorAnnotationsInit $appArmorAnnotationsMediator )) | trim }}
{{- end -}}

{{- define "eric-cm-mediator-notifier.pod.annotations" -}}
{{- $metricsAnnotations := include "eric-cm-mediator.metrics" . | fromYaml -}}
{{- $notifierPodAnnotations := include "eric-cm-mediator-notifier.podAnnotations" . | fromYaml  -}}
{{- $appArmorAnnotationsInit := include "eric-cm-mediator.appArmorAnnotations" ( dict "containerName" "eric-cm-mediator-init-container" "valueContainerKey" "eric-cm-mediator-notifier-init" "Values" .Values ) | fromYaml  }}
{{- $appArmorAnnotationsNotifier :=  include "eric-cm-mediator.appArmorAnnotations" ( dict "containerName" "eric-cm-mediator" "valueContainerKey" "eric-cm-mediator-notifier" "Values" .Values ) | fromYaml }}
{{- include "eric-cm-mediator.mergeAnnotations" (dict "location" .Template.Name "sources" (list $metricsAnnotations $notifierPodAnnotations $appArmorAnnotationsInit $appArmorAnnotationsNotifier )) | trim }}
{{- end -}}

{{- define "eric-cm-mediator-key-init.pod.annotations" -}}
{{- $baseAnnotations := include "eric-cm-mediator.baseAnnotations" . | fromYaml -}}
{{- $appArmorAnnotationsInit := include "eric-cm-mediator.appArmorAnnotations" ( dict "containerName" "eric-cm-mediator-init-container" "valueContainerKey" "eric-cm-key-init-init" "Values" .Values ) | fromYaml  }}
{{- $appArmorAnnotationsKeyInit:= include "eric-cm-mediator.appArmorAnnotations" ( dict "containerName" "eric-cm-key-init" "valueContainerKey" "eric-cm-key-init" "Values" .Values ) | fromYaml  }}
{{- include "eric-cm-mediator.mergeAnnotations" (dict "location" .Template.Name "sources" (list $baseAnnotations  $appArmorAnnotationsInit $appArmorAnnotationsKeyInit )) | trim }}
{{- end -}}

{{- define "eric-cm-mediator-key-cleanup.pod.annotations" -}}
{{- $baseAnnotations := include "eric-cm-mediator.baseAnnotations" . | fromYaml -}}
{{- $appArmorAnnotationsKeyCleanup:= include "eric-cm-mediator.appArmorAnnotations" ( dict "containerName" "eric-cm-key-init" "valueContainerKey" "eric-cm-key-init" "Values" .Values ) | fromYaml  }}
{{- include "eric-cm-mediator.mergeAnnotations" (dict "location" .Template.Name "sources" (list $baseAnnotations  $appArmorAnnotationsKeyCleanup )) | trim }}
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

{{/*
Set appArmor Profile, check for LocalhostProfile if type is localhost
*/}}
{{- define "eric-cm-mediator.setAppArmorProfile" -}}
{{- $container := .container }}
{{- $type := .type }}
{{- $localhostProfile := .localhostProfile }}
{{- $profile := "" -}}
{{- $failureMessage := "If you set appArmor type 'localhost' you are required to set the 'localhostProfile'" }}
{{- if eq "localhost" ( lower $type) }}
    {{- if required $failureMessage $localhostProfile }}
        {{- $profile = printf "localhost/%s" $localhostProfile -}}
    {{- end -}}
{{- else }}
    {{- $profile = toYaml ( lower $type)}}
{{- end -}}
container.apparmor.security.beta.kubernetes.io/{{$container}}: {{ $profile }}
{{- end -}}

{{/*
Get appArmor Values
*/}}
{{- define "eric-cm-mediator.appArmorAnnotations" -}}
{{- $containerName := .containerName }}
{{- $valueContainerKey := .valueContainerKey }}
{{- $appArmorType := "" }}
{{- $localhostProfile := "" }}
{{- if index .Values "appArmorProfile" $valueContainerKey "type" }}
        {{- $appArmorType = index .Values "appArmorProfile" $valueContainerKey "type" }}
        {{- $localhostProfile = index .Values "appArmorProfile" $valueContainerKey "localhostProfile" }}
        {{- include "eric-cm-mediator.setAppArmorProfile" ( dict "type" $appArmorType "container" $containerName "localhostProfile" $localhostProfile ) -}}
{{- end -}}
{{- end -}}

{{/*
Set seccomp profile, check for LocalhostProfile if type is localhost
*/}}
{{- define "eric-cm-mediator.setSeccompProfile" -}}
{{- $type := .type }}
{{- $localhostProfile := .localhostProfile }}
{{- if eq "runtimedefault" (lower $type) -}}
seccompProfile:
  type: "RuntimeDefault"
{{- else if eq "unconfined" (lower $type) -}}
seccompProfile:
  type: "Unconfined"
{{- else if eq "localhost" (lower $type) -}}
{{- $failureMessage := "If you set seccomp type 'Localhost' you are required to set the seccomp 'localhostProfile'" -}}
seccompProfile:
  type: "Localhost"
  localhostProfile: {{ required $failureMessage $localhostProfile | quote }}
{{- else -}}
    {{- $problem := "Wrong Profile type was defined."  -}}
    {{- $details := "Possible values are: RuntimeDefault, Unconfined, Localhost." -}}
    {{- $solution := "To proceed, please resolve the issue and try again." -}}
    {{- printf "%s %s %s " $problem $details $solution | fail -}}
{{- end -}}
{{- end -}}

{{/*
Get values for seccomp
 */}}
{{- define "eric-cm-mediator.seccomp" -}}
{{- $pod := .pod }}
{{- $seccompType := "" }}
{{- $localhostProfile := "" }}
{{- if index .Values "seccompProfile" $pod "type"}}
    {{- $seccompType = index .Values "seccompProfile" $pod "type" }}
    {{- $localhostProfile = index .Values "seccompProfile" $pod "localhostProfile" }}
    {{- include "eric-cm-mediator.setSeccompProfile" ( dict "type" $seccompType "localhostProfile" $localhostProfile ) -}}
{{- end -}}
{{- end -}}