# frozen_string_literal: true

# app/channels/client_channel.rb
# server side of the Cable
class ClientChannel < ApplicationCable::Channel
  def subscribed
    stream_from "client_channel:#{current_user.client.id}"
    # Rails.logger.info "User (#{current_user.id}) subscribed to ClientChannel:#{current_user.client.id}. - File: #{__FILE__} - Line: #{__LINE__}"

    # pubsub = ActionCable.server.pubsub
    # channel_with_prefix = pubsub.send(:channel_with_prefix, ClientChannel.channel_name)
    # redis_connection = pubsub.send(:redis_connection)
    # channels = redis_connection.pubsub('channels', "#{channel_with_prefix}:*")
    # subscriptions = channels.map do |channel|
    #   Base64.decode64(channel.match(/^#{Regexp.escape(channel_with_prefix)}:(.*)$/)[1])
    # end

    # chat_ids = subscriptions.map do |subscription|
    #   subscription.match(gid_uri_pattern)
    #   # compacting because 'subscriptions' include all subscriptions made from RoomChannel,
    #   # not just subscriptions to Room records
    # end.compact.map { |match| match[1] }
  end

  def unsubscribed
    # RedisCloud.redis.del("users:#{current_user.id}")
    # Rails.logger.info "User (#{current_user.id}) unsubscribed from ClientChannel. - File: #{__FILE__} - Line: #{__LINE__}"
  end

  def appear(data)
    # Rails.logger.info "User (#{current_user.id}) appeared on ClientChannel. - File: #{__FILE__} - Line: #{__LINE__}"
  end

  def away
    # Rails.logger.info "User (#{current_user.id}) away from ClientChannel. - File: #{__FILE__} - Line: #{__LINE__}"
  end

  def receive(data)
    ActionCable.server.broadcast('client_channel', data)
  end
end
