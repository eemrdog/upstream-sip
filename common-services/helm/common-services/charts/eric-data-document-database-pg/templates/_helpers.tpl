{{/* vim: set filetype=mustache: */}}
{{/*
Expand the name of the chart.
*/}}
{{- define "eric-data-document-database-pg.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}


{{/* If .CapabilitiesKubeVersion.Version is smaller then 1.4.0, what should we do is TBD */}}
{{/*
Return the appropriate apiVersion for networkpolicy.
*/}}
{{- define "eric-data-document-database-pg.networkPolicy.apiVersion" -}}
{{- if and (semverCompare ">=1.4.0-0" .Capabilities.KubeVersion.Version) (semverCompare "<1.7.0-0" .Capabilities.KubeVersion.Version) -}}
"extensions/v1beta1"
{{- else if (semverCompare ">=1.7.0-0" .Capabilities.KubeVersion.Version) -}}
"networking.k8s.io/v1"
{{- end -}}
{{- end -}}


{{ define "eric-data-document-database-pg.global" }}
  {{- $globalDefaults := dict "registry" (dict "url" "451278531435.dkr.ecr.us-east-1.amazonaws.com") -}}
  {{- $globalDefaults := merge $globalDefaults (dict "pullSecret") -}}
  {{- $globalDefaults := merge $globalDefaults (dict "registry" (dict "imagePullPolicy")) -}}
  {{- $globalDefaults := merge $globalDefaults (dict "adpBR" (dict "broServiceName" "eric-ctrl-bro")) -}}
  {{- $globalDefaults := merge $globalDefaults (dict "adpBR" (dict "broGrpcServicePort" "3000")) -}}
  {{- $globalDefaults := merge $globalDefaults (dict "adpBR" (dict "brLabelKey" "adpbrlabelkey")) -}}
  {{- $globalDefaults := merge $globalDefaults (dict "timezone" "UTC") -}}
  {{ if .Values.global }}
    {{- mergeOverwrite $globalDefaults .Values.global | toJson -}}
  {{ else }}
    {{- $globalDefaults | toJson -}}
  {{ end }}
{{ end }}

{{- define "eric-data-document-database-pg.logRedirect" -}}
  {{- if and (has "stream" .Values.log.outputs) (has "stdout" .Values.log.outputs) }}
    {{- "all " -}}
  {{- else if has "stream" .Values.log.outputs }}
    {{- "file " -}}
  {{- else }}
    {{- "stdout " -}}
  {{- end }}
{{- end -}}

{{- define "eric-data-document-database-pg.stdRedirectCMD" -}}
{{ "/usr/local/bin/pipe_fifo.sh "  }}
{{- end -}}


{{/*
Return the mountpath using in the container's volume.
*/}}
{{- define "eric-data-document-database-pg.mountPath" -}}
{{- "/var/lib/postgresql/data" -}}
{{- end -}}

{{/*
Return the mountpath for postgres config dir.
*/}}
{{- define "eric-data-document-database-pg.configPath" -}}
{{- "/var/lib/postgresql/config" -}}
{{- end -}}

{{/*
Return the mountpath for postgres script dir.
*/}}
{{- define "eric-data-document-database-pg.scriptPath" -}}
{{- "/var/lib/postgresql/scripts" -}}
{{- end -}}

{{/*
Return the mountpath for hook script dir.
*/}}
{{- define "eric-data-document-database-pg.hook.scriptPath" -}}
{{- "/var/lib/scripts" -}}
{{- end -}}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "eric-data-document-database-pg.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create image registry url
*/}}
{{- define "eric-data-document-database-pg.registryUrl" -}}
{{- $g := fromJson (include "eric-data-document-database-pg.global" .) -}}
{{- if .Values.imageCredentials.registry.url -}}
{{- print .Values.imageCredentials.registry.url -}}
{{- else -}}
{{- print $g.registry.url -}}
{{- end -}}
{{- end -}}


{{/*
The targetPGversion
*/}}
{{- define "eric-data-document-database-pg.targetPGversion" }}
    {{- if .Values.targetPGversion -}}
        {{- printf (.Values.targetPGversion | toString) -}}
    {{- else -}}
        {{- printf "10" -}}
    {{- end -}}
{{- end -}}

{{/*
The postgresImage path
*/}}
{{- define "eric-data-document-database-pg.postgresImagePath" }}
    {{- $productInfo := fromYaml (.Files.Get "eric-product-info.yaml") -}}
    {{- $registryUrl := $productInfo.images.postgres.registry -}}
    {{- $repoPath := $productInfo.images.postgres.repoPath -}}
    {{- $name := $productInfo.images.postgres.name -}}
    {{- $tag := $productInfo.images.postgres.tag -}}
    {{- if .Values.global -}}
        {{- if .Values.global.registry -}}
            {{- if .Values.global.registry.url -}}
                {{- $registryUrl = .Values.global.registry.url -}}
            {{- end -}}
        {{- end -}}
    {{- end -}}
    {{- if .Values.imageCredentials -}}
        {{- if .Values.imageCredentials.registry -}}
            {{- if .Values.imageCredentials.registry.url -}}
                {{- $registryUrl = .Values.imageCredentials.registry.url -}}
            {{- end -}}
        {{- end -}}
        {{- if not (kindIs "invalid" .Values.imageCredentials.repoPath) -}}
            {{- $repoPath = .Values.imageCredentials.repoPath -}}
        {{- end -}}
    {{- end -}}
    {{- if .Values.images -}}
        {{- if .Values.images.postgres -}}
            {{- if .Values.images.postgres.name -}}
                {{- $name = .Values.images.postgres.name -}}
            {{- end -}}
            {{- if .Values.images.postgres.tag -}}
                {{- $tag = .Values.images.postgres.tag -}}
            {{- end -}}
        {{- end -}}
    {{- end -}}
    {{- if $repoPath -}}
        {{- $repoPath = printf "%s/" $repoPath -}}
    {{- end -}}
    {{- printf "%s/%s%s:%s" $registryUrl $repoPath $name $tag -}}
{{- end -}}

