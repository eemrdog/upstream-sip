
{{- define "eric-log-transformer.logstash-config.adp-json-transformation-unknown" }}
mutate {
  add_field => {
    "timestamp" => "%{@timestamp}"
    "version" => "0.2.0"
  }
}

if [kubernetes][labels][app_kubernetes_io/name] {
  mutate {
    add_field => {
      "service_id" => "%{[kubernetes][labels][app_kubernetes_io/name]}"
    }
  }
} else if [kubernetes][labels][app][kubernetes][io/name] {
  mutate {
    add_field => {
      "service_id" => "%{[kubernetes][labels][app][kubernetes][io/name]}"
    }
  }
}
else {
  mutate {
    add_field => {
      "service_id" => "UNKNOWN"
    }
  }
}

if [kubernetes][pod][name] and [kubernetes][container][name] {
  mutate {
    add_field => {
      "[metadata][ul_id]" => "%{[kubernetes][pod][name]} %{[kubernetes][container][name]}"
    }
  }
}

ruby {
  code => "
    if (event.get('stream') == 'stderr')
      event.set('severity', 'error')
    else
      event.set('severity', 'info')
    end
  "
}
{{- end }}

{{- define "eric-log-transformer.logstash-config.filebeat-input-filter" }}
{{- if .Values.config.filebeat.input.filter }}
{{ .Values.config.filebeat.input.filter }}
{{- end }}
{{- end }}

{{- define "eric-log-transformer.logstash-config.adp-json" }}
{{- include "eric-log-transformer.logstash-config.json-validation" . -}}

{{- if .Values.config.adpJson.transformation.enabled }}
if ![{{ .Values.config.adpJson.decodedAdpJsonField }}] or ("unknown" in [tags]) {
  {{- include "eric-log-transformer.logstash-config.adp-json-transformation-unknown" . | indent 4 }}
}
else {
  {{- include "eric-log-transformer.logstash-config.json-transformation" . | nindent 2 }}
}

mutate {
  remove_field => [
    "agent",
    "beat",
    "container",
    "ecs",
    "host",
    "input",
    {{ .Values.config.adpJson.decodedAdpJsonField | quote }},
    "log",
    "offset",
    "prospector",
    "source",
    "stream",
    "type",
    "tags",
    "[kubernetes][container][image]",
    "[kubernetes][labels]",
    "[kubernetes][namespace_labels]",
    "[kubernetes][namespace_uid]",
    "[kubernetes][node][hostname]",
    "[kubernetes][node][labels]",
    "[kubernetes][node][uid]",
    "[kubernetes][pod][ip]"
  ]
}
{{- end }}
{{- end }}

{{- define "eric-log-transformer.logstash-config.json-validation" }}
{{- $ti := fromJson (include "eric-log-transformer.testInternal" .) -}}
{{- if .Values.config.adpJson.validation.enabled }}
{{- if .Values.config.adpJson.decodedAdpJsonField }}
if [{{ .Values.config.adpJson.decodedAdpJsonField }}] {
  ruby {
    path => {{ $ti.scriptPath | default "/opt/adp/logstash-ruby-scripts/adp-json-validation.rb" | quote }}
    script_params => {
      "schema_dir" => {{ $ti.schemaPath | default "/opt/adp/log-event-json-schema" | quote }}
      "source_field" => {{ .Values.config.adpJson.decodedAdpJsonField | quote }}
      "tag_on_failure" => "unknown"
      "report_field" => "schema_errors"
    }
  }
}
{{- end }}
{{- end }}
{{- end }}

{{- define "eric-log-transformer.logstash-config.json-transformation" }}
ruby {
  code => '
    jsonData = event.get({{ .Values.config.adpJson.decodedAdpJsonField | quote }})
    if (jsonData.class == Hash)
      if jsonData.key?("@timestamp")
        jsonData["@timestamp"] = LogStash::Timestamp.new(jsonData.delete("@timestamp"))
      end
      if jsonData.key?("timestamp")
        jsonData["timestamp"] = LogStash::Timestamp.new(jsonData.delete("timestamp"))
      end
      jsonData.each do |k, v|
        begin
          event.set(k, v)
        rescue StandardError => e
          errMsg = e.message
          backtrace = e.backtrace.inspect
          puts errMsg.to_s << "  " << backtrace.to_s << "  " << jsonData.to_s
        end
      end
    end
  '
}
if ![timestamp] {
  mutate {
    add_field => {
      "timestamp" => "%{@timestamp}"
    }
  }
}
{{- end }}
