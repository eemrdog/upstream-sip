{{/*
Create a map from global values with defaults if not in the values file. (DR-D1123-124)
*/}}
{{ define "eric-data-coordinator-zk.globalMap" }}
  {{- $globalDefaults := dict "security" (dict "policyBinding" (dict "create" false)) -}}
  {{- $globalDefaults := merge $globalDefaults (dict "security" (dict "policyReferenceMap" (dict "default-restricted-security-policy" "default-restricted-security-policy"))) -}}
  {{ if .Values.global }}
    {{- mergeOverwrite $globalDefaults .Values.global | toJson -}}
  {{ else }}
    {{- $globalDefaults | toJson -}}
  {{ end }}
{{ end }}

{{- define "eric-data-coordinator-zk.pullSecret.global" -}}
{{- $pullSecret := "" -}}
{{- if .Values.global -}}
    {{- if .Values.global.pullSecret -}}
      {{- $pullSecret = .Values.global.pullSecret -}}
    {{- end -}}
{{- end -}}
{{- print $pullSecret -}}
{{- end -}}

{{/*
Create image pull secret, service level parameter takes precedence
*/}}
{{- define "eric-data-coordinator-zk.pullSecret" -}}
{{- $pullSecret := ( include "eric-data-coordinator-zk.pullSecret.global" . ) -}}
  {{- if .Values.imageCredentials.pullSecret -}}
    {{- $pullSecret = .Values.imageCredentials.pullSecret -}}
  {{- end -}}
{{- print $pullSecret -}}
{{- end -}}

{{- define "eric-data-coordinator-zk.imagePullPolicy.global" -}}
{{- $imagePullPolicy := "IfNotPresent" -}}
{{- if .Values.global -}}
    {{- if .Values.global.registry -}}
        {{- if .Values.global.registry.imagePullPolicy -}}
            {{- $imagePullPolicy = .Values.global.registry.imagePullPolicy -}}
        {{- end -}}
    {{- end -}}
{{- end -}}
{{- print $imagePullPolicy -}}
{{- end -}}

{{/*
create internalIPFamily
*/}}
{{- define "eric-data-coordinator-zk.internalIPFamily.global" -}}
{{- $ipFamilies := "" -}}
{{- if .Values.global -}}
  {{- if .Values.global.internalIPFamily -}}
      {{- $ipFamilies = .Values.global.internalIPFamily -}}
  {{- end }}
{{- end }}
{{- print $ipFamilies -}}
{{- end -}}

{{/*
Pull policy for the datacoordinatorzk container
*/}}
{{- define "eric-data-coordinator-zk.dczk.imagePullPolicy" -}}
{{- $imagePullPolicy := ( include "eric-data-coordinator-zk.imagePullPolicy.global" . ) -}}
{{- if .Values.imageCredentials.datacoordinatorzk.registry.imagePullPolicy -}}
    {{- $imagePullPolicy = .Values.imageCredentials.datacoordinatorzk.registry.imagePullPolicy -}}
{{- end -}}
{{- print $imagePullPolicy -}}
{{- end -}}

{{/*
Pull policy for the brAgent container
*/}}
{{- define "eric-data-coordinator-zk.brAgent.imagePullPolicy" -}}
{{- $imagePullPolicy := ( include "eric-data-coordinator-zk.imagePullPolicy.global" . ) -}}
{{- if .Values.imageCredentials.brAgent.registry.imagePullPolicy -}}
    {{- $imagePullPolicy = .Values.imageCredentials.brAgent.registry.imagePullPolicy -}}
{{- end -}}
{{- print $imagePullPolicy -}}
{{- end -}}


