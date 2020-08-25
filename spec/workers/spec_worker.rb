# frozen_string_literal: true

class SpecWorker
  include Sidekiq::Worker

  def perform(fail = false, _params = {})
    raise RuntimeError if fail
  end
end
