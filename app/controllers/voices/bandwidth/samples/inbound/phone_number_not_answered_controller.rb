# frozen_string_literal: true

# app/controllers/voices/bandwidth/samples/inbound/phone_number_not_answered_controller.rb
# rubocop:disable all
module Voices
  module Bandwidth
    module Samples
      module Inbound
        # sample data received/returned from Bandwidth for inbound calls to a phone number where calls are NOT answered
        class PhoneNumberNotAnsweredController < Voices::Bandwidth::VoiceController
          def voice_in
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

          def disconnected_call
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

          def voice_complete
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

          def receive_voicemail
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
  end
end
