require 'logstash-event'

module Sidekiq
  module Logging
    class LogstashFormatter
      def call(severity, time, progname, data)
        json_data = { severity: severity }

        if data.is_a? Hash
          json_data.merge!(data)
        else
          json_data[:message] = data
        end

        # Merge custom_options to provide customization
        custom_options.call(json_data) if custom_options rescue nil
        event = LogStash::Event.new(json_data)

        "#{event.to_json}\n"
      end

      def custom_options
        Sidekiq::Logstash.configuration.custom_options
      end
    end
  end
end
