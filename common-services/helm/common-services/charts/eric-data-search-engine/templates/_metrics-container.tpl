{{- define "eric-data-search-engine.metrics-container" }}
{{- $g := fromJson (include "eric-data-search-engine.global" .root) }}
- name: metrics
  imagePullPolicy: {{ .root.Values.imageCredentials.registry.imagePullPolicy | default $g.registry.imagePullPolicy | quote }}
  image: {{ include "eric-data-search-engine.metrics.image-registry-url" .root | quote }}
  {{- $connection_settings := "--es.uri=http://localhost" }}
  {{- if and $g.security.tls.enabled (eq .context "tls") }}
    {{- $connection_settings = "--es.ca=/run/secrets/sip-tls-trusted-root-cert/ca.crt --es.client-private-key=/run/secrets/http-client-certificates/cliprivkey.pem --es.client-cert=/run/secrets/http-client-certificates/clicert.pem --es.uri=https://localhost" }}
  {{- end }}
  args:
    - /opt/redirect/stdout-redirect
    - -redirect
    - {{ include "eric-data-search-engine.log-redirect" .root }}
    - -run
    - elasticsearch_exporter {{ $connection_settings }}:9200 --log.level={{ .root.Values.logLevel }} --web.listen-address=:9114
    {{- if has "stream" .root.Values.log.outputs }}
    - -logfile
    - {{ .root.Values.logshipper.storagePath }}/metrics.log
    - -size
    - "1"
    {{- end }}
  securityContext:
    allowPrivilegeEscalation: false
    privileged: false
    readOnlyRootFilesystem: true
    runAsNonRoot: true
    capabilities:
      drop:
        - "all"
  ports:
  - name: http-metrics
    containerPort: 9114
    protocol: TCP
  env:
  - name: TZ
    value: {{ $g.timezone | quote }}
  - name: "ES_PORT"
    value: "9200"
  - name: "ES_TLS"
  {{- if and $g.security.tls.enabled (eq .context "tls") }}
    value: "true"
  {{- else }}
    value: "false"
  {{- end }}
  readinessProbe:
    exec:
      command:
      - /readiness-probe.sh
    initialDelaySeconds: {{ .root.Values.probes.metrics.readinessProbe.initialDelaySeconds | default .root.Values.readinessProbe.metrics.initialDelaySeconds }}
    timeoutSeconds: {{ .root.Values.probes.metrics.readinessProbe.timeoutSeconds | default .root.Values.readinessProbe.metrics.timeoutSeconds }}
  livenessProbe:
    httpGet:
      path: /healthz
      port: 9114
    initialDelaySeconds: {{ .root.Values.probes.metrics.livenessProbe.initialDelaySeconds | default .root.Values.livenessProbe.metrics.initialDelaySeconds }}
    timeoutSeconds: {{ .root.Values.probes.metrics.livenessProbe.timeoutSeconds | default .root.Values.livenessProbe.metrics.timeoutSeconds }}
  resources: {{- include "eric-data-search-engine.resources" .root.Values.resources.metrics | nindent 4 }}
  volumeMounts:
{{- if and $g.security.tls.enabled (eq .context "tls") }}
  {{- include "eric-data-search-engine.security-tls-secret-volume-mounts-http-client" .root | indent 2 }}
{{- end }}
{{- if has "stream" .root.Values.log.outputs }}
  {{- include "eric-data-search-engine.logshipper-storage-path" .root | indent 2 }}
{{- end }}
{{- end -}}

{{- define "eric-data-search-engine.metrics-annotations" }}
prometheus.io/scrape: {{ .Values.metrics.enabled | quote }}
prometheus.io/port: "9114"
prometheus.io/path: "/metrics"
{{- end }}

{{- define "eric-data-search-engine.tlsproxy-container" }}
{{- $g := fromJson (include "eric-data-search-engine.global" .root) }}
- name: tlsproxy
  imagePullPolicy: {{ .root.Values.imageCredentials.registry.imagePullPolicy | default $g.registry.imagePullPolicy | quote }}
  image: {{ include "eric-data-search-engine.tlsproxy.image-registry-url" .root | quote }}
  args:
    - /opt/redirect/stdout-redirect
    - -redirect
    - {{ include "eric-data-search-engine.log-redirect" .root }}
    - -run
    - /opt/tls_proxy/bin/tlsproxy
    {{- if has "stream" .root.Values.log.outputs }}
    - -logfile
    - {{ .root.Values.logshipper.storagePath }}/tlsproxy.log
    - -size
    - "1"
    {{- end }}
  securityContext:
    allowPrivilegeEscalation: false
    privileged: false
    readOnlyRootFilesystem: true
    runAsNonRoot: true
    capabilities:
      drop:
        - "all"
  ports:
  - name: metrics-tls
    containerPort: 9115
    protocol: TCP
  env:
  - name: "TZ"
    value: {{ $g.timezone | quote }}
  - name: "ES_PORT"
  - name: "LOGLEVEL"
    value: {{ .root.Values.logLevel | quote }}
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
  - name: "SERVICE_ID"
    value: {{ include "eric-data-search-engine.fullname" .root }}
  - name: "ADP_LOG_VERSION"
    value: "1.1.0"
  - name: "CONTAINER_NAME"
    value: "tlsproxy"
  readinessProbe:
    exec:
      command:
      - /readiness-probe.sh
    initialDelaySeconds: {{ .root.Values.probes.tlsproxy.readinessProbe.initialDelaySeconds }}
    timeoutSeconds: {{ .root.Values.probes.tlsproxy.readinessProbe.timeoutSeconds }}
  livenessProbe:
    exec:
      command:
      - /liveness-probe.sh
    initialDelaySeconds: {{ .root.Values.probes.tlsproxy.livenessProbe.initialDelaySeconds | default .root.Values.livenessProbe.tlsproxy.initialDelaySeconds }}
    timeoutSeconds: {{ .root.Values.probes.tlsproxy.livenessProbe.timeoutSeconds | default .root.Values.livenessProbe.tlsproxy.timeoutSeconds }}
  resources: {{- include "eric-data-search-engine.resources" .root.Values.resources.tlsproxy | nindent 4 }}
  volumeMounts:
    {{- include "eric-data-search-engine.security-tls-secret-volume-mounts-metrics" .root | indent 2 }}
    {{- if has "stream" .root.Values.log.outputs }}
      {{- include "eric-data-search-engine.logshipper-storage-path" .root | indent 2 }}
    {{- end }}
{{- end }}
