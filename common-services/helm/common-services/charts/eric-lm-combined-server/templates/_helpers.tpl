{{/* vim: set filetype=mustache: */}}

{{ define "eric-lm-combined-server.global" }}
  {{- $globalDefaults := dict "log" (dict "outputs" (list "k8sLevel")) -}}
  {{ if .Values.global }}
    {{- mergeOverwrite $globalDefaults .Values.global | toJson -}}
  {{ else }}
    {{- $globalDefaults | toJson -}}
  {{ end }}
{{ end }}

{{/*
Expand the name of the chart.
*/}}
{{- define "eric-lm-combined-server.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create chart version as used by the chart label.
*/}}
{{- define "eric-lm-combined-server.chart-version" -}}
{{- printf "%s" .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "eric-lm-combined-server.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Add common kubernetes labels
*/}}
{{- define "eric-lm-combined-server.labels" -}}
app.kubernetes.io/name: {{ include "eric-lm-combined-server.name" . | quote }}
app.kubernetes.io/version: {{ include "eric-lm-combined-server.chart-version" . | quote }}
app.kubernetes.io/instance : {{ .Release.Name }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
helm.sh/chart: {{ include "eric-lm-combined-server.chart" . }}
{{- if .Values.labels }}
{{ toYaml .Values.labels }}
{{- end -}}
{{- end -}}

{{/*
Add common LCH kubernetes labels
*/}}
{{- define "eric-lm-combined-server.lch-labels" -}}
{{ include "eric-lm-combined-server.labels" . }}
eric.lm.component/name: "license-consumer-handler"
{{- end -}}

{{/*
Add common LCH kubernetes selector labels
*/}}
{{- define "eric-lm-combined-server.lch-selector-labels" -}}
app.kubernetes.io/name: {{ include "eric-lm-combined-server.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
eric.lm.component/name: "license-consumer-handler"
{{- end -}}

{{/*
Add common LSC kubernetes labels
*/}}
{{- define "eric-lm-combined-server.lsc-labels" -}}
{{ include "eric-lm-combined-server.labels" . }}
eric.lm.component/name: "license-server-client"
{{- end -}}

{{/*
Add common LSC kubernetes selector labels
*/}}
{{- define "eric-lm-combined-server.lsc-selector-labels" -}}
app.kubernetes.io/name: {{ include "eric-lm-combined-server.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
eric.lm.component/name: "license-server-client"
{{- end -}}

{{/*
Add Ericsson product information annotations
*/}}
{{- define "eric-lm-combined-server.product-info" -}}
ericsson.com/product-name: {{ (fromYaml (.Files.Get "eric-product-info.yaml")).productName | quote }}
ericsson.com/product-number: {{ (fromYaml (.Files.Get "eric-product-info.yaml")).productNumber | quote }}
ericsson.com/product-revision: 5.0.0
{{- end -}}

{{/*
Set Ericsson product information and additional annotations
*/}}
{{- define "eric-lm-combined-server.annotations" -}}
{{- include "eric-lm-combined-server.product-info" . }}
{{- if .Values.annotations }}
{{ toYaml .Values.annotations }}
{{- end }}
{{- end -}}

{{/*
Add image pull secrets
Expects all registry credentials to be contained in a single secret.
See DR-D1123-115 for secret format
*/}}
{{- define "eric-lm-combined-server.pullSecrets" -}}
{{- if .Values.imageCredentials.pullSecret -}}
- name: {{ .Values.imageCredentials.pullSecret }}
{{ else if .Values.global -}}
{{- if .Values.global.pullSecret -}}
- name: {{ .Values.global.pullSecret }}
{{ end -}}
{{- end -}}
{{- end -}}

{{/*
Global image registry url
*/}}
{{- define "eric-lm-combined-server.global.registry.url" -}}
{{- $url := "451278531435.dkr.ecr.us-east-1.amazonaws.com" -}}
{{- if .Values.global -}}
    {{- if .Values.global.registry -}}
        {{- if .Values.global.registry.url -}}
            {{- $url = .Values.global.registry.url -}}
        {{- end -}}
    {{- end -}}
{{- end -}}
{{- print $url -}}
{{- end -}}

{{/*
Global image registry pullPolicy
*/}}
{{- define "eric-lm-combined-server.global.registry.imagePullPolicy" -}}
{{- $pullPolicy := "IfNotPresent" -}}
{{- if .Values.global -}}
    {{- if .Values.global.registry -}}
        {{- if .Values.global.registry.imagePullPolicy -}}
            {{- $pullPolicy = .Values.global.registry.imagePullPolicy -}}
        {{- end -}}
    {{- end -}}
{{- end -}}
{{- print $pullPolicy -}}
{{- end -}}


{{/*
The database migration image ref (DR-D1121-067)
*/}}
{{- define "eric-lm-combined-server.migration-image-ref" }}
    {{- $productInfo := fromYaml (.Files.Get "eric-product-info.yaml") -}}
    {{- $registryUrl := $productInfo.images.databaseMigration.registry -}}
    {{- $repoPath := $productInfo.images.databaseMigration.repoPath -}}
    {{- $name := $productInfo.images.databaseMigration.name -}}
    {{- $tag := $productInfo.images.databaseMigration.tag -}}
    {{- if .Values.global -}}
        {{- if .Values.global.registry -}}
            {{- if .Values.global.registry.url -}}
                {{- $registryUrl = .Values.global.registry.url -}}
            {{- end -}}
        {{- end -}}
    {{- end -}}
    {{- if .Values.imageCredentials -}}
         {{- if .Values.imageCredentials.registry.url -}}
                {{- $registryUrl = .Values.imageCredentials.registry.url -}}
         {{- end -}}
         {{- if not (kindIs "invalid" .Values.imageCredentials.repoPath) -}}
            {{- $repoPath = .Values.imageCredentials.repoPath -}}
         {{- end -}}
         {{- if (index .Values "imageCredentials" "eric-lm-database-migration") -}}
            {{- if (index .Values "imageCredentials" "eric-lm-database-migration" "registry") -}}
                {{- if (index .Values "imageCredentials" "eric-lm-database-migration" "registry" "url") -}}
                    {{- $registryUrl = (index .Values "imageCredentials" "eric-lm-database-migration" "registry" "url") -}}
                {{- end -}}
            {{- end -}}
            {{- if not (kindIs "invalid" (index .Values "imageCredentials" "eric-lm-database-migration" "repoPath")) -}}
                {{- $repoPath = (index .Values "imageCredentials" "eric-lm-database-migration" "repoPath") -}}
            {{- end -}}
        {{- end -}}
    {{- end -}}
    {{- if $repoPath -}}
        {{- $repoPath = printf "%s/" $repoPath -}}
    {{- end -}}
    {{- printf "%s/%s%s:%s" $registryUrl $repoPath $name $tag -}}
{{- end -}}


{{/*
Create database-migration image pullpolicy
*/}}
{{- define "eric-lm-combined-server.migration-image-pullPolicy" -}}
{{- if (index .Values "imageCredentials" "eric-lm-database-migration" "registry" "imagePullPolicy") -}}
{{ index .Values "imageCredentials" "eric-lm-database-migration" "registry" "imagePullPolicy" }}
{{- else if .Values.imageCredentials.registry.imagePullPolicy -}}
{{- .Values.imageCredentials.registry.imagePullPolicy -}}
{{- else -}}
{{ include "eric-lm-combined-server.global.registry.imagePullPolicy" . }}
{{- end -}}
{{- end -}}


{{/*
The lch image ref (DR-D1121-067)
*/}}
{{- define "eric-lm-combined-server.lch-image-ref" }}
    {{- $productInfo := fromYaml (.Files.Get "eric-product-info.yaml") -}}
    {{- $registryUrl := $productInfo.images.lch.registry -}}
    {{- $repoPath := $productInfo.images.lch.repoPath -}}
    {{- $name := $productInfo.images.lch.name -}}
    {{- $tag := $productInfo.images.lch.tag -}}
    {{- if .Values.global -}}
        {{- if .Values.global.registry -}}
            {{- if .Values.global.registry.url -}}
                {{- $registryUrl = .Values.global.registry.url -}}
            {{- end -}}
        {{- end -}}
    {{- end -}}
    {{- if .Values.imageCredentials -}}
         {{- if .Values.imageCredentials.registry.url -}}
                {{- $registryUrl = .Values.imageCredentials.registry.url -}}
         {{- end -}}
         {{- if not (kindIs "invalid" .Values.imageCredentials.repoPath) -}}
            {{- $repoPath = .Values.imageCredentials.repoPath -}}
         {{- end -}}
         {{- if (index .Values "imageCredentials" "eric-lm-license-consumer-handler") -}}
            {{- if (index .Values "imageCredentials" "eric-lm-license-consumer-handler" "registry") -}}
                {{- if (index .Values "imageCredentials" "eric-lm-license-consumer-handler" "registry" "url") -}}
                    {{- $registryUrl = (index .Values "imageCredentials" "eric-lm-license-consumer-handler" "registry" "url") -}}
                {{- end -}}
            {{- end -}}
            {{- if not (kindIs "invalid" (index .Values "imageCredentials" "eric-lm-license-consumer-handler" "repoPath")) -}}
                {{- $repoPath = (index .Values "imageCredentials" "eric-lm-license-consumer-handler" "repoPath") -}}
            {{- end -}}
        {{- end -}}
    {{- end -}}
    {{- if $repoPath -}}
        {{- $repoPath = printf "%s/" $repoPath -}}
    {{- end -}}
    {{- printf "%s/%s%s:%s" $registryUrl $repoPath $name $tag -}}
{{- end -}}


{{/*
Create LCH image pullpolicy
*/}}
{{- define "eric-lm-combined-server.lch-image-pullPolicy" -}}
{{- if (index .Values "imageCredentials" "eric-lm-license-consumer-handler" "registry" "imagePullPolicy") -}}
{{ index .Values "imageCredentials" "eric-lm-license-consumer-handler" "registry" "imagePullPolicy" }}
{{- else if .Values.imageCredentials.registry.imagePullPolicy -}}
{{- .Values.imageCredentials.registry.imagePullPolicy -}}
{{- else -}}
{{ include "eric-lm-combined-server.global.registry.imagePullPolicy" . }}
{{- end -}}
{{- end -}}


{{/*
The lsc image ref (DR-D1121-067)
*/}}
{{- define "eric-lm-combined-server.lsc-image-ref" }}
    {{- $productInfo := fromYaml (.Files.Get "eric-product-info.yaml") -}}
    {{- $registryUrl := $productInfo.images.lsc.registry -}}
    {{- $repoPath := $productInfo.images.lsc.repoPath -}}
    {{- $name := $productInfo.images.lsc.name -}}
    {{- $tag := $productInfo.images.lsc.tag -}}
    {{- if .Values.global -}}
        {{- if .Values.global.registry -}}
            {{- if .Values.global.registry.url -}}
                {{- $registryUrl = .Values.global.registry.url -}}
            {{- end -}}
        {{- end -}}
    {{- end -}}
    {{- if .Values.imageCredentials -}}
         {{- if .Values.imageCredentials.registry.url -}}
                {{- $registryUrl = .Values.imageCredentials.registry.url -}}
         {{- end -}}
         {{- if not (kindIs "invalid" .Values.imageCredentials.repoPath) -}}
            {{- $repoPath = .Values.imageCredentials.repoPath -}}
         {{- end -}}
         {{- if (index .Values "imageCredentials" "eric-lm-license-server-client") -}}
            {{- if (index .Values "imageCredentials" "eric-lm-license-server-client" "registry") -}}
                {{- if (index .Values "imageCredentials" "eric-lm-license-server-client" "registry" "url") -}}
                    {{- $registryUrl = (index .Values "imageCredentials" "eric-lm-license-server-client" "registry" "url") -}}
                {{- end -}}
            {{- end -}}
            {{- if not (kindIs "invalid" (index .Values "imageCredentials" "eric-lm-license-server-client" "repoPath")) -}}
                {{- $repoPath = (index .Values "imageCredentials" "eric-lm-license-server-client" "repoPath") -}}
            {{- end -}}
        {{- end -}}
    {{- end -}}
    {{- if $repoPath -}}
        {{- $repoPath = printf "%s/" $repoPath -}}
    {{- end -}}
    {{- printf "%s/%s%s:%s" $registryUrl $repoPath $name $tag -}}
{{- end -}}


{{/*
Create LSC image pullpolicy
*/}}
{{- define "eric-lm-combined-server.lsc-image-pullPolicy" -}}
{{- if (index .Values "imageCredentials" "eric-lm-license-server-client" "registry" "imagePullPolicy") -}}
{{ index .Values "imageCredentials" "eric-lm-license-server-client" "registry" "imagePullPolicy" }}
{{- else if .Values.imageCredentials.registry.imagePullPolicy -}}
{{- .Values.imageCredentials.registry.imagePullPolicy -}}
{{- else -}}
{{ include "eric-lm-combined-server.global.registry.imagePullPolicy" . }}
{{- end -}}
{{- end -}}

{{/*
Creates the base JDBC url, without query parameters
*/}}
{{- define "eric-lm-combined-server.database-base-jdbc-url" -}}
{{ printf "%s://%s:%.0f/%s" (include "eric-lm-combined-server.database-protocol" .) .Values.database.host .Values.database.port .Values.database.name }}
{{- end -}}

{{/*
Creates the base PSQL url, without query parameters
*/}}
{{- define "eric-lm-combined-server.database-base-psql-url" -}}
{{ printf "postgresql://postgres:@%s:%.0f" .Values.database.host .Values.database.port }}
{{- end -}}

{{/*
Add database url with JDBC protocol
*/}}
{{- define "eric-lm-combined-server.database-jdbc-url" -}}
{{- $queryParams := dict -}}
{{- $_ := set $queryParams "loginTimeout" "60" -}}
{{- $_ := set $queryParams "socketTimeout" "60" -}}
{{- printf "%s?%s" (include "eric-lm-combined-server.database-base-jdbc-url" .) (include "eric-lm-combined-server.assemble-query-string" $queryParams) -}}
{{- end -}}

{{/*
Add database url without JDBC protocol
*/}}
{{- define "eric-lm-combined-server.database-url" -}}
{{ printf "%s:%.0f/%s" .Values.database.host .Values.database.port .Values.database.name }}
{{- end -}}

{{/*
Creates a URI query string from the passed dict
*/}}
{{- define "eric-lm-combined-server.assemble-query-string" -}}
  {{- $isStart := true -}}
  {{- range $key, $value := . -}}
    {{- if eq $isStart true -}}
      {{- $isStart = false -}}
      {{- printf "%s=%s" $key $value -}}
    {{- else -}}
      {{- printf "&%s=%s" $key $value -}}
    {{- end -}}
  {{- end -}}
{{- end -}}

{{/*
Database Migration DB JDBC TLS url
*/}}
{{- define "eric-lm-combined-server.db-migration.tls.database-jdbc-url" -}}
{{- $queryParams := dict -}}
{{- $_ := set $queryParams "loginTimeout" "60" -}}
{{- $_ := set $queryParams "socketTimeout" "60" -}}
{{- $_ := set $queryParams "ssl" "true" -}}
{{- $_ := set $queryParams "sslmode" .Values.tls.db.sslMode -}}
{{- $_ := set $queryParams "sslrootcert" "/opt/flyway/sipTlsRootCerts/cacertbundle.pem" -}}
{{- $_ := set $queryParams "sslkey" (printf "/opt/DatabaseMigration/certs/%s" (include "eric-lm-combined-server.db.client-cert.key-file" .)) -}}
{{- $_ := set $queryParams "sslcert" (printf "/opt/DatabaseMigration/certs/%s" (include "eric-lm-combined-server.db.client-cert.cert-file" .)) -}}
{{- printf "%s?%s" (include "eric-lm-combined-server.database-base-jdbc-url" .) (include "eric-lm-combined-server.assemble-query-string" $queryParams) -}}
{{- end -}}

{{/*
Database Migration DB TLS url
*/}}
{{- define "eric-lm-combined-server.db-migration.tls.database-url" -}}
{{- $queryParams := dict -}}
{{- $_ := set $queryParams "ssl" "true" -}}
{{- $_ := set $queryParams "sslmode" .Values.tls.db.sslMode -}}
{{- $_ := set $queryParams "sslrootcert" "/opt/flyway/sipTlsRootCerts/cacertbundle.pem" -}}
{{- $_ := set $queryParams "sslkey" (printf "/opt/DatabaseMigration/certs/%s" (include "eric-lm-combined-server.db.client-cert.key-file" .)) -}}
{{- $_ := set $queryParams "sslcert" (printf "/opt/DatabaseMigration/certs/%s" (include "eric-lm-combined-server.db.client-cert.cert-file" .)) -}}
{{- printf "%s?%s" (include "eric-lm-combined-server.database-url" .) (include "eric-lm-combined-server.assemble-query-string" $queryParams) -}}
{{- end -}}

{{/*
Database TLS url for PSQL command
*/}}
{{- define "eric-lm-combined-server.tls.database-psql-url" -}}
{{- $queryParams := dict -}}
{{- $_ := set $queryParams "ssl" "true" -}}
{{- $_ := set $queryParams "sslmode" .Values.tls.db.sslMode -}}
{{- $_ := set $queryParams "sslrootcert" "/opt/flyway/sipTlsRootCerts/cacertbundle.pem" -}}
{{- $_ := set $queryParams "sslkey" (printf "/tmp/%s" (include "eric-lm-combined-server.db.admin-cert.pem-key-file" .)) -}}
{{- $_ := set $queryParams "sslcert" (printf "/opt/DatabaseMigration/adminCerts/%s" (include "eric-lm-combined-server.db.admin-cert.cert-file" .)) -}}
{{- printf "%s?%s" (include "eric-lm-combined-server.database-base-psql-url" .) (include "eric-lm-combined-server.assemble-query-string" $queryParams) -}}
{{- end -}}

{{/*
LCH DB JDBC TLS url
*/}}
{{- define "eric-lm-combined-server.lch.tls.database-jdbc-url" -}}
{{- $queryParams := dict -}}
{{- $_ := set $queryParams "loginTimeout" "60" -}}
{{- $_ := set $queryParams "socketTimeout" "60" -}}
{{- $_ := set $queryParams "ssl" "true" -}}
{{- $_ := set $queryParams "sslmode" .Values.tls.db.sslMode -}}
{{- $_ := set $queryParams "sslrootcert" "/opt/LicenseConsumerHandler/sipTlsRootCerts/cacertbundle.pem" -}}
{{- $_ := set $queryParams "sslkey" (printf "/opt/LicenseConsumerHandler/database/certs/%s" (include "eric-lm-combined-server.db.client-cert.key-file" .)) -}}
{{- $_ := set $queryParams "sslcert" (printf "/opt/LicenseConsumerHandler/database/certs/%s" (include "eric-lm-combined-server.db.client-cert.cert-file" .)) -}}
{{- printf "%s?%s" (include "eric-lm-combined-server.database-base-jdbc-url" .) (include "eric-lm-combined-server.assemble-query-string" $queryParams) -}}
{{- end -}}

{{/*
LSC database TLS url with JDBC protocol
*/}}
{{- define "eric-lm-combined-server.lsc.tls.database-jdbc-url" -}}
{{- $queryParams := dict -}}
{{- $_ := set $queryParams "loginTimeout" "60" -}}
{{- $_ := set $queryParams "socketTimeout" "60" -}}
{{- $_ := set $queryParams "ssl" "true" -}}
{{- $_ := set $queryParams "sslmode" .Values.tls.db.sslMode -}}
{{- $_ := set $queryParams "sslrootcert" "/opt/LicenseServerClient/sipTlsRootCerts/cacertbundle.pem" -}}
{{- $_ := set $queryParams "sslkey" (printf "/opt/LicenseServerClient/database/certs/%s" (include "eric-lm-combined-server.db.client-cert.key-file" .)) -}}
{{- $_ := set $queryParams "sslcert" (printf "/opt/LicenseServerClient/database/certs/%s" (include "eric-lm-combined-server.db.client-cert.cert-file" .)) -}}
{{- printf "%s?%s" (include "eric-lm-combined-server.database-base-jdbc-url" .) (include "eric-lm-combined-server.assemble-query-string" $queryParams) -}}
{{- end -}}

{{/*
Creates a semi-colon separated list of "productType,customerId,swltId" from the license domain information
*/}}
{{- define "eric-lm-combined-server.lsc-license-domains" -}}
{{- if .Values.global -}}
    {{- if .Values.global.ericsson -}}
        {{- if .Values.global.ericsson.licensing -}}
            {{- if .Values.global.ericsson.licensing.licenseDomains -}}
                {{- $licenseDomains := .Values.global.ericsson.licensing.licenseDomains -}}
                {{- range $i, $licenseDomain := $licenseDomains -}}
                {{- if $i -}};{{- end -}}
                {{- $licenseDomain.productType }},{{ $licenseDomain.customerId }},{{ $licenseDomain.swltId -}}
                {{- end -}}
            {{- end -}}
        {{- end -}}
    {{- end -}}
{{- end -}}
{{- end -}}


{{/*
Set IANA Timezone
*/}}
{{- define "eric-lm-combined-server.timezone" -}}
{{- $timezone := "UTC" -}}
{{- if .Values.global -}}
    {{- if .Values.global.timezone -}}
        {{- $timezone = .Values.global.timezone -}}
    {{- end -}}
{{- end -}}
{{- print $timezone -}}
{{- end -}}

{{/*
Set LCH nodeSelector
*/}}
{{- define "eric-lm-combined-server.nodeSelector.licenseConsumerHandler" -}}
{{- $nodeSelector := dict -}}
{{- if .Values.global -}}
    {{- if .Values.global.nodeSelector -}}
        {{- $nodeSelector = .Values.global.nodeSelector -}}
    {{- end -}}
{{- end -}}
{{- if .Values.nodeSelector -}}
    {{- if .Values.nodeSelector.licenseConsumerHandler -}}
        {{- range $key, $localValue := .Values.nodeSelector.licenseConsumerHandler -}}
            {{- if hasKey $nodeSelector $key -}}
                {{- $globalValue := index $nodeSelector $key -}}
                {{- if ne $globalValue $localValue -}}
                    {{- printf "nodeSelector \"%s\" is specified in both global (%s: %s) and service level (%s: %s) with differing values which is not allowed." $key $key $globalValue $key $localValue | fail -}}
                {{- end -}}
            {{- end -}}
        {{- end -}}
        {{- $nodeSelector = merge $nodeSelector .Values.nodeSelector.licenseConsumerHandler -}}
    {{- end -}}
{{- end -}}
{{- if $nodeSelector -}}
    {{- toYaml $nodeSelector | indent 8 | trim -}}
{{- end -}}
{{- end -}}

{{/*
Set LSC nodeSelector
*/}}
{{- define "eric-lm-combined-server.nodeSelector.licenseServerClient" -}}
{{- $nodeSelector := dict -}}
{{- if .Values.global -}}
    {{- if .Values.global.nodeSelector -}}
        {{- $nodeSelector = .Values.global.nodeSelector -}}
    {{- end -}}
{{- end -}}
{{- if .Values.nodeSelector -}}
    {{- if .Values.nodeSelector.licenseServerClient -}}
        {{- range $key, $localValue := .Values.nodeSelector.licenseServerClient -}}
            {{- if hasKey $nodeSelector $key -}}
                {{- $globalValue := index $nodeSelector $key -}}
                {{- if ne $globalValue $localValue -}}
                    {{- printf "nodeSelector \"%s\" is specified in both global (%s: %s) and service level (%s: %s) with differing values which is not allowed." $key $key $globalValue $key $localValue | fail -}}
                {{- end -}}
            {{- end -}}
        {{- end -}}
        {{- $nodeSelector = merge $nodeSelector .Values.nodeSelector.licenseServerClient -}}
    {{- end -}}
{{- end -}}
{{- if $nodeSelector -}}
    {{- toYaml $nodeSelector | indent 8 | trim -}}
{{- end -}}
{{- end -}}

{{/*
Define RoleBinding value, "true" or "false"
*/}}
{{- define "eric-lm-combined-server.roleBinding" -}}
{{- $roleBinding := false -}}
{{- if .Values.global -}}
    {{- if .Values.global.security -}}
        {{- if .Values.global.security.policyBinding -}}
            {{- if hasKey .Values.global.security.policyBinding "create" -}}
                {{- $roleBinding = .Values.global.security.policyBinding.create -}}
            {{- end -}}
        {{- end -}}
    {{- end -}}
{{- end -}}
{{- print $roleBinding -}}
{{- end -}}

{{/*
Define reference to SecurityPolicy
*/}}
{{- define "eric-lm-combined-server.securityPolicy.reference" -}}
{{- $policyreference := "default-restricted-security-policy" -}}
{{- if .Values.global -}}
    {{- if .Values.global.security -}}
        {{- if .Values.global.security.policyReferenceMap -}}
            {{- if hasKey .Values.global.security.policyReferenceMap "default-restricted-security-policy" -}}
               {{- $policyreference = index .Values "global" "security" "policyReferenceMap" "default-restricted-security-policy" -}}
            {{- end -}}
        {{- end -}}
    {{- end -}}
{{- end -}}
{{- print $policyreference -}}
{{- end -}}

{{/*
Service-specific TLS is enabled or not
*/}}
{{- define "eric-lm-combined-server.tls.enabled" -}}
{{/* If the global.security.tls.enabled is not set, it is assumed to be true */}}
{{- $enabled := true -}}
{{/* Get the global.security.tls.enabled value */}}
{{- if .Values.global -}}
    {{- if .Values.global.security -}}
        {{- if .Values.global.security.tls -}}
            {{- if hasKey .Values.global.security.tls "enabled" -}}
                {{- $enabled = .Values.global.security.tls.enabled -}}
            {{- end -}}
        {{- end -}}
    {{- end -}}
{{- end -}}
{{- print $enabled -}}
{{- end -}}

{{/*
Set TLS client authentication preference
*/}}
{{- define "eric-lm-combined-server.tls.clientAuthentication" -}}
{{- $authentication := "requested" -}}
{{- if eq .Values.licenseConsumerHandler.service.endpoints.externalHttps.tls.verifyClientCertificate "required" -}}
    {{- $authentication = "required" -}}
{{- end -}}
{{- if eq (include "eric-lm-combined-server.tls.enabled" .) "false" -}}
    {{- $authentication = "none" -}}
{{- end -}}
{{- print $authentication -}}
{{- end -}}

{{/*
Database TLS is enabled or not
*/}}
{{- define "eric-lm-combined-server.db.tls.enabled" -}}
{{- $enabled := true -}}
{{/* Get the global.security.tls.enabled value */}}
{{- if .Values.global -}}
    {{- if .Values.global.security -}}
        {{- if .Values.global.security.tls -}}
            {{- if hasKey .Values.global.security.tls "enabled" -}}
                {{- $enabled = .Values.global.security.tls.enabled -}}
            {{- end -}}
        {{- end -}}
    {{- end -}}
{{- end -}}
{{/* The below endpoint specific configuration can be used as local overrides of the global ‘true’ configuration */}}
{{- if $enabled -}}
    {{- if eq .Values.database.tls.enforced "optional" -}}
        {{- $enabled = false -}}
    {{- end -}}
{{- end -}}
{{- print $enabled -}}
{{- end -}}

{{/*
Get the name of the Postgres DB Provider's Client CA
*/}}
{{- define "eric-lm-combined-server.db.client-ca-name" -}}
{{ printf "%s-client-ca" .Values.database.host }}
{{- end -}}

{{/*
Set Database Certificate Secret name
*/}}
{{- define "eric-lm-combined-server.db.client-certificate-name" -}}
{{ include "eric-lm-combined-server.name" . }}-db-cert
{{- end -}}

{{/*
Get the name of the postgres admin user's CA
*/}}
{{- define "eric-lm-combined-server.db.admin-ca-name" -}}
{{ printf "%s-db-admin-ca" .Values.database.host }}
{{- end -}}

{{/*
Set Database Certificate Secret name for postgres admin user
*/}}
{{- define "eric-lm-combined-server.db.admin-certificate-name" -}}
{{ include "eric-lm-combined-server.name" . }}-db-admin-cert
{{- end -}}

{{/*
Set LCH REST API server certificate name
*/}}
{{- define "eric-lm-combined-server.lch.server-certificate-name" -}}
{{ include "eric-lm-combined-server.name" . }}-server-cert
{{- end -}}

{{/*
Set name of the CA responsible for signing LCH REST API client certificates
*/}}
{{- define "eric-lm-combined-server.lch.client-ca-name" -}}
{{ include "eric-lm-combined-server.name" . }}-client-ca
{{- end -}}

{{/*
Set the ADP LM ingress certificate name
*/}}
{{- define "eric-lm-combined-server.lch.ingress-certificate-name" -}}
{{ include "eric-lm-combined-server.name" . }}-ingress-cert
{{- end -}}

{{/*
Set the ADP LM ingress name
*/}}
{{- define "eric-lm-combined-server.lch.ingress-name" -}}
{{ include "eric-lm-combined-server.name" . }}-ingress
{{- end -}}

{{/*
ASIH TLS is enabled or not
*/}}
{{- define "eric-lm-combined-server.asih.tls.enabled" -}}
{{- $enabled := true -}}
{{/* Get the global.security.tls.enabled value */}}
{{- if .Values.global -}}
    {{- if .Values.global.security -}}
        {{- if .Values.global.security.tls -}}
            {{- if hasKey .Values.global.security.tls "enabled" -}}
                {{- $enabled = .Values.global.security.tls.enabled -}}
            {{- end -}}
        {{- end -}}
    {{- end -}}
{{- end -}}
{{/* The below endpoint specific configuration can be used as local overrides of the global ‘true’ configuration */}}
{{- if $enabled -}}
    {{- if hasKey .Values.licenseServerClient.asih "tls" -}}
        {{- $enabled = .Values.licenseServerClient.asih.tls -}}
    {{- end -}}
{{- end -}}
{{- print $enabled -}}
{{- end -}}

{{/*
Set ASIH Client Certificate Secret name
*/}}
{{- define "eric-lm-combined-server.asih.client-certificate-name" -}}
{{ include "eric-lm-combined-server.name" . }}-asih-cert
{{- end -}}
