# frozen_string_literal: true

class SpecWorker
  include Sidekiq::Worker

  def perform(fail = false, _params = {})
    raise_error if fail
  rescue StandardError
    raise 'You know nothing, Jon Snow.'
  end

  private

  def raise_error
    raise 'Deepest error'
  rescue StandardError
    raise 'Error rescuing error'
  end
end
