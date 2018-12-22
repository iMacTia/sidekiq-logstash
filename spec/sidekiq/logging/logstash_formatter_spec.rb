require 'spec_helper'
require 'sidekiq/logging/logstash_formatter'

describe Sidekiq::Logging::LogstashFormatter do
  let(:logstash_formatter) { Sidekiq::Logging::LogstashFormatter.new }

  it 'preserves severity when data is a hash' do
    data = { message: 'the message' }

    json = logstash_formatter.call('INFO', Time.now, 'progname', data)

    expect(json).to include_json('severity' => 'INFO')
  end

  it 'preserves severity of given hash' do
    data = {
        severity: 'WARN',
        message: 'the message',
    }

    json = logstash_formatter.call('INFO', Time.now, 'progname', data)

    expect(json).to include_json('severity' => 'WARN')
  end

  it 'preserves severity when data is a string' do
    data = 'the message'

    json = logstash_formatter.call('INFO', Time.now, 'progname', data)

    expect(json).to include_json('severity' => 'INFO')
  end
end