{{/*
Argument: imageName
Returns image path of provided imageName.
*/}}
{{- define "eric-data-coordinator-zk.imagePath" }}
    {{- $productInfo := fromYaml (.Files.Get "eric-product-info.yaml") -}}
    {{- $image := (get $productInfo.images .imageName) -}}
    {{- $registryUrl := $image.registry -}}
    {{- $repoPath := $image.repoPath -}}
    {{- $name := $image.name -}}
    {{- $tag := $image.tag -}}

    {{- if .Values.global -}}
        {{- if .Values.global.registry -}}
            {{- if .Values.global.registry.url -}}
                {{- $registryUrl = .Values.global.registry.url -}}
            {{- end -}}
        {{- end -}}
    {{- end -}}
    {{- if .Values.imageCredentials -}}
        {{- if hasKey .Values.imageCredentials .imageName -}}
            {{- $credImage := get .Values.imageCredentials .imageName }}
            {{- if $credImage.registry -}}
                {{- if $credImage.registry.url -}}
                    {{- $registryUrl = $credImage.registry.url -}}
                {{- end -}}
            {{- end -}}
            {{- if not (kindIs "invalid" $credImage.repoPath) -}}
                {{- $repoPath = $credImage.repoPath -}}
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
Get bro service name
*/}}
{{- define "eric-data-coordinator-zk.broServiceName" -}}
{{- $broServiceName := "eric-ctrl-bro" -}}
{{- if .Values.global -}}
    {{- if .Values.global.adpBR -}}
        {{- if .Values.global.adpBR.broServiceName -}}
            {{- $broServiceName = .Values.global.adpBR.broServiceName -}}
        {{- end -}}
    {{- end -}}
{{- end -}}
{{- print $broServiceName -}}
{{- end -}}

{{/*
Get bro service port
*/}}
{{- define "eric-data-coordinator-zk.broGrpcServicePort" -}}
{{- $broGrpcServicePort := "3000" -}}
{{- if .Values.global -}}
    {{- if .Values.global.adpBR -}}
        {{- if .Values.global.adpBR.broGrpcServicePort -}}
            {{- $broGrpcServicePort = .Values.global.adpBR.broGrpcServicePort -}}
        {{- end -}}
    {{- end -}}
{{- end -}}
{{- print $broGrpcServicePort -}}
{{- end -}}

{{/*
Get bro service brLabelKey
*/}}
{{- define "eric-data-coordinator-zk.brLabelKey" -}}
{{- $brLabelKey := "adpbrlabelkey" -}}
{{- if .Values.global -}}
    {{- if .Values.global.adpBR -}}
        {{- if .Values.global.adpBR.brLabelKey -}}
            {{- $brLabelKey = .Values.global.adpBR.brLabelKey -}}
        {{- end -}}
    {{- end -}}
{{- end -}}
{{- print $brLabelKey -}}
{{- end -}}

{{/*
Define timezone
*/}}
{{- define "eric-data-coordinator-zk.timezone" -}}
{{- $timezone := "UTC" -}}
{{- if .Values.global -}}
    {{- if .Values.global.timezone -}}
        {{- $timezone = .Values.global.timezone -}}
    {{- end -}}
{{- end -}}
{{- print $timezone | quote -}}
{{- end -}}

{{/*
Return the fsgroup set via global parameter if it's set, otherwise 10000
*/}}
{{- define "eric-data-coordinator-zk.fsGroup.coordinated" -}}
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
Define TLS, note: returns boolean as string
*/}}
{{- define "eric-data-coordinator-zk.tls" -}}
{{- $tls := true -}}
{{- if .Values.global -}}
    {{- if .Values.global.security -}}
        {{- if .Values.global.security.tls -}}
            {{- if hasKey .Values.global.security.tls "enabled" -}}
                {{- $tls = .Values.global.security.tls.enabled -}}
            {{- end -}}
        {{- end -}}
    {{- end -}}
{{- end -}}
{{- $tls -}}
{{- end -}}

{{/*
Define SASL PLAINTEXT, note: returns boolean as string
*/}}
{{- define "eric-data-coordinator-zk.sasl" -}}
{{- $sasl := false -}}
{{- if .Values.global -}}
    {{- if .Values.global.security -}}
        {{- if .Values.global.security.sasl -}}
            {{- if hasKey .Values.global.security.sasl "enabled" -}}
                {{- $sasl = .Values.global.security.sasl.enabled -}}
            {{- end -}}
        {{- end -}}
    {{- end -}}
{{- end -}}
{{- $sasl -}}
{{- end -}}

{{/*
Define PM endpoint connectors: TLS,clearText
*/}}
{{- define "eric-data-coordinator-zk.pm.connectors" -}}
    {{- $connectors := list -}}
    {{- if .Values.metrics.enabled -}}
        {{- if (eq (include "eric-data-coordinator-zk.tls" .) "true") -}}
            {{- $connectors = append $connectors "TLS" -}}
            {{- if eq .Values.service.endpoints.pm.tls.enforced "optional" -}}
                {{- $connectors = append $connectors "clearText" -}}
            {{- end -}}
        {{- else -}}
            {{- $connectors = append $connectors "clearText" -}}
        {{- end -}}
    {{- end -}}
    {{- $connectors -}}
{{- end -}}

