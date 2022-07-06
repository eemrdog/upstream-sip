{{/* vim: set filetype=mustache: */}}
{{- define "eric-fh-alarm-handler.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create chart version as used by the kubernetes label.
*/}}
{{- define "eric-fh-alarm-handler.version" -}}
{{- printf "%s" .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "eric-fh-alarm-handler.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Ericsson product information
The annotations are compliant with: DR-HC-064
*/}}
{{- define "eric-fh-alarm-handler.product-info" }}
ericsson.com/product-name: {{ (fromYaml (.Files.Get "eric-product-info.yaml")).productName | quote }}
ericsson.com/product-number: {{ (fromYaml (.Files.Get "eric-product-info.yaml")).productNumber | quote }}
ericsson.com/product-revision: {{ regexReplaceAll "[\\-\\+].+" .Chart.Version "${1}" }}
{{- end -}}

{{/*
Custom annotations set by application engineer
*/}}
{{- define "eric-fh-alarm-handler.custom-annotations" }}
{{- if .Values.annotations }}
{{ toYaml .Values.annotations }}
{{- end }}
{{- end -}}

{{/*
Annotations containing both product info and custom annotations
*/}}
{{- define "eric-fh-alarm-handler.annotations" }}
{{- template "eric-fh-alarm-handler.product-info" . }}
{{- template "eric-fh-alarm-handler.custom-annotations" . }}
{{- template "eric-fh-alarm-handler.roleBinding.annotations" . -}}
{{- end -}}

{{/*
Annotations for security-policy
*/}}
{{- define "eric-fh-alarm-handler.roleBinding.annotations" }}
ericsson.com/security-policy.type: "restricted/default"
ericsson.com/security-policy.capabilities: ""
{{- end -}}

{{/*
The eric-fh-alarm-handler image path (DR-D1121-067)
*/}}
{{- define "eric-fh-alarm-handler.imagePath" }}
    {{- $productInfo := fromYaml (.Files.Get "eric-product-info.yaml") -}}
    {{- $registryUrl := index $productInfo "images" "alarmhandler" "registry" -}}
    {{- $repoPath := index $productInfo "images" "alarmhandler" "repoPath" -}}
    {{- $name := index $productInfo "images" "alarmhandler" "name" -}}
    {{- $tag := index $productInfo "images" "alarmhandler" "tag" -}}
    {{- if .Values.global -}}
        {{- if .Values.global.registry -}}
            {{- if .Values.global.registry.url -}}
                {{- $registryUrl = .Values.global.registry.url -}}
            {{- end -}}
        {{- end -}}
    {{- end -}}
    {{- if .Values.imageCredentials -}}
        {{- if index .Values "imageCredentials" "alarmhandler" -}}
            {{- if index .Values "imageCredentials" "alarmhandler" "registry" -}}
                {{- if index .Values "imageCredentials" "alarmhandler" "registry" "url" -}}
                    {{- $registryUrl = index .Values "imageCredentials" "alarmhandler" "registry" "url" -}}
                {{- end -}}
            {{- end -}}
            {{- if not (kindIs "invalid" (index .Values "imageCredentials" "alarmhandler" "repoPath")) -}}
                {{- $repoPath = index .Values "imageCredentials" "alarmhandler" "repoPath" -}}
            {{- end -}}    
        {{- end -}}
        {{- if index .Values "imageCredentials" "eric-fh-alarm-handler" -}}
            {{- if index .Values "imageCredentials" "eric-fh-alarm-handler" "registry" -}}
                {{- if index .Values "imageCredentials" "eric-fh-alarm-handler" "registry" "url" -}}
                    {{- $registryUrl = index .Values "imageCredentials" "eric-fh-alarm-handler" "registry" "url" -}}
                {{- end -}}
            {{- end -}}
            {{- if not (kindIs "invalid" (index .Values "imageCredentials" "eric-fh-alarm-handler" "repoPath")) -}}
                {{- $repoPath = index .Values "imageCredentials" "eric-fh-alarm-handler" "repoPath" -}}
            {{- end -}}
        {{- end -}}
    {{- end -}}
    {{- if $repoPath -}}
        {{- $repoPath = printf "%s/" $repoPath -}}
    {{- end -}}
    {{- printf "%s/%s%s:%s" $registryUrl $repoPath $name $tag -}}
{{- end -}}

