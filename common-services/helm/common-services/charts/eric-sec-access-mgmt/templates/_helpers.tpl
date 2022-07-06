{{/* vim: set filetype=mustache: */}}

{{/*
Create a map from ".Values.global" with defaults if missing in values file.
This hides defaults from values file.
*/}}
{{ define "eric-sec-access-mgmt.global" }}
  {{- $globalDefaults := (dict "timezone" "UTC") -}}
  {{- $globalDefaults := merge $globalDefaults (dict "registry" (dict "url" "armdocker.rnd.ericsson.se")) -}}
  {{- $globalDefaults := merge $globalDefaults (dict "pullSecret" "") -}}
  {{- $globalDefaults := merge $globalDefaults (dict "registry" (dict "imagePullPolicy" "IfNotPresent")) -}}
  {{- $globalDefaults := merge $globalDefaults (dict "security" (dict "tls" (dict "enabled" "true"))) -}}
  {{- $globalDefaults := merge $globalDefaults (dict "nodeSelector" (dict)) -}}
  {{- $globalDefaults := merge $globalDefaults (dict "internalIPFamily" "") -}}
  {{- $globalDefaults := merge $globalDefaults (dict "security" (dict "policyBinding" (dict "create" false))) -}}
  {{- $globalDefaults := merge $globalDefaults (dict "networkPolicy" ((dict "enabled" false)) ) -}}
  {{- $globalDefaults := merge $globalDefaults (dict "security" (dict "policyReferenceMap" (dict "default-restricted-security-policy" "default-restricted-security-policy"))) -}}
  {{ if .Values.global }}
    {{- mergeOverwrite $globalDefaults .Values.global | toJson -}}
  {{ else }}
    {{- $globalDefaults | toJson -}}
  {{ end }}
{{ end }}

{{/*
Expand the name of the chart.
We truncate to 20 characters because this is used to set the node identifier in WildFly which is limited to
23 characters. This allows for a replica suffix for up to 99 replicas.
*/}}
{{- define "eric-sec-access-mgmt.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 20 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "eric-sec-access-mgmt.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create chart version as used by the chart label.
*/}}
{{- define "eric-sec-access-mgmt.version" -}}
{{- printf "%s" .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Check to enable sipoauth2 is enabled and crds are installed
*/}}
{{- define "eric-sec-access-mgmt.sipoauth2.enabled" -}}
{{- $crdInstalled := .Capabilities.APIVersions.Has "iam.sec.ericsson.com/v1beta1/InternalOAuth2Identity" -}}
{{- $enabled := and $crdInstalled .Values.sipoauth2.enabled -}}
{{- print $enabled -}}
{{- end -}}

{{/*
Create a user defined annotation (DR-D1121-065, DR-D1121-060)
*/}}
{{ define "eric-sec-access-mgmt.config-annotations" }}
  {{- $global := (.Values.global).annotations -}}
  {{- $service := .Values.annotations -}}
  {{- include "eric-sec-access-mgmt.mergeAnnotations" (dict "location" (.Template.Name) "sources" (list $global $service)) }}
{{- end }}

{{/*
Common annotations added to all resources
*/}}
{{- define "eric-sec-access-mgmt.common-annotations" }}
  {{- $productInfo := include "eric-sec-access-mgmt.product-info" . | fromYaml -}}
  {{- $config := include "eric-sec-access-mgmt.config-annotations" . | fromYaml -}}
  {{- include "eric-sec-access-mgmt.mergeAnnotations" (dict "location" (.Template.Name) "sources" (list $productInfo $config)) | trim }}
{{- end }}

{{/*
Create annotation for the product information (DR-D1121-064)
*/}}
{{- define "eric-sec-access-mgmt.product-info" }}
  ericsson.com/product-name: {{ (fromYaml (.Files.Get "eric-product-info.yaml")).productName }}
  ericsson.com/product-number: {{ (fromYaml (.Files.Get "eric-product-info.yaml")).productNumber }}
  ericsson.com/product-revision: {{ regexReplaceAll "(.*)[+|-].*" .Chart.Version "${1}" }}
{{- end}}

