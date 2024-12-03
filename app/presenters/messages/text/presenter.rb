# frozen_string_literal: true

# app/presenters/messages/text/presenter.rb
module Messages
  module Text
    class Presenter < BasePresenter
      attr_accessor :contacts_array, :file_attachments, :file_type, :message, :message_id
      attr_reader :contact, :client, :user
      attr_writer :disabled, :include_estimate_hashtags, :include_invoice_hashtags, :include_job_hashtags, :include_subscription_hashtags, :show_character_count, :show_hashtag_notes, :show_images, :show_msg_delay, :show_ok2text, :show_payment_request, :show_phone_call, :show_quick_responses, :show_submit, :show_video_calls, :show_voicemail

      # Messages::Text::Presenter.new()
      def initialize(args = {})
        super

        @active_aiagents      = @contact.active_aiagents?
        @contacts_array       = []
        @current_phone_number = nil
        @disabled             = false
        @file_attachments     = []
        # [
        #   { id: Integer, type: String, url: String },
        #   { id: Integer, type: String, url: String }
        # ]
        #   type: "client", "user", "contact"
        @file_type                     = 'client'
        @include_estimate_hashtags     = true
        @include_invoice_hashtags      = true
        @include_job_hashtags          = true
        @include_subscription_hashtags = true
        @message                       = ''
        @message_id                    = SecureRandom.uuid
        @show_character_count          = true
        @show_hashtag_notes            = false
        @show_images                   = true
        @show_msg_delay                = true
        @show_ok2text                  = true
        @show_payment_request          = true
        @show_phone_call               = true
        @show_quick_responses          = true
        @show_submit                   = true
        @show_video_calls              = true
        @show_voicemail                = true
        @user_settings                 = nil
      end

      def active_aiagents?
        @active_aiagents
      end

      def current_phone_number
        @current_phone_number ||= self.user_settings.data.dig(:phone_number) || @contact.latest_client_phonenumber(current_session: @session, default_ok: true, phone_numbers_only: true)&.phonenumber.to_s
      end

      def disabled?
        @disabled.to_bool
      end

      def file_upload_url
        app_host = I18n.with_locale(@client.tenant) { I18n.t("tenant.#{Rails.env}.app_host") }

        case @file_type
        when 'client'
          Rails.application.routes.url_helpers.client_file_upload_url(@client, host: app_host)
        when 'user'
          Rails.application.routes.url_helpers.user_file_upload_url(@user, host: app_host)
        when 'contact'
          Rails.application.routes.url_helpers.contact_file_upload_url(@contact, host: app_host)
        else
          ''
        end
      end

      def include_estimate_hashtags?
        @include_estimate_hashtags.to_bool && %w[housecall jobber jobnimbus responsibid servicemonster servicetitan].intersect?(@client.integrations_allowed)
      end

      def include_invoice_hashtags?
        @include_invoice_hashtags.to_bool && %w[jobber].intersect?(@client.integrations_allowed)
      end

      def include_job_hashtags?
        @include_job_hashtags.to_bool && %w[fieldroutes housecall jobber jobnimbus responsibid servicemonster servicetitan].intersect?(@client.integrations_allowed)
      end

      def include_subscription_hashtags?
        @include_subscription_hashtags.to_bool && %w[fieldroutes].intersect?(@client.integrations_allowed)
      end

      def show_character_count?
        @show_character_count.to_bool
      end

      def show_hashtag_notes?
        @show_hashtag_notes.to_bool
      end

      def show_images?
        @show_images.to_bool
      end

      def show_msg_delay?
        @show_msg_delay.to_bool
      end

      def show_ok2text?
        @show_ok2text.to_bool
      end

      def show_payment_request?
        @show_payment_request.to_bool && @client.integrations_allowed.include?('cardx')
      end

      def show_phone_call?
        @show_phone_call.to_bool
      end

      def show_quick_responses?
        @show_quick_responses.to_bool
      end

      def show_submit?
        @show_submit.to_bool
      end

      def show_video_calls?
        @show_video_calls
      end

      def show_voicemail?
        @show_voicemail.to_bool
      end

      def user_settings
        @user_settings ||= @user.message_central_user_settings
      end

      def voice_disabled
        @contact.new_record? || (@client.current_balance.to_d / BigDecimal('100')) < @client.phone_call_credits.to_d || @disabled
      end
    end
  end
end