{{/*
The pg13Image path
*/}}
{{- define "eric-data-document-database-pg.pg13ImagePath" }}
    {{- $productInfo := fromYaml (.Files.Get "eric-product-info.yaml") -}}
    {{- $registryUrl := $productInfo.images.pg13.registry -}}
    {{- $repoPath := $productInfo.images.pg13.repoPath -}}
    {{- $name := $productInfo.images.pg13.name -}}
    {{- $tag := $productInfo.images.pg13.tag -}}
    {{- if .Values.global -}}
        {{- if .Values.global.registry -}}
            {{- if .Values.global.registry.url -}}
                {{- $registryUrl = .Values.global.registry.url -}}
            {{- end -}}
        {{- end -}}
    {{- end -}}
    {{- if .Values.imageCredentials -}}
        {{- if .Values.imageCredentials.registry -}}
            {{- if .Values.imageCredentials.registry.url -}}
                {{- $registryUrl = .Values.imageCredentials.registry.url -}}
            {{- end -}}
        {{- end -}}
        {{- if not (kindIs "invalid" .Values.imageCredentials.repoPath) -}}
            {{- $repoPath = .Values.imageCredentials.repoPath -}}
        {{- end -}}
    {{- end -}}
    {{- if .Values.images -}}
        {{- if .Values.images.postgres -}}
            {{- if .Values.images.postgres.name -}}
                {{- $name = .Values.images.postgres.name -}}
            {{- end -}}
            {{- if .Values.images.postgres.tag -}}
                {{- $tag = .Values.images.postgres.tag -}}
            {{- end -}}
        {{- end -}}
    {{- end -}}
    {{- if $repoPath -}}
        {{- $repoPath = printf "%s/" $repoPath -}}
    {{- end -}}
    {{- printf "%s/%s%s:%s" $registryUrl $repoPath $name $tag -}}
{{- end -}}

{{/*
The metricsImage path
*/}}
{{- define "eric-data-document-database-pg.metricsImagePath" }}
    {{- $productInfo := fromYaml (.Files.Get "eric-product-info.yaml") -}}
    {{- $registryUrl := $productInfo.images.metrics.registry -}}
    {{- $repoPath := $productInfo.images.metrics.repoPath -}}
    {{- $name := $productInfo.images.metrics.name -}}
    {{- $tag := $productInfo.images.metrics.tag -}}
    {{- if .Values.global -}}
        {{- if .Values.global.registry -}}
            {{- if .Values.global.registry.url -}}
                {{- $registryUrl = .Values.global.registry.url -}}
            {{- end -}}
        {{- end -}}
    {{- end -}}
    {{- if .Values.imageCredentials -}}
        {{- if .Values.imageCredentials.registry -}}
            {{- if .Values.imageCredentials.registry.url -}}
                {{- $registryUrl = .Values.imageCredentials.registry.url -}}
            {{- end -}}
        {{- end -}}
        {{- if not (kindIs "invalid" .Values.imageCredentials.repoPath) -}}
            {{- $repoPath = .Values.imageCredentials.repoPath -}}
        {{- end -}}
    {{- end -}}
    {{- if .Values.images -}}
        {{- if .Values.images.metrics -}}
            {{- if .Values.images.metrics.name -}}
                {{- $name = .Values.images.metrics.name -}}
            {{- end -}}
            {{- if .Values.images.metrics.tag -}}
                {{- $tag = .Values.images.metrics.tag -}}
            {{- end -}}
        {{- end -}}
    {{- end -}}
    {{- if $repoPath -}}
        {{- $repoPath = printf "%s/" $repoPath -}}
    {{- end -}}
    {{- printf "%s/%s%s:%s" $registryUrl $repoPath $name $tag -}}
{{- end -}}

{{/*
The kubeclientImage path
*/}}
{{- define "eric-data-document-database-pg.kubeclientImagePath" }}
    {{- $productInfo := fromYaml (.Files.Get "eric-product-info.yaml") -}}
    {{- $registryUrl := $productInfo.images.kubeclient.registry -}}
    {{- $repoPath := $productInfo.images.kubeclient.repoPath -}}
    {{- $name := $productInfo.images.kubeclient.name -}}
    {{- $tag := $productInfo.images.kubeclient.tag -}}
    {{- if .Values.global -}}
        {{- if .Values.global.registry -}}
            {{- if .Values.global.registry.url -}}
                {{- $registryUrl = .Values.global.registry.url -}}
            {{- end -}}
        {{- end -}}
    {{- end -}}
    {{- if .Values.imageCredentials -}}
        {{- if .Values.imageCredentials.registry -}}
            {{- if .Values.imageCredentials.registry.url -}}
                {{- $registryUrl = .Values.imageCredentials.registry.url -}}
            {{- end -}}
        {{- end -}}
        {{- if not (kindIs "invalid" .Values.imageCredentials.repoPath) -}}
            {{- $repoPath = .Values.imageCredentials.repoPath -}}
        {{- end -}}
    {{- end -}}
    {{- if .Values.images -}}
        {{- if (index .Values "images" "kube-client") -}}
            {{- if (index .Values "images" "kube-client" "name") -}}
                {{- $name = index .Values "images" "kube-client" "name" -}}
            {{- end -}}
            {{- if (index .Values "images" "kube-client" "tag") -}}
                {{- $tag = index .Values "images" "kube-client" "tag" -}}
            {{- end -}}
        {{- end -}}
    {{- end -}}
    {{- if $repoPath -}}
        {{- $repoPath = printf "%s/" $repoPath -}}
    {{- end -}}
    {{- printf "%s/%s%s:%s" $registryUrl $repoPath $name $tag -}}
{{- end -}}

{{/*
The braImage path
*/}}
{{- define "eric-data-document-database-pg.braImagePath" }}
    {{- $productInfo := fromYaml (.Files.Get "eric-product-info.yaml") -}}
    {{- $registryUrl := $productInfo.images.bra.registry -}}
    {{- $repoPath := $productInfo.images.bra.repoPath -}}
    {{- $name := $productInfo.images.bra.name -}}
    {{- $tag := $productInfo.images.bra.tag -}}
    {{- if .Values.global -}}
        {{- if .Values.global.registry -}}
            {{- if .Values.global.registry.url -}}
                {{- $registryUrl = .Values.global.registry.url -}}
            {{- end -}}
        {{- end -}}
    {{- end -}}
    {{- if .Values.imageCredentials -}}
        {{- if .Values.imageCredentials.registry -}}
            {{- if .Values.imageCredentials.registry.url -}}
                {{- $registryUrl = .Values.imageCredentials.registry.url -}}
            {{- end -}}
        {{- end -}}
        {{- if not (kindIs "invalid" .Values.imageCredentials.repoPath) -}}
            {{- $repoPath = .Values.imageCredentials.repoPath -}}
        {{- end -}}
    {{- end -}}
    {{- if .Values.images -}}
        {{- if .Values.images.bra -}}
            {{- if .Values.images.bra.name -}}
                {{- $name = .Values.images.bra.name -}}
            {{- end -}}
            {{- if .Values.images.bra.tag -}}
                {{- $tag = .Values.images.bra.tag -}}
            {{- end -}}
        {{- end -}}
    {{- end -}}
    {{- if $repoPath -}}
        {{- $repoPath = printf "%s/" $repoPath -}}
    {{- end -}}
    {{- printf "%s/%s%s:%s" $registryUrl $repoPath $name $tag -}}
{{- end -}}

