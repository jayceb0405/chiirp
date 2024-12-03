# frozen_string_literal: true

# app/lib/redis_cloud.rb
module RedisCloud
  def self.redis
    @redis ||= ConnectionPool::Wrapper.new do
      Redis.new(url: ENV.fetch('REDIS_URL', 'redis://localhost:6379/1'))
    end
  end
end
