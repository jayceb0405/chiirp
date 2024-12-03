# frozen_string_literal: true

# app/lib/contacts/redis_pool.rb
module Contacts
  # process Redis calls to support Contacts
  class RedisPool
    attr_accessor :contact_id

    # Create the object
    # Contacts::RedisPool.new(contact_id)
    #   (opt) contact_id: (Integer)
    def initialize(contact_id = 0)
      @contact_id = contact_id.to_i
    end

    # update RedisPool with current Contact settings
    # Contacts::RedisPool.new(contact_id).user_id_typing=()
    #   (opt) user_id: (Integer)
    def user_id_typing=(user_id = 0)
      return if @contact_id.zero?

      RedisCloud.redis.setex("contacts:#{@contact_id}", 1800, { typing_user_id: user_id.to_i }.to_json)
    end

    # return the User that is typing a message to a Contact
    # Contacts::RedisPool.new(contact_id).user_id_typing
    def user_id_typing
      self.redis_lookup.dig(:typing_user_id).to_i
    end

    private

    def redis_lookup
      JSON.parse(RedisCloud.redis.get("contacts:#{@contact_id}") || '{"typing_user_id":0}').symbolize_keys
    end
  end
end