{{/*
The brmImage path
*/}}
{{- define "eric-data-document-database-pg.brmImagePath" }}
    {{- $productInfo := fromYaml (.Files.Get "eric-product-info.yaml") -}}
    {{- $registryUrl := $productInfo.images.brm.registry -}}
    {{- $repoPath := $productInfo.images.brm.repoPath -}}
    {{- $name := $productInfo.images.brm.name -}}
    {{- $tag := $productInfo.images.brm.tag -}}
    {{- if .Values.global -}}
        {{- if .Values.global.registry -}}
            {{- if .Values.global.registry.url -}}
                {{- $registryUrl = .Values.global.registry.url -}}
            {{- end -}}
        {{- end -}}
    {{- end -}}
    {{- if .Values.imageCredentials -}}
        {{- if .Values.imageCredentials.registry -}}
            {{- if .Values.imageCredentials.registry.url -}}
                {{- $registryUrl = .Values.imageCredentials.registry.url -}}
            {{- end -}}
        {{- end -}}
        {{- if not (kindIs "invalid" .Values.imageCredentials.repoPath) -}}
            {{- $repoPath = .Values.imageCredentials.repoPath -}}
        {{- end -}}
    {{- end -}}
    {{- if .Values.images -}}
        {{- if .Values.images.brm -}}
            {{- if .Values.images.brm.name -}}
                {{- $name = .Values.images.brm.name -}}
            {{- end -}}
            {{- if .Values.images.brm.tag -}}
                {{- $tag = .Values.images.brm.tag -}}
            {{- end -}}
        {{- end -}}
    {{- end -}}
    {{- if $repoPath -}}
        {{- $repoPath = printf "%s/" $repoPath -}}
    {{- end -}}
    {{- printf "%s/%s%s:%s" $registryUrl $repoPath $name $tag -}}
{{- end -}}

{{/*
The brm13Image path
*/}}
{{- define "eric-data-document-database-pg.brm13ImagePath" }}
    {{- $productInfo := fromYaml (.Files.Get "eric-product-info.yaml") -}}
    {{- $registryUrl := $productInfo.images.brm13.registry -}}
    {{- $repoPath := $productInfo.images.brm13.repoPath -}}
    {{- $name := $productInfo.images.brm13.name -}}
    {{- $tag := $productInfo.images.brm13.tag -}}
    {{- if .Values.global -}}
        {{- if .Values.global.registry -}}
            {{- if .Values.global.registry.url -}}
                {{- $registryUrl = .Values.global.registry.url -}}
            {{- end -}}
        {{- end -}}
    {{- end -}}
    {{- if .Values.imageCredentials -}}
        {{- if .Values.imageCredentials.registry -}}
            {{- if .Values.imageCredentials.registry.url -}}
                {{- $registryUrl = .Values.imageCredentials.registry.url -}}
            {{- end -}}
        {{- end -}}
        {{- if not (kindIs "invalid" .Values.imageCredentials.repoPath) -}}
            {{- $repoPath = .Values.imageCredentials.repoPath -}}
        {{- end -}}
    {{- end -}}
    {{- if .Values.images -}}
        {{- if .Values.images.brm -}}
            {{- if .Values.images.brm.name -}}
                {{- $name = .Values.images.brm.name -}}
            {{- end -}}
            {{- if .Values.images.brm.tag -}}
                {{- $tag = .Values.images.brm.tag -}}
            {{- end -}}
        {{- end -}}
    {{- end -}}
    {{- if $repoPath -}}
        {{- $repoPath = printf "%s/" $repoPath -}}
    {{- end -}}
    {{- printf "%s/%s%s:%s" $registryUrl $repoPath $name $tag -}}
{{- end -}}

{{/*
Create image repoPath
*/}}
{{- define "eric-data-document-database-pg.repoPath" -}}
{{- if .Values.imageCredentials.repoPath -}}
{{- print "/" .Values.imageCredentials.repoPath "/" -}}
{{- else -}}
{{- print "/" -}}
{{- end -}}
{{- end -}}

{{/*
Create image pull secrets
*/}}
{{- define "eric-data-document-database-pg.pullSecrets" -}}
{{- $g := fromJson (include "eric-data-document-database-pg.global" .) -}}
{{- if .Values.imageCredentials.pullSecret -}}
{{- print .Values.imageCredentials.pullSecret -}}
{{- else -}}
{{- print $g.pullSecret -}}
{{- end -}}
{{- end -}}

{{/*
Create image pull policy
*/}}
{{- define "eric-data-document-database-pg.imagePullPolicy" -}}
{{- $g := fromJson (include "eric-data-document-database-pg.global" .) -}}
{{- if .Values.imageCredentials.registry.imagePullPolicy -}}
{{- print .Values.imageCredentials.registry.imagePullPolicy -}}
{{- else if $g.registry.imagePullPolicy -}}
{{- print $g.registry.imagePullPolicy -}}
{{- else -}}
{{- print "IfNotPresent" -}}
{{- end -}}
{{- end -}}

{{/*
Transit pvc mount path
*/}}
{{- define "eric-data-document-database-pg.transit.mountpath" -}}
{{- "/shipment_data" -}}
{{- end -}}

{{/*
Expand the component of transit pvc.
*/}}
{{- define "eric-data-document-database-pg.transit.component" -}}
{{- "eric-data-document-database-pg-transit" -}}
{{- end -}}

{{/*
Define the default storage class name.
*/}}
{{- define "eric-data-document-database-pg.persistentVolumeClaim.defaultStorageClassName" -}}
{{- if .Values.persistentVolumeClaim.storageClassName}}
{{- print .Values.persistentVolumeClaim.storageClassName -}}
{{- else }}
{{- "" -}}
{{- end }}
{{- end -}}

{{/*
Define the default backup storage class name.
*/}}
{{- define "eric-data-document-database-pg.backup.defaultStorageClassName" -}}
{{- if .Values.persistence.backup.storageClassName }}
{{- if (eq "-" .Values.persistence.backup.storageClassName) }}
{{- "" -}}
{{- else }}
{{- print .Values.persistence.backup.storageClassName -}}
{{- end }}
{{- else }}
{{- "erikube-rbd" -}}
{{- end }}
{{- end -}}

{{/*
Define the persistentVolumeClaim size
*/}}
{{- define "eric-data-document-database-pg.persistentVolumeClaim.size" -}}
{{- if .Values.persistentVolumeClaim.size}}
{{- print .Values.persistentVolumeClaim.size }}
{{- end }}
{{- end -}}

