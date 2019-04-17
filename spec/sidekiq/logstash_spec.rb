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

  it 'logs only a single line (doesn\'t have a "started" log by default)' do
    buffer = StringIO.new
    Sidekiq.logger = Logger.new(buffer)

    log_job = Sidekiq::LogstashJobLogger.new.call(job, :default) {}

    expect(buffer.string.split("\n").length).to eq(1)
    expect(buffer.string).not_to include('"job_status"=>"started"')
  end

  it 'filter args' do
    Sidekiq::Logstash.configure do |config|
      config.filter_args << 'a_secret_param'
    end
    log_job = Sidekiq::Middleware::Server::LogstashLogging.new.log_job(job, Time.now.utc)
    expect(log_job['args'][2]).to include('[FILTERED]')
  end

  it 'add custom options' do
    Sidekiq::Logstash.configure do |config|
      config.custom_options = lambda do |payload|
        payload['test'] = 'test'
        payload['test2'] = 'test2'
      end
    end
    log_job = Sidekiq::Logstash.configuration.custom_options.call(job)
    expect(log_job['test']).to eq('test')
  end

  context 'when a job has encrypted arguments' do
    let (:job) { FactoryGirl.build(:job, encrypt: true) }

    it 'hides encrypted args' do
      log_job = Sidekiq::Middleware::Server::LogstashLogging.new.log_job(job, Time.now.utc)
      expect(log_job['args'][2]).to include('[ENCRYPTED]')
    end
  end

  context 'enable job_start_log' do
    it 'generates log with job_status=started' do
      buffer = StringIO.new
      Sidekiq.logger = Logger.new(buffer)

      Sidekiq::Logstash.configure do |config|
        config.job_start_log = true
      end

      log_job = Sidekiq::Middleware::Server::LogstashLogging.new.log_job(job, Time.now.utc, exc = nil, start = true)

      expect(log_job['job_status']).to eq('started')
    end

    it 'logs both the starting and finished logs' do
      buffer = StringIO.new
      Sidekiq.logger = Logger.new(buffer)

      Sidekiq::Logstash.configure do |config|
        config.job_start_log = true
      end

      log_job = Sidekiq::LogstashJobLogger.new.call(job, :default) {}

      expect(buffer.string.split("\n").length).to eq(2)
      expect(buffer.string).to include('"job_status"=>"started"')
      expect(buffer.string).to include('"job_status"=>"done"')
    end
  end
end
