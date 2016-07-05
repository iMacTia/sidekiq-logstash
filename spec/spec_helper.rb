$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'sidekiq/logstash'
require 'logstash-event'
require 'sidekiq'
require 'sidekiq/cli' # needed to simulate being in Sidekiq server
require 'sidekiq/testing'