{{/*
Template to derive image path (DR-D1121-067, DR-D1121-104, DR-D1121-105)
Template arguments: (dict "root" . "image" "image-name")
  root - the root scope "."
  image - the image name (in eric-product-info.yaml)
*/}}
{{- define "eric-sec-access-mgmt.imagePath" }}
  {{- $productInfo := fromYaml (.root.Files.Get "eric-product-info.yaml") -}}
  {{- $values := .root.Values -}}
  {{/*.Values.imageCredentials and product info object for this image*/}}
  {{- $productInfoImage := index $productInfo.images .image -}}
  {{- $valuesImageCredentialsImage := index $values.imageCredentials .image -}}

  {{- $registryUrl := $productInfoImage.registry -}}
  {{- $repoPath := $productInfoImage.repoPath -}}
  {{- $name := $productInfoImage.name -}}
  {{- $tag := $productInfoImage.tag -}}

  {{/*DR-D1121-104 - global overrides the default registry url*/}}
  {{- if $values.global -}}
    {{- if $values.global.registry -}}
      {{- if $values.global.registry.url -}}
        {{- $registryUrl = $values.global.registry.url -}}
      {{- end -}}
    {{- end -}}
  {{- end -}}

  {{/*DR-D1121-104 - local registry url overrides global and default*/}}
  {{- if $valuesImageCredentialsImage.registry.url -}}
    {{- $registryUrl = $valuesImageCredentialsImage.registry.url -}}
  {{- end -}}
  {{/*registry url set for all images overrides the above*/}}
  {{- if $values.imageCredentials.registry -}}
    {{- if $values.imageCredentials.registry.url -}}
      {{- $registryUrl = $values.imageCredentials.registry.url -}}
    {{- end -}}
  {{- end -}}

  {{/*DR-D1121-105 - local repopath overrides the default*/}}
  {{- if not (kindIs "invalid" $valuesImageCredentialsImage.repoPath) -}}
    {{- $repoPath = $valuesImageCredentialsImage.repoPath -}}
  {{- end -}}
  {{/*repopath set for all images overrides the above*/}}
  {{- if not (kindIs "invalid" $values.imageCredentials.repoPath) -}}
    {{- $repoPath = $values.imageCredentials.repoPath -}}
  {{- end -}}
  {{- if $repoPath -}}
    {{- $repoPath = printf "%s/" $repoPath -}}
  {{- end -}}

  {{- printf "%s/%s%s:%s" $registryUrl $repoPath $name $tag -}}
{{- end -}}

{{/*
Create the name for the tls secret.
*/}}
{{- define "eric-sec-access-mgmt.ingressTLSSecret" -}}
{{- if .Values.ingress.tls.existingSecret -}}
  {{- .Values.ingress.tls.existingSecret -}}
{{- else -}}
  {{- template "eric-sec-access-mgmt.name" . -}}-ingress-external-tls-secret
{{- end -}}
{{- end -}}

{{/*
Create pullSecret from global and local params.
*/}}
{{- define "eric-sec-access-mgmt.pullSecret" -}}
{{- $global := fromJson (include "eric-sec-access-mgmt.global" .) -}}
{{- if .Values.imageCredentials.pullSecret -}}
  {{- .Values.imageCredentials.pullSecret -}}
{{- else if and $global.pullSecret -}}
  {{- $global.pullSecret -}}
{{- end -}}
{{- end -}}

{{/*
Create the name for the tls secret of authentication proxy
*/}}
{{- define "eric-sec-access-mgmt.authnIngressTLSSecret" -}}
{{- if .Values.authenticationProxy.ingress.existingTlsSecret -}}
  {{- .Values.authenticationProxy.ingress.existingTlsSecret -}}
{{- else -}}
  {{- template "eric-sec-access-mgmt.name" . -}}-authn-ingress-external-tls-secret
{{- end -}}
{{- end -}}

{{/*
Create the name for the database secret.
*/}}
{{- define "eric-sec-access-mgmt.externalDbSecret" -}}
{{- if .Values.persistence.existingSecret -}}
  {{- .Values.persistence.existingSecret -}}
{{- else -}}
  {{- template "eric-sec-access-mgmt.name" . -}}-db
{{- end -}}
{{- end -}}


