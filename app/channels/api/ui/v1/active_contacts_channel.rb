# frozen_string_literal: true

module Api
  module Ui
    module V1
      class ActiveContactsChannel < ApplicationCable::Channel
        def subscribed
          stream_for current_user
        end

        def unsubscribed
          # Any cleanup needed when channel is unsubscribed
        end
      end
    end
  end
end

# determine what channels are currently subscribed to
# pubsub = ActionCable.server.pubsub
# channel_with_prefix = pubsub.send(:channel_with_prefix, Api::Ui::V1::AlertsChannel.channel_name)
# channels = pubsub.send(:redis_connection).pubsub('channels', "#{channel_with_prefix}:*")
