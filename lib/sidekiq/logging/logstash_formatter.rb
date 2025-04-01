# frozen_string_literal: true

require 'logstash-event'

module Sidekiq
  module Logging
    # Class that takes a log payload and format it to be Logstash-compatible.
    class LogstashFormatter
      def call(severity, _time, _progname, data)
        json_data = { severity: }

        if data.is_a? Hash
          json_data.merge!(data)
        else
          json_data[:message] = data
        end

        # Merge custom_options to provide customization
        begin
          custom_options&.call(json_data)
        rescue StandardError
          nil
        end
        event = LogStash::Event.new(json_data)

        "#{event.to_json}\n"
      end

      private

      def custom_options
        Sidekiq::Logstash.configuration.custom_options
      end
    end
  end
end