{{/*
Create Ericsson product specific annotations
*/}}
{{- define "eric-data-document-database-pg.helm-annotations_product_name" -}}
{{- $productname := (fromYaml (.Files.Get "eric-product-info.yaml")).productName -}}
{{- print $productname | quote }}
{{- end -}}
{{- define "eric-data-document-database-pg.helm-annotations_product_number" -}}
{{- $productNumber := (fromYaml (.Files.Get "eric-product-info.yaml")).productNumber -}}
{{- print $productNumber | quote }}
{{- end -}}
{{- define "eric-data-document-database-pg.helm-annotations_product_revision" -}}
{{- $ddbMajorVersion := mustRegexFind "^([0-9]+)\\.([0-9]+)\\.([0-9]+)((-|\\+)EP[0-9]+)*((-|\\+)[0-9]+)*" .Chart.Version -}}
{{- print $ddbMajorVersion | quote }}
{{- end -}}

{{/*
Create Ericsson product app.kubernetes.io info
*/}}
{{- define "eric-data-document-database-pg_app_kubernetes_io_info" -}}
app.kubernetes.io/name: {{ .Chart.Name | quote }}
app.kubernetes.io/version: {{ .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" | quote }}
{{- end -}}

{{/*
Define the secret that sip-tls produced
*/}}
{{- define "eric-data-document-database-pg.secretBaseName" -}}
{{- if .Values.nameOverride }}
{{- printf "%s" .Values.nameOverride -}}
{{- else }}
{{- printf "%s" .Chart.Name -}}
{{- end }}
{{- end -}}
{{/*
Define the mount path of brm-config 
*/}}
{{- define "eric-data-document-database-pg.br-configmap-path" -}}
{{- if .Values.brAgent.brmConfigmapPath -}}
{{- print .Values.brAgent.brmConfigmapPath -}}
{{- else }}
{{- print "/opt/brm_backup" -}}
{{- end }}
{{- end -}}

{{/*
check global.security.tls.enabled since it is removed from values.yaml 
*/}}
{{- define "eric-data-document-database-pg.global-security-tls-enabled" -}}
{{- if  .Values.global -}}
  {{- if  .Values.global.security -}}
    {{- if  .Values.global.security.tls -}}
       {{- .Values.global.security.tls.enabled | toString -}}
    {{- else -}}
       {{- "true" -}}
    {{- end -}}
  {{- else -}}
       {{- "true" -}}
  {{- end -}}
{{- else -}}
{{- "true" -}}
{{- end -}}
{{- end -}}

{{/*
check if postgresConfig.huge_pages is configured for ADPPRG-32783
*/}}
{{- define "eric-data-document-database-pg.hugepage-configured" -}}
{{- if  .Values.postgresConfig -}}
  {{- if  .Values.postgresConfig.huge_pages -}}
       {{- "true" -}}
  {{- else -}}
       {{- "false" -}}
  {{- end -}}
{{- else -}}
{{- "false" -}}
{{- end -}}
{{- end -}}

{{/*
Define affinity property in ddb
*/}}
{{- define "eric-data-document-database-pg.affinity" -}}
{{- if eq .Values.affinity.podAntiAffinity "hard" -}}
podAntiAffinity:
  requiredDuringSchedulingIgnoredDuringExecution:
  - labelSelector:
      matchExpressions:
      - key: app
        operator: In
        values:
        - {{ template "eric-data-document-database-pg.name" . }}
    topologyKey: "kubernetes.io/hostname"
{{- else if eq .Values.affinity.podAntiAffinity "soft" -}}
podAntiAffinity:
  preferredDuringSchedulingIgnoredDuringExecution:
  - weight: 100
    podAffinityTerm:
      labelSelector:
        matchExpressions:
        - key: app
          operator: In
          values:
          - {{ template "eric-data-document-database-pg.name" . }}
      topologyKey: "kubernetes.io/hostname"
{{- end -}}
{{- end -}}

{{/*
To support Dual stack.
*/}}
{{- define "eric-data-document-database-pg.internalIPFamily" -}}
{{- if  .Values.global -}}
  {{- if  .Values.global.internalIPFamily -}}
    {{- .Values.global.internalIPFamily | toString -}}
  {{- else -}}
    {{- "none" -}}
  {{- end -}}
{{- else -}}
{{- "none" -}}

{{- end -}}
{{- end -}}

{{- define "eric-data-document-database-pg.global.nodeSelector" -}}
  {{- $globalNodeSelector := dict -}}
  {{- if .Values.global -}}
    {{- if not (empty .Values.global.nodeSelector) -}}
      {{- mergeOverwrite $globalNodeSelector .Values.global.nodeSelector | toJson -}}
    {{- else -}}
      {{- $globalNodeSelector | toJson -}}
    {{- end -}}
  {{- else -}}
    {{- $globalNodeSelector | toJson -}}
  {{- end -}}
{{- end -}}

{{- define "eric-data-document-database-pg.nodeSelector.postgres" -}}
  {{- $g := fromJson (include "eric-data-document-database-pg.global.nodeSelector" .) -}}
  {{- if not (empty .Values.nodeSelector.postgres) -}}
    {{- range $localkey, $localValue := .Values.nodeSelector.postgres -}}
      {{- if hasKey $g $localkey -}}
        {{- $globalValue := index $g $localkey -}}
        {{- if ne $localValue $globalValue -}}
          {{- printf "nodeSelector \"%s\" is specified in both global (%s: %s) and service level (%s: %s) with differing values which is not allowed." $localkey $localkey $globalValue $localkey $localValue  | fail -}}
        {{- end }}
      {{- end }}
    {{- end }}
    {{- toYaml (merge $g .Values.nodeSelector.postgres) | trim -}}
  {{- else -}}
    {{- toYaml $g | trim -}}
  {{- end -}}
{{- end -}}

{{- define "eric-data-document-database-pg.nodeSelector.brAgent" -}}
  {{- $g := fromJson (include "eric-data-document-database-pg.global.nodeSelector" .) -}}
  {{- if not (empty .Values.nodeSelector.brAgent) -}}
    {{- range $localkey, $localValue := .Values.nodeSelector.brAgent -}}
      {{- if hasKey $g $localkey -}}
        {{- $globalValue := index $g $localkey -}}
        {{- if ne $localValue $globalValue -}}
          {{- printf "nodeSelector \"%s\" is specified in both global (%s: %s) and service level (%s: %s) with differing values which is not allowed." $localkey $localkey $globalValue $localkey $localValue  | fail -}}
        {{- end }}
      {{- end }}
    {{- end }}
    {{- toYaml (merge $g .Values.nodeSelector.brAgent) | trim -}}
  {{- else -}}
    {{- toYaml $g | trim -}}
  {{- end -}}
{{- end -}}

{{- define "eric-data-document-database-pg.nodeSelector.cleanuphook" -}}
  {{- $g := fromJson (include "eric-data-document-database-pg.global.nodeSelector" .) -}}
  {{- if not (empty .Values.nodeSelector.cleanuphook) -}}
    {{- range $localkey, $localValue := .Values.nodeSelector.cleanuphook -}}
      {{- if hasKey $g $localkey -}}
        {{- $globalValue := index $g $localkey -}}
        {{- if ne $localValue $globalValue -}}
          {{- printf "nodeSelector \"%s\" is specified in both global (%s: %s) and service level (%s: %s) with differing values which is not allowed." $localkey $localkey $globalValue $localkey $localValue  | fail -}}
        {{- end }}
      {{- end }}
    {{- end }}
    {{- toYaml (merge $g .Values.nodeSelector.cleanuphook) | trim -}}
  {{- else -}}
    {{- toYaml $g | trim -}}
  {{- end -}}
{{- end -}}

{{- define "eric-data-document-database-pg.tolerations.withoutHandleTS" -}}
{{- if .Values.tolerations.postgres -}}
  {{- if ne (len .Values.tolerations.postgres) 0 -}}
    {{- toYaml .Values.tolerations.postgres -}}
  {{- end -}}
{{- end -}}
{{- end -}}


{{- define "eric-data-document-database-pg.tolerations.withoutHandleTS.brAgent" -}}
{{- if .Values.tolerations.brAgent -}}
    {{- if ne (len .Values.tolerations.brAgent ) 0 -}}
      {{- toYaml .Values.tolerations.brAgent -}}
    {{- end -}}
{{- end -}}
{{- end -}}


{{- define "eric-data-document-database-pg.tolerations.withoutHandleTS.cleanuphook" -}}
{{- if .Values.tolerations.cleanuphook -}}
  {{- if ne (len .Values.tolerations.cleanuphook) 0 -}}
      {{- toYaml .Values.tolerations.cleanuphook -}}
  {{- end -}}
{{- end -}}
{{- end -}}



{{- define "eric-data-document-database-pg.fsGroup.coordinated" -}}
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
Apply when allowPrivilegeEscalation is true.
*/}}
{{- define "eric-data-document-database-pg.securityPolicy.reference" -}}
  {{- if .Values.global -}}
    {{- if .Values.global.security -}}
      {{- if .Values.global.security.policyReferenceMap -}}
        {{ $mapped := index .Values "global" "security" "policyReferenceMap" "plc-59d0cf1dcc793a78b6ce30bfbe6553" }}
        {{- if $mapped -}}
          {{ $mapped }}
        {{- else -}}
          plc-59d0cf1dcc793a78b6ce30bfbe6553
        {{- end -}}
      {{- else -}}
        plc-59d0cf1dcc793a78b6ce30bfbe6553
      {{- end -}}
    {{- else -}}
      plc-59d0cf1dcc793a78b6ce30bfbe6553
    {{- end -}}
  {{- else -}}
    plc-59d0cf1dcc793a78b6ce30bfbe6553
  {{- end -}}
{{- end -}}

