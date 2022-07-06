{{/* vim: set filetype=mustache: */}}
{{/*
    Create a map from ".Values.global" with defaults if missing in values file.
    This hides defaults from values file.
*/}}
{{ define "eric-fh-snmp-alarm-provider.global" }}
    {{- $globalDefaults := dict "security" (dict "policyBinding" (dict "create" false)) -}}
    {{- $globalDefaults := merge $globalDefaults (dict "security" (dict "policyReferenceMap" (dict "plc-03ad10577718e69c935814b4f30054" "plc-03ad10577718e69c935814b4f30054"))) -}}
    {{- $globalDefaults := merge $globalDefaults (dict "security" (dict "policyReferenceMap" (dict "default-restricted-security-policy" "default-restricted-security-policy"))) -}}
    {{ if .Values.global }}
       {{- mergeOverwrite $globalDefaults .Values.global | toJson -}}
    {{ else }}
       {{- $globalDefaults | toJson -}}
    {{ end }}
{{ end }}

{{/*
Expand the name of the chart.
*/}}
{{- define "eric-fh-snmp-alarm-provider.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "eric-fh-snmp-alarm-provider.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "eric-fh-snmp-alarm-provider.version" -}}
{{- printf "%s" .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" | quote -}}
{{- end -}}

{{/*
Define log level.
*/}}
{{- define "eric-fh-snmp-alarm-provider.loglevel" -}}
{{- if .Values.service.debug -}}
    {{- printf "DEBUG" | quote -}}
{{- else -}}
    {{- $loglevel := index .Values "log" "eric-fh-snmp-alarm-provider" "level" -}}
    {{- if $loglevel -}}
        {{- printf "%s" $loglevel | quote -}}
    {{- else -}}
        {{- printf "INFO" | quote -}}
    {{- end -}}
{{- end -}}
{{- end -}}

{{/*
Set true if stdout is defined as log output, note: returns boolean as string
*/}}
{{- define "eric-fh-snmp-alarm-provider.log-to-stdout" -}}
{{- $stdout := false -}}
{{- if has "stdout" .Values.log.outputs }}
  {{- $stdout = true -}}
{{- end }}
{{- $stdout -}}
{{- end -}}

{{/*
REMOVE if logshipper side-car implementation is not using it.
Set true if stream is defined as log output, note: returns boolean as string
*/}}
{{- define "eric-fh-snmp-alarm-provider.log-to-stream" -}}
{{- $stream := false -}}
{{- if has "stream" .Values.log.outputs }}
  {{- $stream = true -}}
{{- end }}
{{- $stream -}}
{{- end -}}

{{/*
Define Stream Server(log transformer) port
*/}}
{{- define "eric-fh-snmp-alarm-provider.stream-server-port" -}}
{{- $port := .Values.logTransformer.port -}}
{{- if eq (include "eric-fh-snmp-alarm-provider.tls" .) "true" }}
  {{- $port = .Values.logTransformer.portTls -}}
{{- end }}
{{- $port -}}
{{- end -}}

{{/*
The snmpAP path (DR-D1121-067)
*/}}
{{- define "eric-fh-snmp-alarm-provider.snmpAPPath" }}
    {{- $productInfo := fromYaml (.Files.Get "eric-product-info.yaml") -}}
    {{- $registryUrl := $productInfo.images.snmpAP.registry -}}
    {{- $repoPath := $productInfo.images.snmpAP.repoPath -}}
    {{- $name := $productInfo.images.snmpAP.name -}}
    {{- $tag := $productInfo.images.snmpAP.tag -}}
    {{- if .Values.global -}}
        {{- if .Values.global.registry -}}
            {{- if .Values.global.registry.url -}}
                {{- $registryUrl = .Values.global.registry.url -}}
            {{- end -}}
        {{- end -}}
    {{- end -}}
    {{- if .Values.imageCredentials -}}
        {{- if .Values.imageCredentials.snmpAP -}}
            {{- if .Values.imageCredentials.snmpAP.registry -}}
                {{- if .Values.imageCredentials.snmpAP.registry.url -}}
                    {{- $registryUrl = .Values.imageCredentials.snmpAP.registry.url -}}
                {{- end -}}
            {{- end -}}
            {{- if not (kindIs "invalid" .Values.imageCredentials.snmpAP.repoPath) -}}
                {{- $repoPath = .Values.imageCredentials.snmpAP.repoPath -}}
            {{- end -}}
        {{- end -}}
        {{- if not (kindIs "invalid" .Values.imageCredentials.repoPath) -}}
            {{- $repoPath = .Values.imageCredentials.repoPath -}}
        {{- end -}}
        {{- if .Values.imageCredentials.registry -}}
            {{- if .Values.imageCredentials.registry.url -}}
                {{- $registryUrl = .Values.imageCredentials.registry.url -}}
            {{- end -}}
        {{- end -}}
    {{- end -}}
    {{- if $repoPath -}}
        {{- $repoPath = printf "%s/" $repoPath -}}
    {{- end -}}
    {{- printf "%s/%s%s:%s" $registryUrl $repoPath $name $tag -}}
{{- end -}}

{{/*
Define timezone
*/}}
{{- define "eric-fh-snmp-alarm-provider.timezone" -}}
{{- $timezone := "UTC" -}}
{{- if .Values.global -}}
    {{- if .Values.global.timezone -}}
        {{- $timezone = .Values.global.timezone -}}
    {{- end -}}
{{- end -}}
{{- print $timezone | quote -}}
{{- end -}}

{{/*
Define MTLS, note: returns boolean as string
*/}}
{{- define "eric-fh-snmp-alarm-provider.tls" -}}
{{- $snmptls := true -}}
{{- if .Values.global -}}
    {{- if .Values.global.security -}}
        {{- if .Values.global.security.tls -}}
            {{- if hasKey .Values.global.security.tls "enabled" -}}
                {{- $snmptls = .Values.global.security.tls.enabled -}}
                {{- if ne (kindOf $snmptls) "bool" -}}
                    {{- printf "The value of global.security.tls.enabled must be true or false not \"%s\"" $snmptls | fail -}}
                {{- end -}}
            {{- end -}}
        {{- end -}}
    {{- end -}}
{{- end -}}
{{- $snmptls -}}
{{- end -}}

{{/*
Create image pull secret
*/}}
{{- define "eric-fh-snmp-alarm-provider.pullSecrets" -}}
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
Create image Pull Policy
*/}}
{{- define "eric-fh-snmp-alarm-provider.imagePullPolicy" -}}
{{- $imagePullPolicy := "IfNotPresent" -}}
{{- if .Values.global -}}
    {{- if .Values.global.registry -}}
        {{- if .Values.global.registry.imagePullPolicy -}}
            {{- $imagePullPolicy = .Values.global.registry.imagePullPolicy -}}
        {{- end -}}
    {{- end -}}
{{- end -}}
{{- if .Values.imageCredentials.snmpAP.registry -}}
    {{- if .Values.imageCredentials.snmpAP.registry.imagePullPolicy -}}
         {{- $imagePullPolicy = .Values.imageCredentials.snmpAP.registry.imagePullPolicy -}}
    {{- end -}}
{{- end -}}
{{- if .Values.imageCredentials.pullPolicy -}}
    {{- $imagePullPolicy = .Values.imageCredentials.pullPolicy -}}
{{- end -}}
{{- print $imagePullPolicy -}}
{{- end -}}

