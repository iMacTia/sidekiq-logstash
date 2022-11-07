# Sidekiq::Logstash

[![Gem Version](https://badge.fury.io/rb/sidekiq-logstash.svg)](https://badge.fury.io/rb/sidekiq-logstash)
[![GitHub Actions CI](https://github.com/iMacTia/sidekiq-logstash/workflows/CI/badge.svg)](https://github.com/iMacTia/sidekiq-logstash/actions?query=workflow%3ACI)

Sidekiq::Logstash turns your [Sidekiq](https://github.com/mperham/sidekiq) log into an organised, aggregated, JSON-syntax log ready to be sent to a logstash server.

```json
{
  "class"           : "MyWorker",
  "args"            : ["first_param","second_param"],
  "retry"           : true,
  "queue"           : "default",
  "status"          : "fail",
  "jid"             : "fd71783c0afa3f5e0958f3e9",
  "created_at"      : "2016-07-02T14:03:26.423Z",
  "enqueued_at"     : "2016-07-02T14:03:26.425Z",
  "retried_at"      : "2016-07-02T16:28:42.195Z",
  "failed_at"       : "2016-07-02T13:04:58.298Z",
  "retried_at"      : "2016-07-02T14:04:11.051Z",
  "retry_count"     : 1,
  "pid"             : 70354,
  "duration"        : 0.306,
  "error_message"   : "An error message that occurred during job execution.",
  "error_backtrace" : "...",
  "@timestamp"      : "2016-07-02T14:03:27.259Z",
  "@version"        : "1"
}
```

## Installation

Add one of the following lines to your application's Gemfile:

```ruby
gem 'sidekiq-logstash', '~> 3.0' # Sidekiq 7
gem 'sidekiq-logstash', '~> 2.0' # Sidekiq 6
gem 'sidekiq-logstash', '< 2' # Sidekiq 5 or older
```

And then execute:

```bash
$ bundle
```

Or install it yourself as:

```bash
$ gem install sidekiq-logstash
```

## Usage

Simply add the following to your sidekiq configuration (in Rails, this will be `initializers/sidekiq.rb`)

```ruby
Sidekiq::Logstash.setup
```

I suggest you add it on top of it, before any other `Sidekiq.configure_server` initialization, in order to avoid unformatted logging.

## Configuration

Sidekiq::Logstash allows you to provide custom configuration

```ruby
Sidekiq::Logstash.configure do |config|
  # filter_args will allow you to filter the job arguments removing
  # it works just like rails params filtering (http://guides.rubyonrails.org/action_controller_overview.html#parameters-filtering)
  config.filter_args << 'foo'
  
  # by default, the "job started" logs are omitted from the logs
  # to have one-line logs for each log (following Lograge), but you can
  # enable job start logs by setting the following flag:
  config.job_start_log = true
  
  # custom_option is a Proc that will be called before logging the payload, allowing you to add fields to it
  config.custom_options = lambda do |payload|
    payload['my_custom_field'] = 'my_custom_value'
  end
  
  # by default, sidekiq-logstash removes the default error handler
  # to keep it, simply set this to true
  config.keep_default_error_handler = true
end
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/iMacTia/sidekiq-logstash.

