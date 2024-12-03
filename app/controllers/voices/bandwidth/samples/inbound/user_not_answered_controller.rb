# frozen_string_literal: true

# app/controllers/voices/bandwidth/samples/inbound/user_not_answered_controller.rb
# rubocop:disable all
module Voices
  module Bandwidth
    module Samples
      module Inbound
        # sample data received/returned from Bandwidth for inbound calls to a User without "press a key" where calls are NOT answered
        class UserNotAnsweredController < Voices::Bandwidth::VoiceController
          def voice_in
             {
              "eventType"=>"initiate",
              "callId"=>"c-7c4e7185-ec05be9c-c3a8-43c6-9250-c4e378b551af",
              "from"=>"+18027791581",
              "to"=>"+18022898010",
              "direction"=>"inbound",
              "applicationId"=>"c7447ab1-2057-4413-b125-03504ed48e28",
              "accountId"=>"5007421",
              "startTime"=>"2022-05-04T18:53:01.814Z",
              "eventTime"=>"2022-05-04T18:53:01.832Z",
              "callUrl"=>"https://voice.bandwidth.com/api/v2/accounts/5007421/calls/c-7c4e7185-ec05be9c-c3a8-43c6-9250-c4e378b551af"
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
              "callId"=>"c-e769bec4-fe9556b5-7cdf-47b1-a469-ede4ac923c12",
              "from"=>"+18027791581",
              "to"=>"+18023455136",
              "direction"=>"outbound",
              "applicationId"=>"c7447ab1-2057-4413-b125-03504ed48e28",
              "accountId"=>"5007421", "startTime"=>"2022-05-04T18:53:03.383Z",
              "eventTime"=>"2022-05-04T18:53:25.179Z",
              "callUrl"=>"https://voice.bandwidth.com/api/v2/accounts/5007421/calls/c-e769bec4-fe9556b5-7cdf-47b1-a469-ede4ac923c12",
              "endTime"=>"2022-05-04T18:53:25.179Z",
              "cause"=>"timeout",
              "errorMessage"=>"Call was not answered",
              "client_phone"=>"8022898010",
              "parent_call_id"=>"c-7c4e7185-ec05be9c-c3a8-43c6-9250-c4e378b551af"
            }

            "<Response></Response>"
          end

          def voice_complete
            {
              "eventType"=>"disconnect",
              "callId"=>"c-7c4e7185-ec05be9c-c3a8-43c6-9250-c4e378b551af",
              "from"=>"+18027791581",
              "to"=>"+18022898010",
              "direction"=>"inbound",
              "applicationId"=>"c7447ab1-2057-4413-b125-03504ed48e28",
              "accountId"=>"5007421",
              "startTime"=>"2022-05-04T18:53:01.814Z",
              "eventTime"=>"2022-05-04T18:53:39.252Z",
              "callUrl"=>"https://voice.bandwidth.com/api/v2/accounts/5007421/calls/c-7c4e7185-ec05be9c-c3a8-43c6-9250-c4e378b551af",
              "answerTime"=>"2022-05-04T18:53:05.360Z",
              "endTime"=>"2022-05-04T18:53:39.252Z",
              "cause"=>"hangup"
            }

            "<Response></Response>"
          end

          def receive_voicemail
            {
              "callId"=>"c-7c4e7185-ec05be9c-c3a8-43c6-9250-c4e378b551af",
              "callUrl"=>"https://voice.bandwidth.com/api/v2/accounts/5007421/calls/c-7c4e7185-ec05be9c-c3a8-43c6-9250-c4e378b551af",
              "mediaUrl"=>"https://voice.bandwidth.com/api/v2/accounts/5007421/calls/c-7c4e7185-ec05be9c-c3a8-43c6-9250-c4e378b551af/recordings/r-fbe17a78-e14a2213-d3c0-4bfb-a0ce-bc9263b1b0aa/media",
              "transcription"=>{
                "id"=>"t-814cb5dd-46c6-4c2e-93c5-0dd8f2fac339",
                "status"=>"available",
                "url"=>"https://voice.bandwidth.com/api/v2/accounts/5007421/calls/c-7c4e7185-ec05be9c-c3a8-43c6-9250-c4e378b551af/recordings/r-fbe17a78-e14a2213-d3c0-4bfb-a0ce-bc9263b1b0aa/transcription",
                "completeTime"=>"2022-05-04T18:54:13.236Z"
              },
              "eventType"=>"transcriptionAvailable",
              "duration"=>"PT3.5S",
              "accountId"=>"5007421",
              "eventTime"=>"2022-05-04T18:54:40.208480157Z",
              "startTime"=>"2022-05-04T18:53:35.716Z",
              "from"=>"+18027791581",
              "endTime"=>"2022-05-04T18:53:39.251Z",
              "to"=>"+18022898010",
              "applicationId"=>"c7447ab1-2057-4413-b125-03504ed48e28",
              "recordingId"=>"r-fbe17a78-e14a2213-d3c0-4bfb-a0ce-bc9263b1b0aa",
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
