{{- define "eric-log-transformer.metrics-container" }}
{{- $g := fromJson (include "eric-log-transformer.global" .) }}
- name: metrics
  imagePullPolicy: {{ .Values.imageCredentials.registry.imagePullPolicy | default $g.registry.imagePullPolicy | quote }}
  image: {{ include "eric-log-transformer.metrics-path" . | quote  }}
  args:
    - /opt/redirect/stdout-redirect
    - -redirect
    - {{ include "eric-log-transformer.redirection" . }}
    - -size
    - "1"
    - -logfile
    - /logs/metrics.log
    - -container
    - metrics
    - -service-id
    - {{ include "eric-log-transformer.fullname" . }}
    - --
    - java
    - -Dlog4j.configurationFile=/opt/ls_exporter/bin/log4j2.properties
    - -Dlog4j2.formatMsgNoLookups=true
    - -jar
    - /opt/ls_exporter/bin/ls-metrics-exporter.jar
    - /opt/ls_exporter/bin/application.properties
  securityContext:
    allowPrivilegeEscalation: false
    privileged: false
    readOnlyRootFilesystem: true
    runAsNonRoot: true
    capabilities:
      drop:
        - all
  env:
  - name: TZ
    value: {{ $g.timezone | quote }}
  - name: LOG_LEVEL
    value: {{ .Values.logLevel | quote | default "error" | lower }}
  - name: "SERVICE_ID"
    value: {{ include "eric-log-transformer.fullname" . | quote }}
  ports:
  - name: "metrics"
    containerPort: 9114
    protocol: "TCP"
  readinessProbe:
    httpGet:
      path: /
      port: 9600
    initialDelaySeconds: {{ .Values.probes.metrics.readinessProbe.initialDelaySeconds }}
    timeoutSeconds: {{ .Values.probes.metrics.readinessProbe.timeoutSeconds }}
    periodSeconds: {{ .Values.probes.metrics.readinessProbe.periodSeconds }}
    successThreshold: {{ .Values.probes.metrics.readinessProbe.successThreshold }}
    failureThreshold: {{ .Values.probes.metrics.readinessProbe.failureThreshold }}
  livenessProbe:
    httpGet:
      path: /health
      port: 9114
    initialDelaySeconds: {{ .Values.probes.metrics.livenessProbe.initialDelaySeconds }}
    timeoutSeconds: {{ .Values.probes.metrics.livenessProbe.timeoutSeconds }}
    periodSeconds: {{ .Values.probes.metrics.livenessProbe.periodSeconds }}
    successThreshold: {{ .Values.probes.metrics.livenessProbe.successThreshold }}
    failureThreshold: {{ .Values.probes.metrics.livenessProbe.failureThreshold }}
  resources:
    limits:
      {{- if .Values.resources.metrics.limits.cpu }}
      cpu: {{ .Values.resources.metrics.limits.cpu | quote }}
      {{- end }}
      {{- if .Values.resources.metrics.limits.memory }}
      memory: {{ .Values.resources.metrics.limits.memory | quote }}
      {{- end }}
      {{- if index .Values.resources.metrics.limits "ephemeral-storage" }}
      ephemeral-storage: {{ index .Values.resources.metrics.limits "ephemeral-storage"  | quote }}
      {{- end }}
    requests:
      {{- if .Values.resources.metrics.requests.cpu }}
      cpu: {{ .Values.resources.metrics.requests.cpu | quote }}
      {{- end }}
      {{- if .Values.resources.metrics.requests.memory }}
      memory: {{ .Values.resources.metrics.requests.memory | quote }}
      {{- end }}
      {{- if index .Values.resources.metrics.requests "ephemeral-storage" }}
      ephemeral-storage: {{ index .Values.resources.metrics.requests "ephemeral-storage"  | quote }}
      {{- end }}
  volumeMounts:
  - name: "metrics-exporter-cfg"
    mountPath: /opt/ls_exporter/bin/application.properties
    subPath: application.properties
    readOnly: true
  - name: "metrics-exporter-cfg"
    mountPath: /opt/ls_exporter/bin/log4j2.properties
    subPath: log4j2.properties
    readOnly: true
    {{- if has "stream" .Values.log.outputs }}
      {{- include "eric-log-transformer.logshipper-storage-path" (mergeOverwrite . (fromJson (include "eric-log-transformer.logshipper-context" .))) | indent 2 }}
    {{- end }}
{{- end -}}

{{- define "eric-log-transformer.metrics-annotations" }}
prometheus.io/scrape: {{ .Values.metrics.enabled | quote }}
prometheus.io/port: "9114"
prometheus.io/path: "/metrics"
{{- end }}

