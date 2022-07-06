{{/* vim: set filetype=mustache: */}}
{{/*
Expand the name of the chart.
*/}}
{{- define "eric-data-distributed-coordinator-ed.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "eric-data-distributed-coordinator-ed.chart" -}}
	{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "eric-data-distributed-coordinator-ed.pullSecret.global" -}}
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
{{- define "eric-data-distributed-coordinator-ed.pullSecret" -}}
{{- $pullSecret := ( include "eric-data-distributed-coordinator-ed.pullSecret.global" . ) -}}
  {{- if .Values.imageCredentials.pullSecret -}}
    {{- $pullSecret = .Values.imageCredentials.pullSecret -}}
  {{- end -}}
{{- print $pullSecret -}}
{{- end -}}

{{/*
create internalIPFamily
*/}}
{{- define "eric-data-distributed-coordinator-ed.internalIPFamily.global" -}}
{{- $ipFamilies := "" -}}
{{- if .Values.global -}}
  {{- if .Values.global.internalIPFamily -}}
      {{- $ipFamilies = .Values.global.internalIPFamily -}}
  {{- end }}
{{- end }}
{{- print $ipFamilies -}}
{{- end -}}


{{- define "eric-data-distributed-coordinator-ed.imagePullPolicy.global" -}}
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
Pull policy for the dced container
*/}}
{{- define "eric-data-distributed-coordinator-ed.dced.imagePullPolicy" -}}
{{- $imagePullPolicy := ( include "eric-data-distributed-coordinator-ed.imagePullPolicy.global" . ) -}}
{{- if .Values.imageCredentials.dced.registry.imagePullPolicy -}}
    {{- $imagePullPolicy = .Values.imageCredentials.dced.registry.imagePullPolicy -}}
{{- end -}}
{{- print $imagePullPolicy -}}
{{- end -}}

{{/*
Pull policy for the brAgent container
*/}}
{{- define "eric-data-distributed-coordinator-ed.brAgent.imagePullPolicy" -}}
{{- $imagePullPolicy := ( include "eric-data-distributed-coordinator-ed.imagePullPolicy.global" . ) -}}
{{- if .Values.imageCredentials.brAgent.registry.imagePullPolicy -}}
    {{- $imagePullPolicy = .Values.imageCredentials.brAgent.registry.imagePullPolicy -}}
{{- end -}}
{{- print $imagePullPolicy -}}
{{- end -}}


{{/*
Argument: imageName
Returns image path of provided imageName.
*/}}
{{- define "eric-data-distributed-coordinator-ed.imagePath" }}
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
    {{- if .Values.images -}}
      {{- if eq .imageName "dced" -}}
        {{- $name = ( include "eric-data-distributed-coordinator-ed.image.dced.name" . ) -}}
        {{- $tag = ( include "eric-data-distributed-coordinator-ed.image.dced.tag" . ) -}}
      {{- else if hasKey .Values.images .imageName -}}
          {{- $deprecatedImageParam := get .Values.images .imageName }}
          {{- if $deprecatedImageParam.name }}
              {{- $name = $deprecatedImageParam.name -}}
          {{- end -}}
          {{- if $deprecatedImageParam.tag }}
              {{- $tag = $deprecatedImageParam.tag -}}
          {{- end -}}
      {{- end -}}
    {{- end -}}
    {{- printf "%s/%s%s:%s" $registryUrl $repoPath $name $tag -}}
{{- end -}}


{{/*
serviceAccount - will be deprecated from k8 1.22.0 onwards, supporting it for older versions
*/}}

{{- define "eric-data-distributed-coordinator-ed.serviceAccount" -}}
{{- $MinorVersion := int (.Capabilities.KubeVersion.Minor) -}}
{{- if lt $MinorVersion 22 -}}
  serviceAccount: ""
{{- end -}}
{{- end -}}


{{/*
DR-HC-113 ( BRAgent will not have an endpoint will have mtls by default)
Aligning with toggling with global.security.tls.enabled parameter - if set mtls is enforced between BRO and DCEDBrAgent.
*/}}

{{- define "eric-data-distributed-coordinator-ed.brAgent.tls" -}}
{{- $tls := true -}}
{{- if .Values.global -}}
    {{- if .Values.global.security -}}
          {{- if .Values.global.security.tls -}}
            {{- $tls = .Values.global.security.tls.enabled -}}
          {{- end -}}
    {{- end -}}
{{- end -}}
{{- $tls -}}
{{- end -}}

{{/*
 Ports - dced -peer
*/}}
{{- define "eric-data-distributed-coordinator-ed.ports.peer" -}}
{{- $peerPort := 2380 -}}
{{- print $peerPort -}}
{{- end -}}

{{/*
Create peer url
*/}}

