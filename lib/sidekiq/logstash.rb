require 'sidekiq/logstash/version'
require 'sidekiq/middleware/server/logstag_logging'
require 'sidekiq/logging/logstash_formatter'

module Sidekiq
  module Logstash
    def self.setup(opts = {})
      # Calls Sidekiq.configure_server to inject logics
      Sidekiq.configure_server do |config|
        # Remove default Sidekiq error_handler that logs errors
        config.error_handlers.delete_if {|h| h.is_a?(Sidekiq::ExceptionHandler::Logger) }

        # Add logstash support
        config.server_middleware do |chain|
          chain.add Sidekiq::Middleware::Server::LogstashLogging
          chain.remove Sidekiq::Middleware::Server::Logging
        end

        # Set custom formatter for Sidekiq logger
        config.logger.formatter = Sidekiq::Logging::LogstashFormatter.new
      end
    end
  end
end
