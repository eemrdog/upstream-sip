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

# Automatically generated annotations for documentation purposes.
{{- define "eric-pm-bulk-reporter.roleBinding.annotations" -}}
  {{- $static := dict -}}
  {{- $_ := set $static "ericsson.com/security-policy.type" "restricted/custom" -}}
  {{- $_ := set $static "ericsson.com/security-policy.capabilities" "audit_write chown kill net_bind_service setgid setuid sys_chroot" -}}
  {{- $annotations := include "eric-pm-bulk-reporter.annotations" . | fromYaml -}}
  {{- include "eric-pm-bulk-reporter.mergeAnnotations" (dict "location" (.Template.Name) "sources" (list $static $annotations)) | trim }}
{{- end -}}
