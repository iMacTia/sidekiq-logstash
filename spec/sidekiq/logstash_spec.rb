require 'spec_helper'
require 'sidekiq'
require 'sidekiq/cli' # needed to simulate being in Sidekiq server

describe Sidekiq::Logstash do
  it 'has a version number' do
    expect(Sidekiq::Logstash::VERSION).not_to be nil
  end

  it 'setup properly' do
    Sidekiq::Logstash.setup

    expect(Sidekiq.logger.formatter).to be_a(Sidekiq::Logging::LogstashFormatter)
  end
end
