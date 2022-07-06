{{/*
Default container template.
*/}}
{{- define "eric-data-search-engine-curator.container-template" }}
{{- $g := fromJson (include "eric-data-search-engine-curator.global" .) }}
template:
  metadata:
    name: {{ include "eric-data-search-engine-curator.fullname" . | quote }}
    labels:
      {{- include "eric-data-search-engine-curator.labels" . | indent 6 }}
    annotations:
      {{- include "eric-data-search-engine-curator.annotations" . | indent 6 }}
  spec:
    {{- if .Capabilities.APIVersions.Has "v1/ServiceAccount" }}
    serviceAccount: ""
    {{- end }}
    {{- if .Values.tolerations }}
    tolerations: {{- toYaml .Values.tolerations | nindent 6 }}
    {{- end }}
    serviceAccountName: "{{ include "eric-data-search-engine-curator.fullname" . }}-sa"
    terminationGracePeriodSeconds: {{ .Values.terminationGracePeriodSeconds }}
    {{- if .Values.podPriority.priorityClassName }}
    priorityClassName: {{ .Values.podPriority.priorityClassName | quote }}
    {{- end }}
    containers:
      - name: "curator"
        image: {{ include "eric-data-search-engine-curator.image-registry-url" . | quote }}
        imagePullPolicy: {{ .Values.imageCredentials.registry.imagePullPolicy | default $g.registry.imagePullPolicy | quote }}
        {{- $redirect := "stdout" }}
        {{- if has "stream" .Values.log.outputs }}
          {{- $redirect = "file" }}
          {{- if has "stdout" .Values.log.outputs }}
            {{- $redirect = "all" }}
          {{- end }}
        {{- end }}
        command:
          - /opt/stdout/stdout-redirect
          - -redirect
          - {{ $redirect }}
          - -size
          - "5"
          - -rotate
          - "5"
          - -logfile
          - /logs/curator.log
          - --
          - curator
          {{- if .Values.dryRun }}
          - --dry-run
          {{- end }}
          - --config
          - /opt/curator/config.yaml
          - /opt/curator/actions.yaml
        securityContext:
          allowPrivilegeEscalation: false
          privileged: false
          readOnlyRootFilesystem: true
          runAsNonRoot: true
          capabilities:
            drop:
              - "all"
        volumeMounts:
          - name: "{{ include "eric-data-search-engine-curator.fullname" . }}-cm"
            mountPath: "/opt/curator"
            readOnly: true
        {{- if $g.security.tls.enabled }}
          - name: "se-http-client-cert"
            mountPath: "/run/secrets/se-http-client-cert"
            readOnly: true
          - name: "sip-tls-trusted-root-cert"
            mountPath: "/run/secrets/sip-tls-trusted-root-cert"
            readOnly: true
        {{- end }}
        {{- if has "stream" .Values.log.outputs }}
          {{- include "eric-data-search-engine-curator.logshipper-storage-path" . | indent 10 }}
        {{- end }}
        resources:
          limits:
            {{- if .Values.resources.curator.limits.cpu }}
            cpu: {{ .Values.resources.curator.limits.cpu | quote }}
            {{- end }}
            {{- if .Values.resources.curator.limits.memory }}
            memory: {{ .Values.resources.curator.limits.memory | quote }}
            {{- end }}
            {{- if index .Values.resources.curator.limits "ephemeral-storage" }}
            ephemeral-storage: {{ index .Values.resources.curator.limits "ephemeral-storage"  | quote }}
            {{- end }}
          requests:
            {{- if .Values.resources.curator.requests.cpu }}
            cpu: {{ .Values.resources.curator.requests.cpu | quote }}
            {{- end }}
            {{- if .Values.resources.curator.requests.memory }}
            memory: {{ .Values.resources.curator.requests.memory | quote }}
            {{- end }}
            {{- if index .Values.resources.curator.requests "ephemeral-storage" }}
            ephemeral-storage: {{ index .Values.resources.curator.requests "ephemeral-storage"  | quote }}
            {{- end }}
        env:
          - name: "TZ"
            value: {{ $g.timezone | quote }}
    {{- if has "stream" .Values.log.outputs }}
      {{- include "eric-data-search-engine-curator.logshipper-container" . | indent 6 }}
    {{- end }}
  {{- if (or .Values.nodeSelector $g.nodeSelector) }}
    nodeSelector: {{- include "eric-data-search-engine-curator.nodeSelector" . | nindent 6 }}
  {{- end }}
    volumes:
      - name: "{{ include "eric-data-search-engine-curator.fullname" . }}-cm"
        configMap:
          name: "{{ include "eric-data-search-engine-curator.fullname" . }}-cm"
          items:
            - key: "config.yaml"
              path: "config.yaml"
            - key: "actions.yaml"
              path: "actions.yaml"
    {{- if has "stream" .Values.log.outputs }}
      {{- include "eric-data-search-engine-curator.logshipper-volume" . | indent 6 }}
    {{- end }}
    {{- if $g.security.tls.enabled }}
      - name: "se-http-client-cert"
        secret:
          secretName: "{{ include "eric-data-search-engine-curator.fullname" . }}-se-http-client-cert"
      - name: "sip-tls-trusted-root-cert"
        secret:
          secretName: "eric-sec-sip-tls-trusted-root-cert"
    {{- end }}
    restartPolicy: "Never"
  {{- if (or .Values.imageCredentials.pullSecret $g.pullSecret) }}
    imagePullSecrets:
      - name: {{ (or .Values.imageCredentials.pullSecret $g.pullSecret) | quote }}
  {{- end }}
{{- end -}}