{{- define "eric-data-distributed-coordinator-ed.peerUrl" -}}
   {{- printf "https://0.0.0.0:%d" (int64 (include "eric-data-distributed-coordinator-ed.ports.peer" . )) -}}
{{- end -}}

{{/*
If the timezone isn't set by a global parameter, set it to UTC
*/}}
{{- define "eric-data-distributed-coordinator-ed.timezone" -}}
{{- if .Values.global -}}
    {{- .Values.global.timezone | default "UTC" | quote -}}
{{- else -}}
    "UTC"
{{- end -}}
{{- end -}}

{{/*
Return the fsgroup set via global parameter if it's set, otherwise 10000
*/}}
{{- define "eric-data-distributed-coordinator-ed.fsGroup.coordinated" -}}
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
 Security TLS - enabled check
*/}}

{{- define "eric-data-distributed-coordinator-ed.tls.enabled" -}}
{{- $tls := false -}}
{{- if .Values.global -}}
    {{- if .Values.global.security -}}
        {{- if .Values.global.security.tls -}}
            {{- if hasKey .Values.global.security.tls "enabled" -}}
                {{- $tls = .Values.global.security.tls.enabled -}}
            {{- end -}}
        {{- end -}}
    {{- end -}}
{{- end -}}
{{- if .Values.security.dced.certificates -}}
{{- $dcedValue := (.Values.security.dced) }}
  {{- $tls = $dcedValue.certificates.enabled -}}
{{- end -}}
{{- $tls -}}
{{- end -}}

{{/*
Client connection scheme
*/}}
{{- define "eric-data-distributed-coordinator-ed.clientConnectionScheme" -}}
{{- if eq ( include "eric-data-distributed-coordinator-ed.tls.enabled" . ) "true" }}
      {{- printf "https" -}}
    {{- else -}}
      {{- printf "http" -}}
  {{- end -}}
{{- end -}}

{{/*

{{/*
 Ports - dced -client
*/}}
{{- define "eric-data-distributed-coordinator-ed.ports.client" -}}
{{- $clientPort := 2379 -}}
{{- print $clientPort -}}
{{- end -}}

Create client url
*/}}
{{- define "eric-data-distributed-coordinator-ed.clientUrl" -}}
   {{ $scheme := include "eric-data-distributed-coordinator-ed.clientConnectionScheme" . }}
   {{- printf "%s://0.0.0.0:%d" $scheme (int64 (include "eric-data-distributed-coordinator-ed.ports.client" . )) -}}
{{- end -}}

{{/*
Advertised client url
*/}}
{{- define "eric-data-distributed-coordinator-ed.advertiseClientUrl" -}}
    {{- $scheme := include "eric-data-distributed-coordinator-ed.clientConnectionScheme" . -}}
    {{- $chartName := include "eric-data-distributed-coordinator-ed.name" . -}}
    {{- printf "%s://$(ETCD_NAME).%s.%s:%d" $scheme $chartName .Release.Namespace (int64 (include "eric-data-distributed-coordinator-ed.ports.client" . )) -}}
{{- end -}}


{{/*
Advertised peer url
*/}}
{{- define "eric-data-distributed-coordinator-ed.initialAdvertisePeerUrl" -}}
	{{ $chartName := include "eric-data-distributed-coordinator-ed.name" . }}
	{{- printf "https://$(ETCD_NAME).%s-peer.%s.svc.%s:%d" $chartName .Release.Namespace .Values.clusterDomain (int64 (include "eric-data-distributed-coordinator-ed.ports.peer" . )) -}}
{{- end -}}


{{/*
client service
*/}}
{{- define "eric-data-distributed-coordinator-ed.clientService" -}}
	{{ $chartName := include "eric-data-distributed-coordinator-ed.name" . }}
	{{- printf "%s.%s:%d" $chartName .Release.Namespace (int64 (include "eric-data-distributed-coordinator-ed.ports.client" . )) -}}
{{- end -}}

{{/*
ETCD endpoint for the agent.
*/}}
{{- define "eric-data-distributed-coordinator-ed.agent.endpoint" -}}
    {{ $chartName := include "eric-data-distributed-coordinator-ed.name" . }}
    {{- printf "%s:%d" $chartName (int64 (include "eric-data-distributed-coordinator-ed.ports.client" . )) -}}
{{- end -}}

{{/*
Parameters that cannot be specified in the settings
*/}}
{{- define "eric-data-distributed-coordinator-ed.forbiddenParameters" -}}
  {{ list "ETCD_INITIAL_CLUSTER_TOKEN" "ETCD_NAME"  }}
{{- end -}}

{{/*
Etcd mountpath
*/}}
{{- define "eric-data-distributed-coordinator-ed.mountPath" -}}
      {{- printf "/data" -}}
{{- end -}}