{{/*
The topic-creator image path (DR-D1121-067)
*/}}
{{- define "eric-fh-alarm-handler.initImagePath" }}
    {{- $productInfo := fromYaml (.Files.Get "eric-product-info.yaml") -}}
    {{- $registryUrl := index $productInfo "images" "topiccreator" "registry" -}}
    {{- $repoPath := index $productInfo "images" "topiccreator" "repoPath" -}}
    {{- $name := index $productInfo "images" "topiccreator" "name" -}}
    {{- $tag := index $productInfo "images" "topiccreator" "tag" -}}
    {{- if .Values.global -}}
        {{- if .Values.global.registry -}}
            {{- if .Values.global.registry.url -}}
                {{- $registryUrl = .Values.global.registry.url -}}
            {{- end -}}
        {{- end -}}
    {{- end -}}
    {{- if .Values.imageCredentials -}}
        {{- if index .Values "imageCredentials" "topiccreator" -}}
            {{- if index .Values "imageCredentials" "topiccreator" "registry" -}}
                {{- if index .Values "imageCredentials" "topiccreator" "registry" "url" -}}
                    {{- $registryUrl = index .Values "imageCredentials" "topiccreator" "registry" "url" -}}
                {{- end -}}
            {{- end -}}
            {{- if not (kindIs "invalid" (index .Values "imageCredentials" "topiccreator" "repoPath")) -}}
                {{- $repoPath = index .Values "imageCredentials" "topiccreator" "repoPath" -}}
            {{- end -}}
        {{- end -}}
        {{- if index .Values "imageCredentials" "topic-creator" -}}
            {{- if index .Values "imageCredentials" "topic-creator" "registry" -}}
                {{- if index .Values "imageCredentials" "topic-creator" "registry" "url" -}}
                    {{- $registryUrl = index .Values "imageCredentials" "topic-creator" "registry" "url" -}}
                {{- end -}}
            {{- end -}}
            {{- if not (kindIs "invalid" (index .Values "imageCredentials" "topic-creator" "repoPath")) -}}
                {{- $repoPath = index .Values "imageCredentials" "topic-creator" "repoPath" -}}
            {{- end -}}
        {{- end -}}
    {{- end -}}
    {{- if $repoPath -}}
        {{- $repoPath = printf "%s/" $repoPath -}}
    {{- end -}}
    {{- printf "%s/%s%s:%s" $registryUrl $repoPath $name $tag -}}
{{- end -}}

{{/*
Create resources fragment.
*/}}
{{- define "eric-fh-alarm-handler.resources.alarmhandler" -}}
{{- $resources := index .Values "resources" "alarmhandler" -}}
{{- toYaml $resources -}}
{{- end -}}

{{- define "eric-fh-alarm-handler.resources.topiccreator" -}}
{{- $resources := index .Values "resources" "topiccreator" -}}
{{- toYaml $resources -}}
{{- end -}}

{{/*
Create image pull secret
*/}}
{{- define "eric-fh-alarm-handler.pullSecrets" -}}
{{- $pullSecret := "" -}}
{{- if .Values.global -}}
    {{- if .Values.global.pullSecret -}}
            {{- $pullSecret = .Values.global.pullSecret -}}
    {{- end -}}
{{- end -}}
{{- if .Values.imageCredentials -}}
    {{- if .Values.imageCredentials.pullSecret -}}
            {{- $pullSecret = .Values.imageCredentials.pullSecret -}}
    {{- end -}}
{{- end -}}
{{- print $pullSecret -}}
{{- end -}}

{{/*
Create pull policy for eric-fh-alarm-handler
*/}}
{{- define "eric-fh-alarm-handler.ImagePullPolicy" -}}
{{- $imagePullPolicy := "IfNotPresent" -}}
{{- if .Values.global -}}
    {{- if .Values.global.registry -}}
        {{- if .Values.global.registry.imagePullPolicy -}}
            {{- $imagePullPolicy = .Values.global.registry.imagePullPolicy -}}
        {{- end -}}
    {{- end -}}
{{- end -}}
{{- if .Values.imageCredentials -}}
    {{- if index .Values "imageCredentials" "alarmhandler" "registry" -}}
        {{- if index .Values "imageCredentials" "alarmhandler" "registry" "imagePullPolicy" -}}
            {{- $imagePullPolicy = index .Values "imageCredentials" "alarmhandler" "registry" "imagePullPolicy" -}}
        {{- end -}}
    {{- end -}}
{{- if index .Values "imageCredentials" "eric-fh-alarm-handler" -}}
        {{- if index .Values "imageCredentials" "eric-fh-alarm-handler" "registry" -}}
            {{- if index .Values "imageCredentials" "eric-fh-alarm-handler" "registry" "imagePullPolicy" -}}
                {{- $imagePullPolicy = index .Values "imageCredentials" "eric-fh-alarm-handler" "registry" "imagePullPolicy" -}}
            {{- end -}}
        {{- end -}}
    {{- end -}}
{{- end -}}
{{- print $imagePullPolicy -}}
{{- end -}}

