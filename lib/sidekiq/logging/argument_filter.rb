# frozen_string_literal: true

# This implementation is taken directly from https://github.com/rails/rails/blob/52ce6ece8c8f74064bb64e0a0b1ddd83092718e1/actionpack/lib/action_dispatch/http/parameter_filter.rb
# Adding actionpack to the gem dependencies would have been too heavy, so here is just what we need.

module Sidekiq
  module Logging
    class ArgumentFilter
      FILTERED = '[FILTERED]'

      def initialize(filters = [])
        @filters = filters
      end

      def filter(args)
        compiled_filter.call(args)
      end

      private

      def compiled_filter
        @compiled_filter ||= CompiledFilter.compile(@filters)
      end

      class CompiledFilter # :nodoc:
        def self.compile(filters)
          return ->(args) { args.dup } if filters.empty?

          strings = []
          regexps = []
          blocks = []
          filters.each do |item|
            case item
            when Proc
              blocks << item
            when Regexp
              regexps << item
            else
              strings << Regexp.escape(item.to_s)
            end
          end
          deep_regexps, regexps = regexps.partition { |r| r.to_s.include?('\\.') }
          deep_strings, strings = strings.partition { |s| s.include?('\\.') }
          regexps << Regexp.new(strings.join('|'), true) unless strings.empty?
          deep_regexps << Regexp.new(deep_strings.join('|'), true) unless deep_strings.empty?
          new regexps, deep_regexps, blocks
        end

        attr_reader :regexps, :deep_regexps, :blocks

        def initialize(regexps, deep_regexps, blocks)
          @regexps      = regexps
          @deep_regexps = deep_regexps.any? ? deep_regexps : nil
          @blocks       = blocks
        end

        def call(original_args, parents = [])
          filtered_args = {}
          original_args.each do |key, value|
            parents.push(key) if deep_regexps
            if regexps.any? { |r| key =~ r }
              value = FILTERED
            elsif deep_regexps && (joined = parents.join('.')) && deep_regexps.any? { |r| joined =~ r }
              value = FILTERED
            elsif value.is_a?(Hash)
              value = call(value, parents)
            elsif value.is_a?(Array)
              value = value.map { |v| v.is_a?(Hash) ? call(v, parents) : v }
            elsif blocks.any?
              key = begin
                      key.dup
                    rescue StandardError
                      key
                    end
              value = begin
                        value.dup
                      rescue StandardError
                        value
                      end
              blocks.each { |b| b.call(key, value) }
            end
            parents.pop if deep_regexps
            filtered_args[key] = value
          end
          filtered_args
        end
      end
    end
  end
end
