# frozen_string_literal: true

# app/jobs/messages/process_message_callback_job.rb
module Messages
  class ProcessMessageCallbackJob < ApplicationJob
    # process a text message callback received from phone vendor
    # Messages::ProcessMessageCallbackJob.set(wait_until: 1.day.from_now).perform_later()
    # Messages::ProcessMessageCallbackJob.set(wait_until: 1.day.from_now, priority: 0).perform_later(

    def initialize(**args)
      super

      @process = (args.dig(:process).presence || 'process_msg_callback').to_s
    end

    # perform the ActiveJob
    #   (req) params: (Hash / received from webhook)
    def perform(**args)
      super

      result = SMS::Router.callback(**args)

      if result[:success] && result[:message_sid].present? && (message = Messages::Message.find_by(message_sid: result[:message_sid]))
        # only update status if it has advanced
        status = SMS::Router.status_options.index(result[:status]) > SMS::Router.status_options.index(message.status) ? result[:status] : message.status
        message.update(status:, error_code: result[:error_code], error_message: result[:error_message])

        UserCable.new.broadcast message.contact.client, message.contact.user, { id: message.id, msg_status: message.status }
      end

      true
    end
  end
end