{{/*
Apply when allowPrivilegeEscalation is false.
*/}}
{{- define "eric-data-document-database-pg.securityPolicy.reference-default" -}}
  {{- if .Values.global -}}
    {{- if .Values.global.security -}}
      {{- if .Values.global.security.policyReferenceMap -}}
        {{ $mapped := index .Values "global" "security" "policyReferenceMap" "default-restricted-security-policy" }}
        {{- if $mapped -}}
          {{ $mapped }}
        {{- else -}}
          default-restricted-security-policy
        {{- end -}}
      {{- else -}}
        default-restricted-security-policy
      {{- end -}}
    {{- else -}}
      default-restricted-security-policy
    {{- end -}}
  {{- else -}}
    default-restricted-security-policy
  {{- end -}}
{{- end -}}
 
{{- define "eric-data-document-database-pg.HugePage.Volumes" }}
  {{- if and (index .Values "resources" "postgres" "limits" "hugepages-2Mi") (index .Values "resources" "postgres" "limits" "hugepages-1Gi") }}
    {{- if semverCompare "<1.19.0-0" .Capabilities.KubeVersion.Version }}
      {{- fail "Multisize hugepage is only supported on Kuberentes 1.19 and later" }}
    {{- else }}
- name: hugepage-2mi
  emptyDir:
    medium: HugePages-2Mi
- name: hugepage-1gi
  emptyDir:
    medium: HugePages-1Gi
    {{- end }}
  {{- else if or (index .Values "resources" "postgres" "limits" "hugepages-2Mi") (index .Values "resources" "postgres" "limits" "hugepages-1Gi") }}
- name: hugepage
  emptyDir:
    medium: HugePages
  {{- end }}
{{- end }}


{{ define "eric-data-document-database-pg.HugePage.VolumeMounts" }}
  {{- if and (index .Values "resources" "postgres" "limits" "hugepages-2Mi") (index .Values "resources" "postgres" "limits" "hugepages-1Gi") }}
    {{- if semverCompare "<1.19.0-0" .Capabilities.KubeVersion.Version }}
      {{- fail "Multisize hugepage is only supported on Kuberentes 1.19 and later" }}
    {{- else }}
- mountPath: /hugepages-2Mi
  name: hugepage-2mi
- mountPath: /hugepages-1Gi
  name: hugepage-1gi
    {{- end }}
  {{- else if or (index .Values "resources" "postgres" "limits" "hugepages-2Mi") (index .Values "resources" "postgres" "limits" "hugepages-1Gi") }}
- mountPath: /hugepages
  name: hugepage
  {{- end }}
{{- end }}

{{- define "eric-data-document-database-pg.labels" }}
app.kubernetes.io/instance: {{ .Release.Name | quote }}
{{- if .Values.labels -}}
{{- range $name, $config := .Values.labels }}
{{ $name }}: {{ tpl $config $ | quote }}
{{- end }}
{{- end }}
{{- end }}

{{- define "eric-data-document-database-pg.annotations" }}
{{- if .Values.annotations -}}
{{- range $name, $config := .Values.annotations }}
{{ $name }}: {{ tpl $config $ | quote }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Align to DR-D1120-056
*/}}
{{- define "eric-data-document-database-pg.podDisruptionBudget" -}}
{{- if or (eq "0" (.Values.podDisruptionBudget.minAvailable | toString )) (not (empty .Values.podDisruptionBudget.minAvailable )) }}
minAvailable: {{ .Values.podDisruptionBudget.minAvailable }}
{{- else if or (eq "0" (.Values.podDisruptionBudget.maxUnavailable | toString )) (not (empty .Values.podDisruptionBudget.maxUnavailable )) }}
maxUnavailable: {{ .Values.podDisruptionBudget.maxUnavailable }}
{{- else }}
minAvailable: 50%
{{- end }}
{{- end -}}

