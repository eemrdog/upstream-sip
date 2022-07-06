{{/*
Create a map from ".Values.global" with defaults if missing in values file.
This hides defaults from values file.
*/}}
{{ define "eric-fh-alarm-handler.global" }}
  {{- $globalDefaults := dict "security" (dict "tls" (dict "enabled" true)) -}}
  {{- $globalDefaults := merge $globalDefaults (dict "security" (dict "policyBinding" (dict "create" false))) -}}
  {{- $globalDefaults := merge $globalDefaults (dict "security" (dict "policyReferenceMap" (dict "default-restricted-security-policy" "default-restricted-security-policy"))) -}}
  {{- $globalDefaults := merge $globalDefaults (dict "nodeSelector" (dict)) -}}
  {{- $globalDefaults := merge $globalDefaults (dict "timezone" "UTC") -}}
  {{- $globalDefaults := merge $globalDefaults (dict "registry" (dict "url" "451278531435.dkr.ecr.us-east-1.amazonaws.com")) -}}
  {{- $globalDefaults := merge $globalDefaults (dict "registry" (dict "pullSecret" (dict))) -}}
  {{ if .Values.global }}
    {{- mergeOverwrite $globalDefaults .Values.global | toJson -}}
  {{ else }}
    {{- $globalDefaults | toJson -}}
  {{ end }}
{{ end }}

{{/*
Verifies TLS is enabled globally
*/}}
{{- define "eric-fh-alarm-handler.tls.enabled" -}}
{{- $g := fromJson (include "eric-fh-alarm-handler.global" .) -}}
{{- $g.security.tls.enabled | toString | lower }}
{{- end -}}

{{/*
Common labels and custom labels set in values.labels
*/}}
{{- define "eric-fh-alarm-handler.labels" }}
app: {{ template "eric-fh-alarm-handler.name" . }}
chart: {{ template "eric-fh-alarm-handler.chart" . }}
release: {{ .Release.Name }}
heritage: {{ .Release.Service }}
app.kubernetes.io/name: {{ template "eric-fh-alarm-handler.name" . }}
app.kubernetes.io/version: {{ template "eric-fh-alarm-handler.version" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- if .Values.labels }}
{{ toYaml .Values.labels }}
{{- end }}
{{- end -}}

{{/*
Create resources fragment for the new AH.
*/}}

{{- define "eric-fh-alarm-handler.resources.alarm-handler" -}}
{{- $resources := index .Values "resources" "alarmhandlerrest" -}}
{{- toYaml $resources -}}
{{- end -}}

{{/* Folder where the fault alarm mapping will be */}}
{{- define "eric-fh-alarm-handler.faultmappings.mountFolder" }}
    {{- printf "%s" "/etc/faultmappings" -}}
{{- end }}

{{- define "eric-fh-alarm-handler.rootFolder" }}
    {{- printf "%s" "/" -}}
{{- end }}

{{/* Metrics server listening port */}}
{{- define "eric-fh-alarm-handler.metrics.port" }}
    {{- printf "%d" 8000 -}}
{{- end }}

{{/* Checks if the metrics server is enabled */}}
{{- define "eric-fh-alarm-handler.metrics.server.enabled" }}
{{- eq ( .Values.service.endpoints.metrics.enabled | quote) "true" -}}
{{- end }}

{{/* Checks if the TLS is required for the metrics server */}}
{{- define "eric-fh-alarm-handler.metrics.server.tlsOnly" }}
{{- eq .Values.service.endpoints.metrics.tls.enforced "required" -}}
{{- end }}

{{/* Checks if the metrics server needs to verify the clients */}}
{{- define "eric-fh-alarm-handler.metrics.server.tls.verifyClientCertificate" }}
{{- eq .Values.service.endpoints.metrics.tls.verifyClientCertificate "required" -}}
{{- end }}

{{/* PM Server client subject alternative name */}}
{{- define "eric-fh-alarm-handler.metrics.client.subAltNameDN" }}
    {{- printf "%s" "certified-scrape-target" -}}
{{- end }}

{{/* Probes server listening port */}}
{{- define "eric-fh-alarm-handler.probes.port" }}
    {{- printf "%d" 7000 -}}
{{- end }}

{{/* K8s client probes scheme HTTP | HTTPS */}}
{{- define "eric-fh-alarm-handler.probes.scheme" }}
{{- $tls := (include "eric-fh-alarm-handler.tls.enabled" .) -}}
{{- if (eq $tls "true") }}
    {{- printf "%s" "HTTPS" -}}
{{- else }}
    {{- printf "%s" "HTTP" -}}
{{- end }}
{{- end }}

{{/* Checks if the TLS is required for the probes server */}}
{{- define "eric-fh-alarm-handler.probes.server.tlsOnly" }}
{{- eq .Values.service.endpoints.probes.tls.enforced "required" -}}
{{- end }}

{{- define "eric-fh-alarm-handler.restapi.server.port" }}
    {{- printf "%d" 5005 -}}
{{- end }}

{{/* restapi server listening tls port */}}
{{- define "eric-fh-alarm-handler.restapi.server.tls.port" }}
    {{- printf "%d" 5006 -}}
{{- end }}


