# frozen_string_literal: true

module Sidekiq
  module Logging
    # Shared module with all the logics used by job loggers.
    module Shared
      ENCRYPTED = '[ENCRYPTED]'

      def log_job(job)
        started_at = Time.now.utc
        log_start = log_job_start(job)
        Sidekiq.logger.info log_start if log_start
        yield if block_given?
        Sidekiq.logger.info log_job_exec(job, started_at)
      rescue StandardError => e
        begin
          Sidekiq.logger.warn log_job_exception(job, started_at, e)
        rescue StandardError => ex
          log_standard_error(job, e, ex)
        end
        raise
      end

      def log_job_start(job)
        return unless Sidekiq::Logstash.configuration.job_start_log
        # Skips start logs for retrying jobs
        return if job['failed_at']

        payload = setup_payload(job)
        payload['job_status'] = 'started'
        payload['message'] += ': started'
        process_payload(payload)
      end

      def log_job_exec(job, started_at)
        payload = setup_payload(job)
        payload['duration'] = elapsed(started_at)

        payload['message'] += ": done: #{payload['duration']} sec"
        payload['job_status'] = 'done'
        payload['completed_at'] = Time.now.utc

        process_payload(payload)
      end

      def log_job_exception(job, started_at, exc)
        payload = setup_payload(job)
        payload['duration'] = elapsed(started_at)

        payload['message'] += ": fail: #{payload['duration']} sec"
        payload['job_status'] = 'fail'
        payload['error_message'] = exc.message
        payload['error'] = exc.class
        payload['error_backtrace'] = %('#{exc.backtrace.join("\n")}')

        process_payload(payload)
      end

      private

      def setup_payload(job)
        # Create a copy of the payload using JSON
        # This should always be possible since Sidekiq store it in Redis
        payload = JSON.parse(JSON.unparse(job))

        # Convert timestamps into Time instances
        %w[created_at enqueued_at retried_at failed_at completed_at].each do |key|
          payload[key] = parse_time(payload[key]) if payload[key]
        end

        # Sets the initial message
        payload['message'] = "#{payload['class']} JID-#{payload['jid']}"

        # Add process id params
        payload['pid'] = ::Process.pid

        payload
      end

      def process_payload(payload)
        # Filter sensitive parameters
        unless filter_args.empty?
          args_filter = Sidekiq::Logging::ArgumentFilter.new(filter_args)
          payload['args'] = args_filter.filter(args: payload['args'])[:args]
        end

        # If encrypt is true, the last arg is encrypted so hide it
        payload['args'][-1] = ENCRYPTED if payload['encrypt']

        # Needs to map all args to strings for ElasticSearch compatibility
        deep_stringify!(payload['args'])

        # Needs to map all unique_args to strings for ElasticSearch
        # compatibility in case sidekiq-unique-jobs is used
        deep_stringify!(payload['unique_args'])

        if payload['retry'].is_a?(Integer)
          payload['max_retries'] = payload['retry']
          payload['retry'] = true
        end

        payload
      end

      def log_standard_error(job, job_exc, log_exc)
        Sidekiq.logger.error 'Error logging the job execution!'
        Sidekiq.logger.error "Job: #{job}"
        Sidekiq.logger.error "Job Exception: #{job_exc}"
        Sidekiq.logger.error "Log Exception: #{log_exc}"
      end

      def elapsed(start)
        (Time.now.utc - start).round(3)
      end

      def parse_time(timestamp)
        return timestamp if timestamp.is_a? Time

        timestamp.is_a?(Float) ? Time.at(timestamp).utc : Time.parse(timestamp)
      rescue StandardError
        timestamp
      end

      def filter_args
        Sidekiq::Logstash.configuration.filter_args
      end

      def deep_stringify!(args)
        case args
        when Hash
          Hash[args.map { |key, value| [deep_stringify!(key), deep_stringify!(value)] }]
        when Array
          args.map! { |val| deep_stringify!(val) }
        else
          args.to_s
        end
      end
    end
  end
end
