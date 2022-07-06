
require "json_schemer"
require "pathname"

def register(params)
    @schema_dir = get_param(params, "schema_dir")
    @source_field = params["source_field"]
    @tag_on_failure = get_param(params, "tag_on_failure")
    @report_field = params["report_field"]

    @schema_dir = File.expand_path(@schema_dir)
    preload_schemas = Dir[File.join(@schema_dir, "*.json")]
    @cached_validators = Hash.new

    preload_schemas.each { |schema_file|
        major_schema_version = File.basename(schema_file, ".*")[1..-1]
        @cached_validators[major_schema_version] = JSONSchemer.schema(
            Pathname.new(schema_file))
        logger.debug? && logger.debug("JSON schema loaded: #{schema_file}")
    }

    @report_validation_errors = !@report_field.nil? && !@report_field.empty?
end

def filter(event)
    begin
        if @source_field.instance_of?(String) && !@source_field.empty?
            event_data = event.get(@source_field)
        else
            event_data = event
        end

        if event_data.nil?
            return [event]
        end

        version = event_data["version"]
        if !version.instance_of?(String) || version.empty?
            tag_event(event)
            add_error(event, "Field 'version' not found, is empty or has wrong format")
            return [event]
        end

        major_version = version.partition(".").first
        validator = @cached_validators["#{major_version}"]
        if !validator.nil?

            if @report_validation_errors
                validation_errors = validator.validate(event_data).to_a
                if validation_errors.any?
                    tag_event(event)
                    validation_errors.each do |err_data|
                        err_data.delete("data")
                        err_data.delete("root_schema")
                        err_data.delete("schema")
                        err_data.delete("schema_pointer")
                    end
                    add_error(event, validation_errors.to_s)
                end
            else
                valid = validator.valid?(event_data)
                unless valid
                    tag_event(event)
                end
            end

        else
            error_msg = "JSON schema version '#{version}' is not supported"
            logger.warn? && logger.warn(error_msg)
            tag_event(event)
            add_error(event, error_msg)
        end

    rescue Exception => e
        error_msg = e.message
        stacktrace = e.backtrace.inspect
        logger.error? && logger.error(error_msg.to_s << "  " << stacktrace.to_s << "  " << event.to_s)
    end

    [event]
end

def get_param(params, param_name)
    value = params["#{param_name}"]
    if value.nil? || value.empty?
        raise ArgumentError.new("Parameter '#{param_name}' is undefined or empty")
    end
    value
end

def tag_event(event)
    event.tag(@tag_on_failure)
end

def add_error(event, error_msg)
    if @report_validation_errors
        event.set(@report_field, error_msg)
    end
end
