require 'spec_helper'
require 'workers/spec_worker'

describe Sidekiq::Logstash do
  before(:each) do
    Sidekiq.logger = double(Logger.new(STDOUT))
  end

  let (:job) { FactoryGirl.build(:job) }

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

  it 'filter args' do
    Sidekiq::Logstash.configure do |config|
      config.filter_args << 'a_secret_param'
    end
    log_job = Sidekiq::Middleware::Server::LogstashLogging.new.log_job(job, Time.now.utc)
    expect(log_job['args'][2]['a_secret_param']).to eq('[FILTERED]')
  end

  it 'add custom options' do
    Sidekiq::Logstash.configure do |config|
      config.custom_options = lambda do |payload|
        payload['test'] = 'test'
        payload['test2'] = 'test2'
      end
    end
    log_job = Sidekiq::Middleware::Server::LogstashLogging.new.log_job(job, Time.now.utc)
    expect(log_job['test']).to eq('test')
  end
end
