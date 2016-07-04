module Sidekiq
  module Middleware
    module Server
      class LogstashLogging
        def call(_, job, _)
          job['started_at'] = Time.now.utc
          yield
          log_job(job)
        rescue => exc
          begin
            log_job(job, exc)
          rescue => ex
            Sidekiq.logger.error 'Error logging the job execution!'
            Sidekiq.logger.error "Job: #{job}"
            Sidekiq.logger.error "Job Exception: #{exc}"
            Sidekiq.logger.error "Log Exception: #{ex}"
          end
          raise
        end

        def log_job(payload, exc = nil)
          # Convert timestamps into Time instances
          %w( started_at created_at enqueued_at retried_at failed_at completed_at ).each do |key|
            payload[key] = parse_time(payload[key]) if payload[key]
          end

          # Add process id params
          payload['pid'] = ::Process.pid
          payload['duration'] = elapsed(payload['started_at'])

          # Merge custom_options to provide customization
          payload.merge!(@custom_options.call(payload, exc)) if @custom_options rescue nil

          if exc
            payload['error_message'] = exc.message
            payload['error']
            payload['error_backtrace'] = %('#{exc.backtrace.join("\n")}')
            Sidekiq.logger.warn payload
          else
            payload['completed_at'] = Time.now.utc
            Sidekiq.logger.info payload
          end
        end

        def elapsed(start)
          (Time.now.utc - start).round(3)
        end

        def parse_time(timestamp)
          return timestamp if timestamp.is_a? Time
          timestamp.is_a?(Float) ?
              Time.at(timestamp).utc :
              Time.parse(timestamp)
        end

        def custom_options=(proc)
          raise ArgumentError, 'Argument must be a Proc.' unless proc.is_a?(Proc)
          @custom_options = proc
        end
      end
    end
  end
end