{{/*
Create pull policy for topic-creator
*/}}
{{- define "eric-fh-alarm-handler.initImagePullPolicy" -}}
{{- $imagePullPolicy := "IfNotPresent" -}}
{{- if .Values.global -}}
    {{- if .Values.global.registry -}}
        {{- if .Values.global.registry.imagePullPolicy -}}
            {{- $imagePullPolicy = .Values.global.registry.imagePullPolicy -}}
        {{- end -}}
    {{- end -}}
{{- end -}}
{{- if .Values.imageCredentials -}}
    {{- if index .Values "imageCredentials" "topiccreator" "registry" -}}
        {{- if index .Values "imageCredentials" "topiccreator" "registry" "imagePullPolicy" -}}
            {{- $imagePullPolicy = index .Values "imageCredentials" "topiccreator" "registry" "imagePullPolicy" -}}
        {{- end -}}
    {{- end -}}
    {{- if index .Values "imageCredentials" "topic-creator" -}}
        {{- if index .Values "imageCredentials" "topic-creator" "registry" -}}
            {{- if index .Values "imageCredentials" "topic-creator" "registry" "imagePullPolicy" -}}
                {{- $imagePullPolicy = index .Values "imageCredentials" "topic-creator" "registry" "imagePullPolicy" -}}
            {{- end -}}
        {{- end -}}
    {{- end -}}
{{- end -}}
{{- print $imagePullPolicy -}}
{{- end -}}


{{/*
Define timezone
*/}}
{{- define "eric-fh-alarm-handler.timezone" -}}
{{- $timezone := "UTC" -}}
{{- if .Values.global -}}
    {{- if .Values.global.timezone -}}
        {{- $timezone = .Values.global.timezone -}}
    {{- end -}}
{{- end -}}
{{- print $timezone | quote -}}
{{- end -}}


{{/*
Define filepath to file which will be watched for log level changes
*/}}
{{- define "eric-fh-alarm-handler.logcontrol" -}}
{{- print "/home/service/logcontrol.json" | quote -}}
{{- end -}}


{{/*
Define nodeSelector
*/}}
{{- define "eric-fh-alarm-handler.nodeSelector" -}}
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
Define logRedirect
Mapping between log.outputs and logshipper redirect parameter
*/}}
{{- define "eric-fh-alarm-handler.logRedirect" -}}
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
Define logOutputsBoth
Env variable used when both stdout and stream outputs should be used
*/}}
{{- define "eric-fh-alarm-handler.logOutputsBoth" -}}
{{- $logOutputsBoth := "false" -}}
{{- if .Values.log -}}
        {{- if .Values.log.outputs -}}
            {{- if (and (has "stream" .Values.log.outputs) (has "stdout" .Values.log.outputs)) -}}
                {{- $logOutputsBoth = "true" -}}
            {{- end -}}
        {{- end -}}
{{- end -}}
{{- print $logOutputsBoth -}}
{{- end -}}

{{/*
Define podAntiAffinity
*/}}
{{- define "eric-fh-alarm-handler.podAntiAffinity" -}}
{{- if eq .Values.affinity.podAntiAffinity "hard" -}}
requiredDuringSchedulingIgnoredDuringExecution:
- labelSelector:
    matchExpressions:
    - key: app
      operator: In
      values:
      - {{ template "eric-fh-alarm-handler.name" . }}
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
        - {{ template "eric-fh-alarm-handler.name" . }}
    topologyKey: "kubernetes.io/hostname"
{{- end -}}
{{- end -}}

{{/* Name of log level config map */}}
{{- define "eric-fh-alarm-handler.logLevel.ConfigmapName" }}
    {{- template "eric-fh-alarm-handler.name" . }}-loglevel
{{- end }}

{{/* Folder where the log level configmap will be mounted */}}
{{- define "eric-fh-alarm-handler.loglevel.mountFolder" }}
    {{- printf "%s" "/home/service/log" -}}
{{- end }}

