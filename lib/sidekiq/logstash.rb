# frozen_string_literal: true

require 'sidekiq/logstash/configuration'
require 'sidekiq/logstash/version'
require 'sidekiq/middleware/server/logstash_logging'
require 'sidekiq/logging/logstash_formatter'
require 'sidekiq/logging/argument_filter'
require 'sidekiq/logstash_job_logger'

module Sidekiq
  # Main level module for Sidekiq::Logstash.
  # Provides integration between Sidekiq and Logstash by changing the way
  # Sidekiq jobs are logged.
  module Logstash
    def self.configuration
      @configuration ||= Configuration.new
    end

    def self.configure
      yield(configuration)
    end

    def self.setup(_opts = {})
      # Calls Sidekiq.configure_server to inject logics
      Sidekiq.configure_server do |config|
        # Remove default Sidekiq error_handler that logs errors
        config.error_handlers.delete_if { |h| h.is_a?(Sidekiq::ExceptionHandler::Logger) }

        # Add logstash support
        # The logging server middleware was removed in Sidekiq 5.0.0, see: https://github.com/mperham/sidekiq/blob/master/Changes.md
        if Sidekiq::Middleware::Server.const_defined?(:Logging)
          config.server_middleware do |chain|
            chain.add Sidekiq::Middleware::Server::LogstashLogging
            chain.remove Sidekiq::Middleware::Server::Logging
          end
        else
          config.options[:job_logger] = Sidekiq::LogstashJobLogger
        end

        # Set custom formatter for Sidekiq logger
        config.logger.formatter = Sidekiq::Logging::LogstashFormatter.new
      end
    end
  end
end