{{/*
 CA Secret provided by PM Server
*/}}
{{- define "eric-data-coordinator-zk.pmCaSecretName" -}}
    {{- if .Values.service.endpoints.pm.tls.caSecretName -}}
        {{- .Values.service.endpoints.pm.tls.caSecretName -}}
    {{- else -}}
        {{- .Values.serverNameParameter.pmServer -}}-ca
    {{- end -}}
{{- end -}}

{{/*
Allow for override of chart name
*/}}
{{- define "eric-data-coordinator-zk.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Allow a fully qualified name for naming kubernetes resources
*/}}
{{- define "eric-data-coordinator-zk.fullname" -}}
{{- if .Values.fullnameOverride -}}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- printf "%s" $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}

{{/*
Client service url
*/}}
{{- define "eric-data-coordinator-zk.clientUrl" -}}
{{ template "eric-data-coordinator-zk.fullname" . }}:{{ .Values.clientPort }}
{{- end -}}

{{/*
Client secure port
*/}}
{{- define "eric-data-coordinator-zk.clientTlsUrl" -}}
{{ template "eric-data-coordinator-zk.fullname" . }}:{{ .Values.network.datacoordinatorzk.client.tlsPort }}
{{- end -}}

{{/*
Name of the Internal Service which controls the domain of the Data Coordinator ZK ensemble.
*/}}
{{- define "eric-data-coordinator-zk.ensembleService.fullname" -}}
{{- if .Values.fullnameOverride -}}
{{- printf "%s-ensemble-service" .Values.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- printf "%s-ensemble-service" $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}

{{/*
Chart name and version used in chart label.
*/}}
{{- define "eric-data-coordinator-zk.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create annotation for the product information (DR-D1121-064)
*/}}
{{- define "eric-data-coordinator-zk.productinfo" }}
ericsson.com/product-name: {{ (fromYaml (.Files.Get "eric-product-info.yaml")).productName | quote }}
ericsson.com/product-number: {{ (fromYaml (.Files.Get "eric-product-info.yaml")).productNumber | quote }}
ericsson.com/product-revision: {{regexReplaceAll "(.*)[+|-].*" .Chart.Version "${1}" | quote }}
{{- end }}

{{/*
Merged annotations for Default, which includes productInfo and config.
*/}}
{{- define "eric-data-coordinator-zk.annotations" -}}
  {{- $productInfo := include "eric-data-coordinator-zk.productinfo" . | fromYaml -}}
  {{- $config := include "eric-data-coordinator-zk.config-annotations" . | fromYaml -}}
  {{- include "eric-data-coordinator-zk.mergeAnnotations" (dict "location" (.Template.Name) "sources" (list $productInfo $config)) | trim }}
{{- end -}}

{{/*
serviceAccount - will be deprecated from k8 1.22.0 onwards, supporting it for older versions
*/}}

{{- define "eric-data-coordinator-zk.serviceAccount" -}}
{{- if and (eq (int (.Capabilities.KubeVersion.Major)) 1) (lt (int (.Capabilities.KubeVersion.Minor)) 22) -}}
  serviceAccount: ""
{{- end -}}
{{- end -}}

{{/*
Create a user defined annotation (DR-D1121-065, DR-D1121-060).
*/}}
{{ define "eric-data-coordinator-zk.config-annotations" }}
  {{- $global := (.Values.global).annotations -}}
  {{- $service := .Values.annotations -}}
  {{- include "eric-data-coordinator-zk.mergeAnnotations" (dict "location" (.Template.Name) "sources" (list $global $service)) -}}
{{- end }}

{{/*
Traffic shaping bandwidth limit annotation (DR-D1125-040-AD)
*/}}
{{ define "eric-data-coordinator-zk.bandwidth-annotations" }}
{{- if .Values.bandwidth.maxEgressRate }}
kubernetes.io/egress-bandwidth: {{ .Values.bandwidth.maxEgressRate }}
{{- end }}
{{- end }}


{{/*
Client CA Secret Name
*/}}
{{- define "eric-data-coordinator-zk.client.ca.secret" -}}
{{ template "eric-data-coordinator-zk.fullname" . }}-client-ca-secret
{{- end -}}

{{/*
Server Cert Secret Name
*/}}
{{- define "eric-data-coordinator-zk.server.cert.secret" -}}
{{ template "eric-data-coordinator-zk.fullname" . }}-server-cert-secret
{{- end -}}

{{/*
Client Cert Secret Name
*/}}
{{- define "eric-data-coordinator-zk.client.cert.secret" -}}
{{ template "eric-data-coordinator-zk.fullname" . }}-client-cert-secret
{{- end -}}

{{/*
Create a user defined label (DR-D1121-068, DR-D1121-060).
*/}}
{{ define "eric-data-coordinator-zk.config-labels" }}
  {{- $global := (.Values.global).labels -}}
  {{- $service := .Values.labels -}}
  {{- include "eric-data-coordinator-zk.mergeLabels" (dict "location" (.Template.Name) "sources" (list $global $service)) -}}
{{- end }}

{{/*
Labels.
*/}}
{{- define "eric-data-coordinator-zk.labels" }}
  {{- $base := dict -}}
  {{- $_ := set $base "app.kubernetes.io/name" (include "eric-data-coordinator-zk.name" .) -}}
  {{- $_ := set $base "app.kubernetes.io/version" (include "eric-data-coordinator-zk.chart" .) -}}
  {{- $_ := set $base "app.kubernetes.io/managed-by" (.Release.Service | toString) -}}

  {{- $config := include "eric-data-coordinator-zk.config-labels" . | fromYaml -}}
  {{- $selector := include "eric-data-coordinator-zk.selectorLabels" . | fromYaml -}}
  {{- include "eric-data-coordinator-zk.mergeLabels" (dict "location" (.Template.Name) "sources" (list $selector $base $config)) | trim }}
{{- end -}}

{{/*
Selector labels.
*/}}
{{- define "eric-data-coordinator-zk.selectorLabels" }}
release: {{ .Release.Name | quote }}
app: {{ template "eric-data-coordinator-zk.name" . }}
{{- if eq (include "eric-data-coordinator-zk.needInstanceLabelSelector" .) "true" }}
app.kubernetes.io/instance: {{ .Release.Name | quote }}
{{- end -}}
{{- end }}

{{- define "eric-data-coordinator-zk.needInstanceLabelSelector" }}
    {{- $needInstanceLabelSelector := false -}}
    {{- if .Release.IsInstall }}
        {{- $needInstanceLabelSelector = true -}}
    {{- else if .Release.IsUpgrade }}
        {{- $dczkSs := (lookup "apps/v1" "StatefulSet" .Release.Namespace (include "eric-data-coordinator-zk.fullname" .)) -}}
        {{- if $dczkSs -}}
            {{- if hasKey $dczkSs.spec.selector.matchLabels "app.kubernetes.io/instance" -}}
                {{- $needInstanceLabelSelector = true -}}
            {{- end -}}
        {{- end -}}
    {{- end -}}
    {{- $needInstanceLabelSelector -}}
{{- end }}

{{/*
Allow for override of agent name
*/}}
{{- define "eric-data-coordinator-zk.agentName" -}}
{{ template "eric-data-coordinator-zk.name" . }}-agent
{{- end -}}

{{/*
Agent Labels.
*/}}
{{- define "eric-data-coordinator-zk.agent.labels" }}
  {{- $base := dict -}}
  {{- $_ := set $base "app.kubernetes.io/version" (include "eric-data-coordinator-zk.chart" .) -}}
  {{- $_ := set $base "app.kubernetes.io/managed-by" (.Release.Service | toString) -}}

  {{- $config := include "eric-data-coordinator-zk.config-labels" . | fromYaml -}}
  {{- $selector := include "eric-data-coordinator-zk.agent.selectorLabels" . | fromYaml -}}
  {{- include "eric-data-coordinator-zk.mergeLabels" (dict "location" (.Template.Name) "sources" (list $selector $config $base)) | trim }}
{{- end -}}

{{/*
brLabelValues.
*/}}
{{- define "eric-data-coordinator-zk.agent.brlabels" }}
{{- if .Values.brAgent.brLabelValue -}}
    {{- print .Values.brAgent.brLabelValue -}}
{{ else }}
    {{ template "eric-data-coordinator-zk.fullname" . }}
{{ end }}
{{- end }}

{{/*
Selector labels.
*/}}
{{- define "eric-data-coordinator-zk.agent.selectorLabels" }}
app.kubernetes.io/name: {{ include "eric-data-coordinator-zk.agentName" . | quote }}
app.kubernetes.io/instance: {{ .Release.Name | quote }}
{{ template "eric-data-coordinator-zk.brLabelKey" . }}: {{ template "eric-data-coordinator-zk.agent.brlabels" . }}
{{- end }}

{{/*
volume information.
*/}}
{{- define "eric-data-coordinator-zk.volumes" }}
{{- if (eq (include "eric-data-coordinator-zk.tls" .) "true") -}}
  {{- if eq .Values.service.endpoints.datacoordinatorzk.tls.provider "edaTls" -}}
- name: {{ .Values.service.endpoints.datacoordinatorzk.tls.edaTls.secretName | quote }}
  secret:
    secretName: {{ .Values.service.endpoints.datacoordinatorzk.tls.edaTls.secretName | quote }}
  {{- else if eq .Values.service.endpoints.datacoordinatorzk.tls.provider "sip-tls" -}}
- name: server-cert
  secret:
    secretName: {{ include "eric-data-coordinator-zk.server.cert.secret" . | quote }}
- name: siptls-ca
  secret:
    secretName: "eric-sec-sip-tls-trusted-root-cert"
- name: client-ca
  secret:
    secretName: {{ include "eric-data-coordinator-zk.client.ca.secret" . | quote }}
  {{- if  eq .Values.service.endpoints.datacoordinatorzk.tls.enforced "required" }}
- name: client-cert
  secret:
    secretName: {{ include "eric-data-coordinator-zk.client.cert.secret" . | quote }}
  {{- end -}}
  {{- end -}}
{{- if contains "TLS" (include "eric-data-coordinator-zk.pm.connectors" . ) }}
- name: eric-pm-server-ca
  secret:
    secretName: {{ include "eric-data-coordinator-zk.pmCaSecretName" . }}
    optional: true
{{- end }}
{{- end -}}
{{- end -}}

{{/*
volume Mount information.
*/}}
{{- define "eric-data-coordinator-zk.secretsMountPath" -}}
{{- if (eq (include "eric-data-coordinator-zk.tls" .) "true") }}
  {{- if eq .Values.service.endpoints.datacoordinatorzk.tls.provider "edaTls" }}
  - name: {{ .Values.service.endpoints.datacoordinatorzk.tls.edaTls.secretName | quote }}
    mountPath: "/etc/zookeeper/secrets"
    readOnly: true
  {{- else if eq .Values.service.endpoints.datacoordinatorzk.tls.provider "sip-tls" }}
  - name:  server-cert
    mountPath: "/run/zookeeper/secrets/servercert"
  - name: siptls-ca
    mountPath: "/run/zookeeper/secrets/siptlsca"
  - name: client-ca
    mountPath: "/run/zookeeper/secrets/clientca"
  {{- if  eq .Values.service.endpoints.datacoordinatorzk.tls.enforced "required" }}
  - name: client-cert
    mountPath: "/run/zookeeper/secrets/clientcert"
  {{- end -}}
  {{- end -}}
  {{- if contains "TLS" (include "eric-data-coordinator-zk.pm.connectors" . ) }}
  - name: eric-pm-server-ca
    mountPath: "/run/pm/secrets/"
  {{- end }}
{{- end -}}
{{- end -}}

{{/*
configmap volumes + additional volumes
*/}}
{{- define "eric-data-coordinator-zk.agent.volumes" -}}
{{- if (eq (include "eric-data-coordinator-zk.tls" .) "true") }}
- name: {{ template "eric-data-coordinator-zk.name" . }}-siptls-ca
  secret:
    secretName: "eric-sec-sip-tls-trusted-root-cert"
- name: {{ template "eric-data-coordinator-zk.agentName" . }}-bro-client-cert
  secret:
    secretName: {{ template "eric-data-coordinator-zk.agentName" . }}-bro-client-cert
- name: {{ template "eric-data-coordinator-zk.agentName" . }}-zk-client-cert
  secret:
    secretName: {{ template "eric-data-coordinator-zk.agentName" . }}-zk-client-cert
{{- end }}
- name: {{ template "eric-data-coordinator-zk.agentName" . }}
  configMap:
    defaultMode: 0444
    name: {{ template "eric-data-coordinator-zk.agentName" . }}
- name: backupdir
  emptyDir:
  {{- if index .Values.resources.brAgent.limits "ephemeral-storage" }}
    sizeLimit: {{ index .Values.resources.brAgent.limits "ephemeral-storage" }}
  {{- end }}
{{- end -}}

{{/*
configmap volumemounts + additional volume mounts
*/}}
{{- define "eric-data-coordinator-zk.agent.volumeMounts" -}}
{{- if ( eq (include "eric-data-coordinator-zk.tls" .) "true") }}
- name: {{ template "eric-data-coordinator-zk.name" . }}-siptls-ca
  mountPath: "/run/sec/cas/siptlsca/"
- name: {{ template "eric-data-coordinator-zk.agentName" . }}-bro-client-cert
  mountPath: "/run/bro/secrets/client"
- name: {{ template "eric-data-coordinator-zk.agentName" . }}-zk-client-cert
  mountPath: "/run/zookeeper/secrets/client"
{{- end }}
- name: {{ template "eric-data-coordinator-zk.agentName" . }}
  mountPath: /{{ .Values.brAgent.properties.fileName }}
  subPath: {{ .Values.brAgent.properties.fileName }}
- name: {{ template "eric-data-coordinator-zk.agentName" . }}
  mountPath: /{{ .Values.brAgent.logging.fileName }}
  subPath: {{ .Values.brAgent.logging.fileName }}
- name: backupdir
  mountPath: /backupdata
{{ end -}}

{{/*
Semi-colon separated list of backup types
*/}}
{{- define "eric-data-coordinator-zk.agent.backupTypes" }}
{{- range $i, $e := .Values.brAgent.backupTypeList -}}
{{- if eq $i 0 -}}{{- printf " " -}}{{- else -}}{{- printf ";" -}}{{- end -}}{{- . -}}
{{- end -}}
{{- end -}}

{{/*
Annotation for brAgent.backupType.
*/}}
{{- define "eric-data-coordinator-zk.agent_deployment.annotations.backupType"}}
{{- if .Values.brAgent.backupTypeList }}
  {{- if (index .Values.brAgent.backupTypeList 0) }}
    backupType: {{- include "eric-data-coordinator-zk.agent.backupTypes" . }}
  {{- end }}
{{- end }}
{{- end -}}

{{/*
DNS LIST.
*/}}
{{- define "eric-data-coordinator-zk.dns" -}}
{{- $dnslist := list (include "eric-data-coordinator-zk.dnsname" .) "certified-scrape-target" -}}
{{- $dnslist | toJson -}}
{{- end}}

{{/*
Quorum DNS
*/}}
{{- define "eric-data-coordinator-zk.dnsname" -}}
*.{{- include "eric-data-coordinator-zk.ensembleService.fullname" . }}.{{ .Release.Namespace }}.svc.{{ .Values.clusterDomain }}
{{- end}}
{{/*
Create a merged set of nodeSelectors from global and service level -dczk.
*/}}
{{ define "eric-data-coordinator-zk.dczkNodeSelector" }}
  {{- $global := .Values.global.nodeSelector -}}
  {{- $service := .Values.nodeSelector.datacoordinatorzk -}}
  {{- include "eric-data-coordinator-zk.aggregatedMerge" (dict "context" "nodeSelector" "location" (.Template.Name) "sources" (list $global $service)) | trim -}}
{{ end }}
{{/*
Create a merged set of nodeSelectors from global and service level - brAgent.
*/}}
{{- define "eric-data-coordinator-zk.brAgentNodeSelector" -}}
  {{- $global := .Values.global.nodeSelector -}}
  {{- $service := .Values.nodeSelector.brAgent -}}
  {{- include "eric-data-coordinator-zk.aggregatedMerge" (dict "context" "nodeSelector" "location" (.Template.Name) "sources" (list $global $service)) | trim -}}
{{ end }}
{{/*
Get DCZK Replicas Count
*/}}
{{- define "eric-data-coordinator-zk.replicas" -}}
{{- $replicas := .Values.replicaCount -}}
{{- print $replicas -}}
{{- end -}}
{{/*
Get DCZK-brAgent Replicas Count
*/}}
{{- define "eric-data-coordinator-zk.brAgent.replicas" -}}
{{- $replicas := .Values.brAgent.replicaCount -}}
{{- print $replicas -}}
{{- end -}}

{{/*
ZK livenessProbeConfig
*/}}
{{- define "eric-data-coordinator-zk.livenessProbeConfig" }}
{{- $image := get .Values.probes .imageName -}}
{{- $initialDelay := $image.livenessProbe.initialDelaySeconds -}}
{{- $timeoutSec := $image.livenessProbe.timeoutSeconds -}}
{{- $periodSec := $image.livenessProbe.periodSeconds -}}
{{ $failThreshold := $image.livenessProbe.failureThreshold }}
{{ printf "initialDelaySeconds: %v"  $initialDelay }}
{{ printf "timeoutSeconds: %v"  $timeoutSec }}
{{ printf "periodSeconds: %v"  $periodSec }}
{{ printf "failureThreshold: %v"  $failThreshold }}
{{- end }}

{{/*
ZK readinessProbeConfig
*/}}
{{- define "eric-data-coordinator-zk.readinessProbeConfig" }}
{{- $image := get .Values.probes .imageName -}}
{{- $initialDelay := $image.readinessProbe.initialDelaySeconds -}}
{{- $timeoutSec := $image.readinessProbe.timeoutSeconds -}}
{{- $periodSec := $image.readinessProbe.periodSeconds -}}
{{- $failThreshold := $image.readinessProbe.failureThreshold -}}
{{ $successfulThreshold := $image.readinessProbe.successThreshold }}
{{ printf "initialDelaySeconds: %v"  $initialDelay }}
{{ printf "timeoutSeconds: %v"  $timeoutSec }}
{{ printf "periodSeconds: %v"  $periodSec }}
{{ printf "failureThreshold: %v"  $failThreshold }}
{{ printf "successThreshold: %v"  $successfulThreshold }}
{{- end }}

{{/*
Define DCZK podPriority
*/}}
{{- define "eric-data-coordinator-zk.podPriority" }}
{{- if .Values.podPriority }}
  {{- if index .Values.podPriority "eric-data-coordinator-zk" -}}
    {{- if (index .Values.podPriority "eric-data-coordinator-zk" "priorityClassName") }}
      priorityClassName: {{ index .Values.podPriority "eric-data-coordinator-zk" "priorityClassName" | quote }}
    {{- end }}
  {{- end }}
{{- end }}
{{- end }}

{{/*
Define DCZK-Agent podPriority
*/}}
{{- define "eric-data-coordinator-zk-agent.podPriority" }}
{{- if .Values.podPriority }}
  {{- if index .Values.podPriority "eric-data-coordinator-zk-agent" -}}
    {{- if (index .Values.podPriority "eric-data-coordinator-zk-agent" "priorityClassName") }}
      priorityClassName: {{ index .Values.podPriority "eric-data-coordinator-zk-agent" "priorityClassName" | quote }}
    {{- end }}
  {{- end }}
{{- end }}
{{- end }}

{{/*
Logshipper labels
*/}}
{{- define "eric-data-coordinator-zk.logshipper-labels" }}
{{- println "" -}}
{{- include "eric-data-coordinator-zk.labels" . -}}
{{- end }}

{{/*
Logshipper annotations
*/}}
{{- define "eric-data-coordinator-zk.logshipper-annotations" }}
{{- println "" -}}
{{- include "eric-data-coordinator-zk.annotations" . -}}
{{- end }}

{{/*
Define the apparmor annotation creation based on input profile and container name
*/}}
{{- define "eric-data-coordinator-zk.getApparmorAnnotation" -}}
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
Define the apparmor annotation for datacoordinatorzk container
*/}}
{{- define "eric-data-coordinator-zk.datacoordinatorzk.appArmorAnnotations" -}}
{{- if .Values.appArmorProfile -}}
{{- $profile := .Values.appArmorProfile -}}
{{- if index .Values.appArmorProfile "datacoordinatorzk" -}}
{{- $profile = index .Values.appArmorProfile "datacoordinatorzk" }}
{{- end -}}
{{- include "eric-data-coordinator-zk.getApparmorAnnotation" (dict "profile" $profile "ContainerName" "datacoordinatorzk") }}
{{- end -}}
{{- end -}}