{{/* Folder where the (emptyDir) memory storage will be mounted in topic creator */}}
{{- define "eric-fh-alarm-handler.memoryStorage.mountFolderTopicCreator" }}
    {{- printf "%s" "/memstore" -}}
{{- end }}

{{/* Folder where the (emptyDir) memory storage will be mounted in topic creator */}}
{{- define "eric-fh-alarm-handler.memoryStorage.mountFolderAlarmHandler" }}
    {{- printf "%s" "/memstoreroot" -}}
{{- end }}

{{/* If the FI API is enabled */}}
{{- define "eric-fh-alarm-handler.rest.fi.api.enabled" }}
    {{- eq (.Values.alarmhandler.rest.fi.api.enabled | toString) "true" -}}
{{- end }}

{{/* FI HTTP listening port */}}
{{- define "eric-fh-alarm-handler.rest.fi.server.httpPort" }}
    {{- printf "%d" 6005 -}}
{{- end }}

{{/* FI HTTPS listening tls port */}}
{{- define "eric-fh-alarm-handler.rest.fi.server.httpsPort" }}
    {{- printf "%d" 6006 -}}
{{- end }}

{{/* If the FI API HTTP is enabled */}}
{{- define "eric-fh-alarm-handler.fiAPI.httpEnabled" }}
    {{- if eq (include "eric-fh-alarm-handler.rest.fi.api.enabled" .) "true" -}}
        {{- $tls := (include "eric-fh-alarm-handler.tls.enabled" .) -}}
        {{- or (eq $tls "false") (eq (.Values.service.endpoints.fiapi.tls.enforced | toString) "optional") -}}
    {{- else }}
        {{- printf "false" -}}
    {{- end }}
{{- end }}

{{/* If the FI API HTTPS is enabled */}}
{{- define "eric-fh-alarm-handler.fiAPI.httpsEnabled" }}
    {{- $tls := (include "eric-fh-alarm-handler.tls.enabled" .) -}}
    {{- and (eq (include "eric-fh-alarm-handler.rest.fi.api.enabled" .) "true") (eq $tls "true") -}}
{{- end }}

{{/* Set KAFKA_ASI_WRITER_ENABLED based on the value of alarmhandler.asi.writer */}}
{{- define "eric-fh-alarm-handler.kafkaAsiWriterEnabled" }}
    {{- eq (.Values.alarmhandler.asi.writer | toString | lower ) "kafka" -}}
{{- end }}

{{/* Set REDIS_WRITER_ENABLED based on the value of alarmhandler.asi.writer */}}
{{- define "eric-fh-alarm-handler.redisAsiWriterEnabled" }}
    {{- eq (.Values.alarmhandler.asi.writer | toString | lower ) "redis" -}}
{{- end }}

{{/* Set KAFKA_ENABLED to true if alamhandler.asi.writer=kafka or kafka.fiReaderEnabled is set to true*/}}
{{- define "eric-fh-alarm-handler.kafkaEnabled" }}
    {{- (or (eq (.Values.kafka.fiReaderEnabled | toString ) "true") (eq (include "eric-fh-alarm-handler.kafkaAsiWriterEnabled" .) "true")) -}}
{{- end }}

{{/*----------------------------------------------------------------*/}}
{{/*----- Methods for defining mount folders for certificates-------*/}}
{{/*----------------------------------------------------------------*/}}

{{/* Folder where the FI REST API CA certificate will be mounted to */}}
{{- define "eric-fh-alarm-handler.fiAPI.client.ca.cert.mountFolder" }}
    {{- printf "%s" "/var/run/secrets/fiapi-client-ca-cert" -}}
{{- end }}

{{/* Folder where the FI REST API server certificate will be mounted to */}}
{{- define "eric-fh-alarm-handler.fiAPI.server.cert.mountFolder" }}
    {{- printf "%s" "/var/run/secrets/fiapi-server-cert" -}}
{{- end }}

{{/* Folder where the FI REST API client certificate will be mounted to */}}
{{- define "eric-fh-alarm-handler.fiAPI.client.cert.mountFolder" }}
    {{- printf "%s" "/var/run/secrets/fiapi-client-cert" -}}
{{- end }}

{{/* Folder where the root certificate will be mounted */}}
{{- define "eric-fh-alarm-handler.siptls.root.cert.mountFolderInit" }}
    {{- printf "%s" "/etc/sip-tls-ca" -}}
{{- end }}


