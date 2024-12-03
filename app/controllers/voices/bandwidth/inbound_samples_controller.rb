# frozen_string_literal: true

# app/controllers/voices/bandwidth/inbound_samples_controller.rb
# rubocop:disable all
module Voices
  module Bandwidth
    # Client phone number settings: Incoming call routed to a User phone number
    # User phone number settings: Incoming calls accepted without User interaction
    # VoiceInController#voice_in
    # Voices::Bandwidth::InboundController#user_answered
    # Voices::Bandwidth::VoiceController#voice_complete
    #
    # Client phone number settings: Incoming call routed to a User phone number
    # User phone number settings: Incoming calls accepted with User interaction (user accepted)
    # VoiceInController#voice_in
    # Voices::Bandwidth::InboundController#user_answered
    # Voices::Bandwidth::InboundController#user_responded
    # Voices::Bandwidth::VoiceController#voice_complete
    #
    # Client phone number settings: Incoming call routed to a User phone number
    # User phone number settings: Incoming calls accepted with User interaction (user declined)
    # VoiceInController#voice_in
    # Voices::Bandwidth::InboundController#user_answered
    # Voices::Bandwidth::InboundController#user_responded
    # Voices::Bandwidth::InboundController#offer_voicemail
    # Voices::Bandwidth::VoiceController#voice_complete
    # Voices::Bandwidth::InboundController#receive_voicemail (if voicemail was left by caller)

    # sample data received from Bandwidth for inbound calls
    class InboundSamplesController < Voices::Bandwidth::VoiceController
      # Client phone number settings: Incoming call routed to a phone number
      #   Contact calls in & call is bridged to a phone number (answered)
      #     VoiceInController#voice_in
      #     Voices::Bandwidth::InboundController#bridge_call
      #     Voices::Bandwidth::InboundController#bridge_target_complete
      #     Voices::Bandwidth::VoiceController#voice_complete
      #
      def voice_in_phone_number_answered
        {
          "eventType"=>"initiate",
          "callId"=>"c-93085a28-4e9d6094-3e38-498a-b71d-a2a36cd2f35b",
          "from"=>"+18027791581",
          "to"=>"+18022898010",
          "direction"=>"inbound",
          "applicationId"=>"c7447ab1-2057-4413-b125-03504ed48e28",
          "accountId"=>"5007421",
          "startTime"=>"2022-05-04T14:28:14.015Z",
          "eventTime"=>"2022-05-04T14:28:14.023Z",
          "callUrl"=>"https://voice.bandwidth.com/api/v2/accounts/5007421/calls/c-93085a28-4e9d6094-3e38-498a-b71d-a2a36cd2f35b"
        }

        "<Response>
          <Ring duration=\"20\" />
          <SpeakSentence locale=\"en_US\" voice=\"julie\">No one is available to take your call. Please record your message. When you are finished recording press the pound key or hang up.</SpeakSentence>
          <Pause duration=\"1\" />
          <PlayAudio>https://media.chiirp.com/video/upload/v1645564095/samples/beep.mp3</PlayAudio>
          <Record maxDuration=\"60\" transcribe=\"true\" fileFormat=\"mp3\" recordCompleteUrl=\"https://dev.chiirp.com/voices/bandwidth/in/receive_voicemail?user_id=3\" transcriptionAvailableUrl=\"https://dev.chiirp.com/voices/bandwidth/in/receive_voicemail?user_id=3\"/>
        </Response>"
      end

      def bridge_call_phone_number_answered
        {
          "eventType"=>"answer",
          "callId"=>"c-7c4e7185-551856bf-d391-41db-8604-a0a0c3d9956e",
          "from"=>"+18027791581",
          "to"=>"+18023455136",
          "direction"=>"outbound",
          "applicationId"=>"c7447ab1-2057-4413-b125-03504ed48e28",
          "accountId"=>"5007421",
          "startTime"=>"2022-05-04T14:28:14.752Z",
          "eventTime"=>"2022-05-04T14:28:19.399Z",
          "callUrl"=>"https://voice.bandwidth.com/api/v2/accounts/5007421/calls/c-7c4e7185-551856bf-d391-41db-8604-a0a0c3d9956e",
          "answerTime"=>"2022-05-04T14:28:19.399Z",
          "client_phone"=>"8022898010",
          "parent_call_id"=>"c-93085a28-4e9d6094-3e38-498a-b71d-a2a36cd2f35b"
        }

        "<Response>
          <Bridge bridgeTargetCompleteUrl=\"https://dev.chiirp.com/voices/bandwidth/in/bridge_target_complete\" bridgeCompleteUrl=\"https://dev.chiirp.com/voices/bandwidth/in/bridge_complete/c-93085a28-4e9d6094-3e38-498a-b71d-a2a36cd2f35b?user_phone=\">c-93085a28-4e9d6094-3e38-498a-b71d-a2a36cd2f35b</Bridge>
        </Response>"
      end

      def disconnected_call_phone_number_answered
        {
          "eventType"=>"disconnect",
          "callId"=>"c-7c4e7185-551856bf-d391-41db-8604-a0a0c3d9956e",
          "from"=>"+18027791581",
          "to"=>"+18023455136",
          "direction"=>"outbound",
          "applicationId"=>"c7447ab1-2057-4413-b125-03504ed48e28",
          "accountId"=>"5007421",
          "startTime"=>"2022-05-04T14:28:14.752Z",
          "eventTime"=>"2022-05-04T14:28:24.947Z",
          "callUrl"=>"https://voice.bandwidth.com/api/v2/accounts/5007421/calls/c-7c4e7185-551856bf-d391-41db-8604-a0a0c3d9956e",
          "answerTime"=>"2022-05-04T14:28:19.399Z",
          "endTime"=>"2022-05-04T14:28:24.947Z",
          "cause"=>"hangup",
          "client_phone"=>"8022898010",
          "parent_call_id"=>"c-93085a28-4e9d6094-3e38-498a-b71d-a2a36cd2f35b"
        }

        "<Response></Response>"
      end

      def bridge_target_complete_phone_number_answered
        # will happen if carrier voicemail answers call to User
        {
          "eventType"=>"bridgeTargetComplete",
          "callId"=>"c-93085a28-4e9d6094-3e38-498a-b71d-a2a36cd2f35b",
          "from"=>"+18027791581",
          "to"=>"+18022898010",
          "direction"=>"inbound",
          "applicationId"=>"c7447ab1-2057-4413-b125-03504ed48e28",
          "accountId"=>"5007421",
          "startTime"=>"2022-05-04T14:28:14.015Z",
          "eventTime"=>"2022-05-04T14:28:25.006Z",
          "callUrl"=>"https://voice.bandwidth.com/api/v2/accounts/5007421/calls/c-93085a28-4e9d6094-3e38-498a-b71d-a2a36cd2f35b",
          "answerTime"=>"2022-05-04T14:28:14.923Z"
        }

        "<Response></Response>"
      end

      def voice_complete_phone_number_answered
        {
          "eventType"=>"disconnect",
          "callId"=>"c-93085a28-4e9d6094-3e38-498a-b71d-a2a36cd2f35b",
          "from"=>"+18027791581",
          "to"=>"+18022898010",
          "direction"=>"inbound",
          "applicationId"=>"c7447ab1-2057-4413-b125-03504ed48e28",
          "accountId"=>"5007421",
          "startTime"=>"2022-05-04T14:28:14.015Z",
          "eventTime"=>"2022-05-04T14:28:25.598Z",
          "callUrl"=>"https://voice.bandwidth.com/api/v2/accounts/5007421/calls/c-93085a28-4e9d6094-3e38-498a-b71d-a2a36cd2f35b",
          "answerTime"=>"2022-05-04T14:28:14.923Z",
          "endTime"=>"2022-05-04T14:28:25.597Z",
          "cause"=>"hangup"
        }

        "<Response></Response>"
      end

      # Client phone number settings: Incoming call routed to a phone number
      #   Contact calls in & call is bridged to a phone number (not answered)
      #     VoiceInController#voice_in
      #     Voices::Bandwidth::VoiceController#voice_complete
      #     Voices::Bandwidth::InboundController#bridge_call
      #     Voices::Bandwidth::InboundController#bridge_complete
      #
      def voice_in_phone_number_not_answered
        {
          "eventType"=>"initiate",
          "callId"=>"c-7c4e7185-038dbd9a-7759-43cf-a918-5fba37048437",
          "from"=>"+18027791581",
          "to"=>"+18022898010",
          "direction"=>"inbound",
          "applicationId"=>"c7447ab1-2057-4413-b125-03504ed48e28",
          "accountId"=>"5007421",
          "startTime"=>"2022-05-04T18:05:13.694Z",
          "eventTime"=>"2022-05-04T18:05:13.714Z",
          "callUrl"=>"https://voice.bandwidth.com/api/v2/accounts/5007421/calls/c-7c4e7185-038dbd9a-7759-43cf-a918-5fba37048437"
        }

        "<Response>
          <Ring duration=\"20\" />
          <SpeakSentence locale=\"en_US\" voice=\"julie\">No one is available to take your call. Please record your message. When you are finished recording press the pound key or hang up.</SpeakSentence>
          <Pause duration=\"1\" />
          <PlayAudio>https://media.chiirp.com/video/upload/v1645564095/samples/beep.mp3</PlayAudio>
          <Record maxDuration=\"60\" transcribe=\"true\" fileFormat=\"mp3\" recordCompleteUrl=\"https://dev.chiirp.com/voices/bandwidth/in/receive_voicemail?user_id=3\" transcriptionAvailableUrl=\"https://dev.chiirp.com/voices/bandwidth/in/receive_voicemail?user_id=3\"/>
        </Response>"
      end

      def disconnected_call_phone_number_not_answered
         {
          "eventType"=>"disconnect",
          "callId"=>"c-e769bec4-9c2001ec-7559-4641-9460-b32aff0df57a",
          "from"=>"+18027791581",
          "to"=>"+18023455136",
          "direction"=>"outbound",
          "applicationId"=>"c7447ab1-2057-4413-b125-03504ed48e28",
          "accountId"=>"5007421",
          "startTime"=>"2022-05-04T18:05:15.104Z",
          "eventTime"=>"2022-05-04T18:05:36.748Z",
          "callUrl"=>"https://voice.bandwidth.com/api/v2/accounts/5007421/calls/c-e769bec4-9c2001ec-7559-4641-9460-b32aff0df57a",
          "endTime"=>"2022-05-04T18:05:36.748Z",
          "cause"=>"timeout",
          "errorMessage"=>"Call was not answered",
          "client_phone"=>"8022898010",
          "parent_call_id"=>"c-7c4e7185-038dbd9a-7759-43cf-a918-5fba37048437"
        }

        "<Response></Response>"
      end

      def voice_complete_phone_number_not_answered
        {
          "eventType"=>"disconnect",
          "callId"=>"c-7c4e7185-038dbd9a-7759-43cf-a918-5fba37048437",
          "from"=>"+18027791581",
          "to"=>"+18022898010",
          "direction"=>"inbound",
          "applicationId"=>"c7447ab1-2057-4413-b125-03504ed48e28",
          "accountId"=>"5007421",
          "startTime"=>"2022-05-04T18:05:13.694Z",
          "eventTime"=>"2022-05-04T18:05:48.922Z",
          "callUrl"=>"https://voice.bandwidth.com/api/v2/accounts/5007421/calls/c-7c4e7185-038dbd9a-7759-43cf-a918-5fba37048437",
          "answerTime"=>"2022-05-04T18:05:15.349Z",
          "endTime"=>"2022-05-04T18:05:48.922Z",
          "cause"=>"hangup"
        }

        "<Response></Response>"
      end

      def receive_voicemail_phone_number_not_answered
        {
          "callId"=>"c-7c4e7185-038dbd9a-7759-43cf-a918-5fba37048437",
          "callUrl"=>"https://voice.bandwidth.com/api/v2/accounts/5007421/calls/c-7c4e7185-038dbd9a-7759-43cf-a918-5fba37048437",
          "mediaUrl"=>"https://voice.bandwidth.com/api/v2/accounts/5007421/calls/c-7c4e7185-038dbd9a-7759-43cf-a918-5fba37048437/recordings/r-fbe17a78-6679c0dd-e2eb-45f4-b5ad-803ca9d1d1c9/media",
          "transcription"=>{
            "id"=>"t-e3221842-ba01-427a-bc1e-fd1b24557f11",
            "status"=>"available",
            "url"=>"https://voice.bandwidth.com/api/v2/accounts/5007421/calls/c-7c4e7185-038dbd9a-7759-43cf-a918-5fba37048437/recordings/r-fbe17a78-6679c0dd-e2eb-45f4-b5ad-803ca9d1d1c9/transcription",
            "completeTime"=>"2022-05-04T18:06:07.797Z"
          },
          "eventType"=>"transcriptionAvailable",
          "duration"=>"PT3.1S",
          "accountId"=>"5007421",
          "eventTime"=>"2022-05-04T18:06:49.821024168Z",
          "startTime"=>"2022-05-04T18:05:45.746Z",
          "from"=>"+18027791581",
          "endTime"=>"2022-05-04T18:05:48.921Z",
          "to"=>"+18022898010",
          "applicationId"=>"c7447ab1-2057-4413-b125-03504ed48e28",
          "recordingId"=>"r-fbe17a78-6679c0dd-e2eb-45f4-b5ad-803ca9d1d1c9",
          "fileFormat"=>"mp3",
          "direction"=>"inbound",
          "user_id"=>"3"
        }
      end
    end
  end
end
