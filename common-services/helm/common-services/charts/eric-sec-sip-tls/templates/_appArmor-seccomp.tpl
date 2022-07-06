{{/*
Various appArmor annotation and seccomp securityContext annotation parameters
*/}}

{{/*
Define the appArmor annotation creation based on input argument
*/}}
{{- define "eric-sec-sip-tls.appArmorAnnotation.getAnnotation" -}}
{{- $profile := index . "profile" -}}
{{- $containerName := index . "containerName" -}}
{{- if $profile.type -}}
{{- if eq "runtime/default" (lower $profile.type) }}
container.apparmor.security.beta.kubernetes.io/{{ $containerName }}: "runtime/default"
{{- else if eq "unconfined" (lower $profile.type) }}
container.apparmor.security.beta.kubernetes.io/{{ $containerName }}: "unconfined"
{{- else if eq "localhost" (lower $profile.type) }}
{{- $failureMessage := "If you set appArmor type 'localhost' you are required to set the 'localhostProfile'" }}
{{- if required $failureMessage $profile.localhostProfile }}
{{- $profileText := printf "localhost/%s" $profile.localhostProfile }}
container.apparmor.security.beta.kubernetes.io/{{ $containerName }}: {{ $profileText | quote }}
{{- end }}
{{- else }}
    {{- $problem := "Wrong AppArmor Profile type was defined."  -}}
    {{- $details := "Possible values are: runtime/default, unconfined, localhost." -}}
    {{- $solution := "To proceed, please resolve the issue and try again." -}}
    {{- printf "%s %s %s " $problem $details $solution | fail -}}
{{- end }}
{{- end -}}
{{- end -}}

{{/*
Define the appArmor annotation for sip-tls container
*/}}
{{- define "eric-sec-sip-tls.appArmorAnnotation.sip-tls" -}}
{{- if .Values.appArmorProfile -}}
{{- $profile := .Values.appArmorProfile }}
{{- if index .Values.appArmorProfile "sip-tls" -}}
{{- $profile = index .Values.appArmorProfile "sip-tls" }}
{{- end -}}
{{- include "eric-sec-sip-tls.appArmorAnnotation.getAnnotation" (dict "profile" $profile "containerName" "sip-tls") }}
{{- end -}}
{{- end -}}

{{/*
Define the appArmor annotation for sip-tls-init container
*/}}
{{- define "eric-sec-sip-tls.appArmorAnnotation.sip-tls-init" -}}
{{- if .Values.appArmorProfile -}}
{{- $profile := .Values.appArmorProfile }}
{{- if index .Values.appArmorProfile "sip-tls-init" -}}
{{- $profile = index .Values.appArmorProfile "sip-tls-init" }}
{{- end -}}
{{- include "eric-sec-sip-tls.appArmorAnnotation.getAnnotation" (dict "profile" $profile "containerName" "sip-tls-init") }}
{{- end -}}
{{- end -}}

{{/*
Define the appArmor annotation for sip-tls-supervisor container
*/}}
{{- define "eric-sec-sip-tls.appArmorAnnotation.sip-tls-supervisor" -}}
{{- if .Values.appArmorProfile -}}
{{- $profile := .Values.appArmorProfile }}
{{- if index .Values.appArmorProfile "sip-tls-supervisor" -}}
{{- $profile = index .Values.appArmorProfile "sip-tls-supervisor" }}
{{- end -}}
{{- include "eric-sec-sip-tls.appArmorAnnotation.getAnnotation" (dict "profile" $profile "containerName" "sip-tls-supervisor") }}
{{- end -}}
{{- end -}}

{{/*
Define the appArmor annotation for logshipper container
*/}}
{{- define "eric-sec-sip-tls.appArmorAnnotation.logshipper" -}}
{{- if .Values.appArmorProfile -}}
{{- $profile := .Values.appArmorProfile }}
{{- if index .Values.appArmorProfile "logshipper" -}}
{{- $profile = index .Values.appArmorProfile "logshipper" }}
{{- end -}}
{{- include "eric-sec-sip-tls.appArmorAnnotation.getAnnotation" (dict "profile" $profile "containerName" "logshipper") }}
{{- end -}}
{{- end -}}

{{/*
Define the seccomp annotation creation based on input argument
*/}}
{{- define "eric-sec-sip-tls.seccompAnnotation.getAnnotation" -}}
{{- $profile := index . "profile" -}}
{{- if $profile.type -}}
{{- if eq "runtimedefault" (lower $profile.type) }}
seccompProfile:
  type: "RuntimeDefault"
{{- else if eq "unconfined" (lower $profile.type) }}
seccompProfile:
  type: "Unconfined"
{{- else if eq "localhost" (lower $profile.type) }}
{{- $failureMessage := "If you set seccomp type 'Localhost' you are required to set the seccomp 'localhostProfile'" }}
seccompProfile:
  type: "Localhost"
  localhostProfile: {{ required $failureMessage $profile.localhostProfile | quote }}
{{- else }}
    {{- $problem := "Wrong seccomp Profile type was defined."  -}}
    {{- $details := "Possible values are: RuntimeDefault, Unconfined, Localhost." -}}
    {{- $solution := "To proceed, please resolve the issue and try again." -}}
    {{- printf "%s %s %s " $problem $details $solution | fail -}}
{{- end }}
{{- end -}}
{{- end -}}

{{/*
Define the seccomp securityContext for sip-tls container
*/}}
{{- define "eric-sec-sip-tls.seccompProfile.sip-tls" -}}
{{- if .Values.seccompProfile }}
{{- $profile := .Values.seccompProfile }}
{{- if index .Values.seccompProfile "sip-tls" }}
{{- $profile = index .Values.seccompProfile "sip-tls" }}
{{- end }}
{{- include "eric-sec-sip-tls.seccompAnnotation.getAnnotation" (dict "profile" $profile) }}
{{- end -}}
{{- end -}}

{{/*
Define the seccomp securityContext for sip-tls-init container
*/}}
{{- define "eric-sec-sip-tls.seccompProfile.sip-tls-init" -}}
{{- if .Values.seccompProfile }}
{{- $profile := .Values.seccompProfile }}
{{- if index .Values.seccompProfile "sip-tls-init" }}
{{- $profile = index .Values.seccompProfile "sip-tls-init" }}
{{- end }}
{{- include "eric-sec-sip-tls.seccompAnnotation.getAnnotation" (dict "profile" $profile) }}
{{- end -}}
{{- end -}}

{{/*
Define the seccomp securityContext for sip-tls-supervisor container
*/}}
{{- define "eric-sec-sip-tls.seccompProfile.sip-tls-supervisor" -}}
{{- if .Values.seccompProfile }}
{{- $profile := .Values.seccompProfile }}
{{- if index .Values.seccompProfile "sip-tls-supervisor" }}
{{- $profile = index .Values.seccompProfile "sip-tls-supervisor" }}
{{- end }}
{{- include "eric-sec-sip-tls.seccompAnnotation.getAnnotation" (dict "profile" $profile) }}
{{- end -}}
{{- end -}}
