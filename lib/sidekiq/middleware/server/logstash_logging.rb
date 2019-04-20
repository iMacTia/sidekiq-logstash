# frozen_string_literal: true

require 'sidekiq/logging/shared'

module Sidekiq
  module Middleware
    module Server
      class LogstashLogging
        include Sidekiq::Logging::Shared

        def call(_, job, _)
          started_at = Time.now.utc
          yield
          Sidekiq.logger.info log_job(job, started_at)
        rescue StandardError => exc
          begin
            Sidekiq.logger.warn log_job(job, started_at, exc)
          rescue StandardError => ex
            Sidekiq.logger.error 'Error logging the job execution!'
            Sidekiq.logger.error "Job: #{job}"
            Sidekiq.logger.error "Job Exception: #{exc}"
            Sidekiq.logger.error "Log Exception: #{ex}"
          end
          raise
        end
      end
    end
  end
end