{{/*
Create IPv4 boolean service/global/<notset>
*/}}
{{- define "eric-fh-snmp-alarm-provider.enabled-IPv4" -}}
    {{- if .Values.service.externalIPv4.enabled | quote -}}
        {{- .Values.service.externalIPv4.enabled -}}
    {{- else -}}
        {{- if .Values.global -}}
            {{- if .Values.global.externalIPv4 -}}
                {{- if .Values.global.externalIPv4.enabled | quote -}}
                    {{- .Values.global.externalIPv4.enabled -}}
                {{- end -}}
            {{- end -}}
        {{- end -}}
    {{- end -}}
{{- end -}}

{{/*
Create IPv6 boolean service/global/<notset>
*/}}
{{- define "eric-fh-snmp-alarm-provider.enabled-IPv6" -}}
    {{- if .Values.service.externalIPv6.enabled | quote -}}
        {{- .Values.service.externalIPv6.enabled -}}
    {{- else -}}
        {{- if .Values.global -}}
            {{- if .Values.global.externalIPv6 -}}
                {{- if .Values.global.externalIPv6.enabled | quote -}}
                    {{- .Values.global.externalIPv6.enabled -}}
                {{- end -}}
            {{- end -}}
        {{- end -}}
    {{- end -}}
{{- end -}}

