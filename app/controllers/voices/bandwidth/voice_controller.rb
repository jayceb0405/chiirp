# frozen_string_literal: true

# app/controllers/voices/bandwidth/voice_controller.rb
module Voices
  module Bandwidth
    # Support for voices/bandwidth endpoints used with Chiirp
    class VoiceController < Voices::VoiceController
      skip_before_action :verify_authenticity_token, only: %i[voice_complete]

      # callback after Bandwidth call is complete
      # /voices/bandwidth/voicecomplete
      # voices_bandwidth_voice_complete_path
      # voices_bandwidth_voice_complete_url
      def voice_complete
        sanitized_params = params.permit(:accountId, :applicationId, :callId, :callUrl, :cause, :direction, :endTime, :errorMessage, :eventTime, :eventType, :from, :startTime, :to)
        call_status      = 'completed'

        render plain: '', content_type: 'text/plain', layout: false, status: :ok

        if %w[cancel hangup].include?(sanitized_params.dig(:cause).to_s.downcase)
          call_status = sanitized_params.dig(:cause).to_s.downcase
          vr_client   = Voice::RedisPool.new(sanitized_params.dig(:callId).to_s)

          vr_client.call_ids.each do |call_id|
            Voice::Bandwidth.call_cancel(call_id)
          end

          vr_client.call_ids_destroy
        end

        update_message(
          message_sid:   sanitized_params.dig(:callId),
          call_status:,
          call_duration: Voice::Bandwidth.call_duration(sanitized_params.dig(:startTime), sanitized_params.dig(:endTime))
        )

        return nil unless sanitized_params.dig(:cause).to_s.downcase == 'hangup' &&
                          sanitized_params.dig(:startTime).presence&.respond_to?(:to_time) && sanitized_params.dig(:endTime).presence&.respond_to?(:to_time) &&
                          (message = Messages::Message.find_by(message_sid: sanitized_params.dig(:callId).to_s)) &&
                          (sanitized_params.dig(:endTime).to_time - sanitized_params.dig(:startTime).to_time) <= Twnumber.find_by(client_id: message.contact.client_id, phonenumber: sanitized_params.dig(:to).to_s.clean_phone)&.hangup_detection_duration.to_i.seconds

        Contacts::Campaigns::StartOnMissedCallJob.perform_later(
          client_id:           message.contact.client_id,
          client_phone_number: message.to_phone,
          contact_id:          message.contact.id,
          user_id:             message.contact.user_id
        )
      end
      # sample parameters after call was connected to a User
      # {
      #   eventType:     'disconnect',
      #   callId:        'c-693ef4a6-f3536426-ddc2-4751-b1b4-61385a4f1d40',
      #   from:          '+18022823191',
      #   to:            '+18022898010',
      #   privacy:       false,
      #   direction:     'inbound',
      #   applicationId: 'c7447ab1-2057-4413-b125-03504ed48e28',
      #   accountId:     '5007421',
      #   startTime:     '2024-08-05T20:44:25.894Z',
      #   eventTime:     '2024-08-05T20:44:37.924Z',
      #   callUrl:       'https://voice.bandwidth.com/api/v2/accounts/5007421/calls/c-693ef4a6-f3536426-ddc2-4751-b1b4-61385a4f1d40',
      #   answerTime:    '2024-08-05T20:44:28.681Z',
      #   endTime:       '2024-08-05T20:44:37.924Z',
      #   cause:         'hangup'
      # }
      # sample parameters after a Contact hung up before the call was connected to a User
      # {
      #   eventType:     'disconnect',
      #   callId:        'c-fe23a767-af072c0b-c2f9-449d-8d8d-84b90acab58d',
      #   from:          '+18022823191',
      #   to:            '+18022898010',
      #   privacy:       false,
      #   direction:     'inbound',
      #   applicationId: 'c7447ab1-2057-4413-b125-03504ed48e28',
      #   accountId:     '5007421',
      #   startTime:     '2024-08-05T22:25:33.274Z',
      #   eventTime:     '2024-08-05T22:25:39.495Z',
      #   callUrl:       'https://voice.bandwidth.com/api/v2/accounts/5007421/calls/c-fe23a767-af072c0b-c2f9-449d-8d8d-84b90acab58d',
      #   answerTime:    '2024-08-05T22:25:36.432Z',
      #   endTime:       '2024-08-05T22:25:39.494Z',
      #   cause:         'hangup'
      # }
    end
  end
end