{{/*
Define the apparmor annotation for metricsexporter container
*/}}
{{- define "eric-data-coordinator-zk.metricsexporter.appArmorAnnotations" -}}
{{- if .Values.appArmorProfile -}}
{{- $profile := .Values.appArmorProfile -}}
{{- if index .Values.appArmorProfile "metricsexporter" -}}
{{- $profile = index .Values.appArmorProfile "metricsexporter" }}
{{- end -}}
{{- include "eric-data-coordinator-zk.getApparmorAnnotation" (dict "profile" $profile "ContainerName" "metricsexporter") }}
{{- end -}}
{{- end -}}

{{/*
Define the apparmor annotation for logshipper container
*/}}
{{- define "eric-data-coordinator-zk.logshipper.appArmorAnnotations" -}}
{{- if .Values.appArmorProfile -}}
{{- $profile := .Values.appArmorProfile -}}
{{- if index .Values.appArmorProfile "logshipper" -}}
{{- $profile = index .Values.appArmorProfile "logshipper" }}
{{- end -}}
{{- include "eric-data-coordinator-zk.getApparmorAnnotation" (dict "profile" $profile "ContainerName" "logshipper") }}
{{- end -}}
{{- end -}}

{{/*
Define the apparmor annotation for brAgent container
*/}}
{{- define "eric-data-coordinator-zk.brAgent.appArmorAnnotations" -}}
{{- if .Values.appArmorProfile -}}
{{- $profile := .Values.appArmorProfile -}}
{{- if index .Values.appArmorProfile "brAgent" -}}
{{- $profile = index .Values.appArmorProfile "brAgent" }}
{{- end -}}
{{- $bragentcontainer := (printf "%s%s" .Chart.Name "-agent") }}
{{- include "eric-data-coordinator-zk.getApparmorAnnotation" (dict "profile" $profile "ContainerName" $bragentcontainer) }}
{{- end -}}
{{- end -}}


