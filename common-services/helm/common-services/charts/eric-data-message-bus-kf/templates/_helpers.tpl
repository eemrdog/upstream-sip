{{/*
Create a map from global values with defaults if not in the values file.
*/}}
{{ define "eric-data-message-bus-kf.globalMap" }}
  {{- $globalDefaults := dict "security" (dict "policyBinding" (dict "create" false)) -}}
  {{- $globalDefaults := merge $globalDefaults (dict "security" (dict "policyReferenceMap" (dict "default-restricted-security-policy" "default-restricted-security-policy"))) -}}
  {{ if .Values.global }}
    {{- mergeOverwrite $globalDefaults .Values.global | toJson -}}
  {{ else }}
    {{- $globalDefaults | toJson -}}
  {{ end }}
{{ end }}

{{/*
Argument: imageName
Returns image path of provided imageName.
*/}}
{{- define "eric-data-message-bus-kf.imagePath" }}
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
    {{- if hasKey .Values.images .imageName -}}
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
To be deprecated - dr-hc-120,011,115 support for .Values.imageCredentials.registry. will be removed
*/}}
{{- define "eric-data-message-bus-kf.pullSecret.global" -}}
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
{{- define "eric-data-message-bus-kf.pullSecret" -}}
{{- $pullSecret := (include "eric-data-message-bus-kf.pullSecret.global" . ) -}}
{{- if .Values.imageCredentials -}}
  {{- if .Values.imageCredentials.pullSecret -}}
    {{- $pullSecret = .Values.imageCredentials.pullSecret -}}
  {{- end -}}
{{- end -}}
{{- print $pullSecret -}}
{{- end -}}

{{- define "eric-data-message-bus-kf.imagePullPolicy.global" -}}
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

{{- define "eric-data-message-bus-kf.internalIPFamily.global" -}}
{{- $ipFamilies := "" -}}
{{- if .Values.global -}}
  {{- if .Values.global.internalIPFamily -}}
      {{- $ipFamilies = .Values.global.internalIPFamily -}}
  {{- end }}
{{- end }}
{{- print $ipFamilies -}}
{{- end -}}

{{/*
Pull policy for the messagebuskf container
*/}}
{{- define "eric-data-message-bus-kf.mbkf.imagePullPolicy" -}}
{{- $imagePullPolicy := ( include "eric-data-message-bus-kf.imagePullPolicy.global" . ) -}}
  {{- if .Values.imageCredentials.messagebuskf.registry.imagePullPolicy -}}
    {{- $imagePullPolicy = .Values.imageCredentials.messagebuskf.registry.imagePullPolicy -}}
  {{- end -}}
{{- print $imagePullPolicy -}}
{{- end -}}

{{/*
Define timezone
*/}}
{{- define "eric-data-message-bus-kf.timezone" -}}
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
{{- define "eric-data-message-bus-kf.tls" -}}
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
Define SASL, note: returns boolean as string
*/}}
{{- define "eric-data-message-bus-kf.sasl" -}}
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
Define Network Policy, note: returns boolean as string
*/}}
{{- define "eric-data-message-bus-kf.networkPolicy" -}}
{{- $networkPolicy := false -}}
{{- if .Values.global -}}
    {{- if and .Values.global.networkPolicy .Values.networkPolicy -}}
      {{- if and .Values.global.networkPolicy.enabled .Values.networkPolicy.enabled -}}
        {{- $networkPolicy = .Values.global.networkPolicy.enabled -}}
      {{- end -}}
    {{- end -}}
{{- end -}}
{{- $networkPolicy -}}
{{- end -}}

{{/*
Return the fsgroup set via global parameter if it's set, otherwise 10000
*/}}
{{- define "eric-data-message-bus-kf.fsGroup.coordinated" -}}
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
 CA for client certs to connect to dczk
*/}}
{{- define "eric-data-message-bus-kf.dataCoordinator.clientCA" -}}
{{- if .Values.service.endpoints.dataCoordinator.tls.certificateAuthority -}}
{{- .Values.service.endpoints.dataCoordinator.tls.certificateAuthority -}}
{{- else -}}
{{- printf "%s%s" .Values.dataCoordinator.clientServiceName "-client-ca" -}}
{{- end -}}
{{- end -}}


{{/*
Client port to dataCoordinator
*/}}
{{- define "eric-data-message-bus-kf.dataCoordinator.clientPort" -}}
{{- if and ( eq (include "eric-data-message-bus-kf.tls" .) "true" ) ( eq .Values.service.endpoints.dataCoordinator.tls.enforced "required" ) ( eq .Values.security.tls.messagebuskf.provider "sip-tls" ) }}
{{- .Values.dataCoordinator.tlsClientPort -}}
{{- else -}}
{{- .Values.dataCoordinator.clientPort -}}
{{- end -}}
{{- end -}}


{{/*
Connection to dataCoordinator
*/}}
{{- define "eric-data-message-bus-kf.dataCoordinator.connectHost" -}}
{{- printf "%s:%s/" .Values.dataCoordinator.clientServiceName ( include "eric-data-message-bus-kf.dataCoordinator.clientPort" . ) -}}
{{- end -}}