{{/*
Create a merged set of nodeSelectors from global and service level.
WARNING: if nodeSelector is empty list, it won't appear in the template
*/}}
{{ define "eric-fh-snmp-alarm-provider.nodeSelector" }}
  {{- $global := (.Values.global).nodeSelector -}}
  {{- $service := .Values.nodeSelector -}}
  {{- $context := "eric-fh-snmp-alarm-provider.nodeSelector" -}}
  {{- include "eric-fh-snmp-alarm-provider.aggregatedMerge" (dict "context" $context "location" .Template.Name "sources" (list $global $service)) | trim -}}
{{ end }}

{{/*
Merge user-defined annotations (DR-D1121-065, DR-D1121-060)
*/}}
{{ define "eric-fh-snmp-alarm-provider.config-annotations" }}
  {{- $global := (.Values.global).annotations -}}
  {{- $service := .Values.annotations -}}
  {{- include "eric-fh-snmp-alarm-provider.mergeAnnotations" (dict "location" (.Template.Name) "sources" (list $global $service)) }}
{{- end }}

{{/*
Define annotations
*/}}
{{- define "eric-fh-snmp-alarm-provider.annotations" -}}
  {{- $securityPolicy := dict -}}
  {{- if .Values.oamVIP.enabled -}}
    {{- range $key, $value := (include "eric-fh-snmp-alarm-provider.roleBinding.customAnnotations" . | fromYaml) -}}
      {{- $_ := set $securityPolicy $key $value -}}
    {{- end -}}
  {{- else -}}
    {{- range $key, $value := (include "eric-fh-snmp-alarm-provider.roleBinding.defaultAnnotations" . | fromYaml) -}}
      {{- $_ := set $securityPolicy $key $value -}}
    {{- end -}}
  {{- end -}}
  {{- $productInfo := include "eric-fh-snmp-alarm-provider.product-info" . | fromYaml -}}
  {{- $config := include "eric-fh-snmp-alarm-provider.config-annotations" . | fromYaml -}}
  {{- include "eric-fh-snmp-alarm-provider.mergeAnnotations" (dict "location" (.Template.Name) "sources" (list $securityPolicy $productInfo $config)) | trim }}
{{- end -}}

{{/*----------------------------------------------------------------*/}}
{{/*-----Defining security policy name---------------------*/}}
{{/*----------------------------------------------------------------*/}}
{{/* Need to use index function since key name 'default-restricted-security-policy' contains dashes */}}
{{- define "eric-fh-snmp-alarm-provider.securityPolicy.reference" -}}
{{- $g := fromJson (include "eric-fh-snmp-alarm-provider.global" .) }}
{{- $policyName := "" -}}
{{- if .Values.oamVIP.enabled -}}
	{{ $policyName = index $g "security" "policyReferenceMap" "plc-03ad10577718e69c935814b4f30054" }}
{{- else -}}
	{{ $policyName = index $g "security" "policyReferenceMap" "default-restricted-security-policy" }}
{{- end -}}
{{- if .Values.oamVIP.enabled -}}
    {{- $policyName = default "plc-03ad10577718e69c935814b4f30054" $policyName -}}
{{- else -}}
    {{- $policyName = default "default-restricted-security-policy" $policyName -}}
{{- end -}}
{{- $policyName -}}
{{- end -}}

{{/*----------------------------------------------------------------*/}}
{{/*-----Defining security policies annotations----------*/}}
{{/*----------------------------------------------------------------*/}}
{{- define "eric-fh-snmp-alarm-provider.roleBinding.defaultAnnotations" -}}
ericsson.com/security-policy.type: "restricted/default"
ericsson.com/security-policy.capabilities: ""
{{- end -}}

{{- define "eric-fh-snmp-alarm-provider.roleBinding.customAnnotations" -}}
ericsson.com/security-policy.type: "restricted/custom"
ericsson.com/security-policy.capabilities: "net_admin net_raw"
{{- end -}}

