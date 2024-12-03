# frozen_string_literal: true

# app/controllers/voices/bandwidth/samples/inbound/user_press_any_key_not_answered_controller.rb
# rubocop:disable all
module Voices
  module Bandwidth
    module Samples
      module Inbound
        # sample data received/returned from Bandwidth for inbound calls to a User with "press a key" where calls NOT answered
        class UserPressAnyKeyNotAnsweredController < Voices::Bandwidth::VoiceController
          def voice_in
            {
              "eventType"=>"initiate",
              "callId"=>"c-52850c03-cb1f44ff-21d8-4424-98f9-4dbbca2ad1f1",
              "from"=>"+18027791581",
              "to"=>"+18022898010",
              "direction"=>"inbound",
              "applicationId"=>"c7447ab1-2057-4413-b125-03504ed48e28",
              "accountId"=>"5007421", "startTime"=>"2022-05-04T19:32:02.226Z",
              "eventTime"=>"2022-05-04T19:32:02.238Z",
              "callUrl"=>"https://voice.bandwidth.com/api/v2/accounts/5007421/calls/c-52850c03-cb1f44ff-21d8-4424-98f9-4dbbca2ad1f1"
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
              "callId"=>"c-e769bec4-fcaacf0d-a246-43e7-a441-c67416668f28",
              "from"=>"+18027791581",
              "to"=>"+18023455136",
              "direction"=>"outbound",
              "applicationId"=>"c7447ab1-2057-4413-b125-03504ed48e28",
              "accountId"=>"5007421", "startTime"=>"2022-05-04T19:32:03.558Z",
              "eventTime"=>"2022-05-04T19:32:25.363Z",
              "callUrl"=>"https://voice.bandwidth.com/api/v2/accounts/5007421/calls/c-e769bec4-fcaacf0d-a246-43e7-a441-c67416668f28",
              "endTime"=>"2022-05-04T19:32:25.363Z",
              "cause"=>"timeout",
              "errorMessage"=>"Call was not answered",
              "client_phone"=>"8022898010",
              "parent_call_id"=>"c-52850c03-cb1f44ff-21d8-4424-98f9-4dbbca2ad1f1"
            }

            "<Response></Response>"
          end

          def voice_complete
            {
              "eventType"=>"disconnect",
              "callId"=>"c-52850c03-cb1f44ff-21d8-4424-98f9-4dbbca2ad1f1",
              "from"=>"+18027791581",
              "to"=>"+18022898010",
              "direction"=>"inbound",
              "applicationId"=>"c7447ab1-2057-4413-b125-03504ed48e28",
              "accountId"=>"5007421",
              "startTime"=>"2022-05-04T19:32:02.226Z",
              "eventTime"=>"2022-05-04T19:32:39.183Z",
              "callUrl"=>"https://voice.bandwidth.com/api/v2/accounts/5007421/calls/c-52850c03-cb1f44ff-21d8-4424-98f9-4dbbca2ad1f1",
              "answerTime"=>"2022-05-04T19:32:05.003Z",
              "endTime"=>"2022-05-04T19:32:39.183Z",
              "cause"=>"hangup"
            }

            "<Response></Response>"
          end

          def receive_voicemail
            {
              "callId"=>"c-52850c03-cb1f44ff-21d8-4424-98f9-4dbbca2ad1f1",
              "callUrl"=>"https://voice.bandwidth.com/api/v2/accounts/5007421/calls/c-52850c03-cb1f44ff-21d8-4424-98f9-4dbbca2ad1f1",
              "mediaUrl"=>"https://voice.bandwidth.com/api/v2/accounts/5007421/calls/c-52850c03-cb1f44ff-21d8-4424-98f9-4dbbca2ad1f1/recordings/r-fbe17a78-56acb4d0-99cd-46ed-bad1-f22ac0d6706d/media", "transcription"=>{
                "id"=>"t-4746436c-8b7a-414f-a875-79d2827085b1",
                "status"=>"available",
                "url"=>"https://voice.bandwidth.com/api/v2/accounts/5007421/calls/c-52850c03-cb1f44ff-21d8-4424-98f9-4dbbca2ad1f1/recordings/r-fbe17a78-56acb4d0-99cd-46ed-bad1-f22ac0d6706d/transcription",
                "completeTime"=>"2022-05-04T19:33:04.127Z"
              },
              "eventType"=>"transcriptionAvailable",
              "duration"=>"PT3.6S",
              "accountId"=>"5007421",
              "eventTime"=>"2022-05-04T19:33:40.161311865Z",
              "startTime"=>"2022-05-04T19:32:35.519Z",
              "from"=>"+18027791581",
              "endTime"=>"2022-05-04T19:32:39.182Z",
              "to"=>"+18022898010",
              "applicationId"=>"c7447ab1-2057-4413-b125-03504ed48e28",
              "recordingId"=>"r-fbe17a78-56acb4d0-99cd-46ed-bad1-f22ac0d6706d",
              "fileFormat"=>"mp3",
              "direction"=>"inbound",
              "user_id"=>"3"
            }

            "<Response></Response>"
          end
        end
      end
    end
  end
end