{{/* Folder where the kafka client certificate will be mounted */}}
{{- define "eric-fh-alarm-handler.kafka.client.cert.mountFolderInit" }}
    {{- printf "%s" "/etc/sip-tls-kafka" -}}
{{- end }}

{{/* Folder where the root certificate will be mounted */}}
{{- define "eric-fh-alarm-handler.siptls.root.cert.mountFolder" }}
    {{- printf "%s" "/var/run/secrets/siptls-root" -}}
{{- end }}

{{/* Folder where the CA Cert used by restapi will be mounted to */}}
{{- define "eric-fh-alarm-handler.client.ca.cert.mountFolder" }}
    {{- printf "%s" "/var/run/secrets/client-ca-cert" -}}
{{- end }}

{{/* Folder where the restapi server certificates will be mounted */}}
{{- define "eric-fh-alarm-handler.restapi.server.cert.mountFolder" }}
    {{- printf "%s" "/var/run/secrets/restapi-server-cert" -}}
{{- end }}

{{/* Folder where the AH client certificate will be mounted */}}
{{- define "eric-fh-alarm-handler.client.cert.mountFolder" }}
    {{- printf "%s" "/var/run/secrets/client-cert" -}}
{{- end }}

{{/* Folder where the kafka client certificate will be mounted */}}
{{- define "eric-fh-alarm-handler.kafka.client.cert.mountFolder" }}
    {{- printf "%s" "/var/run/secrets/sip-tls-kafka" -}}
{{- end }}

{{/* Folder where the Redis client certificate will be mounted */}}
{{- define "eric-fh-alarm-handler.redis.client.cert.mountFolder" }}
    {{- printf "%s" "/var/run/secrets/sip-tls-redis" -}}
{{- end}}

{{/* Folder where the PG client certificates will be mounted */}}
{{- define "eric-fh-alarm-handler.pg.client.cert.mountFolder" }}
    {{- printf "%s" "/var/run/secrets/pg-client-cert" -}}
{{- end }}

{{/* Folder where the PG admin certificates will be mounted */}}
{{- define "eric-fh-alarm-handler.pg.admin.cert.mountFolder" }}
    {{- printf "%s" "/var/run/secrets/pg-admin-cert" -}}
{{- end }}

{{/* Folder where the metrics client certificates will be mounted */}}
{{- define "eric-fh-alarm-handler.metrics.client.cacert.mountFolder" }}
    {{- printf "%s" "/var/run/secrets/metrics-client-cacert" -}}
{{- end }}

{{/* Folder where the metrics server certificates will be mounted */}}
{{- define "eric-fh-alarm-handler.metrics.server.cert.mountFolder" }}
    {{- printf "%s" "/var/run/secrets/metrics-server-cert" -}}
{{- end }}

{{/* Folder where the probes server certificates will be mounted */}}
{{- define "eric-fh-alarm-handler.probes.server.cert.mountFolder" }}
    {{- printf "%s" "/var/run/secrets/probes-server-cert" -}}
{{- end }}


{{/*----------------------------------------------------------------*/}}
{{/*----Methods for defining paths to certificates------------------*/}}
{{/*----------------------------------------------------------------*/}}

{{/* SIP TLS root certificate mount path*/}}
{{- define "eric-fh-alarm-handler.siptls.root.certPath" }}
    {{- printf "%s/%s" (include "eric-fh-alarm-handler.siptls.root.cert.mountFolder" .) "cacertbundle.pem" -}}
{{- end }}

{{/* Path to the Client CA Cert */}}
{{- define "eric-fh-alarm-handler.client.cacertPath" }}
    {{- printf "%s/%s" (include "eric-fh-alarm-handler.client.ca.cert.mountFolder" .) "client-cacertbundle.pem" -}}
{{- end }}

{{/* Path to the restapi server certificate */}}
{{- define "eric-fh-alarm-handler.restapi.server.certPath" }}
    {{- printf "%s/%s" (include "eric-fh-alarm-handler.restapi.server.cert.mountFolder" .) "srvcert.pem" -}}
{{- end }}

{{/* Path to the restapi server private key */}}
{{- define "eric-fh-alarm-handler.restapi.server.keyPath" }}
    {{- printf "%s/%s" (include "eric-fh-alarm-handler.restapi.server.cert.mountFolder" .) "srvprivkey.pem" -}}
{{- end }}