{{/*
Create the ports used by KC.
*/}}
{{- define "eric-sec-access-mgmt.httpPort" -}}
8080
{{- end -}}
{{- define "eric-sec-access-mgmt.httpsPort" -}}
8443
{{- end -}}
{{- define "eric-sec-access-mgmt.adminPortHttps" -}}
8444
{{- end -}}
{{- define "eric-sec-access-mgmt.adminPortHttp" -}}
8081
{{- end -}}
{{- define "eric-sec-access-mgmt.jgroupsTCPPort" -}}
7600
{{- end -}}
{{- define "eric-sec-access-mgmt.jgroupsTCPFDPort" -}}
57600
{{- end -}}
{{- define "eric-sec-access-mgmt.jgroupsSSLKeyExchange" -}}
2157
{{- end -}}
{{- define "eric-sec-access-mgmt.serviceHttpPort" -}}
8080
{{- end -}}
{{- define "eric-sec-access-mgmt.serviceHttpsPort" -}}
8443
{{- end -}}
{{- define "eric-sec-access-mgmt.serviceAdminConsolePort" -}}
8444
{{- end -}}
{{- define "eric-sec-access-mgmt.authProxyPort" -}}
6443
{{- end -}}
{{- define "eric-sec-access-mgmt.serverCertMountPath" -}}
/run/secrets/tls-int-cert
{{- end -}}

{{/*
LDAP url
*/}}
{{- define "eric-sec-access-mgmt.ldapUrl" -}}
{{ printf "ldap://%s:389" .Values.ldap.server }}
{{- end -}}

{{/*
Ingress tls enabled
*/}}
{{- define "eric-sec-access-mgmt.ingressTlsEnabled" -}}
{{- $ingressTlsEnabled := .Values.ingress.tls.enabled | toString }}
{{- print $ingressTlsEnabled -}}
{{- end -}}

{{/*
HA tls enabled.
*/}}
{{- define "eric-sec-access-mgmt.haTlsEnabled" -}}
{{- $global := fromJson (include "eric-sec-access-mgmt.global" .) -}}
{{- $haTlsEnabled := $global.security.tls.enabled }}
{{- if (hasKey .Values.statefulset "tls") }}
  {{- if (hasKey .Values.statefulset.tls "enabled") -}}
    {{- $haTlsEnabled = .Values.statefulset.tls.enabled }}
  {{- end -}}
{{- end -}}
{{- print $haTlsEnabled -}}
{{- end -}}

{{/*
Create environment variables for database configuration.
*/}}
{{- define "eric-sec-access-mgmt.externalDbConfig" -}}
{{- $global := fromJson (include "eric-sec-access-mgmt.global" .) -}}
- name: DB_VENDOR
  value: {{ .Values.persistence.dbVendor | quote }}
{{- if eq .Values.persistence.dbVendor "POSTGRES" }}
- name: DB_ADDR
  value: {{ .Values.persistence.dbHost | quote }}
- name: DB_PORT
  value: {{ .Values.persistence.dbPort | quote }}
{{- if not $global.security.tls.enabled }}
- name: DB_USER
  valueFrom:
    secretKeyRef:
      name: {{ .Values.persistence.dbsecret }}
      key: {{ default "pguserid" .Values.persistence.dbUserkey}}
- name: DB_PASSWORD
  valueFrom:
    secretKeyRef:
      name: {{ .Values.persistence.dbsecret }}
      key: {{ default "pgpasswd" .Values.persistence.dbPasswdkey}}
{{- else }}
- name: DB_USER
  value: {{ .Values.tls.client.pg.subject | quote }}
{{- end }}
- name: DB_DATABASE
  value: {{ .Values.persistence.dbName | quote }}
{{- end -}}
{{- end -}}

{{/*
Create environment variables for TLS configuration for proxy container.
*/}}
{{- define "eric-sec-access-mgmt.tlsProxyConfig" -}}
{{- $global := fromJson (include "eric-sec-access-mgmt.global" .) -}}
{{- if $global.security.tls.enabled }}
# Configure SSL client certificate for IAM towards LDAP
- name: PG_CLIENT_CERT_MOUNT_PATH
  value: {{ .Values.tls.client.pg.mountPath | quote }}
{{- if .Values.metrics.enabled }}
- name: PM_SERVER_CA_CERT_MOUNT_PATH
  value: {{ include "eric-sec-access-mgmt.pmServerCACertPath" . | quote }}
{{- end }}
{{- end }}
{{- if $global.security.tls.enabled }}
- name: TRUSTED_CA_CERT_MOUNT_PATH
  value: {{ .Values.tls.client.caMountPath | quote }}
{{- end }}
{{- end }}