{{- define "eric-data-document-database-pg.preUpgradeHook" }}
{{- if or .Release.IsUpgrade .Release.IsInstall }}
{{- $globalValue := fromJson (include "eric-data-document-database-pg.global" .) -}}
{{- $defaultLogshipperValue := fromJson (include "eric-data-document-database-pg.logshipper-default-value" .) -}}
apiVersion: batch/v1
kind: Job
metadata:
  name: {{ template "eric-data-document-database-pg.name" . }}-backup-pgdata
  labels:
    app: {{ template "eric-data-document-database-pg.name" . }}
    chart: {{ template "eric-data-document-database-pg.chart" . }}
    release: {{ .Release.Name | quote }}
    heritage: {{ .Release.Service }}
{{- include "eric-data-document-database-pg.labels" . | indent 4 }}
{{- include "eric-data-document-database-pg_app_kubernetes_io_info" .| nindent 4 }}
  annotations:
    ericsson.com/product-name: {{ template "eric-data-document-database-pg.helm-annotations_product_name" . }}
    ericsson.com/product-number: {{ template "eric-data-document-database-pg.helm-annotations_product_number" . }}
    ericsson.com/product-revision: {{ template "eric-data-document-database-pg.helm-annotations_product_revision" . }}
    "helm.sh/hook": pre-upgrade
    "helm.sh/hook-delete-policy": hook-succeeded,before-hook-creation
    "helm.sh/hook-weight": "-3"
spec:
  backoffLimit: 0
  template:
    metadata:
      labels:
        app: {{ template "eric-data-document-database-pg.name" . }}-backup-pgdata
      annotations:
        ericsson.com/product-name: {{ template "eric-data-document-database-pg.helm-annotations_product_name" . }}
        ericsson.com/product-number: {{ template "eric-data-document-database-pg.helm-annotations_product_number" . }}
        ericsson.com/product-revision: {{ template "eric-data-document-database-pg.helm-annotations_product_revision" . }}
    spec:
      restartPolicy: Never
      serviceAccountName: {{ template "eric-data-document-database-pg.name" . }}-pgdata-hook
      {{- if include "eric-data-document-database-pg.pullSecrets" . }}
      imagePullSecrets:
        - name: {{ template "eric-data-document-database-pg.pullSecrets" . }}
      {{- end }}
      securityContext:
        fsGroup: {{ template "eric-data-document-database-pg.fsGroup.coordinated" . }}
      
      {{- if or (not (empty .Values.nodeSelector.cleanuphook)) (not (eq "{}" (include "eric-data-document-database-pg.global.nodeSelector" .))) }}
      nodeSelector:
{{- include "eric-data-document-database-pg.nodeSelector.cleanuphook" . | nindent 8 }}
      {{- end }}
      tolerations:
      {{- if .Values.tolerations }}
{{ include "eric-data-document-database-pg.tolerations.withoutHandleTS.cleanuphook" . | indent 8 }}
      {{- end }}
      containers:
        - name: backup-pgdata
          image: {{ template "eric-data-document-database-pg.kubeclientImagePath" . }}
          imagePullPolicy: {{ include "eric-data-document-database-pg.imagePullPolicy" . | quote }}
          env:
          - name: STATEFULSET_NAME
            value: {{ template "eric-data-document-database-pg.name" . }}
          - name: REPLICA_COUNT
            value: {{ .Values.highAvailability.replicaCount | quote }}
          - name: CLUSTER_NAME
            value: {{ template "eric-data-document-database-pg.name" . }}
          - name: KUBERNETES_NAMESPACE
            valueFrom: { fieldRef: { fieldPath: metadata.namespace } }
          - name: TRANSIT_COMPONENT
            value: {{ template "eric-data-document-database-pg.name" . }}-transit-pvc
          - name: TARGET_PG_VERSION
            value: {{ default "10" .Values.targetPGversion | quote }}
          {{- if (eq (include "eric-data-document-database-pg.global-security-tls-enabled" .) "false") }}
          - name: PGPASSWORD
            valueFrom:
              secretKeyRef:
                name: {{ required "Require .Values.credentials.kubernetesSecretName " .Values.credentials.kubernetesSecretName | quote }}
                key: {{ .Values.credentials.keyForSuperPw | quote }}
          {{- else if eq .Values.service.endpoints.postgres.tls.enforced "optional" }}
          - name: PGPASSWORD
            valueFrom:
              secretKeyRef:
                name: {{ required "Require .Values.credentials.kubernetesSecretName " .Values.credentials.kubernetesSecretName | quote }}
                key: {{ .Values.credentials.keyForSuperPw | quote }}
          {{- else }}
          - name: PGPASSWORD
            value: "fakepgpass"
          {{- end }}
          - name: ENABLE_SIPTLS
            {{- if (not (eq (include "eric-data-document-database-pg.global-security-tls-enabled" .) "false")) }}
            value: "true"
            {{- else }}
            value: "false"
            {{- end }}
          {{- if (has "stream" .Values.log.outputs) }}
          - name: CONTAINER_NAME
            value:  {{ template "eric-data-document-database-pg.name" . }}-hook
          - name: LOG_REDIRECT
            value: {{ template "eric-data-document-database-pg.logRedirect" . }}
          - name: LOG_FORMAT
            value: json
          command:
            - /bin/bash
            - -c
          args:
            - "
              /usr/bin/catatonit -- 
              {{ template "eric-data-document-database-pg.stdRedirectCMD" .  }}
              {{ template "eric-data-document-database-pg.hook.scriptPath" . }}/backuppgdata.sh; sleep 3"
          {{- else }}
          command:
            - /bin/bash
            - -c
          args:
            - "
            /usr/bin/catatonit -- 
            {{ template "eric-data-document-database-pg.hook.scriptPath" . }}/backuppgdata.sh
            "
          {{- end }}
          securityContext:
            allowPrivilegeEscalation: false
            privileged: false
            readOnlyRootFilesystem: true
            runAsNonRoot: true
            capabilities:
              drop:
                - all
          volumeMounts:
          {{- if (has "stream" .Values.log.outputs) }}
            {{- include "eric-data-document-database-pg.logshipper-storage-path" . | indent 12 }}
          {{- end }}
            - name: tmp
              mountPath: /tmp
            - name: pgdata-volume
              mountPath: "/var/pgdata"
          {{- if  (not (eq (include "eric-data-document-database-pg.global-security-tls-enabled" .) "false")) }}
            - name: postgres-client-certificates
              mountPath: /tmp/certificates/client/postgres/
          {{- end }}
          resources:
            requests:
            {{- if .Values.resources.kube_client.requests.cpu }}
              cpu: {{ .Values.resources.kube_client.requests.cpu  | quote }}
            {{- end }}
            {{- if .Values.resources.kube_client.requests.memory }}
              memory: {{ .Values.resources.kube_client.requests.memory  | quote }}
            {{- end }}
            {{- if index .Values.resources.kube_client.requests "ephemeral-storage" }}
              ephemeral-storage: {{ index .Values.resources.kube_client.requests "ephemeral-storage" | quote }}
            {{- end }}
            limits:
            {{- if .Values.resources.kube_client.limits.cpu }}
              cpu: {{ .Values.resources.kube_client.limits.cpu  | quote }}
            {{- end }}
            {{- if .Values.resources.kube_client.limits.memory }}
              memory: {{ .Values.resources.kube_client.limits.memory  | quote }}
            {{- end }}
            {{- if index .Values.resources.kube_client.limits "ephemeral-storage" }}
              ephemeral-storage: {{ index .Values.resources.kube_client.limits "ephemeral-storage" | quote }}
            {{- end }}
      {{- if (has "stream" .Values.log.outputs) }}
      {{- include "eric-data-document-database-pg.logshipper-container-hook" . | indent 8 }}
      {{- end }}
      volumes:
      {{- if (has "stream" .Values.log.outputs) }}
      {{- include "eric-data-document-database-pg.logshipper-volume-hook" . | indent 6 }}
      {{- end }}
      - name: tmp
        emptyDir: {}
      - name: pgdata-volume
        persistentVolumeClaim:
          claimName: {{ template "eric-data-document-database-pg.name" . }}-backup-pgdata
      {{- if  (not (eq (include "eric-data-document-database-pg.global-security-tls-enabled" .) "false")) }}
      - name: postgres-client-certificates
        secret:
          secretName: {{ template "eric-data-document-database-pg.secretBaseName" . }}-postgres-cert
          defaultMode: 0640
      {{- end }}
{{- end -}}
{{- end }}


