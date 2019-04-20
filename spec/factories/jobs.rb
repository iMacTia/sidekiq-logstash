# frozen_string_literal: true

FactoryGirl.define do
  factory :job, class: Hash do
    args [
      'just a simple string',
      {
        object_name: 'stars',
        object_id: Kernel.rand(10_000),
        data: {
          id: Kernel.rand(10_000),
          num_units: Kernel.rand(10_000) * Kernel.rand
        }.stringify_keys
      }.stringify_keys,
      {
        a_simple_param: 'hello',
        a_secret_param: 'secret'
      }.stringify_keys
    ]
    queue 'default'
    jid '0afe8ddfcba21525022ce638'
    enqueued_at '2016-07-06T18:18:25.499Z'
    encrypt false

    initialize_with { attributes.stringify_keys }
    after(:build) do |job|
      job['args'][-1] = 'BAhTOhFTaWRla2lxOjpFbmMIOgdpdiIVo1mbHmnVxiOIT' if job['encrypt']
    end
  end
end