{{/* Path to the FI REST API client CA certificate */}}
{{- define "eric-fh-alarm-handler.fiAPI.client.cacertPath" }}
    {{- printf "%s/%s" (include "eric-fh-alarm-handler.fiAPI.client.ca.cert.mountFolder" .) "client-ca.pem" -}}
{{- end }}

{{/* Path to the FI REST API server certificate */}}
{{- define "eric-fh-alarm-handler.fiAPI.server.certPath" }}
    {{- printf "%s/%s" (include "eric-fh-alarm-handler.fiAPI.server.cert.mountFolder" .) "cert.pem" -}}
{{- end }}

{{/* Path to the FI REST API server certificate private key */}}
{{- define "eric-fh-alarm-handler.fiAPI.server.keyPath" }}
    {{- printf "%s/%s" (include "eric-fh-alarm-handler.fiAPI.server.cert.mountFolder" .) "privkey.pem" -}}
{{- end }}

{{/* Path to the PG client certificate */}}
{{- define "eric-fh-alarm-handler.pg.client.certPath" }}
    {{- printf "%s/%s" (include "eric-fh-alarm-handler.pg.client.cert.mountFolder" .) "clicert.pem" -}}
{{- end }}

{{/* Path to the PG client private key */}}
{{- define "eric-fh-alarm-handler.pg.client.keyPath" }}
    {{- printf "%s/%s" (include "eric-fh-alarm-handler.pg.client.cert.mountFolder" .) "cliprivkey.pem" -}}
{{- end }}

{{/* Path to the Redis client certificate */}}
{{- define "eric-fh-alarm-handler.redis.client.certPath" }}
    {{- printf "%s/%s" (include "eric-fh-alarm-handler.redis.client.cert.mountFolder" .) "clicert-redis.pem" -}}
{{- end}}

{{/* Path to the Redis client private key */}}
{{- define "eric-fh-alarm-handler.redis.client.keyPath" }}
    {{- printf "%s/%s" (include "eric-fh-alarm-handler.redis.client.cert.mountFolder" .) "cliprivkey-redis.pem" -}}
{{- end}}

{{/* Path to the PM Server Client CA Cert */}}
{{- define "eric-fh-alarm-handler.metrics.client.cacertPath" }}
    {{- printf "%s/%s" (include "eric-fh-alarm-handler.metrics.client.cacert.mountFolder" .) "client-cacertbundle.pem" -}}
{{- end }}

{{/* Path to the metrics server certificate */}}
{{- define "eric-fh-alarm-handler.metrics.server.certPath" }}
    {{- printf "%s/%s" (include "eric-fh-alarm-handler.metrics.server.cert.mountFolder" .) "cert.pem" -}}
{{- end }}

{{/* Path to the metrics server private key */}}
{{- define "eric-fh-alarm-handler.metrics.server.keyPath" }}
    {{- printf "%s/%s" (include "eric-fh-alarm-handler.metrics.server.cert.mountFolder" .) "key.pem" -}}
{{- end }}

{{/* Path to the probes server certificate */}}
{{- define "eric-fh-alarm-handler.probes.server.certPath" }}
    {{- printf "%s/%s" (include "eric-fh-alarm-handler.probes.server.cert.mountFolder" .) "cert.pem" -}}
{{- end }}

{{/* Path to the probes server private key */}}
{{- define "eric-fh-alarm-handler.probes.server.keyPath" }}
    {{- printf "%s/%s" (include "eric-fh-alarm-handler.probes.server.cert.mountFolder" .) "key.pem" -}}
{{- end }}


{{/*----------------------------------------------------------------*/}}
{{/*-----Methods for defining secret names holding certificates-----*/}}
{{/*----------------------------------------------------------------*/}}

{{/* Name of the secret holding the FI API client CA secret */}}
{{- define "eric-fh-alarm-handler.fiAPI.client.ca.secretname" }}
    {{- printf "%s-%s" (include "eric-fh-alarm-handler.name" .) "fi-server-client-ca-secret" -}}
{{- end }}

{{/* Name of the secret holding the FI API server secret */}}
{{- define "eric-fh-alarm-handler.fiAPI.server.secretname" }}
    {{- printf "%s-%s" (include "eric-fh-alarm-handler.name" .) "fi-server-secret" -}}
{{- end }}

{{/* Name of the secret holding the FI API client secret */}}
{{- define "eric-fh-alarm-handler.fiAPI.client.secretname" }}
    {{- printf "%s-%s" (include "eric-fh-alarm-handler.name" .) "fi-server-client-secret" -}}
{{- end }}

