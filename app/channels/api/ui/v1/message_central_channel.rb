# frozen_string_literal: true

# Api::Ui::V1::MessageCentralChannel
module Api
  module Ui
    module V1
      class MessageCentralChannel < ApplicationCable::Channel
        def subscribed
          contact = Contact.find_by(id: params[:contact_id])

          return reject if contact.blank?
          return reject unless current_user.access_contact?(contact)

          stream_for [contact, current_user]
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