{{/*
Standard labels of Helm and Kubernetes.
*/}}
{{- define "eric-fh-snmp-alarm-provider.standard-logshipper-labels" }}
app.kubernetes.io/name: {{ template "eric-fh-snmp-alarm-provider.name" . }}
app.kubernetes.io/version: {{ .Chart.Version | replace "+" "_" | quote }}
app.kubernetes.io/instance: {{ .Release.Name | quote }}
{{- end -}}

{{/*
Merged Logshipper labels
*/}}
{{- define "eric-fh-snmp-alarm-provider.logshipper-labels" }}
  {{- $config := include "eric-fh-snmp-alarm-provider.config-labels" . | fromYaml -}}
  {{- $standard := include "eric-fh-snmp-alarm-provider.standard-logshipper-labels" . | fromYaml -}}
  {{- include "eric-fh-snmp-alarm-provider.mergeLabels" (dict "location" (.Template.Name) "sources" (list $config $standard)) | trim }}
{{- end }}

{{/*
Log redirect mapping for logshipper
*/}}
{{- define "eric-fh-snmp-alarm-provider.logRedirect" }}
{{- $logRedirect := "file" }}
{{- if .Values.log }}
        {{- if .Values.log.outputs }}
            {{- if (and (has "stream" .Values.log.outputs) (has "stdout" .Values.log.outputs)) }}
                {{- $logRedirect = "all" }}
            {{- else if (and (not (has "stream" .Values.log.outputs)) (has "stdout" .Values.log.outputs)) }}
                {{- $logRedirect = "stdout" }}
            {{- end }}
        {{- end }}
{{- end }}
{{- print $logRedirect }}
{{- end }}

{{/*
Java virtual machine memory heap options
*/}}
{{- define "eric-fh-snmp-alarm-provider.memoryHeapOptions" }}
{{- if .Values.jvm.heapOptions -}}
    {{- print .Values.jvm.heapOptions }}
{{- else -}}
    {{- $minRAMPercentage := "" }}
    {{- if .Values.jvm.minRAMPercentage -}}
        {{- $minRAMPercentage =  print  "-XX:MinRAMPercentage=" .Values.jvm.minRAMPercentage }}
    {{- end -}}
    {{- $maxRAMPercentage := "" }}
    {{- if .Values.jvm.maxRAMPercentage -}}
        {{- $maxRAMPercentage = print  "-XX:MaxRAMPercentage=" .Values.jvm.maxRAMPercentage }}
    {{- end -}}
    {{- $initialRAMPercentage := "" }}
    {{- if .Values.jvm.initialRAMPercentage -}}
        {{- $initialRAMPercentage =  print  "-XX:InitialRAMPercentage=" .Values.jvm.initialRAMPercentage }}
    {{- end -}}
    {{- printf "%s %s %s" $minRAMPercentage $maxRAMPercentage $initialRAMPercentage }}
{{- end }}
{{- end -}}

{{/*--------------------- Starting line-------------------------------------------*/}}
{{/*----- Helper functions for supporting both old and new probe parameters.---------------------*/}}
{{/*----------------------------------------------------------------*/}}
{{- define "eric-fh-snmp-alarm-provider.livenessProbe-initialDelaySeconds" }}
{{- $initialDelaySeconds := .Values.probes.snmpAP.livenessProbe.initialDelaySeconds }}
{{- print $initialDelaySeconds}}
{{- end -}}

{{- define "eric-fh-snmp-alarm-provider.livenessProbe-periodSeconds" }}
{{- $periodSeconds := .Values.probes.snmpAP.livenessProbe.periodSeconds }}
{{- print $periodSeconds}}
{{- end -}}

{{- define "eric-fh-snmp-alarm-provider.livenessProbe-timeoutSeconds" }}
{{- $timeoutSeconds := .Values.probes.snmpAP.livenessProbe.timeoutSeconds }}
{{- print $timeoutSeconds}}
{{- end -}}

{{- define "eric-fh-snmp-alarm-provider.livenessProbe-failureThreshold" }}
{{- $failureThreshold := .Values.probes.snmpAP.livenessProbe.failureThreshold }}
{{- print $failureThreshold}}
{{- end -}}

