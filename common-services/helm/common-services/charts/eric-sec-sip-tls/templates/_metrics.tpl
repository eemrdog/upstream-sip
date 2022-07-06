{{/*---------------------------------------------------------------*/}}
{{/*-------------------- Metrics server ---------------------------*/}}
{{/*---------------------------------------------------------------*/}}

{{/* Checks if metrics are enabled */}}
{{- define "eric-sec-sip-tls.metrics.server.enabled" }}
{{- eq .Values.metrics.enabled true -}}
{{- end }}

{{/* Metrics server listening port */}}
{{- define "eric-sec-sip-tls.metrics.server.port" }}
    {{- if eq (include "eric-sec-sip-tls.metrics.server.tlsOnly" .) "true" -}}
        {{- 8889 -}}
    {{- else -}}
        {{- 8888 -}}
    {{- end -}}
{{- end }}

{{/* Metrics server listening endpoint */}}
{{- define "eric-sec-sip-tls.metrics.server.endpoint" }}
    {{- printf "%s" "/metrics" -}}
{{- end }}

{{/* Metric server scheme HTTP | HTTPS */}}
{{- define "eric-sec-sip-tls.metrics.server.scheme" }}
    {{- if eq (include "eric-sec-sip-tls.metrics.server.tlsOnly" .) "true" -}}
        {{- printf "%s" "HTTPS" -}}
    {{- else }}
        {{- printf "%s" "HTTP" -}}
    {{- end }}
{{- end }}

{{/* Metrics server listening name */}}
{{- define "eric-sec-sip-tls.metrics.server.name" }}
    {{- if eq (include "eric-sec-sip-tls.metrics.server.tlsOnly" .) "true" -}}
        {{- printf "%s" "http-metric-tls" -}}
    {{- else -}}
        {{- printf "%s" "http-metric" -}}
    {{- end -}}
{{- end }}

{{/* Checks if the TLS is required for the metrics server */}}
{{- define "eric-sec-sip-tls.metrics.server.tls.enabled" }}
{{- and (eq (include "eric-sec-sip-tls.tls.enabled" .) "true") (eq (include "eric-sec-sip-tls.metrics.server.tlsOnly" .) "true") -}}
{{- end }}

{{/* Checks if the TLS is required for the metrics server */}}
{{- define "eric-sec-sip-tls.metrics.server.tlsOnly" }}
{{- eq .Values.service.endpoints.metrics.tls.enforced "required" -}}
{{- end }}

{{/* Checks if the verify client certificate is required for the metrics server */}}
{{- define "eric-sec-sip-tls.metrics.server.verifyClient" }}
{{- eq .Values.service.endpoints.metrics.tls.verifyClientCertificate "required" -}}
{{- end }}

{{/* Name of the secret holding the metrics server certificate */}}
{{- define "eric-sec-sip-tls.metrics.server.certSecret" }}
    {{- printf "%s-%s" (include "eric-sec-sip-tls.name" .) "metrics-server-cert" -}}
{{- end }}

{{/* Folder where the metrics server certificates will be mounted */}}
{{- define "eric-sec-sip-tls.metrics.server.cert.mountFolder" }}
    {{- printf "%s" "/run/secrets/metrics-server-cert" -}}
{{- end }}

{{/* Path to the metrics server certificate */}}
{{- define "eric-sec-sip-tls.metrics.server.certPath" }}
    {{- printf "%s/%s" (include "eric-sec-sip-tls.metrics.server.cert.mountFolder" .) "cert.pem" -}}
{{- end }}

{{/* Path to the metrics server private key */}}
{{- define "eric-sec-sip-tls.metrics.server.keyPath" }}
    {{- printf "%s/%s" (include "eric-sec-sip-tls.metrics.server.cert.mountFolder" .) "key.pem" -}}
{{- end }}

{{/* Folder where the CA Cert used by PM Server will be mounted */}}
{{- define "eric-sec-sip-tls.metrics.client.cacert.mountFolder" }}
    {{- printf "%s" "/run/secrets/metrics-client-cacert" -}}
{{- end }}

{{/* Path to the PM Server Client CA Cert */}}
{{- define "eric-sec-sip-tls.metrics.client.cacertPath" }}
    {{- printf "%s/%s" (include "eric-sec-sip-tls.metrics.client.cacert.mountFolder" .) "client-cacertbundle.pem" -}}
{{- end }}

{{/*
Secret name where the PM Server Client CA root certificate is stored
*/}}
{{- define "eric-sec-sip-tls.metrics.caRootCertSecret" }}
    {{-  printf "%s-%s" (.Values.pm.serviceName) "ca" -}}
{{- end -}}

{{/* PM Server client subject alternative name */}}
{{- define "eric-sec-sip-tls.metrics.client.subAltNameDN" }}
    {{- printf "%s" "certified-scrape-target" -}}
{{- end }}