{{/*
Create environment variables for TLS configuration for init container.
*/}}
{{- define "eric-sec-access-mgmt.tlsInitConfig" -}}
{{- $global := fromJson (include "eric-sec-access-mgmt.global" .) -}}
{{- if $global.security.tls.enabled }}
- name: TRUSTED_CA_CERT_MOUNT_PATH
  value: {{ .Values.tls.client.caMountPath | quote }}
{{- end }}
{{- if $global.security.tls.enabled }}
# Configure SSL client certificate for IAM towards LDAP
- name: PG_CLIENT_CERT_MOUNT_PATH
  value: {{ .Values.tls.client.pg.mountPath | quote }}
{{- end }}
{{- end }}

{{/*
Create environment variables for TLS configuration for IAM container.
*/}}
{{- define "eric-sec-access-mgmt.tlsIamConfig" -}}
{{- $global := fromJson (include "eric-sec-access-mgmt.global" .) -}}
{{- if $global.security.tls.enabled }}
- name: TRUSTED_CA_CERT_MOUNT_PATH
  value: {{ .Values.tls.client.caMountPath | quote }}
- name: SERVER_CERT_PATH
  value: {{ include "eric-sec-access-mgmt.serverCertMountPath" . | quote }}
- name: IAM_INT_CA_CERT_PATH
  value: {{ include "eric-sec-access-mgmt.IAMintCACertPath" . | quote }}
- name: IAM_INT_PROBE_CLIENT_CERT_PATH
  value: {{ include "eric-sec-access-mgmt.probeCliCertPath" . | quote }}
- name: IAM_INT_CLIENT_CERT_PATH
  value: {{ include "eric-sec-access-mgmt.iamIntCliCertPath" . | quote }}
## <START>Delete below env after the deprecation ends: ADPPRG-66120
- name: IAM_CLIENT_CA_CERT_PATH
  value: {{ include "eric-sec-access-mgmt.iamClientCACertPath" . | quote }}
## <END>
- name: HA_CERT_PATH
  value: {{ include "eric-sec-access-mgmt.haCertPath" . | quote }}
- name: HA_KEYSTORE_PATH
  value: {{ include "eric-sec-access-mgmt.haKeystorePath" . | quote }}
- name: HA_TRUSTED_CA_CERT_MOUNT_PATH
  value: {{ include "eric-sec-access-mgmt.IntCACertPath" . | quote }}
# Configure SSL client certificate for IAM towards LDAP
- name: PG_CLIENT_CERT_MOUNT_PATH
  value: {{ .Values.tls.client.pg.mountPath | quote }}
# Configure MTLS between IAM and Document DB PG
- name: JDBC_PARAMS
  value: 'user={{ .Values.tls.client.pg.subject }}&ssl=true&sslmode=verify-full&sslfactory=org.postgresql.ssl.DefaultJavaSSLFactory'
- name: IAM_CLIENT_CA_CERT_PATH_1
  value: {{ include "eric-sec-access-mgmt.iamClientCACertPath1" . | quote }}
- name: ICCR_CLIENT_CA_CERT_PATH
  value: "/run/secrets/iccr-client-ca"
  {{- if .Values.ldap.enabled }}
# Configure SSL client certificate for IAM towards LDAP
- name: LDAP_CLIENT_CERT_MOUNT_PATH
  value: {{ .Values.tls.client.ldap.mountPath | quote }}
  {{- end }}
  {{- if .Values.metrics.enabled }}
- name: PM_SERVER_CA_CERT_MOUNT_PATH
  value: {{ include "eric-sec-access-mgmt.pmServerCACertPath" . | quote }}
  {{- end }}
  {{- if and .Values.authenticationProxy.enabled }}