{{- define "eric-data-document-database-pg.postUpgradeHook" }}
{{- if or .Release.IsUpgrade .Release.IsInstall }}
{{- $globalValue := fromJson (include "eric-data-document-database-pg.global" .) -}}
{{- $defaultLogshipperValue := fromJson (include "eric-data-document-database-pg.logshipper-default-value" .) -}}
apiVersion: batch/v1
kind: Job
metadata:
  name: {{ template "eric-data-document-database-pg.name" . }}-restore-pgdata
  labels:
    app: {{ template "eric-data-document-database-pg.name" . }}
    chart: {{ template "eric-data-document-database-pg.chart" . }}
    release: {{ .Release.Name | quote }}
    heritage: {{ .Release.Service }}
{{- include "eric-data-document-database-pg.labels" . | indent 4 }}
{{- include "eric-data-document-database-pg_app_kubernetes_io_info" .| nindent 4 }}
  annotations:
    ericsson.com/product-name: {{ template "eric-data-document-database-pg.helm-annotations_product_name" . }}
    ericsson.com/product-number: {{ template "eric-data-document-database-pg.helm-annotations_product_number" . }}
    ericsson.com/product-revision: {{ template "eric-data-document-database-pg.helm-annotations_product_revision" . }}
    "helm.sh/hook": post-upgrade
    "helm.sh/hook-delete-policy": hook-succeeded,before-hook-creation
    "helm.sh/hook-weight": "-5"
spec:
  backoffLimit: 0
  template:
    metadata:
      labels:
        app: {{ template "eric-data-document-database-pg.name" . }}-restore-pgdata
      annotations:
        ericsson.com/product-name: {{ template "eric-data-document-database-pg.helm-annotations_product_name" . }}
        ericsson.com/product-number: {{ template "eric-data-document-database-pg.helm-annotations_product_number" . }}
        ericsson.com/product-revision: {{ template "eric-data-document-database-pg.helm-annotations_product_revision" . }}
    spec:
      restartPolicy: Never
      serviceAccountName: {{ template "eric-data-document-database-pg.name" . }}-pgdata-hook
      {{- if include "eric-data-document-database-pg.pullSecrets" . }}
      imagePullSecrets:
        - name: {{ template "eric-data-document-database-pg.pullSecrets" . }}
      {{- end }}
      
      {{- if or (not (empty .Values.nodeSelector.cleanuphook)) (not (eq "{}" (include "eric-data-document-database-pg.global.nodeSelector" .))) }}
      nodeSelector:
{{- include "eric-data-document-database-pg.nodeSelector.cleanuphook" . | nindent 8 }}
      {{- end }}
      tolerations:
      {{- if .Values.tolerations }}
{{ include "eric-data-document-database-pg.tolerations.withoutHandleTS.cleanuphook" . | indent 8 }}
      {{- end }}
      containers:
        - name: restore-pgdata
          image: {{ template "eric-data-document-database-pg.kubeclientImagePath" . }}
          imagePullPolicy: {{ include "eric-data-document-database-pg.imagePullPolicy" . | quote }}
          env:
          - name: STATEFULSET_NAME
            value: {{ template "eric-data-document-database-pg.name" . }}
          - name: REPLICA_COUNT
            value: {{ .Values.highAvailability.replicaCount | quote }}
          - name: CLUSTER_NAME
            value: {{ template "eric-data-document-database-pg.name" . }}
          - name: KUBERNETES_NAMESPACE
            valueFrom: { fieldRef: { fieldPath: metadata.namespace } }
          - name: TRANSIT_COMPONENT
            value: {{ template "eric-data-document-database-pg.name" . }}-transit-pvc
          - name: TARGET_PG_VERSION
            value: {{ default "10" .Values.targetPGversion | quote }}
          {{- if (eq (include "eric-data-document-database-pg.global-security-tls-enabled" .) "false") }}
          - name: PGPASSWORD
            valueFrom:
              secretKeyRef:
                name: {{ required "Require .Values.credentials.kubernetesSecretName " .Values.credentials.kubernetesSecretName | quote }}
                key: {{ .Values.credentials.keyForSuperPw | quote }}
          {{- else if eq .Values.service.endpoints.postgres.tls.enforced "optional" }}
          - name: PGPASSWORD
            valueFrom:
              secretKeyRef:
                name: {{ required "Require .Values.credentials.kubernetesSecretName " .Values.credentials.kubernetesSecretName | quote }}
                key: {{ .Values.credentials.keyForSuperPw | quote }}
          {{- else }}
          - name: PGPASSWORD
            value: "fakepgpass"
          {{- end }}
          - name: ENABLE_SIPTLS
            {{- if (not (eq (include "eric-data-document-database-pg.global-security-tls-enabled" .) "false")) }}
            value: "true"
            {{- else }}
            value: "false"
            {{- end }}
          {{- if (has "stream" .Values.log.outputs) }}
          - name: CONTAINER_NAME
            value:  {{ template "eric-data-document-database-pg.name" . }}-hook
          - name: LOG_REDIRECT
            value: {{ template "eric-data-document-database-pg.logRedirect" . }}
          - name: LOG_FORMAT
            value: json
          command:
            - /bin/bash
            - -c
          args:
            - "
              /usr/bin/catatonit -- 
              {{ template "eric-data-document-database-pg.stdRedirectCMD" .  }}
              /usr/bin/python {{ template "eric-data-document-database-pg.hook.scriptPath" . }}/postupgrade_handler.py; sleep 3"
          {{- else }}
          command:
            - /bin/bash
            - -c
          args:
            - "
            /usr/bin/catatonit -- /usr/bin/python
            {{ template "eric-data-document-database-pg.hook.scriptPath" . }}/postupgrade_handler.py 
            "
          {{- end }}
          securityContext:
            allowPrivilegeEscalation: false
            privileged: false
            readOnlyRootFilesystem: true
            runAsNonRoot: true
            capabilities:
              drop:
                - all
          volumeMounts:
          {{- if (has "stream" .Values.log.outputs) }}
            {{- include "eric-data-document-database-pg.logshipper-storage-path" . | indent 12 }}
          {{- end }}
            - name: tmp
              mountPath: /tmp
            - name: pgdata-volume
              mountPath: "/var/pgdata"
          {{- if  (not (eq (include "eric-data-document-database-pg.global-security-tls-enabled" .) "false")) }}
            - name: postgres-client-certificates
              mountPath: /tmp/certificates/client/postgres/
          {{- end }}
          resources:
            requests:
            {{- if .Values.resources.kube_client.requests.cpu }}
              cpu: {{ .Values.resources.kube_client.requests.cpu  | quote }}
            {{- end }}
            {{- if .Values.resources.kube_client.requests.memory }}
              memory: {{ .Values.resources.kube_client.requests.memory  | quote }}
            {{- end }}
            {{- if index .Values.resources.kube_client.requests "ephemeral-storage" }}
              ephemeral-storage: {{ index .Values.resources.kube_client.requests "ephemeral-storage" | quote }}
            {{- end }}
            limits:
            {{- if .Values.resources.kube_client.limits.cpu }}
              cpu: {{ .Values.resources.kube_client.limits.cpu  | quote }}
            {{- end }}
            {{- if .Values.resources.kube_client.limits.memory }}
              memory: {{ .Values.resources.kube_client.limits.memory  | quote }}
            {{- end }}
            {{- if index .Values.resources.kube_client.limits "ephemeral-storage" }}
              ephemeral-storage: {{ index .Values.resources.kube_client.limits "ephemeral-storage" | quote }}
            {{- end }}
      {{- if (has "stream" .Values.log.outputs) }}
      {{- include "eric-data-document-database-pg.logshipper-container-hook" . | indent 8 }}
      {{- end }}
      volumes:
      {{- if (has "stream" .Values.log.outputs) }}
      {{- include "eric-data-document-database-pg.logshipper-volume-hook" . | indent 6 }}
      {{- end }}
      - name: tmp
        emptyDir: {}
      - name: pgdata-volume
        persistentVolumeClaim:
          claimName: {{ template "eric-data-document-database-pg.name" . }}-backup-pgdata
      {{- if  (not (eq (include "eric-data-document-database-pg.global-security-tls-enabled" .) "false")) }}
      - name: postgres-client-certificates
        secret:
          secretName: {{ template "eric-data-document-database-pg.secretBaseName" . }}-postgres-cert
          defaultMode: 0640
      {{- end }}
{{- end -}}
{{- end }}


