# frozen_string_literal: true

# app/controllers/messages/emails_controller.rb
module Messages
  class EmailsController < ApplicationController
    before_action :authenticate_user!
    before_action :message

    # (GET) show Messages::Email in a modal
    # /messages/messages/:message_id/email
    # messages_message_email_path(:message_id)
    # messages_message_email_url(:message_id)
    def show
      respond_to do |format|
        format.js { render partial: 'messages/emails/js/show', locals: { cards: %w[message_email message_email_show] } }
        format.html { redirect_to root_path and return false }
      end
    end

    # (GET) show Messages::Email HTML body
    # /messages/messages/:message_id/image
    # messages_message_email_html_body_path(:message_id)
    # messages_message_email_html_body_url(:message_id)
    def html_body
      send_data @message.email.html_body, type: 'text/html', disposition: :inline
    end

    private

    def message
      message_id = params.dig(:message_id).to_i

      @message = Messages::Message.find_by(id: message_id)
      raise ActiveRecord::RecordNotFound unless @message && @message.contact.client_id == current_user.client_id
    end
  end
end
