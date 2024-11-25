# frozen_string_literal: true

# Utility that allows us to get a hash representation of an exception
module ExceptionUtils
  def self.exception_to_hash(exc, parent_backtrace = nil)
    backtrace = exc.backtrace || []
    if parent_backtrace
      common_lines = backtrace.reverse.zip(parent_backtrace.reverse).take_while { |a, b| a == b }

      backtrace = backtrace[0...-common_lines.length] if common_lines.any?
    end

    error_hash = {
      'class' => exc.class.to_s,
      'message' => exc.message,
      'backtrace' => backtrace
    }

    cause = exc.cause
    if cause
      # Pass the current backtrace as the parent_backtrace to the cause to shorten cause's backtrace list
      error_hash['cause'] = exception_to_hash(cause, exc.backtrace)
    end

    error_hash
  end
end
