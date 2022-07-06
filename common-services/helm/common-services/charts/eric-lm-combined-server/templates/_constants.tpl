{{/* vim: set filetype=mustache: */}}

{{/*
host address for internal LM API (e.g. liveness and readiness)
*/}}
{{- define "eric-lm-combined-server.lch-internalAPIHost" -}}
0.0.0.0
{{- end -}}

{{/*
port for internal LM API (e.g. liveness and readiness)
*/}}
{{- define "eric-lm-combined-server.lch-internalAPIPort" -}}
8081
{{- end -}}

{{/*
host address for LM client-facing API
*/}}
{{- define "eric-lm-combined-server.lch-externalAPIHost" -}}
0.0.0.0
{{- end -}}

{{/*
port for LM client-facing API
*/}}
{{- define "eric-lm-combined-server.lch-insecureExternalAPIPort" -}}
8080
{{- end -}}

{{/*
Set period between LCH test of the LSC's health (milliseconds)
*/}}
{{- define "eric-lm-combined-server.lch-lscHealthCheckPeriodMillis" -}}
5000
{{- end -}}

{{/*
Kubernetes liveness probe port
*/}}
{{- define "eric-lm-combined-server.lsc-livenessProbePort" -}}
9090
{{- end -}}

{{/*
Kubernetes readiness probe port
*/}}
{{- define "eric-lm-combined-server.lsc-readinessProbePort" -}}
9091
{{- end -}}

{{/*
Set LSC Service Type
*/}}
{{- define "eric-lm-combined-server.lsc-service-type" -}}
ClusterIP
{{- end -}}

{{/*
Set LSC Service Address
*/}}
{{- define "eric-lm-combined-server.lsc-service-address" -}}
{{ include "eric-lm-combined-server.name" . }}-license-server-client
{{- end -}}

{{/*
protocol used for jdbc access to the db
*/}}
{{- define "eric-lm-combined-server.database-protocol" -}}
jdbc:postgresql
{{- end -}}

{{/*
hibernate dialect for the sql server type
*/}}
{{- define "eric-lm-combined-server.database-dialect" -}}
org.hibernate.dialect.PostgreSQL94Dialect
{{- end -}}

{{/*
the jdbc driver to use
*/}}
{{- define "eric-lm-combined-server.database-driver" -}}
org.postgresql.Driver
{{- end -}}

{{/*
Private key and certificate files for client authentication of all LM Postgres DB clients
*/}}
{{- define "eric-lm-combined-server.db.client-cert.cert-file" -}}
adp_lm_db_client.crt
{{- end -}}
{{- define "eric-lm-combined-server.db.client-cert.key-file" -}}
adp_lm_db_client_private.key
{{- end -}}

{{/*
Private key and certificate files for postgres database admin user (hardcoded as "postgres") authentication
*/}}
{{- define "eric-lm-combined-server.db.admin-cert.cert-file" -}}
adp_lm_db_admin.crt
{{- end -}}
{{- define "eric-lm-combined-server.db.admin-cert.pem-key-file" -}}
adp_lm_db_admin_private.key
{{- end -}}

{{/*
CA certificate file for signing client certificates for the LCH REST API
*/}}
{{- define "eric-lm-combined-server.lch.client-ca.cert-file" -}}
adp_lm_CA.crt
{{- end -}}

{{/*
Private key and certificate files for server authentication of the LCH REST API
*/}}
{{- define "eric-lm-combined-server.lch.server-cert.cert-file" -}}
adp_lm.crt
{{- end -}}
{{- define "eric-lm-combined-server.lch.server-cert.key-file" -}}
adp_lm_private.key
{{- end -}}

{{/*
Minimum flyway schema version for lch-managed db schemas
*/}}
{{- define "eric-lm-combined-server.database.lchMigrationVersion" -}}
1.9
{{- end -}}

{{/*
Private key and certificate files for client authentication of ASIH clients
*/}}
{{- define "eric-lm-combined-server.asih.client-cert.cert-file" -}}
adp_lm_asih_client.crt
{{- end -}}
{{- define "eric-lm-combined-server.asih.client-cert.key-file" -}}
adp_lm_asih_client_private.key
{{- end -}}
