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

{{/* Folder where the (emptyDir) memory storage will be mounted in topic creator */}}
{{- define "eric-fh-alarm-handler.memoryStorage.mountFolderTopicCreator" }}
    {{- printf "%s" "/memstore" -}}
{{- end }}

{{/* Folder where the (emptyDir) memory storage will be mounted in topic creator */}}
{{- define "eric-fh-alarm-handler.memoryStorage.mountFolderAlarmHandler" }}
    {{- printf "%s" "/memstoreroot" -}}
{{- end }}

{{/*
Define resources fragment.
*/}}
{{- define "eric-fh-alarm-handler.resources.topiccreator.requests.memory" }}
    {{- if .Values.resources.topiccreator.requests.memory }}
        {{- printf  (.Values.resources.topiccreator.requests.memory | quote) -}}
    {{- end }}
{{- end }}
{{- define "eric-fh-alarm-handler.resources.topiccreator.requests.cpu" }}
    {{- if .Values.resources.topiccreator.requests.cpu }}
        {{- printf (.Values.resources.topiccreator.requests.cpu | quote) -}}
    {{- end }}
{{- end }}
{{- define "eric-fh-alarm-handler.resources.topiccreator.requests.ephemeral-storage" }}
    {{- if index .Values.resources.topiccreator.requests "ephemeral-storage" }}
        {{- printf (index .Values.resources.topiccreator.requests "ephemeral-storage" | quote) -}}
    {{- end }}
{{- end }}

{{- define "eric-fh-alarm-handler.resources.topiccreator.limits.memory" }}
    {{- if not .Values.resources.topiccreator.limits }}
        {{- printf "512Mi" -}}
    {{- else if not .Values.resources.topiccreator.limits.memory }}
        {{- printf "512Mi" -}}
    {{- else }}
        {{- printf (.Values.resources.topiccreator.limits.memory | quote) -}}
    {{- end }}
{{- end }}
{{- define "eric-fh-alarm-handler.resources.topiccreator.limits.cpu" }}
    {{- if not .Values.resources.topiccreator.limits }}
        {{- printf "1000m" -}}
    {{- else if not .Values.resources.topiccreator.limits.cpu }}
        {{- printf "1000m" -}}
    {{- else }}
        {{- printf (.Values.resources.topiccreator.limits.cpu | quote) -}}
    {{- end }}
{{- end }}
{{- define "eric-fh-alarm-handler.resources.topiccreator.limits.ephemeral-storage" }}
    {{- if not .Values.resources.topiccreator.requests }}
        {{- printf "2Gi" -}}
    {{- else if not (index .Values.resources.topiccreator.limits "ephemeral-storage") }}
        {{- printf "2Gi" -}}
    {{- else }}
        {{- printf (index .Values.resources.topiccreator.limits "ephemeral-storage" | quote) -}}
    {{- end }}
{{- end }}