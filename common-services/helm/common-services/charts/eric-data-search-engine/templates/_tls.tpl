{{- define "eric-data-search-engine.security-tls-secret-volumes-http-server" }}
- name: "http-cert"
  secret:
    secretName: "{{ include "eric-data-search-engine.fullname" . }}-http-cert"
- name: "http-client-cert-internal"
  secret:
    secretName: "{{ include "eric-data-search-engine.fullname" . }}-http-client-cert-internal"
- name: "http-ca-cert"
  secret:
    secretName: "{{ include "eric-data-search-engine.fullname" . }}-http-ca-cert"
{{- end }}

{{- define "eric-data-search-engine.security-tls-secret-volumes-http-client" }}
- name: "http-client-cert-internal"
  secret:
    secretName: "{{ include "eric-data-search-engine.fullname" . }}-http-client-cert-internal"
- name: "sip-tls-trusted-root-cert"
  secret:
    secretName: "eric-sec-sip-tls-trusted-root-cert"
{{- end }}

{{- define "eric-data-search-engine.security-tls-secret-volumes-transport" }}
- name: "transport-cert"
  secret:
    secretName: "{{ include "eric-data-search-engine.fullname" . }}-transport-cert"
- name: "transport-ca-cert"
  secret:
    secretName: "{{ include "eric-data-search-engine.fullname" . }}-transport-ca-cert"
- name: "sip-tls-trusted-root-cert"
  secret:
    secretName: "eric-sec-sip-tls-trusted-root-cert"
{{- end }}

{{- define "eric-data-search-engine.security-tls-secret-volumes-metrics-client" }}
- name: "pm-trusted-ca"
  secret:
    secretName: "{{ .Values.metrics.pmServer }}-ca"
{{- end }}

{{- define "eric-data-search-engine.security-tls-secret-volumes-metrics-server" }}
- name: "pm-server-cert"
  secret:
    secretName: "{{ include "eric-data-search-engine.fullname" . }}-pm-server-cert"
- name: "tlsproxy-client"
  secret:
    secretName: "{{ include "eric-data-search-engine.fullname" . }}-tlsproxy-client"
{{- end }}

{{- define "eric-data-search-engine.security-tls-secret-volume-mounts-http-server" }}
- name: "http-cert"
  mountPath: "/run/secrets/http-certificates"
  readOnly: true
- name: "http-client-cert-internal"
  mountPath: "/run/secrets/http-client-certificates"
  readOnly: true
- name: "http-ca-cert"
  mountPath: "/run/secrets/http-ca-certificates"
  readOnly: true
{{- end }}

{{- define "eric-data-search-engine.security-tls-secret-volume-mounts-http-client" }}
- name: "http-client-cert-internal"
  mountPath: "/run/secrets/http-client-certificates"
  readOnly: true
- name: "sip-tls-trusted-root-cert"
  mountPath: "/run/secrets/sip-tls-trusted-root-cert"
  readOnly: true
{{- end }}

{{- define "eric-data-search-engine.security-tls-secret-volume-mounts-transport" }}
- name: "transport-cert"
  mountPath: "/run/secrets/transport-certificates"
  readOnly: true
- name: "transport-ca-cert"
  mountPath: "/run/secrets/transport-ca-certificates"
  readOnly: true
- name: "sip-tls-trusted-root-cert"
  mountPath: "/run/secrets/sip-tls-trusted-root-cert"
  readOnly: true
{{- end }}

{{- define "eric-data-search-engine.security-tls-secret-volume-mounts-metrics" }}
- name: "pm-server-cert"
  mountPath: "/run/secrets/pm-server-certificates"
  readOnly: true
- name: "pm-trusted-ca"
  mountPath: "/run/secrets/pm-trusted-ca"
  readOnly: true
- name: "tlsproxy-client"
  mountPath: "/run/secrets/tlsproxy-client"
  readOnly: true
- name: "sip-tls-trusted-root-cert"
  mountPath: "/run/secrets/sip-tls-trusted-root-cert"
  readOnly: true
{{- end }}
