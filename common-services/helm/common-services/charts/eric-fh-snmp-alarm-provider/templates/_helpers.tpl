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
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" | quote -}}
{{- end -}}

{{- define "eric-fh-snmp-alarm-provider.version" -}}
{{- printf "%s" .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" | quote -}}
{{- end -}}

{{/*
Define Service Name
*/}}
{{- define "eric-fh-snmp-alarm-provider.servicename" -}}
{{- if eq (include "eric-fh-snmp-alarm-provider.enabled-IPv4" .) "true" -}}
    {{ template "eric-fh-snmp-alarm-provider.name" . }}-ipv4
{{- else if eq (include "eric-fh-snmp-alarm-provider.enabled-IPv6" .) "true" -}}
    {{ template "eric-fh-snmp-alarm-provider.name" . }}-ipv6
{{- else -}}
    {{ template "eric-fh-snmp-alarm-provider.name" . }}
{{- end -}}
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
*/}}
{{ define "eric-fh-snmp-alarm-provider.nodeSelector" }}
{{- if .Values.global -}}
    {{- if .Values.global.nodeSelector -}}
        {{- $nodeSelector := .Values.global.nodeSelector -}}
        {{- if .Values.nodeSelector -}}
            {{- range $key, $localValue := .Values.nodeSelector -}}
                {{- if hasKey $nodeSelector $key -}}
                    {{- $globalValue := index $nodeSelector $key -}}
                    {{- if ne $globalValue $localValue -}}
                        {{- printf "nodeSelector \"%s\" is specified in both global (%s: %s) and service level (%s: %s) with differing values which is not allowed." $key $key $globalValue $key $localValue | fail -}}
                    {{- end -}}
                {{- end -}}
            {{- end -}}
            {{- toYaml (merge $nodeSelector .Values.nodeSelector) | trim -}}
        {{- else -}}
            {{- toYaml $nodeSelector | trim -}}
        {{- end -}}
    {{- else -}}
        {{- toYaml .Values.nodeSelector -}}
    {{- end -}}
{{- else -}}
    {{- toYaml .Values.nodeSelector -}}
{{- end -}}
{{ end }}

{{/*
DR-D1121-065. Support .Values.annotations, custom annotations set by application engineer.
Need the range statement to avoid printing '{}' if all custom annotations are empty.
*/}}
{{- define "eric-fh-snmp-alarm-provider.custom-annotations" }}
{{- if .Values.annotations }}
{{ toYaml .Values.annotations }}
{{- end }}
{{- end -}}

{{/*
Annotations containing both product info and custom annotations
*/}}
{{- define "eric-fh-snmp-alarm-provider.annotations" }}
{{- template "eric-fh-snmp-alarm-provider.product-info" . }}
{{- template "eric-fh-snmp-alarm-provider.custom-annotations" . }}
{{ if .Values.oamVIP.enabled -}}
    {{- template "eric-fh-snmp-alarm-provider.roleBinding.customAnnotations" -}}
{{- else -}}
    {{- template "eric-fh-snmp-alarm-provider.roleBinding.defaultAnnotations" -}}
{{- end -}}
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