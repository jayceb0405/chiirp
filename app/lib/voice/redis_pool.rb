# frozen_string_literal: true

# app/lib/voice/redis_pool.rb
module Voice
  # process Redis calls to support Bandwidth voice processing
  class RedisPool
    # Create the object
    # vr_client = Voice::RedisPool.new(String)
    def initialize(parent_call_id)
      @parent_call_id = parent_call_id.to_s
    end

    # get call_ids from RedisPool
    # vr_client.call_ids
    def call_ids
      self.redis_lookup.dig('call_ids')
    end

    # set call_ids in RedisPool
    # vr_client.call_ids = []
    def call_ids=(call_ids)
      RedisCloud.redis.setex("pass_routing_method_multi:#{@parent_call_id}", self.ttl, { call_ids: }.to_json)
    end

    # delete call_ids from RedisPool
    # vr_client.call_ids_destroy
    def call_ids_destroy
      self.call_ids = []
    end

    private

    def redis_lookup
      JSON.parse(RedisCloud.redis.get("pass_routing_method_multi:#{@parent_call_id}") || '{"call_ids":[]}')
    end

    def ttl
      # 60 seconds
      60
    end
  end
end