{{/*
Name of the bootstrap CA certificates
*/}}
{{- define "eric-data-distributed-coordinator-ed.ca.bootstrap.name" -}}
  {{ printf "eric-sec-sip-tls-bootstrap-ca-cert" }}
{{- end -}}

{{/*
Name of the sip-tls CA certificates
*/}}
{{- define "eric-data-distributed-coordinator-ed.ca.sipTls.name" -}}
  {{ printf "eric-sec-sip-tls-trusted-root-cert" }}
{{- end -}}

{{/*
Path to the TLS trusted CA cert file.
*/}}
{{- define "eric-data-distributed-coordinator-ed.trustedCA" -}}
  {{ printf "/data/combinedca/cacertbundle.pem" }}
{{- end -}}

{{/*
Peer TLS Paths.
*/}}
{{- define "eric-data-distributed-coordinator-ed.peerPath" -}}
  {{ printf "/run/sec/certs/peer" }}
{{- end -}}

{{/*
Path to the peer TLS cert file.
*/}}
{{- define "eric-data-distributed-coordinator-ed.peerClientCert" -}}
  {{ printf "%s/srvcert.pem" (include "eric-data-distributed-coordinator-ed.peerPath" . ) }}
{{- end -}}

{{/*
Path to the peer TLS key file.
*/}}
{{- define "eric-data-distributed-coordinator-ed.peerClientKeyFile" -}}
  {{ printf "%s/srvprivkey.pem" (include "eric-data-distributed-coordinator-ed.peerPath" . ) }}
{{- end -}}

{{/*
etcdctl parameters
*/}}
{{- define "eric-data-distributed-coordinator-ed.etcdctlParameters" -}}
- name: ETCDCTL_API
  value: "3"
- name: ETCDCTL_ENDPOINTS
  value: {{ template "eric-data-distributed-coordinator-ed.clientService" . }}
{{- if eq (include "eric-data-distributed-coordinator-ed.tls.enabled" .) "true" }}
- name: ETCDCTL_CACERT
  value: {{ template "eric-data-distributed-coordinator-ed.trustedCA" . }}
- name: ETCDCTL_CERT
  value: {{ template "eric-data-distributed-coordinator-ed.certs.clientcert" . }}
- name: ETCDCTL_KEY
  value: {{ template "eric-data-distributed-coordinator-ed.certs.clientkey" . }}
{{- end -}}
{{- end -}}
{{- define "eric-data-distributed-coordinator-ed.serverCert.path" -}}
{{ print "/run/sec/certs/server/" }}
{{- end}}

{{- define "eric-data-distributed-coordinator-ed.clientCa.path" -}}
{{ print "/run/sec/cas/clientca/" }}
{{- end}}

{{- define "eric-data-distributed-coordinator-ed.clientCert.path" -}}
{{ print "/run/sec/certs/client/" }}
{{- end}}

{{- define "eric-data-distributed-coordinator-ed.siptlsCa.path" -}}
{{ print "/run/sec/cas/siptlsca/" }}
{{- end}}

{{- define "eric-data-distributed-coordinator-ed.pmca.path" -}}
{{ print "/run/sec/cas/pmca/" }}
{{- end}}

{{- define "eric-data-distributed-coordinator-ed.bootstrapCa.path" -}}
{{ print "/run/sec/cas/bootstrap/" }}
{{- end}}
{{/*
secrets mount paths
*/}}
{{- define "eric-data-distributed-coordinator-ed.secretsMountPath" -}}
{{- if eq ( include "eric-data-distributed-coordinator-ed.tls.enabled" . ) "true" }}
- name: server-cert
  mountPath: {{ include "eric-data-distributed-coordinator-ed.serverCert.path" . }}
- name: peer-client-cert
  mountPath: {{ include "eric-data-distributed-coordinator-ed.peerPath" . }}
- name: bootstrap-ca
  mountPath: {{ include "eric-data-distributed-coordinator-ed.bootstrapCa.path" . }}
- name: client-ca
  mountPath: {{ include "eric-data-distributed-coordinator-ed.clientCa.path" . }}
- name: etcdctl-client-cert
  mountPath: {{ include "eric-data-distributed-coordinator-ed.clientCert.path" . }}
{{- if and ( eq (include "eric-data-distributed-coordinator-ed.brAgent.tls" . ) "true" ) (.Values.brAgent.enabled) }}
- name: etcd-bro-client-cert
  mountPath: {{ .Values.service.endpoints.dced.certificates.client.bro }}
{{- end }}
- name: siptls-ca
  mountPath: {{ include "eric-data-distributed-coordinator-ed.siptlsCa.path" . }}
- name: pmca
  mountPath: {{ include "eric-data-distributed-coordinator-ed.pmca.path" . }}
{{- end }}
{{- end -}}

