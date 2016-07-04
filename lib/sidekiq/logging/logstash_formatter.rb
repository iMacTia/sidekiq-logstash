module Sidekiq
  module Logging
    class LogstashFormatter
      def call(severity, time, progname, data)
        if data.is_a? Hash
          json_data = data
        else
          json_data = {
              severity: severity,
              message: data
          }
        end
        event = LogStash::Event.new(json_data)

        "#{event.to_json}\n"
      end
    end
  end
end