{{/* Name of the secret holding the restapi server certificate */}}
{{- define "eric-fh-alarm-handler.restapi.server.secretname" }}
    {{- printf "%s-%s" (include "eric-fh-alarm-handler.name" .) "tls-server-secret" -}}
{{- end }}

{{/* Name of the secret holding SIP-TLS CA */}}
{{- define "eric-fh-alarm-handler.tls.trusted.cacert.secretname" }}
    {{- printf "%s" "eric-sec-sip-tls-trusted-root-cert" -}}
{{- end }}

{{/* Name of the secret holding the AH tls client secret */}}
{{- define "eric-fh-alarm-handler.client.secretname" }}
    {{- printf "%s-%s" (include "eric-fh-alarm-handler.name" .) "tls-client-secret" -}}
{{- end }}

{{/* Name of the secret holding the AH tls CA secret */}}
{{- define "eric-fh-alarm-handler.client.ca.secretname" }}
    {{- printf "%s-%s" (include "eric-fh-alarm-handler.name" .) "tls-client-ca-secret" -}}
{{- end }}

{{/* Name of the secret holding the Kafka client certificate */}}
{{- define "eric-fh-alarm-handler.kafka.client.secretname" }}
    {{- printf "%s-%s" (include "eric-fh-alarm-handler.name" .) "tls-kafka-client-secret" -}}
{{- end }}

{{/* Name of the secret holding the Redis client certificate */}}
{{- define "eric-fh-alarm-handler.redis.client.secretname" }}
    {{- printf "%s-%s" (include "eric-fh-alarm-handler.name" .) "tls-redis-client-secret" -}}
{{- end }}

{{/* Name of the secret holding Redis ACL username and password */}}
{{- define "eric-fh-alarm-handler.redis.acl.secretname" }}
    {{- printf "%s-secret-%s" .Values.redis.hostname .Values.redis.acl.user -}}
{{- end }}

{{/* Name of the secret holding the PG client certificate */}}
{{- define "eric-fh-alarm-handler.pg.client.secretname" }}
    {{- printf "%s-%s" (include "eric-fh-alarm-handler.name" .) "document-db-tls-client-secret" -}}
{{- end }}

{{/* Name of the secret holding the PG admin certificate */}}
{{- define "eric-fh-alarm-handler.pg.admin.secretname" }}
    {{- printf "%s-%s" (include "eric-fh-alarm-handler.name" .) "document-db-tls-admin-secret" -}}
{{- end }}

{{/* Name of the secret holding the metrics server certificate */}}
{{- define "eric-fh-alarm-handler.metrics.server.certSecret" }}
    {{- printf "%s-%s" (include "eric-fh-alarm-handler.name" .) "metrics-server-cert" -}}
{{- end }}

{{/* Name of the secret holding the probes server certificate */}}
{{- define "eric-fh-alarm-handler.probes.server.certSecret" }}
    {{- printf "%s-%s" (include "eric-fh-alarm-handler.name" .) "probes-server-cert" -}}
{{- end }}

{/*----------------------------------------------------------------*/}}
{{/*-----Functions (including helpers) related to deprecations-----*/}}
{{/*---------------------------------------------------------------*/}}