- name: AAPROXY_CA_CERT_PATH
  value: {{ include "eric-sec-access-mgmt.aaproxyCAcertPath" . | quote }}
  {{- end }}
{{- else }}
# Configure one-way TLS between IAM and Document DB PG
- name: JDBC_PARAMS
  value: 'sslmode=prefer'
{{- end }}
{{- if .Values.egress.ldap.certificates.trustedCertificateListSecret }}
- name: EGRESS_LDAP_TRUSTED_CA_CERT_MOUNT_PATH
  value: {{ include "eric-sec-access-mgmt.egressLdapCertPath" . | quote }}
{{- end }}
{{- if or .Values.egress.identityProvider.certificates.trustedCertificateListSecret .Values.egress.identityProvider.certificates.trustedCertificateListName }}
- name: EGRESS_IDP_TRUSTED_CA_CERT_MOUNT_PATH
  value: {{ include "eric-sec-access-mgmt.egressIdpCertPath" . | quote }}
{{- end }}
{{- end }}

{{/*
Create imagePullPolicy
*/}}
{{- define "eric-sec-access-mgmt.imagePullPolicy" -}}
  {{- $global := fromJson (include "eric-sec-access-mgmt.global" .) -}}
  {{- $imagePullPolicy := $global.registry.imagePullPolicy -}}
  {{- if .Values.imageCredentials.registry -}}
    {{- if .Values.imageCredentials.registry.imagePullPolicy -}}
      {{- $imagePullPolicy = .Values.imageCredentials.registry.imagePullPolicy -}}
    {{- end -}}
  {{- end -}}
  {{- print $imagePullPolicy -}}
{{- end -}}

{{/*
Set environment variables for timezone
*/}}
{{- define "eric-sec-access-mgmt.timezone" -}}
{{- $global := fromJson (include "eric-sec-access-mgmt.global" .) -}}
- name: TZ
  value: {{ $global.timezone }}
{{- end -}}

{{- define "eric-sec-access-mgmt.adminUserCredentialsMountPath" }}/run/secrets/kc-admin{{- end }}
{{/*
Set environment variables for Keycloak admin user credentials
*/}}
{{- define "eric-sec-access-mgmt.credentials" -}}
{{- if not .Values.adminSecret }}
- name: KEYCLOAK_USER
  valueFrom:
    secretKeyRef:
      name: {{ .Values.statefulset.adminSecret | quote }}
      key: {{ .Values.statefulset.userkey | quote }}
- name: KEYCLOAK_PASSWORD
  valueFrom:
    secretKeyRef:
      name:  {{ .Values.statefulset.adminSecret | quote }}
      key: {{ .Values.statefulset.passwdkey | quote }}
{{- else }}
# The below environment variable needs to be set for custom Expire password policy to exclude this admin user.
# See ExpirePassword.java from /src/keycloak-custom for more details. Hence, the secrets cannot be made optional yet
# until we go through a deprecation process to deprecate excluding admin user by default.
- name: KEYCLOAK_USER
  valueFrom:
    secretKeyRef:
      name: {{ .Values.adminSecret | quote }}
      key: "username"
- name: ADM_USR_CREDS_MNT_PATH
  value: {{ include "eric-sec-access-mgmt.adminUserCredentialsMountPath" . | quote }}
{{- end }}
{{- end -}}

{{/*
This function takes (dict "Values" .Values "resourceName" "i.e:iam") as paramter
And render the ressource attributes (requests and limits)
* Values to access .Values
* resourceName to help access the specific resource from .Values.resources
*/}}
{{- define "eric-sec-access-mgmt.resourcesHelper" -}}
requests:
{{- if index .Values.resources .resourceName "requests" "memory" }}
  memory: {{ index .Values.resources .resourceName "requests" "memory" | quote}}
{{- end }}
{{- if index .Values.resources .resourceName "requests" "cpu"}}
  cpu: {{ index .Values.resources .resourceName "requests" "cpu" | quote}}
{{- end }}
{{- if index .Values.resources .resourceName "requests" "ephemeral-storage"}}
  ephemeral-storage: {{ index .Values.resources .resourceName "requests" "ephemeral-storage" | quote}}
{{- end }}
limits:
{{- if index .Values.resources .resourceName "limits" "memory" }}
  memory: {{ index .Values.resources .resourceName "limits" "memory" | quote}}
{{- end }}
{{- if index .Values.resources .resourceName "limits" "cpu"}}
  cpu: {{ index .Values.resources .resourceName "limits" "cpu" | quote}}
{{- end }}
{{- if index .Values.resources .resourceName "limits" "ephemeral-storage"}}
  ephemeral-storage: {{ index .Values.resources .resourceName "limits" "ephemeral-storage" | quote}}
{{- end }}
{{- end -}}
{{/*
LDAP federator password mount path
*/}}
{{- define "eric-sec-access-mgmt.ldapFedPasswdPath" }}/run/secrets/ldap-fed-passwd{{- end }}
{{- define "eric-sec-access-mgmt.egressLdapCertPath" }}/run/secrets/egress-ldap-cert{{- end }}
{{- define "eric-sec-access-mgmt.egressIdpCertPath" }}/run/secrets/egress-idp-cert{{- end }}

