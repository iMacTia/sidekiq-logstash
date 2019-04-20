# frozen_string_literal: true

require 'sidekiq/logging/shared'

module Sidekiq
  module Middleware
    module Server
      # Class used to replace Sidekiq 4 job logger.
      class LogstashLogging
        include Sidekiq::Logging::Shared

        def call(_, job, _, &block)
          log_job(job, &block)
        end
      end
    end
  end
end