{{- define "eric-data-document-database-pg.upgradeHookPVC" }}
{{- if or .Release.IsUpgrade .Release.IsInstall }}
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: {{ template "eric-data-document-database-pg.name" . }}-backup-pgdata
  labels:
    app: {{ template "eric-data-document-database-pg.name" . }}
    release: {{ .Release.Name | quote }}
    cluster-name: {{ template "eric-data-document-database-pg.name" . }}
    ## workaround after migrate from helm2 to helm3. Avoid upgrade fail. ADPPRG-26626
    heritage: Tiller
{{- include "eric-data-document-database-pg.labels" . | indent 4 }}
{{- include "eric-data-document-database-pg_app_kubernetes_io_info" .| nindent 4 }}
  annotations:
    ericsson.com/product-name: {{ template "eric-data-document-database-pg.helm-annotations_product_name" . }}
    ericsson.com/product-number: {{ template "eric-data-document-database-pg.helm-annotations_product_number" . }}
    ericsson.com/product-revision: {{ template "eric-data-document-database-pg.helm-annotations_product_revision" . }}
    "helm.sh/hook": pre-upgrade
    "helm.sh/hook-delete-policy": before-hook-creation
    "helm.sh/hook-weight": "-5"
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: {{ template "eric-data-document-database-pg.persistentVolumeClaim.size" . }}
  storageClassName: {{ template "eric-data-document-database-pg.persistentVolumeClaim.defaultStorageClassName" . }}
{{- end }}
{{- end }}

{{/*
check if a default value of max_slot_wal_keep_size needs to be set
*/}}
{{- define "eric-data-document-database-pg.default-maxslotwalkeepsize-needed" -}}
{{- if .Values.targetPGversion -}}
  {{- if (eq "13" (.Values.targetPGversion | toString) ) -}}
    {{- if .Values.persistentVolumeClaim.housekeeping_threshold -}}
      {{- if (eq "100" (.Values.persistentVolumeClaim.housekeeping_threshold | toString) ) -}}
         {{- "false" -}}
      {{- else -}}
         {{- if (index .Values "postgresConfig") -}}
           {{- if (index .Values "postgresConfig" "max_slot_wal_keep_size") -}}
             {{- "false" -}}
           {{- else -}}
             {{- "true" -}}
           {{- end -}}
         {{- else -}}
           {{- "true" -}}
         {{- end -}}
      {{- end -}}
    {{- else -}}
       {{- "false" -}}
    {{- end -}}
  {{- else -}}
    {{- "false" -}}
  {{- end -}}
{{- else -}}
{{- "false" -}}
{{- end -}}
{{- end -}}

{{/*
Define topologySpreadConstraints in ddb
*/}}
{{- define "eric-data-document-database-pg.topologySpreadConstraints.postgres" -}}
{{- range $index, $postgres := .Values.topologySpreadConstraints.postgres }}
- maxSkew: {{ $postgres.maxSkew }}
  topologyKey: {{ $postgres.topologyKey }}
  whenUnsatisfiable: {{ $postgres.whenUnsatisfiable }}
  labelSelector:
    matchLabels:
      app: {{ default $.Chart.Name $.Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end -}}
{{- end -}}


{{/*
Define probes in ddb
*/}}
{{- define "eric-data-document-database-pg.probes" -}}
{{- $default := .Values.probes -}}
{{- $default | toJson -}}
{{- end -}}
