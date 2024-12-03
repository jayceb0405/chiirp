# frozen_string_literal: true

# app/jobs/messages/update_unread_message_indicators_job.rb
module Messages
  class UpdateUnreadMessageIndicatorsJob < ApplicationJob
    # Messages::UpdateUnreadMessageIndicatorsJob.perform_later(user_id: Integer)
    #   (req) user_id: (Integer)

    def initialize(**args)
      super

      @process = (args.dig(:process).presence || 'update_unread_message_indicators').to_s
    end

    # perform the ActiveJob
    def perform(**args)
      super

      return unless (user = User.find_by(id: args.dig(:user_id).to_i))

      Users::SendPushJob.perform_now(
        content: '',
        user_id: user.id
      )

      CableBroadcaster.new.unread_messages(user:, light: Messages::Message.unread_messages_by_user(user.id).any?)
    end
  end
end
