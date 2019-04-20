# frozen_string_literal: true

require 'sidekiq/logging/shared'

module Sidekiq
  module Middleware
    module Server
      class LogstashLogging
        include Sidekiq::Logging::Shared

        def call(_, job, _, &block)
          log_job(job, &block)
        end
      end
    end
  end
end