{{/*
HA cluster tls mount path
*/}}
{{- define "eric-sec-access-mgmt.haCertPath" }}/run/secrets/ha-cert-path{{- end }}
{{- define "eric-sec-access-mgmt.haKeystorePath" }}/opt/jboss/rundir-safe/ha.keystore{{- end }}
{{- define "eric-sec-access-mgmt.IntCACertPath" }}/run/secrets/int-ca-cert-path{{- end }}

{{/*
AA Proxy tls mount path
*/}}
{{- define "eric-sec-access-mgmt.aaproxyCAcertPath" }}/run/secrets/aaproxy-ca-cert-path{{- end }}

{{- define "eric-sec-access-mgmt.sipOauth2ClientSecretPath" }}/run/secrets/sip-oauth2-client-secret{{- end }}

{{- define "eric-sec-access-mgmt.authnProxyClientSecretPath" }}/run/secrets/authn-proxy-client-secret{{- end }}

{{/*
Allowed values for HTTP host validation. Valid hosts are all
service name combinations, ingress hostname, and any additional
hostnames specified. Outputs a comma separated list of hostnames
*/}}
{{- define "eric-sec-access-mgmt.allowedHosts" -}}
  {{- $svc := printf "%s-%s" (include "eric-sec-access-mgmt.name" . ) "http" -}}
  {{- $svcAlias1 := printf "%s.%s" $svc .Release.Namespace -}}
  {{- $svcAlias2 := printf "%s.%s.svc" $svc .Release.Namespace -}}
  {{- $svcAlias3 := printf "%s.%s.svc.cluster" $svc .Release.Namespace -}}
  {{- $svcAlias4 := printf "%s.%s.svc.cluster.local" $svc .Release.Namespace -}}

  {{- $allowedHosts := printf "%s" $svc -}}
  {{- $allowedHosts = printf "%s, %s" $allowedHosts $svcAlias1 -}}
  {{- $allowedHosts = printf "%s, %s" $allowedHosts $svcAlias2 -}}
  {{- $allowedHosts = printf "%s, %s" $allowedHosts $svcAlias3 -}}
  {{- $allowedHosts = printf "%s, %s" $allowedHosts $svcAlias4 -}}

  {{- if and .Values.ingress.enabled .Values.ingress.hostname -}}
    {{- $allowedHosts = printf "%s, %s" $allowedHosts .Values.ingress.hostname -}}
  {{- end -}}

  {{- if .Values.http.hostValidation.allowedHosts -}}
    {{- $allowedHosts = printf "%s, %s" $allowedHosts .Values.http.hostValidation.allowedHosts -}}
  {{- end -}}

  {{- print $allowedHosts | nospace -}}
{{- end -}}

{{- define "eric-sec-access-mgmt.securityPolicy.annotations" }}
  {{- $securityPolicy := dict -}}
  {{- $_ := set $securityPolicy "ericsson.com/security-policy.name" "restricted/default" -}}
  {{- $_ := set $securityPolicy "ericsson.com/security-policy.privileged" "false" -}}
  {{- $_ := set $securityPolicy "ericsson.com/security-policy.capabilities" "N/A" -}}
  {{- $common := include "eric-sec-access-mgmt.common-annotations" . | fromYaml -}}
  {{- include "eric-sec-access-mgmt.mergeAnnotations" (dict "location" (.Template.Name) "sources" (list $securityPolicy $common)) | trim }}
{{- end -}}

