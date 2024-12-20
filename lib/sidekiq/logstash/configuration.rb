# frozen_string_literal: true

module Sidekiq
  module Logstash
    # Class that allows to configure the gem behaviour.
    class Configuration
      attr_accessor :custom_options,
                    :filter_args,
                    :job_start_log,
                    :keep_default_error_handler,
                    :log_job_exception_with_causes,
                    :causes_logging_max_depth

      def initialize
        @filter_args = []
        @job_start_log = false
        @log_job_exception_with_causes = false
        @causes_logging_max_depth = 2
      end

      # Added to ensure custom_options is a Proc
      def custom_options=(proc)
        raise ArgumentError, 'Argument must be a Proc.' unless proc.is_a?(Proc)

        @custom_options = proc
      end
    end
  end
end
