# frozen_string_literal: true

require 'sidekiq/logging/shared'

module Sidekiq
  class LogstashJobLogger
    include Sidekiq::Logging::Shared

    def call(job, _queue, &block)
      log_job(job, &block)
    end
  end
end