{{- define "eric-fh-snmp-alarm-provider.readinessProbe-initialDelaySeconds" }}
{{- $initialDelaySeconds := .Values.probes.snmpAP.readinessProbe.initialDelaySeconds }}
{{- print $initialDelaySeconds}}
{{- end -}}

{{- define "eric-fh-snmp-alarm-provider.readinessProbe-periodSeconds" }}
{{- $periodSeconds := .Values.probes.snmpAP.readinessProbe.periodSeconds }}
{{- print $periodSeconds}}
{{- end -}}

{{- define "eric-fh-snmp-alarm-provider.readinessProbe-timeoutSeconds" }}
{{- $timeoutSeconds := .Values.probes.snmpAP.readinessProbe.timeoutSeconds }}
{{- print $timeoutSeconds}}
{{- end -}}

{{- define "eric-fh-snmp-alarm-provider.readinessProbe-successThreshold" }}
{{- $successThreshold := .Values.probes.snmpAP.readinessProbe.successThreshold }}
{{- print $successThreshold}}
{{- end -}}

{{- define "eric-fh-snmp-alarm-provider.readinessProbe-failureThreshold" }}
{{- $failureThreshold := .Values.probes.snmpAP.readinessProbe.failureThreshold }}
{{- print $failureThreshold}}
{{- end -}}
{{/*------------------------Ending line----------------------------------------*/}}
{{/*----- Helper functions for supporting both old and new probe parameters.---------------------*/}}

{{/*
Define podPriority check
*/}}
{{- define "eric-fh-snmp-alarm-provider.podpriority" }}
{{- if index .Values "podPriority" }}
  {{- if index .Values "podPriority" "snmpAP" }}
    {{- if index .Values "podPriority" "snmpAP" "priorityClassName" }}
      priorityClassName: {{ index .Values "podPriority" "snmpAP" "priorityClassName" | quote }}
    {{- end }}
  {{- end }}
{{- end }}
{{- end }}

{{/* Name of the secret holding Redis ACL username and password */}}
{{- define "eric-fh-snmp-alarm-provider.messageBusRd.acl.secret" }}
    {{- printf "%s-secret-%s" .Values.messageBusRd.host .Values.messageBusRd.acl.user -}}
{{- end }}

{{/* App armor annotations for SNMP container */}}
{{- define "eric-fh-snmp-alarm-provider.snmpAP.appArmorProfileAnnotations" -}}
  {{- $acceptedProfiles := list "unconfined" "runtime/default" "localhost" }}
  {{- $commonProfile := dict -}}
  {{- if .Values.appArmorProfile.type -}}
    {{- $_ := set $commonProfile "type" .Values.appArmorProfile.type -}}
    {{- if and (eq .Values.appArmorProfile.type "localhost") .Values.appArmorProfile.localhostProfile -}}
      {{- $_ := set $commonProfile "localhostProfile" .Values.appArmorProfile.localhostProfile -}}
    {{- end -}}
  {{- end -}}
  {{- $snmpApProfile := $commonProfile -}}
  {{- if and (hasKey $.Values.appArmorProfile "snmpAP") (index $.Values.appArmorProfile "snmpAP" "type") -}}
    {{- $snmpApProfile = (index $.Values.appArmorProfile "snmpAP") -}}
  {{- end -}}
  {{- if $snmpApProfile.type -}}
    {{- if not (has $snmpApProfile.type $acceptedProfiles) -}}
      {{- fail (printf "Unsupported appArmor profile type: %s, use one of the supported profiles %s" $snmpApProfile.type $acceptedProfiles) -}}
    {{- end -}}
    {{- if and (eq $snmpApProfile.type "localhost") (empty $snmpApProfile.localhostProfile) -}}
      {{- fail "The 'localhost' appArmor profile requires a profile name to be provided in localhostProfile parameter." -}}
    {{- end }}
    {{- if eq $snmpApProfile.type "localhost" }}
      {{- $localhostProfileList := splitList "/" $snmpApProfile.localhostProfile -}}
      {{- if last $localhostProfileList }}
container.apparmor.security.beta.kubernetes.io/eric-fh-snmp-alarm-provider: "localhost/{{ last $localhostProfileList }}"
      {{- end }}
    {{- else }}
