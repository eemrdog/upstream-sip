{{/*
Various supervisor parameters
*/}}

{{- define "eric-sec-sip-tls.supervisor.emergencyTtl" -}}
{{- $supervisor := default dict .Values.supervisor }}
{{- default 15778800 $supervisor.emergencyTtl -}}
{{- end -}}

{{- define "eric-sec-sip-tls.supervisor.recoveryThreshold" -}}
{{- $supervisor := default dict .Values.supervisor }}
{{- default 3600 $supervisor.recoveryThreshold -}}
{{- end -}}

{{- define "eric-sec-sip-tls.supervisor.wdcTtl" -}}
{{- $supervisor := default dict .Values.supervisor }}
{{- default 1800 $supervisor.wdcTtl -}}
{{- end -}}

{{/* Checks if the TLS is required for the Alarm Handler communication */}}
{{- define "eric-sec-sip-tls.alarmHandler.tlsOnly" }}
{{- eq .Values.alarmHandler.tls.enabled true -}}
{{- end }}

{{/* Checks if the TLS is required for the Alarm Handler communication based on the global parameter and service parameter */}}
{{- define "eric-sec-sip-tls.alarmHandler.tls.enabled" }}
{{- and (eq (include "eric-sec-sip-tls.tls.enabled" .) "true") (eq (include "eric-sec-sip-tls.alarmHandler.tlsOnly" .) "true") -}}
{{- end }}

{{/* Name of the secret holding the Alarm Handler client certificate */}}
{{- define "eric-sec-sip-tls.alarmHandler.client.cert.secret" }}
    {{- printf "%s-%s" (include "eric-sec-sip-tls.name" .) "alarm-handler-client-cert" -}}
{{- end }}

{{/* Checks if the fault indication should be produced towards Alarm Handler REST API */}}
{{- define "eric-sec-sip-tls.alarmHandler.useAPIDefinition" }}
{{- eq .Values.alarmHandler.useAPIDefinition true -}}
{{- end }}

{{/* Folder where the Alarm Handler client certificates will be mounted */}}
{{- define "eric-sec-sip-tls.alarmHandler.client.cert.mountFolder" }}
    {{- printf "%s" "/run/secrets/alarm-handler-client-cert" -}}
{{- end }}

{{/* Path to the Alarm Handler client certificate */}}
{{- define "eric-sec-sip-tls.alarmHandler.client.cert.certPath" }}
    {{- printf "%s/%s" (include "eric-sec-sip-tls.alarmHandler.client.cert.mountFolder" .) "cert.pem" -}}
{{- end }}

{{/* Path to the Alarm Handler client private key */}}
{{- define "eric-sec-sip-tls.alarmHandler.client.cert.keyPath" }}
    {{- printf "%s/%s" (include "eric-sec-sip-tls.alarmHandler.client.cert.mountFolder" .) "key.pem" -}}
{{- end }}
