# frozen_string_literal: true

# app/controllers/voices/voice_controller.rb
module Voices
  # endpoints supporting voice handling
  class VoiceController < ApplicationController
    private

    # update a Messages::Message with call details
    # update_message()
    #   (req) message_sid          (String)
    #
    #   (opt) answered_by_phone:   (String / default: '')
    #   (opt) call_status:         (String / default: '')
    #   (opt) call_duration:       (BigDecimal / default: 0)
    #   (opt) connected_to_phone:  (String / default: '')
    #   (opt) contact_campaign_id: (Integer / default: 0)
    #   (opt) declined_by_phone:   (String / default: '')
    #   (opt) recording_url:       (String / default: '')
    #   (opt) refresh_messages:    (Boolean / default: false)
    #   (opt) transcription_text:  (String / default: '')
    #   (opt) triggeraction_id:    (Integer / default: 0)
    #   (opt) unanswered_by_phone: (String / default: '')
    def update_message(args = {})
      return unless args.dig(:message_sid).present? && (message = Messages::Message.find_by(message_sid: args.dig(:message_sid).to_s))

      unanswered_by_phone = args.dig(:unanswered_by_phone).to_s.clean_phone(message.contact.client.primary_area_code)
      answered_by_phone   = args.dig(:answered_by_phone).to_s.clean_phone(message.contact.client.primary_area_code)
      connected_to_phone  = args.dig(:connected_to_phone).to_s.clean_phone(message.contact.client.primary_area_code)
      declined_by_phone   = args.dig(:declined_by_phone).to_s.clean_phone(message.contact.client.primary_area_code)

      message.reload
      message.message += " Not answered by #{ActionController::Base.helpers.number_to_phone(unanswered_by_phone)}." if unanswered_by_phone.present?
      message.message += " Answered by #{ActionController::Base.helpers.number_to_phone(answered_by_phone)}." if answered_by_phone.present?
      message.message += " Connected to #{ActionController::Base.helpers.number_to_phone(connected_to_phone)}." if connected_to_phone.present?
      message.message += " Declined by #{ActionController::Base.helpers.number_to_phone(declined_by_phone)}." if declined_by_phone.present?

      if args.dig(:transcription_text).present? || args.dig(:recording_url).present?
        message.message += " Voicemail: #{args[:transcription_text]} #{ActionController::Base.helpers.audio_tag(args.dig(:recording_url).to_s, controls: true)}"
        message.status   = 'voicemail'
      end

      if args.dig(:call_status).to_s.downcase == 'completed' && args.dig(:call_duration).to_d.positive?
        message.message      += " (length: #{ActionController::Base.helpers.distance_of_time_in_words(Time.current, Time.current + args[:call_duration].to_i.seconds, { include_seconds: true })})"
        message.num_segments  = args[:call_duration].to_i
        message.status        = args.dig(:call_status).to_s.downcase
      end

      message.save

      if %w[completed voicemail].include?(message.status)
        args[:refresh_messages] = true

        if args.dig(:contact_campaign_id).to_i.positive? && (contact_campaign = message.contact.contact_campaigns.find_by(id: args[:contact_campaign_id].to_i))
          add_on = contact_campaign.data.dig(:triggeractions, args.dig(:triggeraction_id).to_i, :machine_detection) ? BigDecimal('0.5') : 0
        end

        # charge Client for call
        message.contact.client.charge_for_action(key: 'phone_call_credits', multiplier: message.num_segments, add_on:, contact_id: message.contact_id, message_id: message.id)

        # update Contact last contact date
        message.contact.update(last_contacted: Time.current)
      end

      return unless args.dig(:refresh_messages).to_bool

      show_live_messenger = ShowLiveMessenger.new(message:)
      show_live_messenger.queue_broadcast_active_contacts
      show_live_messenger.queue_broadcast_message_thread_message
    end
  end
end