{{/*
secrets volumes
*/}}

{{- define "eric-data-distributed-coordinator-ed.secretsVolumes" -}}
{{- if eq ( include "eric-data-distributed-coordinator-ed.tls.enabled" . ) "true" }}
- name: siptls-ca
  secret:
    optional: true
    secretName: {{ template "eric-data-distributed-coordinator-ed.ca.sipTls.name" . }}
- name: bootstrap-ca
  secret:
    optional: true
    secretName: {{ template "eric-data-distributed-coordinator-ed.ca.bootstrap.name" . }}
- name: client-ca
  secret:
    optional: true
    secretName: {{ template "eric-data-distributed-coordinator-ed.name" . }}-ca
- name: server-cert
  secret:
    secretName: {{ template "eric-data-distributed-coordinator-ed.name" . }}-cert
- name: peer-client-cert
  secret:
    optional: true
    secretName: {{ template "eric-data-distributed-coordinator-ed.name" . }}-peer-cert
- name: etcdctl-client-cert
  secret:
    optional: true
    secretName: {{ template "eric-data-distributed-coordinator-ed.name" . }}-etcdctl-client-cert
- name: pmca
  secret:
    optional: true
    secretName: {{ template "eric-data-distributed-coordinator-ed.pmCaSecretName" . }}
{{- if and ( eq (include "eric-data-distributed-coordinator-ed.brAgent.tls" . ) "true" ) (.Values.brAgent.enabled) }}
- name: etcd-bro-client-cert
  secret:
    optional: true
    secretName: {{ template "eric-data-distributed-coordinator-ed.name" . }}-etcd-bro-client-cert
{{- end }}
{{- end }}
{{- end -}}


{{/*
Siptls ca cert bundle path.
*/}}
{{- define "eric-data-distributed-coordinator-ed.siptlsca.certbundle" -}}
{{- print   "/run/sec/cas/siptlsca/cacertbundle.pem" -}}
{{- end -}}

{{/*
client cert path.
*/}}
{{- define "eric-data-distributed-coordinator-ed.certs.clientcert" -}}
{{ print "/run/sec/certs/client/clicert.pem" }}
{{- end -}}

{{/*
client private key path
*/}}
{{- define "eric-data-distributed-coordinator-ed.certs.clientkey" -}}
{{ print "/run/sec/certs/client/cliprivkey.pem" }}
{{- end -}}

{{/*
Server cert path.
*/}}
{{- define "eric-data-distributed-coordinator-ed.certs.servercert" -}}
{{ print "/run/sec/certs/server/srvcert.pem" }}
{{- end -}}

{{/*
Server private key path
*/}}
{{- define "eric-data-distributed-coordinator-ed.certs.serverkey" -}}
{{ print "/run/sec/certs/server/srvprivkey.pem" }}
{{- end -}}

{{/*
Validate parameters helper
*/}}
{{- define "eric-data-distributed-coordinator-ed.validateParametersHelper" -}}
{{ $forbiddenParameters := list "ETCD_INITIAL_CLUSTER_TOKEN" "ETCD_NAME" "ETCDCTL_API" "ETCD_DATA_DIR" "ETCD_LISTEN_PEER_URLS" "ETCD_LISTEN_CLIENT_URLS" "ETCD_ADVERTISE_CLIENT_URLS" "ETCD_INITIAL_ADVERTISE_PEER_URLS" "ETCD_INITIAL_CLUSTER_STATE" "ETCD_INITIAL_CLUSTER" "ETCD_PEER_AUTO_TLS" "ETCD_CLIENT_CERT_AUTH" "ETCD_CERT_FILE" "ETCD_TRUSTED_CA_FILE" "ETCD_KEY_FILE" }}
{{- $dcedValue := (.Values.env.dced) }}
  {{- range $configName, $configValue := $dcedValue -}}
    {{- if has $configName $forbiddenParameters -}}
      {{- printf "%s " $configName -}}
    {{- end -}}
  {{- end -}}
{{- end -}}

{{/*
Validate parameters
*/}}
{{- define "eric-data-distributed-coordinator-ed.validateParameters" -}}
  {{- $definedInvalidParameters := include "eric-data-distributed-coordinator-ed.validateParametersHelper" . -}}
  {{- $len := len $definedInvalidParameters -}}
  {{- if eq $len 0 -}}
    {{- print " valid" -}}
  {{- end -}}
{{- end -}}

{{/*
Create annotation for the product information (DR-D1121-064)
*/}}
{{- define "eric-data-distributed-coordinator-ed.productinfo" }}
ericsson.com/product-name: {{ (fromYaml (.Files.Get "eric-product-info.yaml")).productName | quote }}
ericsson.com/product-number: {{ (fromYaml (.Files.Get "eric-product-info.yaml")).productNumber | quote }}
ericsson.com/product-revision: {{regexReplaceAll "(.*)[+|-].*" .Chart.Version "${1}" | quote }}
{{- end }}