{{/*
Define the seccomp security context creation based on input profile (no container name needed since it is already in the containers security profile)
*/}}
{{- define "eric-data-coordinator-zk.getSeccompSecurityContext" -}}
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
Define the seccomp security context for datacoordinatorzk container
*/}}
{{- define "eric-data-coordinator-zk.datacoordinatorzk.seccompProfile" -}}
{{- if .Values.seccompProfile }}
{{- $profile := .Values.seccompProfile }}
{{- if index .Values.seccompProfile "datacoordinatorzk" }}
{{- $profile = index .Values.seccompProfile "datacoordinatorzk" }}
{{- end }}
{{- include "eric-data-coordinator-zk.getSeccompSecurityContext" (dict "profile" $profile) }}
{{- end -}}
{{- end -}}

{{/*
Define the seccomp security context for metricsexporter container
*/}}
{{- define "eric-data-coordinator-zk.metricsexporter.seccompProfile" -}}
{{- if .Values.seccompProfile }}
{{- $profile := .Values.seccompProfile }}
{{- if index .Values.seccompProfile "metricsexporter" }}
{{- $profile = index .Values.seccompProfile "metricsexporter" }}
{{- end }}
{{- include "eric-data-coordinator-zk.getSeccompSecurityContext" (dict "profile" $profile) }}
{{- end -}}
{{- end -}}

{{/*
Define the seccomp security context for logshipper container
*/}}
{{- define "eric-data-coordinator-zk.logshipper.seccompProfile" -}}
{{- if .Values.seccompProfile }}
{{- $profile := .Values.seccompProfile }}
{{- if index .Values.seccompProfile "logshipper" }}
{{- $profile = index .Values.seccompProfile "logshipper" }}
{{- end }}
{{- include "eric-data-coordinator-zk.getSeccompSecurityContext" (dict "profile" $profile) }}
{{- end -}}
{{- end -}}

{{/*
Define the seccomp security context for brAgent container
*/}}
{{- define "eric-data-coordinator-zk.brAgent.seccompProfile" -}}
{{- if .Values.seccompProfile }}
{{- $profile := .Values.seccompProfile }}
{{- if index .Values.seccompProfile "brAgent" }}
{{- $profile = index .Values.seccompProfile "brAgent" }}
{{- end }}
{{- include "eric-data-coordinator-zk.getSeccompSecurityContext" (dict "profile" $profile) }}
{{- end -}}
{{- end -}}