{{/* Deprecation notices */}}
{{/* Remember to clean this section occasionally */}}
{{- define "eric-fh-alarm-handler.deprecation.notices" }}
  {{- if .Values.alarmhandler.kafkaLogLevel }}
    {{- printf "'alarmhandler.kafkaLogLevel' is deprecated as of release 7.2.0, the input value will be discarded.\n" }}
  {{- end }}
  {{- if .Values.resources.alarmhandlerrest }}
    {{- if .Values.resources.alarmhandlerrest.requests }}
      {{- range $key, $_ := .Values.resources.alarmhandlerrest.requests }}
        {{- printf "'resources.alarmhandlerrest.requests.%s' is deprecated as of release 7.1.0, the highest value between this and 'resources.alarmhandler.requests.%s' will be used.\n" $key $key }}
      {{- end }}
    {{- end }}
    {{- if .Values.resources.alarmhandlerrest.limits }}
      {{- range $key, $_ := .Values.resources.alarmhandlerrest.limits }}
        {{- printf "'resources.alarmhandlerrest.limits.%s' is deprecated as of release 7.1.0, the highest value between this and 'resources.alarmhandler.limits.%s' will be used.\n" $key $key }}
      {{- end }}
    {{- end }}
  {{- end }}
  {{- if (index .Values "imageCredentials" "eric-fh-alarm-handler-rest") }}
    {{- if (index .Values "imageCredentials" "eric-fh-alarm-handler-rest" "registry") }}
      {{- range $k, $_ := (index .Values "imageCredentials" "eric-fh-alarm-handler-rest" "registry") }}
        {{- printf "'imageCredentials.eric-fh-alarm-handler-rest.%s' is deprecated as of release 7.1.0, the input value will be discarded.\n" $k }}
      {{- end }}
    {{- end }}
    {{- if (index .Values "imageCredentials" "eric-fh-alarm-handler-rest" "repoPath") }}
      {{- printf "'imageCredentials.eric-fh-alarm-handler-rest.repoPath' is deprecated as of release 7.1.0, the input value will be discarded.\n" }}
    {{- end }}
  {{- end }}
  {{- if (index .Values "images") }}
    {{- if (index .Values "images" "eric-fh-alarm-handler-rest") }}
      {{- range $k, $_ := (index .Values "images" "eric-fh-alarm-handler-rest") }}
        {{- printf "'images.eric-fh-alarm-handler-rest.%s' is deprecated as of release 7.1.0, the input value will be discarded.\n" $k }}
      {{- end }}
    {{- end }}
  {{- end }}
  {{- if .Values.readinessProbe.logshipper }}
    {{- range $k, $_ := (index .Values.readinessProbe.logshipper) }}
      {{- printf "'readinessProbe.logshipper.%s' is deprecated as of release 7.2.0, the input value will be discarded.\n" $k }}
    {{- end }}
  {{- end }}
{{- end }}

{{/* Merges resources for alarmhandler and alarmhandlerrest (deprecated). Selects alarmhandler resource if alarmhandlerrest not set - otherwise selects the largest of the two */}}
{{- define "eric-fh-alarm-handler.resources.alarmhandler.merged" -}}
  {{- $ahRestResources := index .Values "resources" "alarmhandlerrest" -}}
  {{- $ahResources := index .Values "resources" "alarmhandler" -}}
  {{- $mergedResources := dict "requests" dict "limits" dict -}}
  {{- range tuple "requests" "limits" -}}
    {{- $tempDict := dict -}}
    {{- $resource := . -}}
    {{- range tuple "cpu" "memory" "ephemeral-storage" -}}
      {{- $type := . -}}
      {{- if empty (index $.Values "resources" "alarmhandlerrest") -}}
        {{- $_ := set $tempDict $type (index $ahResources $resource $type) }}
      {{- else -}}
        {{- if empty (index $.Values "resources" "alarmhandlerrest" $resource) -}}
          {{- $_ := set $tempDict $type (index $ahResources $resource $type) }}
        {{- else -}}
          {{- $_ := set $tempDict $type (include "eric-fh-alarm-handler.util.select.largest.value" (dict "arg1" (index $ahResources $resource $type) "arg2" (index $ahRestResources $resource $type))) -}}
        {{- end -}}
      {{- end -}}
    {{- end -}}
  {{- $_ := set $mergedResources $resource $tempDict -}}
  {{- end -}}
  {{- toYaml $mergedResources -}}
{{- end -}}

{{/* Selects the largest of two resource values. Assumes that both values have same (if any) suffix */}}
{{- define "eric-fh-alarm-handler.util.select.largest.value" -}}
  {{- $arg1 := include "eric-fh-alarm-handler.util.remove.suffix" (dict "arg" .arg1) -}}
  {{- $arg2 := include "eric-fh-alarm-handler.util.remove.suffix" (dict "arg" .arg2) -}}
  {{- if ge ($arg1 | float64) ($arg2 | float64) -}}
    {{- .arg1 -}}
  {{- else -}}
    {{- .arg2 -}}
  {{- end -}}
{{- end -}}

{{/* Remove suffix (if present) in resource values */}}
{{- define "eric-fh-alarm-handler.util.remove.suffix" -}}
  {{ $arg := print .arg }}
  {{- $suffix := regexReplaceAll "[0-9]" $arg "" }}
  {{- if empty $suffix -}}
    {{- $arg -}}
  {{- else -}}
    {{- regexReplaceAll "[A-Za-z]" $arg "" -}}
  {{- end -}}
{{- end -}}