{{/*
Create a user defined annotation (DR-D1121-065)
*/}}
{{ define "eric-data-distributed-coordinator-ed.config-annotations" }}
{{- if .Values.annotations -}}
{{- range $name, $config := .Values.annotations }}
{{ $name }}: {{ tpl $config $ | quote }}
{{- end }}
{{- end }}
{{- end}}

{{/*
Labels
*/}}
{{- define "eric-data-distributed-coordinator-ed.labels" }}
{{- include "eric-data-distributed-coordinator-ed.selectorLabels" . }}
  app.kubernetes.io/version: {{ include "eric-data-distributed-coordinator-ed.chart" . | quote }}
  app.kubernetes.io/managed-by: {{ .Release.Service | quote  }}
  app: {{ include "eric-data-distributed-coordinator-ed.name" . | quote }}
  {{- if .Values.labels }}
{{ toYaml .Values.labels | indent 2 }}
  {{- end }}
{{- end }}

{{/*
Selector labels.
*/}}
{{- define "eric-data-distributed-coordinator-ed.selectorLabels" }}
  app.kubernetes.io/name: {{ include "eric-data-distributed-coordinator-ed.name" . | quote }}
  app.kubernetes.io/instance: {{ .Release.Name | quote }}
{{- end }}

{{/*
logshipper labels.
*/}}
{{- define "eric-data-distributed-coordinator-ed.logshipper-labels" }}
{{- include "eric-data-distributed-coordinator-ed.labels" . }}
{{- end }}

{{/*
Allow for override of agent name
*/}}
{{- define "eric-data-distributed-coordinator-ed.agentName" -}}
{{ template "eric-data-distributed-coordinator-ed.name" . }}-agent
{{- end -}}

{{/*
Agent Labels.
*/}}
{{- define "eric-data-distributed-coordinator-ed.agent.labels" }}
{{- include "eric-data-distributed-coordinator-ed.agent.selectorLabels" . }}
app.kubernetes.io/version: {{ include "eric-data-distributed-coordinator-ed.chart" . | quote }}
app.kubernetes.io/managed-by: {{ .Release.Service | quote }}
{{- if .Values.labels }}
{{ toYaml .Values.labels}}
{{- end }}
{{- end }}

{{/*
Accommodate global params for broGrpcServicePort
*/}}

{{- define "eric-data-distributed-coordinator-ed.agent.broGrpcServicePort" -}}
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
Accommodate global params for broServiceName
*/}}
{{- define "eric-data-distributed-coordinator-ed.agent.broServiceName" -}}
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
Accommodate global params for brLabelKey
*/}}
{{/*
Get bro service brLabelKey
*/}}
{{- define "eric-data-distributed-coordinator-ed.agent.brLabelKey" -}}
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
Selector labels for Agent.
*/}}
{{- define "eric-data-distributed-coordinator-ed.agent.selectorLabels" }}
app.kubernetes.io/name: {{ include "eric-data-distributed-coordinator-ed.agentName" . | quote }}
app.kubernetes.io/instance: {{ .Release.Name | quote }}
{{- if .Values.brAgent.brLabelValue }}
{{ include "eric-data-distributed-coordinator-ed.agent.brLabelKey" . }}: {{ .Values.brAgent.brLabelValue }}
{{ else }}
{{ include "eric-data-distributed-coordinator-ed.agent.brLabelKey" . }}: dc-etcd
{{- end }}
{{- end }}



{{/*
secrets mount paths
*/}}
{{- define "eric-data-distributed-coordinator-ed.agent.secretsMountPath" -}}
{{- if or ( eq ( include "eric-data-distributed-coordinator-ed.brAgent.tls" . ) "true" ) ( eq ( include "eric-data-distributed-coordinator-ed.tls.enabled" . ) "true" ) }}
- name: siptls-ca
  mountPath: {{ include "eric-data-distributed-coordinator-ed.siptlsCa.path" . }}
{{- end -}}
{{- if eq ( include "eric-data-distributed-coordinator-ed.brAgent.tls" . ) "true" }}
- name: etcd-bro-client-cert
  mountPath: {{ .Values.service.endpoints.dced.certificates.client.bro }}
{{- end -}}
{{- if eq ( include "eric-data-distributed-coordinator-ed.tls.enabled" . ) "true" }}
- name: etcdctl-client-cert
  mountPath: {{ include "eric-data-distributed-coordinator-ed.clientCert.path" . }}
- name: client-ca
  mountPath: {{ include "eric-data-distributed-coordinator-ed.clientCa.path" . }}
{{- end }}
{{- end -}}


