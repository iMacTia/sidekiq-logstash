# frozen_string_literal: true

class SpecWorker
  include Sidekiq::Worker

  def perform(fail = false, _params = {})
    raise 'You know nothing, Jon Snow.' if fail
  end
end