{{- define "eric-sec-access-mgmt.IAMintCACertPath" }}/run/secrets/iam-int-ca-cert-path{{- end }}
{{- define "eric-sec-access-mgmt.probeCliCertPath" }}/run/secrets/iam-probe-cli-cert{{- end }}
{{- define "eric-sec-access-mgmt.iamIntCliCertPath" }}/run/secrets/iam-int-cli-cert{{- end }}
{{- define "eric-sec-access-mgmt.pmServerCACertPath" }}/run/secrets/pm-server-ca-cert{{- end }}
## <START> Delete below after the deprecation ends: ADPPRG-66120
{{- define "eric-sec-access-mgmt.iamClientCACertPath" }}/run/secrets/iam-client-ca-cert{{- end }}
## <END>
{{- define "eric-sec-access-mgmt.iamClientCACertPath1" }}/run/secrets/iam-client-ca-cert-1{{- end }}

{{/*
Writable emptyDir volume definitions for files that need write access in the iam-init, iam and authProxy containers.
*/}}
{{- define "eric-sec-access-mgmt.initRunDirSafeMountPath" }}/opt/iam/rundir-safe{{- end }}
{{- define "eric-sec-access-mgmt.runDirSafeMountPath" }}/opt/jboss/rundir-safe{{- end }}
{{- define "eric-sec-access-mgmt.tempDirMountPath" }}/tmp{{- end }}
{{- define "eric-sec-access-mgmt.authProxyRunDirSafeMountPath" }}/rundir-safe{{- end }}
{{- define "eric-sec-access-mgmt.sipoauth2RunDirMountPath" }}/rundir{{- end }}

# DR-D1125-056-AD - Declaration of access to peer services
{{- define "eric-sec-access-mgmt.peerServiceAccess" -}}
{{ .Values.persistence.dbHost }}-access: "true"
{{ template "eric-sec-access-mgmt.name" . }}-access: "true"
{{ .Values.keyManagement.server }}-access: "true"
{{ .Values.ldap.server }}-access: "true"
{{- end -}}

# DR-D1125-056-AD - Declaration of access to peer services
{{- define "eric-sec-access-mgmt.peerServiceAccess.sipoauth2" -}}
eric-sec-access-mgmt-access: "true"
{{- end -}}

{{/*
terminationGracePeriodSeconds for iam statefulset. .Values.terminationGracePeriodSeconds is deprecated (ADPPRG-81960)
If set, use .Values.terminationGracePeriodSeconds.iam, otherwise .Values.terminationGracePeriodSeconds.
*/}}
{{- define "eric-sec-access-mgmt.terminationGracePeriodSeconds.iam" -}}
  {{- if kindIs "map" .Values.terminationGracePeriodSeconds -}}
    {{- if hasKey .Values.terminationGracePeriodSeconds "iam" -}}
      {{.Values.terminationGracePeriodSeconds.iam }}
    {{- else -}}
      {{.Values.terminationGracePeriodSeconds }}
    {{- end }}
  {{- else -}}
    {{.Values.terminationGracePeriodSeconds }}
  {{- end }}
{{- end }}

{{/*
terminationGracePeriodSeconds for sipoauth2 deployment. .Values.terminationGracePeriodSeconds is deprecated (ADPPRG-81960)
If set, use .Values.terminationGracePeriodSeconds.sipoauth2, otherwise otherwise .Values.terminationGracePeriodSeconds.
*/}}
{{- define "eric-sec-access-mgmt.terminationGracePeriodSeconds.sipoauth2" -}}
  {{- if kindIs "map" .Values.terminationGracePeriodSeconds -}}
    {{- if hasKey .Values.terminationGracePeriodSeconds "sipoauth2" -}}
      {{.Values.terminationGracePeriodSeconds.sipoauth2 }}
    {{- else -}}
      {{.Values.terminationGracePeriodSeconds }}
    {{- end }}
  {{- else -}}
    {{.Values.terminationGracePeriodSeconds }}
  {{- end }}
{{- end }}

{{/*
updateStrategy.type for iam statefulset. .Values.updateStrategy.type is deprecated (ADPPRG-81960)
If set, use .Values.updateStrategy.iam.type, otherwise .Values.updateStrategy.type.
*/}}
{{- define "eric-sec-access-mgmt.updateStrategy.iam" -}}
  {{- if hasKey .Values.updateStrategy "type" -}}
    {{.Values.updateStrategy.type }}
  {{- else -}}
    {{.Values.updateStrategy.iam.type }}
  {{- end }}
{{- end }}

