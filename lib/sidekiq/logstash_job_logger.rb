# frozen_string_literal: true

require 'sidekiq/job_logger'
require 'sidekiq/logging/shared'

module Sidekiq
  # Class used to replace Sidekiq default job logger.
  class LogstashJobLogger < ::Sidekiq::JobLogger
    include Sidekiq::Logging::Shared

    def call(job, _queue, &)
      log_job(job, &)
    end
  end
end
