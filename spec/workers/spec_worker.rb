class SpecWorker
  include Sidekiq::Worker

  def perform(fail = false)
    raise RuntimeError if fail
  end
end
