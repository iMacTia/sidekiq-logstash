# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path('../lib', __dir__)
$LOAD_PATH.unshift File.expand_path(__dir__)

require 'sidekiq/logstash'
require 'logstash-event'
require 'sidekiq'
require 'sidekiq/cli' # needed to simulate being in Sidekiq server
require 'sidekiq/testing'
require 'rspec'
require 'forwardable' # needed by rspec-json_expectations
require 'rspec/json_expectations'
require 'factory_bot'
require 'support/factory_bot'

RSpec::Matchers.define_negated_matcher :not_output, :output
