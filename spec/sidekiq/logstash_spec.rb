# frozen_string_literal: true

require 'spec_helper'
require 'workers/spec_worker'

describe Sidekiq::Logstash do
  def process(worker, params = [], encrypt: false)
    msg = Sidekiq.dump_json({ 'class' => worker.to_s, 'args' => params, 'encrypt' => encrypt })
    work = Sidekiq::BasicFetch::UnitOfWork.new('queue:default', msg)
    processor.send(:process, work)
  end

  let(:buffer) { StringIO.new }
  let(:logger) { Logger.new(buffer) }
  let(:job) { build(:job) }
  let(:logstash_config) { Sidekiq::Logstash::Configuration.new }
  let(:sidekiq_config) { Sidekiq::Config.new }
  let(:processor) { Sidekiq::Processor.new(sidekiq_config.default_capsule) }
  let(:log_message) { JSON.parse(buffer.string) }
  let(:log_messages) { buffer.string.split("\n").map { |log| JSON.parse(log) } }
  let(:mock_redis) { double(:Redis) }
  let(:custom_config) { nil }

  before do
    # Reset error handlers because they're globally stored across instances of Sidekiq::Config
    Sidekiq::Config::DEFAULTS[:error_handlers] = []
    allow(Sidekiq).to receive(:default_configuration).and_return(sidekiq_config)
    allow(Sidekiq::Logstash).to receive(:configuration).and_return(logstash_config)
    logger.formatter = Sidekiq::Logging::LogstashFormatter.new
    sidekiq_config.logger = logger
    Sidekiq::Logstash.setup
  end

  it 'has a version number' do
    expect(Sidekiq::Logstash::VERSION).not_to be nil
  end

  it 'setup properly' do
    expect(Sidekiq.logger).to receive(:formatter=)
    Sidekiq::Logstash.setup
  end

  it 'logs properly' do
    process(SpecWorker)
    expect(buffer.string).to include('@timestamp')
  end

  it 'logs only a single line (doesn\'t have a "started" log by default)' do
    process(SpecWorker)
    expect(buffer.string.split("\n").length).to eq(1)
    expect(buffer.string).not_to include('started')
  end

  it 'stringifies parameters' do
    hash = { a_really: { deep: { hash: [1, 2] } } }
    process(SpecWorker, [false, hash])
    expect(log_message['args'].last).to eq({ 'a_really' => { 'deep' => { 'hash' => %w[1 2] } } })
  end

  context 'with arguments filtered' do
    before do
      Sidekiq::Logstash.configure do |config|
        config.filter_args << 'a_secret_param'
      end
    end

    after do
      Sidekiq::Logstash.configure do |config|
        config.filter_args.clear
      end
    end

    it 'filter args' do
      process(SpecWorker, [false, { 'a_secret_param' => 'secret' }])
      expect(log_message['args'].last['a_secret_param']).to eq('[FILTERED]')
    end
  end

  context 'with custom options' do
    before do
      Sidekiq::Logstash.configure do |config|
        config.custom_options = lambda do |payload|
          payload['test'] = 'test'
          payload['test2'] = 'test2'
        end
      end
    end

    after do
      Sidekiq::Logstash.configure do |config|
        config.custom_options = proc {}
      end
    end

    it 'add custom options' do
      process(SpecWorker)
      expect(log_message['test']).to eq('test')
      expect(log_message['test2']).to eq('test2')
    end
  end

  context 'when a job has encrypted arguments' do
    it 'hides encrypted args' do
      process(SpecWorker, [false, 'encrypted_param'], encrypt: true)
      expect(buffer.string).to include('[ENCRYPTED]')
    end
  end

  context 'when job raises a error' do
    before do
      allow(processor.capsule).to receive(:redis)
    end

    it 'logs a single line, silencing the default error handler' do
      expect { process(SpecWorker, [true]) }
        .to raise_error(RuntimeError)
        .and not_output.to_stdout
    end

    it 'logs the exception with job retry' do
      expect { process(SpecWorker, [true]) }.to raise_error(RuntimeError)

      expect(log_message['error_message']).to eq('You know nothing, Jon Snow.')
      expect(log_message['error']).to eq('RuntimeError')
      expect(log_message['error_backtrace'].split("\n").first).to include('workers/spec_worker.rb:')
    end

    it 'logs the exception without job retry' do
      allow(SpecWorker).to receive(:get_sidekiq_options).and_return({ 'retry' => false, 'queue' => 'default' })

      expect { process(SpecWorker, [true]) }.to raise_error(RuntimeError)

      expect(log_message['error_message']).to eq('You know nothing, Jon Snow.')
      expect(log_message['error']).to eq('RuntimeError')
      expect(log_message['error_backtrace'].split("\n").first).to include('workers/spec_worker.rb:')
    end

    context 'log_job_exception_with_causes enabled' do
      before do
        Sidekiq::Logstash.configure do |config|
          config.log_job_exception_with_causes = true
        end
      end

      after do
        Sidekiq::Logstash.configure do |config|
          config.log_job_exception_with_causes = false
        end
      end

      it 'logs the exception with its two causes' do
        expect { process(SpecWorker, [true]) }.to raise_error(RuntimeError)

        expect(log_message['error']['class']).to eq('Sidekiq::JobRetry::Handled')
        expect(log_message['error']['message']).to eq('Sidekiq::JobRetry::Handled')

        expect(log_message['error']['cause']['class']).to eq('RuntimeError')
        expect(log_message['error']['cause']['message']).to eq('You know nothing, Jon Snow.')

        expect(log_message['error']['cause']['cause']['class']).to eq('RuntimeError')
        expect(log_message['error']['cause']['cause']['message']).to eq('Error rescuing error')
      end

      context 'causes_logging_max_depth is set to 3' do
        before do
          Sidekiq::Logstash.configure do |config|
            config.log_job_exception_with_causes = true
            config.causes_logging_max_depth = 3
          end
        end

        after do
          Sidekiq::Logstash.configure do |config|
            config.log_job_exception_with_causes = true
            config.causes_logging_max_depth = 2
          end
        end

        it 'logs the exception with its three causes' do
          expect { process(SpecWorker, [true]) }.to raise_error(RuntimeError)

          expect(log_message['error']['class']).to eq('Sidekiq::JobRetry::Handled')
          expect(log_message['error']['message']).to eq('Sidekiq::JobRetry::Handled')

          expect(log_message['error']['cause']['class']).to eq('RuntimeError')
          expect(log_message['error']['cause']['message']).to eq('You know nothing, Jon Snow.')

          expect(log_message['error']['cause']['cause']['class']).to eq('RuntimeError')
          expect(log_message['error']['cause']['cause']['message']).to eq('Error rescuing error')

          expect(log_message['error']['cause']['cause']['cause']['class']).to eq('RuntimeError')
          expect(log_message['error']['cause']['cause']['cause']['message']).to eq('Deepest error')
        end
      end
    end
  end

  context 'with job_start_log enabled' do
    before do
      Sidekiq::Logstash.configure do |config|
        config.job_start_log = true
      end
    end

    after do
      Sidekiq::Logstash.configure do |config|
        config.job_start_log = false
      end
    end

    it 'logs both the starting and finished logs' do
      process(SpecWorker)
      expect(log_messages.length).to eq(2)
      expect(log_messages.first['job_status']).to eq('started')
      expect(log_messages.last['job_status']).to eq('done')
    end
  end

  context 'with keep_default_error_handler' do
    let(:logstash_config) do
      Sidekiq::Logstash::Configuration.new.tap do |config|
        config.keep_default_error_handler = true
      end
    end

    it 'leaves the default error handler in place' do
      expect(sidekiq_config.error_handlers).to include(Sidekiq::Config::ERROR_HANDLER)
    end
  end
end
