{{/*
Various security context parameters
*/}}

{{/*
sip-tls-init container security context parameter
*/}}
{{- define "eric-sec-sip-tls.sip-tls-init.securityContext" -}}
securityContext:
  allowPrivilegeEscalation: false
  privileged: false
  readOnlyRootFilesystem: true
  runAsNonRoot: true
  {{- if and ( ge .Capabilities.KubeVersion.Major "1" ) ( ge .Capabilities.KubeVersion.Minor "19" ) }}
  {{- include "eric-sec-sip-tls.seccompProfile.sip-tls-init" . | indent 2 }}
  {{- end }}
  capabilities:
    drop:
      - all
{{- end -}}

{{/*
sip-tls container security context parameter
*/}}
{{- define "eric-sec-sip-tls.sip-tls.securityContext" -}}
securityContext:
  allowPrivilegeEscalation: false
  privileged: false
  readOnlyRootFilesystem: true
  runAsNonRoot: true
  {{- if and ( ge .Capabilities.KubeVersion.Major "1" ) ( ge .Capabilities.KubeVersion.Minor "19" ) }}
  {{- include "eric-sec-sip-tls.seccompProfile.sip-tls" . | indent 2 }}
  {{- end }}
  capabilities:
    drop:
      - all
{{- end -}}

{{/*
sip-tls-supervisor container security context parameter
*/}}
{{- define "eric-sec-sip-tls.sip-tls-supervisor.securityContext" -}}
securityContext:
  allowPrivilegeEscalation: false
  privileged: false
  readOnlyRootFilesystem: true
  runAsNonRoot: true
  {{- if and ( ge .Capabilities.KubeVersion.Major "1" ) ( ge .Capabilities.KubeVersion.Minor "19" ) }}
  {{- include "eric-sec-sip-tls.seccompProfile.sip-tls-supervisor" . | indent 2 }}
  {{- end }}
  capabilities:
    drop:
      - all
{{- end -}}