require 'spec_helper'
require 'workers/spec_worker'

describe Sidekiq::Logstash do
  before(:each) do
    Sidekiq.logger = double(Logger.new(STDOUT))
  end

  it 'has a version number' do
    expect(Sidekiq::Logstash::VERSION).not_to be nil
  end

  it 'setup properly' do
    expect(Sidekiq.logger).to receive(:formatter=)
    Sidekiq::Logstash.setup
  end

  it 'logs properly' do
    expect(Sidekiq.logger).to receive(:info)
    Sidekiq::Testing.inline! do
      SpecWorker.perform_async
    end
  end
end