{{/* restapi server listening single port */}}
{{- define "eric-fh-alarm-handler.restapi.server.single.port" }}
{{- $g := fromJson (include "eric-fh-alarm-handler.global" .) -}}
    {{- if $g.security.tls.enabled -}}
    {{- include "eric-fh-alarm-handler.restapi.server.tls.port" . -}}
    {{- else }}
    {{- include "eric-fh-alarm-handler.restapi.server.port" . -}}
    {{- end }}
{{- end }}

{{/* Checks if the restapi server needs to enforce tls */}}
{{- define "eric-fh-alarm-handler.restapi.server.tlsOnly" }}
{{- eq .Values.service.endpoints.restapi.tls.enforced "required" -}}
{{- end }}

{{/* Checks if the restapi server needs to verify the clients */}}
{{- define "eric-fh-alarm-handler.restapi.server.tls.verifyClientCertificate" }}
{{- eq .Values.service.endpoints.restapi.tls.verifyClientCertificate "required" -}}
{{- end }}

{{/*----------------------------------------------------------------*/}}
{{/*-----Methods for defining security policies---------------------*/}}
{{/*----------------------------------------------------------------*/}}
{{- define "eric-fh-alarm-handler.securityPolicy.reference" -}}
{{- $g := fromJson (include "eric-fh-alarm-handler.global" .) }}
{{- $policyName := "" -}}
    {{- if $g.security -}}
        {{- if $g.security.policyReferenceMap -}}
            {{- if index $g "security" "policyReferenceMap" "default-restricted-security-policy" -}}
                {{ $policyName = index $g "security" "policyReferenceMap" "default-restricted-security-policy" }}
            {{- end -}}
        {{- end -}}
    {{- end -}}
{{- $policyName := default "default-restricted-security-policy" $policyName -}}
{{- $policyName -}}
{{- end -}}

{{/*----------------------------------------------------------------*/}}
{{/*-----Templates for ingress--------------------------------------*/}}
{{/*----------------------------------------------------------------*/}}

{{/*
Backend for the nginx ingress, dependent on which API version is used,
and if global tls is enabled.
*/}}
{{- define "eric-fh-alarm-handler.ingress.backend" -}}
{{- $g := fromJson (include "eric-fh-alarm-handler.global" .) }}
{{- if .Capabilities.APIVersions.Has "networking.k8s.io/v1/Ingress" -}}
backend:
  service:
    name: {{ include "eric-fh-alarm-handler.name" . }}
    port:
{{- if $g.security.tls.enabled }}
      number: {{ include "eric-fh-alarm-handler.restapi.server.tls.port" . }}
{{- else }}
      number: {{ include "eric-fh-alarm-handler.restapi.server.port" . }}
{{- end -}}
{{- else if .Capabilities.APIVersions.Has "networking.k8s.io/v1beta1" -}}
backend:
  serviceName: {{ include "eric-fh-alarm-handler.name" . }}
{{- if $g.security.tls.enabled }}
  servicePort: {{ include "eric-fh-alarm-handler.restapi.server.tls.port" . }}
{{- else }}
  servicePort: {{ include "eric-fh-alarm-handler.restapi.server.port" . }}
{{- end -}}
{{- else -}}
{{- printf "Neither 'networking.k8s.io/v1' nor 'networking.k8s.io/v1beta1' are found, no api available for creating Ingress." | fail -}}
{{- end -}}
{{- end -}}

{{/*
Annotations for TLS settings between the nginx ingress and the Alarm Handler service.
*/}}
{{- define "eric-fh-alarm-handler.ingress.tls.annotations" }}
{{- $g := fromJson (include "eric-fh-alarm-handler.global" .) }}
{{- if $g.security.tls.enabled -}}
nginx.ingress.kubernetes.io/backend-protocol: "HTTPS"
{{- else -}}
nginx.ingress.kubernetes.io/backend-protocol: "HTTP"
{{- end }}
{{- end }}

{{/*
Annotations for validating the external client from the nginx ingress.
*/}}
{{- define "eric-fh-alarm-handler.ingress.clientverification.annotations" }}
{{- $g := fromJson (include "eric-fh-alarm-handler.global" .) }}
{{- if $g.security.tls.enabled -}}
{{- if eq .Values.ingress.tls.verifyClientCertificate true -}}
nginx.ingress.kubernetes.io/auth-tls-verify-client: "on"
nginx.ingress.kubernetes.io/auth-tls-secret: {{ .Values.ingress.certificates.caSecret | default (printf "%s-external-ca-certificate-secret" (include "eric-fh-alarm-handler.name" .)) | quote }}
{{- else -}}
nginx.ingress.kubernetes.io/auth-tls-verify-client: "off"
{{- end }}
{{- end }}
{{- end }}

{{/*
API version to use in ingress depending on K8s version.
*/}}
{{ define "eric-fh-alarm-handler.ingress.apiversion" }}
{{- if .Capabilities.APIVersions.Has "networking.k8s.io/v1/Ingress" -}}
networking.k8s.io/v1
{{- else if .Capabilities.APIVersions.Has "networking.k8s.io/v1beta1" -}}
networking.k8s.io/v1beta1
{{- else -}}
{{- printf "Neither 'networking.k8s.io/v1' nor 'networking.k8s.io/v1beta1' are found, no api available for creating Ingress." | fail -}}
{{- end }}
{{- end -}}