{{/*
secrets volumes
*/}}
{{- define "eric-data-distributed-coordinator-ed.agent.secretsVolumes" -}}
{{- if or ( eq ( include "eric-data-distributed-coordinator-ed.brAgent.tls" . ) "true" ) ( eq ( include "eric-data-distributed-coordinator-ed.tls.enabled" . ) "true" ) }}
- name: siptls-ca
  secret:
    optional: false
    secretName: "eric-sec-sip-tls-trusted-root-cert"
{{- end -}}
{{- if eq ( include "eric-data-distributed-coordinator-ed.brAgent.tls" . ) "true" }}
- name: etcd-bro-client-cert
  secret:
    optional: false
    secretName: {{ template "eric-data-distributed-coordinator-ed.name" . }}-etcd-bro-client-cert
{{- end -}}
{{- if eq ( include "eric-data-distributed-coordinator-ed.tls.enabled" . ) "true" }}
- name: etcdctl-client-cert
  secret:
    optional: false
    secretName: {{ template "eric-data-distributed-coordinator-ed.name" . }}-etcdctl-client-cert
- name: client-ca
  secret:
    optional: false
    secretName: {{ template "eric-data-distributed-coordinator-ed.name" . }}-ca
{{- end -}}
{{- end -}}

{{/*
Semi-colon separated list of backup types
*/}}
{{- define "eric-data-distributed-coordinator-ed.agent.backupTypes" }}
{{- range $i, $e := .Values.brAgent.backupTypeList -}}
{{- if eq $i 0 -}}{{- printf " " -}}{{- else -}}{{- printf ";" -}}{{- end -}}{{- . -}}
{{- end -}}
{{- end -}}


{{/*
Additional SAN in cert to support hostname verification
*/}}
{{- define "eric-data-distributed-coordinator-ed.dns" -}}
{{- $dnslist := list (include "eric-data-distributed-coordinator-ed.dnsname-peer" .) (include "eric-data-distributed-coordinator-ed.dnsname" .) (include "eric-data-distributed-coordinator-ed.pmdnsname" .) -}}
{{- $dnslist | toJson -}}
{{- end}}


{{/*
Wildcard name to match all ETCD instances.
*/}}
{{- define "eric-data-distributed-coordinator-ed.dnsname-peer" -}}
*.{{- include "eric-data-distributed-coordinator-ed.name" . }}-peer.{{ .Release.Namespace }}.svc.{{ .Values.clusterDomain }}
{{- end}}

{{/*
Wildcard name to match non-peer instances
*/}}
{{- define "eric-data-distributed-coordinator-ed.dnsname" -}}
*.{{- include "eric-data-distributed-coordinator-ed.name" . }}.{{ .Release.Namespace }}.svc.{{ .Values.clusterDomain }}
{{- end}}

{{/*
Wildcard name to match non-peer instances
*/}}
{{- define "eric-data-distributed-coordinator-ed.pmdnsname" -}}
{{ print "certified-scrape-target" }}
{{- end}}

{{/*
AccessMode - For PVC set ReadWriteOnce
*/}}
{{- define "eric-data-distributed-coordinator-ed.persistentVolumeClaim.accessMode" -}}
{{ print "ReadWriteOnce" }}
{{- end}}

{{/*
Create a merged set of nodeSelectors from global and service level -dced.
*/}}
{{- define "eric-data-distributed-coordinator-ed.dcedNodeSelector" -}}
{{- $globalValue := (dict) -}}
{{- if .Values.global -}}
    {{- if .Values.global.nodeSelector -}}
         {{- $globalValue = .Values.global.nodeSelector -}}
    {{- end -}}
{{- end -}}
{{- if .Values.nodeSelector.dced -}}
  {{- range $key, $localValue := .Values.nodeSelector.dced -}}
    {{- if hasKey $globalValue $key -}}
         {{- $Value := index $globalValue $key -}}
         {{- if ne $Value $localValue -}}
           {{- printf "nodeSelector \"%s\" is specified in both global (%s: %s) and service level (%s: %s) with differing values which is not allowed." $key $key $globalValue $key $localValue | fail -}}
         {{- end -}}
     {{- end -}}
    {{- end -}}
    nodeSelector: {{- toYaml (merge $globalValue .Values.nodeSelector.dced) | trim | nindent 2 -}}
{{- else -}}
  {{- if not ( empty $globalValue ) -}}
    nodeSelector: {{- toYaml $globalValue | trim | nindent 2 -}}
  {{- end -}}
{{- end -}}
{{- end -}}

