# frozen_string_literal: true

require 'sidekiq/job_logger'
require 'sidekiq/logging/shared'

module Sidekiq
  # Class used to replace Sidekiq 5 job logger.
  class LogstashJobLogger < ::Sidekiq::JobLogger
    include Sidekiq::Logging::Shared

    def call(job, _queue, &block)
      log_job(job, &block)
    end
  end
end
