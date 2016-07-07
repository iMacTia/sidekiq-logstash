$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
$LOAD_PATH.unshift File.expand_path('..', __FILE__)

require 'sidekiq/logstash'
require 'logstash-event'
require 'sidekiq'
require 'sidekiq/cli' # needed to simulate being in Sidekiq server
require 'sidekiq/testing'
require 'rspec'
require 'factory_girl'
require 'support/factory_girl'