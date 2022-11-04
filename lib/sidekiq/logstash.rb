# frozen_string_literal: true

require 'sidekiq/logstash/configuration'
require 'sidekiq/logstash/version'
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
        # Remove default, noisy error handler,
        # unless LogStash.configuration.keep_default_error_handler is set to true
        config.error_handlers.delete(Sidekiq::Config::ERROR_HANDLER) unless configuration.keep_default_error_handler

        # Add logstash support
        config[:job_logger] = Sidekiq::LogstashJobLogger
        # Set custom formatter for Sidekiq logger
        config.logger.formatter = Sidekiq::Logging::LogstashFormatter.new
      end
    end
  end
end
