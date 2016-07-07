FactoryGirl.define do
  factory :job, class: Hash do
    args [
      'just a simple string',
      {
        object_name: 'stars',
        object_id: Kernel.rand(10000),
        data: {
          id: Kernel.rand(10000),
          num_units: Kernel.rand(10000) * Kernel.rand
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

    initialize_with {attributes.stringify_keys}
  end
end