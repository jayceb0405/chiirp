# frozen_string_literal: true

module ActionCable
  module Channel
    module Broadcasting
      module ClassMethods
        def active_subscriptions_for?(key)
          # TODO: Redis pubsub numsub will not work with Redis Cluster
          REDIS_POOL.with { |client| client.pubsub('numsub', full_channel_name(key)).last.positive? }
        end

        def active_subscriptions_for_prefix(prefix)
          # TODO: Redis pubsub channels will not work with Redis Cluster
          REDIS_POOL.with { |client| client.pubsub('channels', "#{full_channel_name(prefix)}:*") }
        end

        def full_channel_name(key)
          [
            ActionCable.server.config.cable[:channel_prefix],
            broadcasting_for(key)
          ].compact.join(':').gsub(':turbo:streams', '')
        end
      end
    end
  end
end