{{/*
Create a merged set of nodeSelectors from global and service level - brAgent.
*/}}
{{- define "eric-data-distributed-coordinator-ed.brAgentNodeSelector" -}}
{{- $globalValue := (dict) -}}
{{- if .Values.global -}}
    {{- if .Values.global.nodeSelector -}}
         {{- $globalValue = .Values.global.nodeSelector -}}
    {{- end -}}
{{- end -}}
{{- if .Values.nodeSelector.brAgent -}}
  {{- range $key, $localValue := .Values.nodeSelector.brAgent -}}
    {{- if hasKey $globalValue $key -}}
         {{- $Value := index $globalValue $key -}}
         {{- if ne $Value $localValue -}}
           {{- printf "nodeSelector \"%s\" is specified in both global (%s: %s) and service level (%s: %s) with differing values which is not allowed." $key $key $globalValue $key $localValue | fail -}}
         {{- end -}}
     {{- end -}}
    {{- end -}}
    nodeSelector: {{- toYaml (merge $globalValue .Values.nodeSelector.brAgent) | trim | nindent 2 -}}
{{- else -}}
  {{- if not ( empty $globalValue ) -}}
    nodeSelector: {{- toYaml $globalValue | trim | nindent 2 -}}
  {{- end -}}
{{- end -}}
{{- end -}}

{{/*
Create a map from global values with defaults if not in the values file. (DR-D1123-124)
*/}}
{{ define "eric-data-distributed-coordinator-ed.globalMap" }}
  {{- $globalDefaults := dict "security" (dict "policyBinding" (dict "create" false)) -}}
  {{- $globalDefaults := merge $globalDefaults (dict "security" (dict "policyReferenceMap" (dict "default-restricted-security-policy" "default-restricted-security-policy"))) -}}
  {{ if .Values.global }}
    {{- mergeOverwrite $globalDefaults .Values.global | toJson -}}
  {{ else }}
    {{- $globalDefaults | toJson -}}
  {{ end }}
{{ end }}

{{/*
 CA Secret provided by PM Server
*/}}
{{- define "eric-data-distributed-coordinator-ed.pmCaSecretName" -}}
    {{- if .Values.service.endpoints.pm.tls.caSecretName -}}
        {{- .Values.service.endpoints.pm.tls.caSecretName -}}
    {{- else -}}
        {{- .Values.pmServer.pmServiceName -}}-ca
    {{- end -}}
{{- end -}}

{{/*
dced livenessProbeConfig
*/}}
{{- define "eric-data-distributed-coordinator-ed.livenessProbeConfig" }}
{{- $image := get .Values.probes .imageName -}}
{{- $initialDelay := $image.livenessProbe.initialDelaySeconds -}}
{{- $timeoutSec := $image.livenessProbe.timeoutSeconds -}}
{{- $periodSec := $image.livenessProbe.periodSeconds -}}
{{- $failThreshold := $image.livenessProbe.failureThreshold }}
{{ printf "initialDelaySeconds: %v"  $initialDelay }}
{{ printf "timeoutSeconds: %v"  $timeoutSec }}
{{ printf "periodSeconds: %v"  $periodSec }}
{{ printf "failureThreshold: %v"  $failThreshold }}
{{- end }}

{{/*
dced readinessProbeConfig
*/}}
{{- define "eric-data-distributed-coordinator-ed.readinessProbeConfig" }}
{{- $image := get .Values.probes .imageName -}}
{{- $initialDelay := $image.readinessProbe.initialDelaySeconds -}}
{{- $timeoutSec := $image.readinessProbe.timeoutSeconds -}}
{{- $periodSec := $image.readinessProbe.periodSeconds -}}
{{- $failThreshold := $image.readinessProbe.failureThreshold -}}
{{- $successfulThreshold := $image.readinessProbe.successThreshold }}
{{ printf "initialDelaySeconds: %v"  $initialDelay }}
{{ printf "timeoutSeconds: %v"  $timeoutSec }}
{{ printf "periodSeconds: %v"  $periodSec }}
{{ printf "failureThreshold: %v"  $failThreshold }}
{{ printf "successThreshold: %v"  $successfulThreshold }}
{{- end }}

{{/*
 Replicas
*/}}

{{- define "eric-data-distributed-coordinator-ed.pods.replicas" -}}
{{- print .Values.pods.dced.replicas -}}
{{- end -}}

{{/*
 Probes - Defination StatefulSet
*/}}
{{- define "eric-data-distributed-coordinator-ed.probes.statefulSet.dced" -}}
{{- $dcedValue := (.Values.probes.dced) }}
{{- $MinorVersion := int (.Capabilities.KubeVersion.Minor) -}}
{{/*
StartupProbe feature is stable from k8 v.1.20.x onwards, in case deployed in a cluster for that version and above,
readiness Probe's & liveness Probe's InitialDelaySeconds: 0
with a failureThreshold * periodSeconds long enough to cover the worse case startup time. ( Default 6x20 60 2 minutes )
*/}}

