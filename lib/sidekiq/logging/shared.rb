# frozen_string_literal: true

module Sidekiq
  module Logging
    module Shared
      ENCRYPTED = '[ENCRYPTED]'

      def log_job(payload, started_at, exc = nil, start = false)
        # skip start logs for retrying jobs
        return if start && payload['failed_at']

        # Create a copy of the payload using JSON
        # This should always be possible since Sidekiq store it in Redis
        payload = JSON.parse(JSON.unparse(payload))

        # Convert timestamps into Time instances
        %w[created_at enqueued_at retried_at failed_at completed_at].each do |key|
          payload[key] = parse_time(payload[key]) if payload[key]
        end

        message = "#{payload['class']} JID-#{payload['jid']}"

        # Add process id params
        payload['pid'] = ::Process.pid

        if start
          payload['job_status'] = 'started'
          payload['message'] = "#{message}: started"
        else
          payload['duration'] = elapsed(started_at)

          if exc
            payload['message'] = "#{message}: fail: #{payload['duration']} sec"
            payload['job_status'] = 'fail'
            payload['error_message'] = exc.message
            payload['error'] = exc.class
            payload['error_backtrace'] = %('#{exc.backtrace.join("\n")}')
          else
            payload['message'] = "#{message}: done: #{payload['duration']} sec"
            payload['job_status'] = 'done'
            payload['completed_at'] = Time.now.utc
          end
        end

        # Filter sensitive parameters
        unless filter_args.empty?
          args_filter = Sidekiq::Logging::ArgumentFilter.new(filter_args)
          payload['args'] = args_filter.filter(args: payload['args'])[:args]
        end

        # If encrypt is true, the last arg is encrypted so hide it
        payload['args'][-1] = ENCRYPTED if payload['encrypt']

        # Needs to map all args to strings for ElasticSearch compatibility
        payload['args'].map!(&:to_s)

        # Needs to map all unique_args to strings for ElasticSearch compatibility in case sidekiq-unique-jobs is used
        payload['unique_args']&.map!(&:to_s)

        if payload['retry'].is_a?(Integer)
          payload['max_retries'] = payload['retry']
          payload['retry'] = true
        end

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
      rescue StandardError
        timestamp
      end

      def filter_args
        Sidekiq::Logstash.configuration.filter_args
      end
    end
  end
end