container.apparmor.security.beta.kubernetes.io/eric-fh-snmp-alarm-provider: {{ $snmpApProfile.type }}
    {{- end }}
  {{- end -}}
{{- end -}}

{{/* App armor annotations for VIP container */}}
{{- define "eric-fh-snmp-alarm-provider.vip.appArmorProfileAnnotations" -}}
  {{- $acceptedProfiles := list "unconfined" "runtime/default" "localhost" }}
  {{- $commonProfile := dict -}}
  {{- if .Values.appArmorProfile.type -}}
    {{- $_ := set $commonProfile "type" .Values.appArmorProfile.type -}}
    {{- if and (eq .Values.appArmorProfile.type "localhost") .Values.appArmorProfile.localhostProfile -}}
      {{- $_ := set $commonProfile "localhostProfile" .Values.appArmorProfile.localhostProfile -}}
    {{- end -}}
  {{- end -}}
  {{- $vipProfile := $commonProfile -}}
  {{- if and (hasKey $.Values.appArmorProfile "vip") (index $.Values.appArmorProfile "vip" "type") -}}
    {{- $vipProfile = (index $.Values.appArmorProfile "vip") -}}
  {{- end -}}
  {{- if $vipProfile.type -}}
    {{- if not (has $vipProfile.type $acceptedProfiles) -}}
      {{- fail (printf "Unsupported appArmor profile type: %s, use one of the supported profiles %s" $vipProfile.type $acceptedProfiles) -}}
    {{- end -}}
    {{- if and (eq $vipProfile.type "localhost") (empty $vipProfile.localhostProfile) -}}
      {{- fail "The 'localhost' appArmor profile requires a profile name to be provided in localhostProfile parameter." -}}
    {{- end }}
    {{- if eq $vipProfile.type "localhost" }}
      {{- $localhostProfileList := splitList "/" $vipProfile.localhostProfile -}}
      {{- if last $localhostProfileList }}
container.apparmor.security.beta.kubernetes.io/eric-fh-snmp-alarm-provider-daemonset-vip: "localhost/{{ last $localhostProfileList }}"
      {{- end }}
    {{- else }}
container.apparmor.security.beta.kubernetes.io/eric-fh-snmp-alarm-provider-daemonset-vip: {{ $vipProfile.type }}
    {{- end }}
  {{- end -}}
{{- end -}}

{{/*
Define seccompProfile for SNMP Alarm Provider container
*/}}
{{- define "eric-fh-snmp-alarm-provider.snmpAP.seccompProfile" -}}
{{- if .Values.seccompProfile -}}
{{- if and .Values.seccompProfile.snmpAP .Values.seccompProfile.snmpAP.type }}
seccompProfile:
  type: {{ .Values.seccompProfile.snmpAP.type }}
{{- if eq .Values.seccompProfile.snmpAP.type "Localhost" }}
  localhostProfile: {{ .Values.seccompProfile.snmpAP.localhostProfile }}
{{- end }}
{{- else if .Values.seccompProfile.type }}
seccompProfile:
  type: {{ .Values.seccompProfile.type }}
{{- if eq .Values.seccompProfile.type "Localhost" }}
  localhostProfile: {{ .Values.seccompProfile.localhostProfile }}
{{- end -}}
{{- end -}}
{{- end -}}
{{- end -}}

{{/*
Define seccompProfile for VIP
*/}}
{{- define "eric-fh-snmp-alarm-provider.vip.seccompProfile" -}}
{{- if .Values.seccompProfile -}}
{{- if and .Values.seccompProfile.vip .Values.seccompProfile.vip.type }}
seccompProfile:
  type: {{ .Values.seccompProfile.vip.type }}
{{- if eq .Values.seccompProfile.vip.type "Localhost" }}
  localhostProfile: {{ .Values.seccompProfile.vip.localhostProfile }}
{{- end }}
{{- else if .Values.seccompProfile.type }}
seccompProfile:
  type: {{ .Values.seccompProfile.type }}
{{- if eq .Values.seccompProfile.type "Localhost" }}
  localhostProfile: {{ .Values.seccompProfile.localhostProfile }}
{{- end -}}
{{- end -}}
{{- end -}}
{{- end -}}