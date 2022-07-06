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