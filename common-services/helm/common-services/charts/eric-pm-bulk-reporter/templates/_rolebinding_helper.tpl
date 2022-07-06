{{- define "eric-pm-bulk-reporter.roleBinding.reference" -}}
  {{- if .Values.global -}}
    {{- if .Values.global.security -}}
      {{- if .Values.global.security.policyReferenceMap -}}
        {{ $mapped := index .Values "global" "security" "policyReferenceMap" "plc-38dc0a0ee2b2564ef10039d2c6c0e0" }}
        {{- if $mapped -}}
          {{ $mapped }}
        {{- else -}}
          plc-38dc0a0ee2b2564ef10039d2c6c0e0
        {{- end -}}
      {{- else -}}
        plc-38dc0a0ee2b2564ef10039d2c6c0e0
      {{- end -}}
    {{- else -}}
      plc-38dc0a0ee2b2564ef10039d2c6c0e0
    {{- end -}}
  {{- else -}}
    plc-38dc0a0ee2b2564ef10039d2c6c0e0
  {{- end -}}
{{- end -}}

{{- define "eric-pm-bulk-reporter.roleBinding.annotations" -}}
# Automatically generated annotations for documentation purposes.
ericsson.com/security-policy.type: "restricted/custom"
ericsson.com/security-policy.capabilities: "audit_write chown kill net_bind_service setgid setuid sys_chroot"
{{- end -}}