{{- $livenessInitialDelaySeconds := .Values.probes.dced.livenessProbe.initialDelaySeconds -}}
{{- $readinessInitialDelaySeconds := .Values.probes.dced.readinessProbe.initialDelaySeconds -}}

{{- if ge $MinorVersion 20 -}}
{{- $livenessInitialDelaySeconds := 0 -}}
{{- $readinessInitialDelaySeconds := 0 -}}
{{ end }}
          livenessProbe:
            exec:
              command: [/usr/local/bin/scripts/liveness.sh]
            initialDelaySeconds: {{ $livenessInitialDelaySeconds }}
            timeoutSeconds: {{ .Values.probes.dced.livenessProbe.timeoutSeconds }}
            failureThreshold: {{ .Values.probes.dced.livenessProbe.failureThreshold }}
            periodSeconds: {{ .Values.probes.dced.livenessProbe.periodSeconds }}
{{ if ge $MinorVersion 20 }}
          startupProbe:
            exec:
              command: [/usr/local/bin/scripts/liveness.sh]
            initialDelaySeconds: {{ .Values.probes.dced.startupProbe.initialDelaySeconds }}
            timeoutSeconds: {{ .Values.probes.dced.startupProbe.timeoutSeconds }}
            periodSeconds: {{ .Values.probes.dced.startupProbe.periodSeconds }}
            failureThreshold: {{ .Values.probes.dced.startupProbe.failureThreshold }}
{{ end }}
          readinessProbe:
            exec:
              command:
              - "pgrep"
              - "-fl"
              - "etcd"
            initialDelaySeconds: {{ $readinessInitialDelaySeconds }}
            timeoutSeconds: {{ .Values.probes.dced.readinessProbe.timeoutSeconds }}
            failureThreshold: {{ .Values.probes.dced.readinessProbe.failureThreshold }}
            periodSeconds: {{ .Values.probes.dced.readinessProbe.periodSeconds }}
            successThreshold: {{ .Values.probes.dced.readinessProbe.successThreshold }}
{{- end -}}

{{/*
 livenessProbe EntrypointChecksNumber
*/}}
{{- define "eric-data-distributed-coordinator-ed.livenessProbe.entrypointChecksNumber" -}}
{{- print .Values.probes.dced.livenessProbe.EntrypointChecksNumber -}}
{{- end -}}

{{/*
 livenessProbe EntrypointRestartEtcd
*/}}
{{- define "eric-data-distributed-coordinator-ed.livenessProbe.entrypointRestartEtcd" -}}
{{- print .Values.probes.dced.livenessProbe.EntrypointRestartEtcd -}}
{{- end -}}

{{/*
 livenessProbe entrypointPipeTimeout
*/}}
{{- define "eric-data-distributed-coordinator-ed.livenessProbe.entrypointPipeTimeout" -}}
{{- print .Values.probes.dced.livenessProbe.EntrypointPipeTimeout -}}
{{- end -}}

{{/*
 livenessProbe EntrypointDcedProcessInterval
*/}}
{{- define "eric-data-distributed-coordinator-ed.livenessProbe.entrypointDcedProcessInterval" -}}
{{- print .Values.probes.dced.livenessProbe.EntrypointEctdProcessInterval -}}
{{- end -}}

{{/*
Env parameters
*/}}
{{- define "eric-data-distributed-coordinator-ed.env.dced" -}}
{{- $dcedValue := (.Values.env.dced) }}
{{ range $configName, $configValue := $dcedValue }}
            - name: {{ $configName }}
              value: {{ $configValue | quote }}
{{- end }}
{{- end -}}

{{/*
 Security TLS - client enabled check
*/}}

{{- define "eric-data-distributed-coordinator-ed.tls.clientEnabled" -}}
{{- print .Values.service.endpoints.dced.certificates.client.clientCertAuth -}}
{{- end -}}

{{/*
 Security TLS - Peer autoTls enabled check
*/}}
{{- define "eric-data-distributed-coordinator-ed.tls.peerAutoTls.enabled" -}}
{{- print .Values.service.endpoints.dced.certificates.peer.autoTls -}}
{{- end -}}

{{/*
 Security TLS - Peer autoTls enabled check
*/}}
{{- define "eric-data-distributed-coordinator-ed.tls.peerCertAuth.enabled" -}}
{{- print .Values.service.endpoints.dced.certificates.peer.peerCertAuth -}}
{{- end -}}

{{/*
 Security TLS -root acls
*/}}

{{- define "eric-data-distributed-coordinator-ed.tls.acls" -}}
{{- $dcedValue := (.Values.service.endpoints.dced) }}
    secretKeyRef:
      name: {{ $dcedValue.acls.adminSecret | quote }}
      key: {{ $dcedValue.acls.rootPassword | quote }}
{{- end -}}