{{- define "eric-log-transformer.tlsproxy-container" }}
{{- $g := fromJson (include "eric-log-transformer.global" .) }}
- name: tlsproxy
  imagePullPolicy: {{ .Values.imageCredentials.registry.imagePullPolicy | default $g.registry.imagePullPolicy | quote }}
  image: {{ include "eric-log-transformer.tlsproxy-path" . | quote  }}
  args:
    - /opt/redirect/stdout-redirect
    - -redirect
    - {{ include "eric-log-transformer.redirection" . }}
    - -size
    - "1"
    - -logfile
    - /logs/tlsproxy.log
    - --
    - /opt/tls_proxy/bin/tlsproxy
  securityContext:
    allowPrivilegeEscalation: false
    privileged: false
    readOnlyRootFilesystem: true
    runAsNonRoot: true
    capabilities:
      drop:
        - all
  ports:
  - name: "metrics-tls"
    containerPort: 9115
    protocol: "TCP"
  env:
  - name: "TZ"
    value: {{ $g.timezone | quote }}
  - name: "LOGLEVEL"
    value: {{ .Values.logLevel | quote }}
  - name: "TARGET"
    value: "http://localhost:9114"
  - name: "PORT"
    value: "9115"
  - name: "CERT"
    value: "/run/secrets/pm-server-certificates/srvcert.pem"
  - name: "KEY"
    value: "/run/secrets/pm-server-certificates/srvprivkey.pem"
  - name: "CLIENT_CA"
    value: "/run/secrets/pm-trusted-ca/client-cacertbundle.pem"
  - name: "ADP_LOG_VERSION"
    value: "1.0.0"
  - name: "SERVICE_ID"
    value: {{ include "eric-log-transformer.fullname" . | quote }}
  - name: "CONTAINER_NAME"
    value: "tlsproxy"
  - name: "NAMESPACE"
    valueFrom:
      fieldRef:
        fieldPath: "metadata.namespace"
  - name: "NODE_NAME"
    valueFrom:
      fieldRef:
        fieldPath: "spec.nodeName"
  - name: "POD_NAME"
    valueFrom:
      fieldRef:
        fieldPath: "metadata.name"
  - name: "POD_UID"
    valueFrom:
      fieldRef:
        fieldPath: "metadata.uid"
  livenessProbe:
    exec:
      command:
      - /liveness-probe.sh
    initialDelaySeconds: {{ .Values.probes.tlsproxy.livenessProbe.initialDelaySeconds }}
    timeoutSeconds: {{ .Values.probes.tlsproxy.livenessProbe.timeoutSeconds }}
    periodSeconds: {{ .Values.probes.tlsproxy.livenessProbe.periodSeconds }}
    successThreshold: {{ .Values.probes.tlsproxy.livenessProbe.successThreshold }}
    failureThreshold: {{ .Values.probes.tlsproxy.livenessProbe.failureThreshold }}
  readinessProbe:
    exec:
      command:
      - /readiness-probe.sh
    initialDelaySeconds: {{ .Values.probes.tlsproxy.readinessProbe.initialDelaySeconds }}
    timeoutSeconds: {{ .Values.probes.tlsproxy.readinessProbe.timeoutSeconds }}
    periodSeconds: {{ .Values.probes.tlsproxy.readinessProbe.periodSeconds }}
    successThreshold: {{ .Values.probes.tlsproxy.readinessProbe.successThreshold }}
    failureThreshold: {{ .Values.probes.tlsproxy.readinessProbe.failureThreshold }}
  resources:
    limits:
      {{- if .Values.resources.tlsproxy.limits.cpu }}
      cpu: {{ .Values.resources.tlsproxy.limits.cpu | quote }}
      {{- end }}
      {{- if .Values.resources.tlsproxy.limits.memory }}
      memory: {{ .Values.resources.tlsproxy.limits.memory | quote }}
      {{- end }}
      {{- if index .Values.resources.tlsproxy.limits "ephemeral-storage" }}
      ephemeral-storage: {{ index .Values.resources.tlsproxy.limits "ephemeral-storage" | quote }}
      {{- end }}
    requests:
      {{- if .Values.resources.tlsproxy.requests.cpu }}
      cpu: {{ .Values.resources.tlsproxy.requests.cpu | quote }}
      {{- end }}
      {{- if .Values.resources.tlsproxy.requests.memory }}
      memory: {{ .Values.resources.tlsproxy.requests.memory | quote }}
      {{- end }}
      {{- if index .Values.resources.tlsproxy.requests "ephemeral-storage" }}
      ephemeral-storage: {{ index .Values.resources.tlsproxy.requests "ephemeral-storage" | quote }}
      {{- end }}
  volumeMounts:
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
    {{- if has "stream" .Values.log.outputs }}
      {{- include "eric-log-transformer.logshipper-storage-path" (mergeOverwrite . (fromJson (include "eric-log-transformer.logshipper-context" .))) | indent 2 }}
    {{- end }}
{{- end }}