{{/*
Connection to dataCoordinator with chroot
*/}}
{{- define "eric-data-message-bus-kf.dataCoordinator.connect" -}}
{{ template "eric-data-message-bus-kf.dataCoordinator.connectHost" . }}{{ template "eric-data-message-bus-kf.fullname" . }}
{{- end -}}


{{/*
Expand the name of the chart.
*/}}
{{- define "eric-data-message-bus-kf.fullname" -}}
{{- if .Values.fullnameOverride -}}
  {{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
  {{- $name := default .Chart.Name .Values.nameOverride -}}
  {{- printf "%s" $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}


{{/*
Expand the name of the chart.
*/}}
{{- define "eric-data-message-bus-kf-ext.fullname" -}}
{{- if .Values.fullnameOverride -}}
  {{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
  {{- $name := default .Chart.Name .Values.nameOverride -}}
  {{- printf "%s-ext" $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}


{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "eric-data-message-bus-kf.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Expand the name of the chart.
*/}}
{{- define "eric-data-message-bus-kf.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Common labels
*/}}
{{- define "eric-data-message-bus-kf.labels" }}
  {{- $selectorLabelsK8s := include "eric-data-message-bus-kf.selector-labels-k8s" . | fromYaml -}}
  {{- $k8sLabels := dict -}}
  {{- $_ := set $k8sLabels "app.kubernetes.io/version" (include "eric-data-message-bus-kf.chart" . | toString) -}}
  {{- $_ := set $k8sLabels "app.kubernetes.io/managed-by" (.Release.Service | toString) -}}
  {{- $globalLabels := (.Values.global).labels -}}
  {{- $serviceLabels := .Values.labels -}}
  {{- include "eric-data-message-bus-kf.mergeLabels" (dict "location" .Template.Name "sources" (list $k8sLabels $selectorLabelsK8s $globalLabels $serviceLabels)) | trim }}
{{- end }}

{{/*
Selector labels for Kubernetes
*/}}
{{- define "eric-data-message-bus-kf.selector-labels-k8s" }}
app.kubernetes.io/name: {{ include "eric-data-message-bus-kf.name" . | quote }}
app.kubernetes.io/instance: {{ .Release.Name | quote }}
{{- end }}

{{/*
Logshipper labels
*/}}
{{- define "eric-data-message-bus-kf.logshipper-labels" }}
{{- println "" -}}
{{- include "eric-data-message-bus-kf.labels" . -}}
{{- end }}

{{/*
Client CA Secret Name
*/}}
{{- define "eric-data-message-bus-kf.client.ca.secret" -}}
{{ template "eric-data-message-bus-kf.fullname" . }}-client-ca-secret
{{- end -}}

{{/*
Client client CA Secret Name
*/}}
{{- define "eric-data-message-bus-kf.client.client.ca.secret" -}}
{{ template "eric-data-message-bus-kf.fullname" . }}-client-client-ca-secret
{{- end -}}

{{/*
Server Cert Secret Name
*/}}
{{- define "eric-data-message-bus-kf.server.cert.secret" -}}
{{ template "eric-data-message-bus-kf.fullname" . }}-server-cert-secret
{{- end -}}

{{/*
DCZK client Cert Secret Name
*/}}
{{- define "eric-data-message-bus-kf.dczk.client.cert.secret" -}}
{{ template "eric-data-message-bus-kf.fullname" . }}-zk-client-cert-secret
{{- end -}}

{{/*
Product information. Create annotation for the product information (DR-D1121-064)
*/}}
{{- define "eric-data-message-bus-kf.productinfo" }}
ericsson.com/product-name: {{ (fromYaml (.Files.Get "eric-product-info.yaml")).productName | quote }}
ericsson.com/product-number: {{ (fromYaml (.Files.Get "eric-product-info.yaml")).productNumber | quote }}
ericsson.com/product-revision: {{regexReplaceAll "(.*)[+|-].*" .Chart.Version "${1}" | quote }}
{{- end}}

{{/*
Container level annotations
*/}}
{{- define "eric-data-message-bus-kf.container.annotation" }}
seccomp.security.alpha.kubernetes.io/pod: runtime/default
container.apparmor.security.beta.kubernetes.io/messagebuskf: runtime/default
{{ if .Values.jmx.enabled }}
container.apparmor.security.beta.kubernetes.io/jmxexporter: runtime/default
{{ end }}
{{ if has "stream" .Values.log.outputs }}
container.apparmor.security.beta.kubernetes.io/logshipper: runtime/default
{{ end }}
{{- end}}

{{/*
serviceAccount - will be deprecated from k8 1.22.0 onwards, supporting it for older versions
*/}}

{{- define "eric-data-message-bus-kf.serviceAccount" -}}
{{- $MinorVersion := int (.Capabilities.KubeVersion.Minor) -}}
{{- if lt $MinorVersion 22 -}}
  serviceAccount: ""
{{- end -}}
{{- end -}}

{{/*
Common annotations
*/}}
{{- define "eric-data-message-bus-kf.annotations" }}
  {{- $productInfoAnnotations := include "eric-data-message-bus-kf.productinfo" . | fromYaml -}}
  {{- $globalAnnotations := (.Values.global).annotations -}}
  {{- $serviceAnnotations := .Values.annotations -}}
  {{- include "eric-data-message-bus-kf.mergeAnnotations" (dict "location" .Template.Name "sources" (list $productInfoAnnotations $globalAnnotations $serviceAnnotations)) | trim }}
{{- end }}

{{/*
Logshipper annotations
*/}}
{{- define "eric-data-message-bus-kf.logshipper-annotations" }}
{{- println "" -}}
{{- include "eric-data-message-bus-kf.annotations" . -}}
{{- end }}

{{/*
volume information.
*/}}
{{- define "eric-data-message-bus-kf.volumes" }}
{{- if eq (include "eric-data-message-bus-kf.tls" .) "true" -}}
  {{- if eq .Values.security.tls.messagebuskf.provider "edaTls" -}}
- name: {{ .Values.security.tls.messagebuskf.edaTls.secretName | quote }}
  secret:
    secretName: {{ .Values.security.tls.messagebuskf.edaTls.secretName | quote }}
  {{- else if eq .Values.security.tls.messagebuskf.provider "sip-tls" -}}
- name: dczk-client-cert
  secret:
    secretName: {{ include "eric-data-message-bus-kf.dczk.client.cert.secret" . | quote }}
- name: server-cert
  secret:
    secretName: {{ include "eric-data-message-bus-kf.server.cert.secret" . | quote }}
- name: siptls-ca
  secret:
    secretName: "eric-sec-sip-tls-trusted-root-cert"
- name: client-ca
  secret:
    secretName: {{ include "eric-data-message-bus-kf.client.ca.secret" . | quote }}
- name: pmca
  secret:
    optional: true
    secretName: {{ template "eric-data-message-bus-kf.pmCaSecretName" . }}
- name: client-client-ca
  secret:
    secretName: {{ include "eric-data-message-bus-kf.client.client.ca.secret" . | quote }}
  {{- end -}}
{{- end -}}
{{- include "eric-data-message-bus-kf.volumes.temporaryVolume" . -}}

{{- end -}}


{{- define "eric-data-message-bus-kf.volumes.temporaryVolume" -}}
{{- if ( not .Values.persistence.persistentVolumeClaim.enabled ) }}
{{- if .Values.persistence.temporaryVolume.enabled }}
{{-  if eq .Values.persistence.temporaryVolume.medium "Memory" }}
- name: datadir
  emptyDir:
    medium: "Memory"
    sizeLimit: {{ .Values.persistence.temporaryVolume.sizeLimit }}
{{- else }}
- name: datadir
  emptyDir:
    sizeLimit: {{ .Values.persistence.temporaryVolume.sizeLimit }}
{{- end }}
{{- else }}
- name: datadir
  emptyDir: {}
{{- end }}
{{- end -}}
{{- end -}}

{{/*
Enable plaintext communication
*/}}
{{- define "eric-data-message-bus-kf.plaintext.enabled" -}}
{{- if and (not (eq (include "eric-data-message-bus-kf.tls" .) "true")) (not (eq (include "eric-data-message-bus-kf.sasl" .) "true")) -}}
true
{{- else if and (not (eq (include "eric-data-message-bus-kf.tls" .) "true")) (eq .Values.service.endpoints.messagebuskf.sasl.enforced "optional") -}}
true
{{- else if and (not (eq (include "eric-data-message-bus-kf.sasl" .) "true")) (eq .Values.service.endpoints.messagebuskf.tls.enforced "optional") -}}
true
{{- end -}}
{{- end -}}

{{/*
plaintext port
*/}}
{{- define "eric-data-message-bus-kf.plaintextPort" -}}
{{- if .Values.kafkaPort -}}
{{- .Values.kafkaPort }}
{{- else -}}
{{- .Values.security.plaintext.messagebuskf.port -}}
{{- end -}}
{{- end -}}

{{/*
sasl-plaintext port
*/}}
{{- define "eric-data-message-bus-kf.saslPlaintextPort" -}}
{{- .Values.security.saslplaintext.messagebuskf.port -}}
{{- end -}}

{{/*
Volume mount name used for Statefulset
*/}}
{{- define "eric-data-message-bus-kf.persistence.volumeMount.name" -}}
  {{- printf "%s" "datadir" -}}
{{- end -}}

{{/*
volume Mount information.
*/}}
{{- define "eric-data-message-bus-kf.secretsMountPath" }}
{{- if eq (include "eric-data-message-bus-kf.tls" .) "true" }}
  {{- if eq .Values.security.tls.messagebuskf.provider "edaTls" }}
  - name: {{ .Values.security.tls.messagebuskf.edaTls.secretName | quote }}
    mountPath: "/etc/kafka/secrets"
    readOnly: true
  {{- else if eq .Values.security.tls.messagebuskf.provider "sip-tls" }}
  {{- include "eric-data-message-bus-kf.init.secretsMountPath" . }}
  - name:  server-cert
    mountPath: {{ template "eric-data-message-bus-kf.servercert" . }}
  - name: client-ca
    mountPath: {{ template "eric-data-message-bus-kf.clientca" . }}
  - name: pmca
    mountPath: {{ template "eric-data-message-bus-kf.pmca" . }}
  - name: client-client-ca
    mountPath: {{ template "eric-data-message-bus-kf.client.clientca" . }}
  {{- end -}}
{{- end -}}
{{- end -}}

{{/*
mounts for the init container
*/}}
{{- define "eric-data-message-bus-kf.init.secretsMountPath" -}}
{{ if eq (include "eric-data-message-bus-kf.zkclient.tls" .) "true" }}
  - name:  dczk-client-cert
    mountPath: {{ template "eric-data-message-bus-kf.dczkclientcert" . }}
{{ end }}
  - name: siptls-ca
    mountPath: {{ template "eric-data-message-bus-kf.siptlsca" . }}
{{- end -}}


{{/*
DCZK client cert location
*/}}
{{- define "eric-data-message-bus-kf.dczkclientcert" -}}
"/run/kafka/secrets/dczkclientcert"
{{- end -}}

{{/*
SIP TLS server cert location
*/}}
{{- define "eric-data-message-bus-kf.servercert" -}}
"/run/kafka/secrets/servercert"
{{- end -}}

{{/*
SIP TLS certificate authority location
*/}}
{{- define "eric-data-message-bus-kf.siptlsca" -}}
"/run/kafka/secrets/siptlsca"
{{- end -}}

{{/*
SIP TLS certificate authority location
*/}}
{{- define "eric-data-message-bus-kf.pmca" -}}
"/run/kafka/secrets/pmca"
{{- end -}}

{{/*
Client CA certificate authority location
*/}}
{{- define "eric-data-message-bus-kf.clientca" -}}
"/run/kafka/secrets/clientca"
{{- end -}}

{{/*
Client CA certificate authority location
*/}}
{{- define "eric-data-message-bus-kf.client.clientca" -}}
"/run/kafka/secrets/client/clientca"
{{- end -}}


{{/*
SSL Client Authentication for Kafka
*/}}
{{- define "eric-data-message-bus-kf.clientAuth" -}}
{{- if eq .Values.service.endpoints.messagebuskf.tls.verifyClientCertificate "optional" -}}
"requested"
{{- else -}}
{{- .Values.service.endpoints.messagebuskf.tls.verifyClientCertificate | quote -}}
{{- end -}}
{{- end -}}

{{/*
DNS LIST.
*/}}
{{- define "eric-data-message-bus-kf.dns" -}}
{{- $dnslist := list (include "eric-data-message-bus-kf.dnsname" .) (include "eric-data-message-bus-kf.dnsname-namespace-only" .) (include "eric-data-message-bus-kf.client" .) (include "eric-data-message-bus-kf.pmdnsname" .) -}}
{{- $dnslist | toJson -}}
{{- end}}

{{/*
DNS.
*/}}
{{- define "eric-data-message-bus-kf.dnsname" -}}
*.{{- include "eric-data-message-bus-kf.fullname" . }}.{{ .Release.Namespace }}.svc.{{ .Values.clusterDomain }}
{{- end}}

{{/*
DNS.
*/}}
{{- define "eric-data-message-bus-kf.dnsname-namespace-only" -}}
*.{{- include "eric-data-message-bus-kf.fullname" . }}.{{ .Release.Namespace }}
{{- end}}

{{/*
Client
*/}}
{{- define "eric-data-message-bus-kf.client" -}}
{{ template "eric-data-message-bus-kf.fullname" . }}-client
{{- end -}}

{{/*
Wildcard name to match non-peer instances
*/}}
{{- define "eric-data-message-bus-kf.pmdnsname" -}}
{{ print "certified-scrape-target" }}
{{- end}}

{{/*
Zookeeper Client parameters for mTLS between Kafka and ZK
*/}}
{{- define "eric-data-message-bus-kf.zkclient.tls" -}}
{{- if and ( eq (include "eric-data-message-bus-kf.tls" .) "true" ) ( eq .Values.service.endpoints.dataCoordinator.tls.enforced "required" ) ( eq .Values.security.tls.messagebuskf.provider "sip-tls" ) }}
{{- print "true" -}}
{{- else -}}
{{- print "false" -}}
{{- end -}}
{{- end -}}


{{/*
Create a merged set of nodeSelectors from global and service level - mbkf.
*/}}
{{- define "eric-data-message-bus-kf.nodeSelector" -}}
{{- $globalValue := (dict) -}}
{{- if .Values.global -}}
    {{- if .Values.global.nodeSelector -}}
      {{- $globalValue = .Values.global.nodeSelector -}}
    {{- end -}}
{{- end -}}
{{- if .Values.nodeSelector -}}
  {{- range $key, $localValue := .Values.nodeSelector -}}
    {{- if hasKey $globalValue $key -}}
         {{- $Value := index $globalValue $key -}}
         {{- if ne $Value $localValue -}}
           {{- printf "nodeSelector \"%s\" is specified in both global (%s: %s) and service level (%s: %s) with differing values which is not allowed." $key $key $globalValue $key $localValue | fail -}}
         {{- end -}}
     {{- end -}}
    {{- end -}}
    nodeSelector: {{- toYaml (merge $globalValue .Values.nodeSelector) | trim | nindent 2 -}}
{{- else -}}
  {{- if not ( empty $globalValue ) -}}
    nodeSelector: {{- toYaml $globalValue | trim | nindent 2 -}}
  {{- end -}}
{{- end -}}
{{- end -}}

{{/*
JMX Exporter JVM Option, adding localPort in the jvmOpt.
*/}}
{{- define "eric-data-message-bus-kf.jmx-jvm" -}}
{{- if and .Values.jmx.jvmOpt .Values.jmx.localPort -}}
    {{- $jvmOpts := .Values.jmx.jvmOpt -}}
    {{- if .Values.jmx.enableRemote -}}
      {{- $jvmJmxRemoteOpts := "-Dcom.sun.management.jmxremote.ssl=false -Dcom.sun.management.jmxremote.authenticate=false -Dcom.sun.management.jmxremote.port" -}}
      {{- $jvmOpts = printf "%s %s=%v" $jvmOpts $jvmJmxRemoteOpts .Values.jmx.localPort -}}
    {{- end -}}
    {{- print $jvmOpts -}}
{{- end -}}
{{- end -}}

{{/*
Define logRedirect
Mapping between log.outputs and logshipper redirect parameter
*/}}
{{- define "eric-data-message-bus-kf.logRedirect" -}}
{{- $logRedirect := "file" -}}
{{- if .Values.log -}}
        {{- if .Values.log.outputs -}}
            {{- if (and (has "stream" .Values.log.outputs) (has "stdout" .Values.log.outputs)) -}}
                {{- $logRedirect = "all" -}}
            {{- else if (and (not (has "stream" .Values.log.outputs)) (has "stdout" .Values.log.outputs)) -}}
                {{- $logRedirect = "stdout" -}}
            {{- end -}}
        {{- end -}}
{{- end -}}
{{- print $logRedirect -}}
{{- end -}}

{{/*
Selector labels for MBKF
*/}}
{{- define "eric-data-message-bus-kf.selector-labels-mbkf" }}
app: {{ template "eric-data-message-bus-kf.name" . }}
release: {{ .Release.Name | quote }}
{{- end }}

{{/*
Parallel support for jmxExporter and jmxexporter
*/}}

{{/*
 Requests - memory
*/}}
{{- define "eric-data-message-bus-kf.jmx.requests.memory.jmxExporter" -}}
{{- if .Values.resources.jmxExporter -}}
  {{- if .Values.resources.jmxExporter.requests -}}
    {{- if .Values.resources.jmxExporter.requests.memory -}}
      {{ .Values.resources.jmxExporter.requests.memory }}
    {{- end -}}
  {{- end -}}
{{- end -}}
{{- end -}}

{{- define "eric-data-message-bus-kf.jmx.requests.memory" -}}
{{- print (default .Values.resources.jmxexporter.requests.memory (include "eric-data-message-bus-kf.jmx.requests.memory.jmxExporter" . )) | quote -}}
{{- end -}}

{{/*
 Requests - cpu
*/}}
{{- define "eric-data-message-bus-kf.jmx.requests.cpu.jmxExporter" -}}
{{- if .Values.resources.jmxExporter -}}
  {{- if .Values.resources.jmxExporter.requests -}}
    {{- if .Values.resources.jmxExporter.requests.cpu -}}
      {{ .Values.resources.jmxExporter.requests.cpu }}
    {{- end -}}
  {{- end -}}
{{- end -}}
{{- end -}}

{{- define "eric-data-message-bus-kf.jmx.requests.cpu" -}}
{{- print (default .Values.resources.jmxexporter.requests.cpu (include "eric-data-message-bus-kf.jmx.requests.cpu.jmxExporter" . )) | quote -}}
{{- end -}}

{{/*
 Requests - ephemeral-storage
*/}}
{{- define "eric-data-message-bus-kf.jmx.requests.ephemeral-storage.istrue" -}}
{{- if .Values.resources.jmxExporter -}}
  {{- if .Values.resources.jmxExporter.requests -}}
    {{- if (index .Values.resources.jmxExporter.requests "ephemeral-storage") -}}
      true
    {{- end -}}
  {{- end -}}
{{- end -}}
{{- if (index .Values.resources.jmxexporter.requests "ephemeral-storage") -}}
  true
{{- end -}}
{{- end -}}

{{- define "eric-data-message-bus-kf.jmx.requests.ephemeral-storage.jmxExporter" -}}
{{- if .Values.resources.jmxExporter -}}
  {{- if .Values.resources.jmxExporter.requests -}}
    {{- if (index .Values.resources.jmxExporter.requests "ephemeral-storage") -}}
      {{ (index .Values.resources.jmxExporter.requests "ephemeral-storage") }}
    {{- end -}}
  {{- end -}}
{{- end -}}
{{- end -}}

{{- define "eric-data-message-bus-kf.jmx.requests.ephemeral-storage" -}}
{{- print (default (index .Values.resources.jmxexporter.requests "ephemeral-storage") (include "eric-data-message-bus-kf.jmx.requests.ephemeral-storage.jmxExporter" . )) | quote -}}
{{- end -}}

{{/*
 Limits - memory
*/}}
{{- define "eric-data-message-bus-kf.jmx.limits.memory.jmxExporter" -}}
{{- if .Values.resources.jmxExporter -}}
  {{- if .Values.resources.jmxExporter.limits -}}
    {{- if .Values.resources.jmxExporter.limits.memory -}}
      {{ .Values.resources.jmxExporter.limits.memory }}
    {{- end -}}
  {{- end -}}
{{- end -}}
{{- end -}}

{{- define "eric-data-message-bus-kf.jmx.limits.memory" -}}
{{- print (default .Values.resources.jmxexporter.limits.memory (include "eric-data-message-bus-kf.jmx.limits.memory.jmxExporter" . )) | quote -}}
{{- end -}}

{{/*
 Limits - cpu
*/}}
{{- define "eric-data-message-bus-kf.jmx.limits.cpu.jmxExporter" -}}
{{- if .Values.resources.jmxExporter -}}
  {{- if .Values.resources.jmxExporter.limits -}}
    {{- if .Values.resources.jmxExporter.limits.cpu -}}
      {{ .Values.resources.jmxExporter.limits.cpu }}
    {{- end -}}
  {{- end -}}
{{- end -}}
{{- end -}}

{{- define "eric-data-message-bus-kf.jmx.limits.cpu" -}}
{{- print (default .Values.resources.jmxexporter.limits.cpu (include "eric-data-message-bus-kf.jmx.limits.cpu.jmxExporter" . )) | quote -}}
{{- end -}}

{{/*
 Limits - ephemeral-storage
*/}}
{{- define "eric-data-message-bus-kf.jmx.limits.ephemeral-storage.istrue" -}}
{{- if .Values.resources.jmxExporter -}}
  {{- if .Values.resources.jmxExporter.limits -}}
    {{- if (index .Values.resources.jmxExporter.limits "ephemeral-storage") -}}
      true
    {{- end -}}
  {{- end -}}
{{- end -}}
{{- if (index .Values.resources.jmxexporter.limits "ephemeral-storage") -}}
  true
{{- end -}}
{{- end -}}

{{- define "eric-data-message-bus-kf.jmx.limits.ephemeral-storage.jmxExporter" -}}
{{- if .Values.resources.jmxExporter -}}
  {{- if .Values.resources.jmxExporter.limits -}}
    {{- if (index .Values.resources.jmxExporter.limits "ephemeral-storage") -}}
      {{ (index .Values.resources.jmxExporter.limits "ephemeral-storage") }}
    {{- end -}}
  {{- end -}}
{{- end -}}
{{- end -}}

{{- define "eric-data-message-bus-kf.jmx.limits.ephemeral-storage" -}}
{{- print (default (index .Values.resources.jmxexporter.limits "ephemeral-storage") (include "eric-data-message-bus-kf.jmx.limits.ephemeral-storage.jmxExporter" . )) | quote -}}
{{- end -}}

{{/*
 Readiness probe logic - TLS_OPTIONAL, TLS_ENFORCED_SIPTLS, TLS_ENFORCED_EDA, SASL_PLAINTEXT, PLAINTEXT
*/}}
{{- define "eric-data-message-bus-kf.messagebuskf.readinessProbe" -}}
            {{- if and ( eq (include "eric-data-message-bus-kf.tls" .) "true" ) ( eq .Values.service.endpoints.messagebuskf.tls.enforced "optional" ) }}
              - "python3 /usr/bin/readiness.py {{ template "eric-data-message-bus-kf.plaintextPort" . }} TLS_OPTIONAL None"
            {{- else if and ( eq (include "eric-data-message-bus-kf.tls" .) "true" ) ( eq .Values.security.tls.messagebuskf.provider "sip-tls" ) }}
              - "python3 /usr/bin/readiness.py {{ .Values.security.tls.messagebuskf.port }} TLS_ENFORCED_SIPTLS None"
            {{- else if and ( eq (include "eric-data-message-bus-kf.tls" .) "true" ) ( eq .Values.security.tls.messagebuskf.provider "edaTls" ) }}
              - "python3 /usr/bin/readiness.py {{ .Values.security.tls.messagebuskf.port }} TLS_ENFORCED_EDA None"
            {{- else if eq (include "eric-data-message-bus-kf.sasl" .) "true" }}
              - "python3 /usr/bin/readiness.py {{ template "eric-data-message-bus-kf.saslPlaintextPort" . }} SASL_PLAINTEXT $KAFKA_SASL_SERVER_ADMIN_PASSWORD"
            {{- else }}
              - "python3 /usr/bin/readiness.py {{ template "eric-data-message-bus-kf.plaintextPort" . }} PLAINTEXT None"
            {{- end -}}
{{- end -}}


{{- define "eric-data-message-bus-kf.messagebuskf.readiness" -}}
{{- $probe:= .Values.probes.messagebuskf -}}
{{- $initialDelaySeconds := $probe.readinessProbe.initialDelaySeconds -}}
{{- $timeoutSeconds := $probe.readinessProbe.timeoutSeconds -}}
{{- $periodSeconds := $probe.readinessProbe.periodSeconds -}}
{{- $failureThreshold := $probe.readinessProbe.failureThreshold -}}
{{- $successThreshold := $probe.readinessProbe.successThreshold }}
          initialDelaySeconds: {{ print $initialDelaySeconds }}
          timeoutSeconds: {{ print $timeoutSeconds }}
          periodSeconds: {{ print $periodSeconds }}
          failureThreshold: {{ print $failureThreshold }}
          successThreshold: {{ print $successThreshold }}
{{- end -}}

{{- define "eric-data-message-bus-kf.messagebuskf.liveness" -}}
{{- $probe:= .Values.probes.messagebuskf -}}
{{- $initialDelaySeconds := $probe.livenessProbe.initialDelaySeconds -}}
{{- $timeoutSeconds :=$probe.livenessProbe.timeoutSeconds -}}
{{- $periodSeconds := $probe.livenessProbe.periodSeconds -}}
{{- $failureThreshold := $probe.livenessProbe.failureThreshold -}}
{{- $successThreshold := $probe.livenessProbe.successThreshold }}
          initialDelaySeconds: {{ print $initialDelaySeconds }}
          timeoutSeconds: {{ print $timeoutSeconds }}
          periodSeconds: {{ print $periodSeconds }}
          failureThreshold: {{ print $failureThreshold }}
          successThreshold: {{ print $successThreshold }}
{{- end -}}

{{- define "eric-data-message-bus-kf.jmxexporter.readiness" -}}
{{- $probe:= .Values.probes.jmxexporter -}}
{{- $initialDelaySeconds := $probe.readinessProbe.initialDelaySeconds -}}
{{- $timeoutSeconds := $probe.readinessProbe.timeoutSeconds -}}
{{- $periodSeconds := $probe.readinessProbe.periodSeconds -}}
{{- $failureThreshold := $probe.readinessProbe.failureThreshold -}}
{{- $successThreshold := $probe.readinessProbe.successThreshold }}
          initialDelaySeconds: {{ print $initialDelaySeconds }}
          timeoutSeconds: {{ print $timeoutSeconds }}
          periodSeconds: {{ print $periodSeconds }}
          failureThreshold: {{ print $failureThreshold }}
          successThreshold: {{ print $successThreshold }}
{{- end -}}

{{- define "eric-data-message-bus-kf.jmxexporter.liveness" -}}
{{- $probe:= .Values.probes.jmxexporter -}}
{{- $initialDelaySeconds := $probe.livenessProbe.initialDelaySeconds -}}
{{- $timeoutSeconds :=$probe.livenessProbe.timeoutSeconds -}}
{{- $periodSeconds := $probe.livenessProbe.periodSeconds -}}
{{- $failureThreshold := $probe.livenessProbe.failureThreshold -}}
{{- $successThreshold := $probe.livenessProbe.successThreshold }}
          initialDelaySeconds: {{ print $initialDelaySeconds }}
          timeoutSeconds: {{ print $timeoutSeconds }}
          periodSeconds: {{ print $periodSeconds }}
          failureThreshold: {{ print $failureThreshold }}
          successThreshold: {{ print $successThreshold }}
{{- end -}}

{{- define "eric-data-message-bus-kf.metricsexporter.readiness" -}}
{{- $probe:= .Values.probes.metricsexporter -}}
{{- $initialDelaySeconds := $probe.readinessProbe.initialDelaySeconds -}}
{{- $timeoutSeconds := $probe.readinessProbe.timeoutSeconds -}}
{{- $periodSeconds := $probe.readinessProbe.periodSeconds -}}
{{- $failureThreshold := $probe.readinessProbe.failureThreshold -}}
{{- $successThreshold := $probe.readinessProbe.successThreshold -}}
    {{- if .Values.readynessProbeInitialDelaySeconds -}}
      {{- $initialDelaySeconds = .Values.readynessProbeInitialDelaySeconds -}}
    {{- end -}}
    {{- if .Values.readynessProbeTimeoutSeconds -}}
      {{- $timeoutSeconds = .Values.readynessProbeTimeoutSeconds -}}
    {{- end -}}
    {{- if .Values.readynessProbePeriodSeconds -}}
      {{- $periodSeconds = .Values.readynessProbePeriodSeconds -}}
    {{- end -}}
    {{- if .Values.readinessProbeFailureThreshold}}
      {{- $failureThreshold = .Values.readinessProbeFailureThreshold -}}
    {{- end }}
          initialDelaySeconds: {{ print $initialDelaySeconds }}
          timeoutSeconds: {{ print $timeoutSeconds }}
          periodSeconds: {{ print $periodSeconds }}
          failureThreshold: {{ print $failureThreshold }}
          successThreshold: {{ print $successThreshold }}
{{- end -}}

{{- define "eric-data-message-bus-kf.metricsexporter.liveness" -}}
{{- $probe:= .Values.probes.metricsexporter -}}
{{- $initialDelaySeconds := $probe.livenessProbe.initialDelaySeconds -}}
{{- $timeoutSeconds :=$probe.livenessProbe.timeoutSeconds -}}
{{- $periodSeconds := $probe.livenessProbe.periodSeconds -}}
{{- $failureThreshold := $probe.livenessProbe.failureThreshold -}}
{{- $successThreshold := $probe.livenessProbe.successThreshold -}}
    {{- if .Values.livenessProbeInitialDelaySeconds -}}
      {{- $initialDelaySeconds = .Values.livenessProbeInitialDelaySeconds -}}
    {{- end -}}
    {{- if .Values.livenessProbeTimeoutSeconds -}}
      {{- $timeoutSeconds = .Values.livenessProbeTimeoutSeconds -}}
    {{- end -}}
    {{- if .Values.livenessProbePeriodSeconds -}}
      {{- $periodSeconds = .Values.livenessProbePeriodSeconds -}}
    {{- end -}}
    {{- if .Values.livenessProbeFailureThreshold}}
      {{- $failureThreshold = .Values.livenessProbeFailureThreshold -}}
    {{- end }}
          initialDelaySeconds: {{ print $initialDelaySeconds }}
          timeoutSeconds: {{ print $timeoutSeconds }}
          periodSeconds: {{ print $periodSeconds }}
          failureThreshold: {{ print $failureThreshold }}
          successThreshold: {{ print $successThreshold }}
{{- end -}}

{{/*
 CA Secret provided by PM Server
*/}}
{{- define "eric-data-message-bus-kf.pmCaSecretName" -}}
        {{- .Values.pmServer.pmServiceName -}}-ca
{{- end -}}


{{/*
Define podPriority
*/}}
{{- define "eric-data-message-bus-kf.podPriority" }}
{{- if .Values.podPriority }}
  {{- if index .Values.podPriority "eric-data-message-bus-kf" -}}
    {{- if (index .Values.podPriority "eric-data-message-bus-kf" "priorityClassName") }}
      priorityClassName: {{ index .Values.podPriority "eric-data-message-bus-kf" "priorityClassName" | quote }}
    {{- end }}
  {{- end }}
{{- end }}
{{- end }}

{{/*
Define eric-data-message-bus-kf.podSeccompProfile
*/}}
{{- define "eric-data-message-bus-kf.SeccompProfile" -}}
{{- if and .Values.seccompProfile .Values.seccompProfile.type }}
seccompProfile:
  type: {{ .Values.seccompProfile.type }}
  {{- if eq .Values.seccompProfile.type "Localhost" }}
  localhostProfile: {{ .Values.seccompProfile.localhostProfile }}
  {{- end }}
{{- end }}
{{- end -}}

{{/*
Define eric-data-message-bus-kf.appArmorProfile
*/}}
{{- define "eric-data-message-bus-kf.appArmorProfile" -}}
{{- $acceptedProfiles := list "unconfined" "runtime/default" "localhost" }}
{{- $commonProfile := dict -}}
{{- if .Values.appArmorProfile.type -}}
  {{- $_ := set $commonProfile "type" .Values.appArmorProfile.type -}}
  {{- if and (eq .Values.appArmorProfile.type "localhost") .Values.appArmorProfile.localhostProfile -}}
    {{- $_ := set $commonProfile "localhostProfile" .Values.appArmorProfile.localhostProfile -}}
  {{- end -}}
{{- end -}}
{{- $profiles := dict -}}
{{- range $container := list "messagebuskf" "jmxexporter" "logshipper" "checkzkready" "metricsexporter" -}}
  {{- if and (hasKey $.Values.appArmorProfile $container) (index $.Values.appArmorProfile $container "type") -}}
    {{- $_ := set $profiles $container (index $.Values.appArmorProfile $container) -}}
  {{- else -}}
    {{- $_ := set $profiles $container $commonProfile -}}
  {{- end -}}
{{- end -}}
{{- range $key, $value := $profiles -}}
  {{- if $value.type -}}
    {{- if not (has $value.type $acceptedProfiles) -}}
      {{- fail (printf "Unsupported appArmor profile type: %s, use one of the supported profiles %s" $value.type $acceptedProfiles) -}}
    {{- end -}}
    {{- if and (eq $value.type "localhost") (empty $value.localhostProfile) -}}
      {{- fail "The 'localhost' appArmor profile requires a profile name to be provided in localhostProfile parameter." -}}
    {{- end }}
container.apparmor.security.beta.kubernetes.io/{{ $key }}: {{ $value.type }}{{ eq $value.type "localhost" | ternary (printf "/%s" $value.localhostProfile) ""  }}
  {{- end -}}
{{- end -}}
{{- end -}}