{{/*
Create a merged set of nodeSelectors from global, stateful and service level.
*/}}
{{ define "eric-sec-access-mgmt.nodeSelector" }}
  {{- $global := (.Values.global).nodeSelector -}}
  {{- $service := .Values.nodeSelector -}}
  {{- $context := "eric-sec-access-mgmt.nodeSelector" -}}
  {{- include "eric-sec-access-mgmt.aggregatedMerge" (dict "context" $context "location" .Template.Name "sources" (list $global $service)) | trim -}}
{{ end }}

{{/*
Create a merged set of nodeSelectors from global and service level. Local helm parameter nodeSelector has been deprecated and
replaced with nodeSelector.iam (ADPPRG-81960)
*/}}
{{ define "eric-sec-access-mgmt.nodeSelector.iam" }}
  {{- $global := fromJson (include "eric-sec-access-mgmt.global" .) -}}
  {{- if hasKey .Values.nodeSelector "iam" -}}
    {{- if .Values.nodeSelector.iam -}}
      {{- range $key, $localValue := .Values.nodeSelector.iam -}}
        {{- if hasKey $global.nodeSelector $key -}}
            {{- $globalValue := index $global.nodeSelector $key -}}
            {{- if ne $globalValue $localValue -}}
              {{- printf "nodeSelector \"%s\" is specified in both global (%s: %s) and service level (%s: %s) with differing values which is not allowed." $key $key $globalValue $key $localValue | fail -}}
            {{- end -}}
        {{- end -}}
      {{- end -}}
      {{- toYaml (merge $global.nodeSelector .Values.nodeSelector.iam) | trim -}}
    {{- else -}}
      {{- toYaml $global.nodeSelector | trim -}}
    {{- end -}}
  {{- else if .Values.nodeSelector -}}
    {{- $temp := omit .Values.nodeSelector "sipoauth2" -}}
    {{- range $key, $localValue := $temp -}}
      {{- if hasKey $global.nodeSelector $key -}}
          {{- $globalValue := index $global.nodeSelector $key -}}
          {{- if ne $globalValue $localValue -}}
            {{- printf "nodeSelector \"%s\" is specified in both global (%s: %s) and service level (%s: %s) with differing values which is not allowed." $key $key $globalValue $key $localValue | fail -}}
          {{- end -}}
      {{- end -}}
    {{- end -}}
    {{- toYaml (merge $global.nodeSelector $temp) | trim -}}
  {{- else -}}
    {{- toYaml $global.nodeSelector | trim -}}
  {{- end -}}
{{ end }}

{{/*
Create a merged set of nodeSelectors from global and service level for sipoauth2.
*/}}
{{ define "eric-sec-access-mgmt.nodeSelector.sipoauth2" }}
  {{- $global := fromJson (include "eric-sec-access-mgmt.global" .) -}}
  {{- if hasKey .Values.nodeSelector "sipoauth2" -}}
    {{- if .Values.nodeSelector.sipoauth2 -}}
      {{- range $key, $localValue := .Values.nodeSelector.sipoauth2 -}}
        {{- if hasKey $global.nodeSelector $key -}}
            {{- $globalValue := index $global.nodeSelector $key -}}
            {{- if ne $globalValue $localValue -}}
              {{- printf "nodeSelector \"%s\" is specified in both global (%s: %s) and service level (%s: %s) with differing values which is not allowed." $key $key $globalValue $key $localValue | fail -}}
            {{- end -}}
        {{- end -}}
      {{- end -}}
      {{- toYaml (merge $global.nodeSelector .Values.nodeSelector.sipoauth2) | trim -}}
    {{- else -}}
      {{- toYaml $global.nodeSelector | trim -}}
    {{- end -}}
  {{- else -}}
    {{- toYaml $global.nodeSelector | trim -}}
  {{- end -}}
{{ end }}

{{/*
Logshipper annotations
*/}}
{{- define "eric-sec-access-mgmt.logshipper-annotations" }}
{{- println "" -}}
{{- include "eric-sec-access-mgmt.common-annotations" . -}}
{{- end }}