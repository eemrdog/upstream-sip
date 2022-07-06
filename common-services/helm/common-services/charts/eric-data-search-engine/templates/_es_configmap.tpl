{{- define "eric-data-search-engine.es-configmap" -}}
{{- $g := fromJson (include "eric-data-search-engine.global" .root ) -}}
apiVersion: v1
kind: ConfigMap
metadata:
  {{- if eq .context "tls" }}
  name: {{ include "eric-data-search-engine.fullname" .root }}-cfg
  {{- else }}
  name: {{ include "eric-data-search-engine.fullname" .root }}-cfg-ingest-notls
  {{- end }}
  annotations:
{{- include "eric-data-search-engine.annotations" .root | indent 4 }}
  labels:
{{- include "eric-data-search-engine.labels" .root | indent 4 }}
data:
  template.json: |
    {
        "index_patterns": [
            "*"
        ],
        "priority": 200,
        "template": {
            "settings": {
                "number_of_shards": "5",
                "refresh_interval": "1s",
                "unassigned" : {
                  "node_left" : {
                    "delayed_timeout" : {{ .root.Values.unassignedNode_leftDelayed_timeout | default "3m" | quote }}
                  }
                }
            }
        },
        "version": {{ include "eric-data-search-engine.version" .root | replace "." "" | replace "-" "" | replace "_" "" }}
    }

  settings.json: |
    {
        "index": {
            "refresh_interval" : "1s"
        }
    }

  elasticsearch.yml: |
    path:
      data: "${ES_HOME}/data"
      logs: "${ES_HOME}/logs"
      repo: ["${ES_HOME}/repository"]

    bootstrap:
      memory_lock: false

    discovery:
      seed_hosts:
        - "{{ include "eric-data-search-engine.fullname" .root }}-discovery"

    cluster:
      initial_master_nodes:
      {{- $replicas := .root.Values.replicaCount.master | int }}
      {{- $hostname := include "eric-data-search-engine.fullname" .root }}
      {{- range $i, $e := untilStep 0 $replicas 1 }}
        - "{{ $hostname }}-master-{{ $i }}"
      {{- end }}

    http:
      compression: true
      {{- include "eric-data-search-engine.service-network-protocol" .root | nindent 6 }}

    transport:
      {{- include "eric-data-search-engine.service-network-protocol" .root | nindent 6 }}

    {{- if and .root.Values.brAgent.enabled (eq .root.Values.brAgent.backupRepository.type "s3") }}

    s3.client.default.endpoint: {{ required "brAgent.backupRepository.s3.endPoint is required when brAgent.backupRepository.type=s3" .root.Values.brAgent.backupRepository.s3.endPoint | quote }}
    s3.client.default.protocol: "http"
    s3.client.default.path_style_access: true
    {{- end }}

    {{- if $g.security.tls.enabled }}

    transport.type: tls
    tls_plugin.internode.mutual: true
    tls_plugin.internode.hostname_verification: {{ .root.Values.service.endpoints.internode.tls.verifyClientHostname }}
    tls_plugin.internode.cert: "/run/secrets/transport-certificates/srvcert.pem"
    tls_plugin.internode.privatekey: "/run/secrets/transport-certificates/srvprivkey.pem"
    tls_plugin.internode.ca: "/run/secrets/transport-ca-certificates/client-cacertbundle.pem"

    {{- if eq .context "tls" }}

    http.type: tls
    tls_plugin.http.type: tls
    {{- if eq .root.Values.service.endpoints.rest.tls.verifyClientCertificate "optional" }}
    tls_plugin.http.mutual: false
    {{- else }}
    tls_plugin.http.mutual: true
    {{- end }}
    tls_plugin.http.hostname_verification: {{ .root.Values.service.endpoints.rest.tls.verifyClientHostname }}
    tls_plugin.http.cert: "/run/secrets/http-certificates/srvcert.pem"
    tls_plugin.http.privatekey: "/run/secrets/http-certificates/srvprivkey.pem"
    tls_plugin.http.ca: "/run/secrets/http-ca-certificates/client-cacertbundle.pem"
    {{- else }}

    tls_plugin.http.type: notls
    {{- end }}
    {{- end }}

  log4j2.properties: |
    status = {{ .root.Values.logLevel | default "info" | lower }}

    appender.console.type = Console
    appender.console.name = console
    appender.console.layout.type = PatternLayout
    appender.console.layout.pattern = [%d{YYYY-MM-dd'T'HH:mm:ss.sssXXX}][%-5p][%-25c{1.}] %marker%m%n

    rootLogger.level = {{ .root.Values.logLevel | default "info" | lower }}
    rootLogger.appenderRef.console.ref = console

    logger.deprecation.name = org.elasticsearch.deprecation
    logger.deprecation.level = error

  jvm.options: |
    #-Xms1g
    #-Xmx1g

    ## GC configuration
    -XX:+UseConcMarkSweepGC
    -XX:CMSInitiatingOccupancyFraction=75
    -XX:+UseCMSInitiatingOccupancyOnly

    ## optimizations

    # pre-touch memory pages used by the JVM during initialization
    -XX:+AlwaysPreTouch

    ## basic

    # explicitly set the stack size
    -Xss1m

    # The virtual file /proc/self/cgroup should list the current cgroup
    # membership. For each hierarchy, you can follow the cgroup path from
    # this file to the cgroup filesystem (usually /sys/fs/cgroup/) and
    # introspect the statistics for the cgroup for the given
    # hierarchy. Alas, Docker breaks this by mounting the container
    # statistics at the root while leaving the cgroup paths as the actual
    # paths. Therefore, Elasticsearch provides a mechanism to override
    # reading the cgroup path from /proc/self/cgroup and instead uses the
    # cgroup path defined the JVM system property
    # es.cgroups.hierarchy.override. Therefore, we set this value here so
    # that cgroup statistics are available for the container this process
    # will run in.
    -Des.cgroups.hierarchy.override=/

    # set to headless, just in case
    -Djava.awt.headless=true

    # ensure UTF-8 encoding by default (e.g. filenames)
    -Dfile.encoding=UTF-8

    # use our provided JNA always versus the system one
    -Djna.nosys=true

    # turn off a JDK optimization that throws away stack traces for common
    # exceptions because stack traces are important for debugging
    -XX:-OmitStackTraceInFastThrow

    # flags to configure Netty
    -Dio.netty.noUnsafe=true
    -Dio.netty.noKeySetOptimization=true
    -Dio.netty.recycler.maxCapacityPerThread=0

    # log4j 2
    -Dlog4j.shutdownHookEnabled=false
    -Dlog4j2.disable.jmx=true
    -Dlog4j2.formatMsgNoLookups=true

    -Djava.io.tmpdir=${ES_TMPDIR}

    ## heap dumps

    # generate a heap dump when an allocation from the Java heap fails
    # heap dumps are created in the working directory of the JVM
    -XX:+HeapDumpOnOutOfMemoryError

    # specify an alternative path for heap dumps; ensure the directory exists and
    # has sufficient space
    -XX:HeapDumpPath=data

    # specify an alternative path for JVM fatal error logs
    -XX:ErrorFile=logs/hs_err_pid%p.log

    # temporary workaround for C2 bug with JDK 10 on hardware with AVX-512
    10-:-XX:UseAVX=2

    # Security policy
    -Djava.security.policy=file:///etc/elasticsearch/java.policy

  jvmdata.options: |
    -Xms{{ .root.Values.jvmHeap.data }}
    -Xmx{{ .root.Values.jvmHeap.data }}

  jvmmaster.options: |
    -Xms{{ .root.Values.jvmHeap.master }}
    -Xmx{{ .root.Values.jvmHeap.master }}

  jvmingest.options: |
    -Xms{{ .root.Values.jvmHeap.ingest }}
    -Xmx{{ .root.Values.jvmHeap.ingest }}

  java.policy: |
    grant {
        permission java.io.FilePermission "/run/secrets/-", "read";
    };

{{ end }}
