module Sidekiq
  module Logging
    module Shared
      def log_job(payload, started_at, exc = nil)
        # Create a copy of the payload using JSON
        # This should always be possible since Sidekiq store it in Redis
        payload = JSON.parse(JSON.unparse(payload))

        # Convert timestamps into Time instances
        %w( created_at enqueued_at retried_at failed_at completed_at ).each do |key|
          payload[key] = parse_time(payload[key]) if payload[key]
        end

        # Add process id params
        payload['pid']      = ::Process.pid
        payload['duration'] = elapsed(started_at)

        message = "#{payload['class']} JID-#{payload['jid']}"

        if exc
          payload['message']         = "#{message}: fail: #{payload['duration']} sec"
          payload['job_status']      = 'fail'
          payload['error_message']   = exc.message
          payload['error']           = exc.class
          payload['error_backtrace'] = %('#{exc.backtrace.join("\n")}')
        else
          payload['message']      = "#{message}: done: #{payload['duration']} sec"
          payload['job_status']   = 'done'
          payload['completed_at'] = Time.now.utc
        end

        # Filter sensitive parameters
        unless filter_args.empty?
          args_filter     = Sidekiq::Logging::ArgumentFilter.new(filter_args)
          payload['args'] = args_filter.filter({ args: payload['args'] })[:args]
        end

        # Needs to map all args to strings for ElasticSearch compatibility
        payload['args'].map!(&:to_s)

        payload
      end

      def elapsed(start)
        (Time.now.utc - start).round(3)
      end

      def parse_time(timestamp)
        return timestamp if timestamp.is_a? Time
        timestamp.is_a?(Float) ?
            Time.at(timestamp).utc :
            Time.parse(timestamp)
      rescue
        timestamp
      end

      def filter_args
        Sidekiq::Logstash.configuration.filter_args
      end
    end
  end
end
