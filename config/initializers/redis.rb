# config/initializers/redis.rb

# connection pool to Redis
REDIS_POOL = ConnectionPool.new(size: 20) { Redis.new(url: ENV.fetch('REDIS_URL', 'redis://localhost:6379/1')) }
