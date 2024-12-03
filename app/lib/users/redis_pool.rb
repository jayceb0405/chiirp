# frozen_string_literal: true

# app/lib/users/redis_pool.rb
module Users
  # process Redis calls to support Users
  class RedisPool
    # Create the object
    # Users::RedisPool.new(user_id)
    #   (opt) user_id: (Integer)
    def initialize(user_id = 0)
      @user_redis_hash = self.redis_lookup(user_id) if user_id.to_i.positive?
    end

    def action_name
      @user_redis_hash.dig('action_name').to_s
    end

    # return true if any view is visible to User
    # Users::RedisPool.new(user_id).any_view_visible?
    def any_view_visible?
      self.contact_id.present? && self.action_name.present?
    end

    def contact_id
      @user_redis_hash.dig('contact_id').to_i
    end

    # return true if Contact is visible by User in Message Central
    # Users::RedisPool.new(user_id).contact_visible_by_user_in_message_central?(contact_id)
    #   (req) contact_id: (Integer)
    def contact_visible_by_user_in_message_central?(contact_id)
      self.message_central_visible? && self.contact_id == contact_id
    end

    def controller_class
      @user_redis_hash.dig('controller_class').to_s.downcase
    end

    def controller_name
      @user_redis_hash.dig('controller_name').to_s
    end

    # return true if Message Central is visible by User
    # Users::RedisPool.new(user_id).message_central_visible?
    def message_central_visible?
      self.controller_name == 'central' && self.action_name == 'index'
    end

    # update RedisPool with current User settings
    # Users::RedisPool.new(0).update(user_id: Integer, controller_name: String, action_name: String, contact_id: Integer)
    def update(args = {})
      user_id          = args.dig(:user_id).to_i
      controller_name  = args.dig(:controller_name).to_s
      action_name      = args.dig(:action_name).to_s
      controller_class = args.dig(:controller_class).to_s
      contact_id       = args.dig(:contact_id).to_i
      keep_contact_id  = args.dig(:keep_contact_id).to_bool

      return if controller_name == 'client_widgets' && action_name == 'show_widget'

      if contact_id.zero? && keep_contact_id
        @user_redis_hash = self.redis_lookup(user_id)
        contact_id       = @user_redis_hash['contact_id'].to_i
      end

      RedisCloud.redis.setex("users:#{user_id}", 1800, { controller_name:, action_name:, controller_class:, contact_id: }.to_json) if user_id.positive?
    end

    def users_viewing_contact(contact_id)
      user_ids = []
      RedisCloud.redis.with { |c_1| c_1.keys('users:*') }.each { |u| user_ids << u[6..].to_i if RedisCloud.redis.with { |c_2| JSON.parse(c_2.get(u) || '{}').dig('contact_id').to_i == contact_id.to_i } }

      user_ids
    end

    private

    def redis_lookup(user_id)
      JSON.parse(RedisCloud.redis.get("users:#{user_id}") || '{"controller_name":"","action_name":"","controller_class":"","contact_id":0}')
    end
  end
end
