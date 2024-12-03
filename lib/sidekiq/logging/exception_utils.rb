# frozen_string_literal: true

module Sidekiq
  module Logging
    # Utility that allows us to get a hash representation of an exception
    module ExceptionUtils
      module_function

      def get_exception_with_cause_hash(exc, parent_backtrace = nil, max_depth_left: 1)
        error_hash = {
          'class' => exc.class.to_s,
          'message' => exc.message,
          'backtrace' => backtrace_for(exc, parent_backtrace)
        }

        if (cause = exc.cause) && max_depth_left.positive?
          # Pass the current backtrace as the parent_backtrace to the cause to shorten cause's backtrace list
          error_hash['cause'] = get_exception_with_cause_hash(cause, exc.backtrace, max_depth_left: max_depth_left - 1)
        end

        error_hash
      end

      def backtrace_for(exception, parent_backtrace = nil)
        backtrace = exception.backtrace || []
        if parent_backtrace
          common_lines = backtrace.reverse.zip(parent_backtrace.reverse).take_while { |a, b| a == b }

          backtrace = backtrace[0...-common_lines.length] if common_lines.any?
        end

        backtrace
      end
    end
  end
end
