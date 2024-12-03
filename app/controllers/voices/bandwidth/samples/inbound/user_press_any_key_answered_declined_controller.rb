# frozen_string_literal: true

# app/controllers/voices/bandwidth/samples/inbound/user_press_any_key_answered_declined_controller.rb
# rubocop:disable all
module Voices
  module Bandwidth
    module Samples
      module Inbound
        # sample data received/returned from Bandwidth for inbound calls to a User with "press a key" where calls are answered & declined
        class UserPressAnyKeyAnsweredDeclinedController < Voices::Bandwidth::VoiceController
          def voice_in
            {
              "eventType"=>"initiate",
              "callId"=>"c-7c4e7185-e904f29f-6039-4f09-b6bf-70173014fd95",
              "from"=>"+18027791581",
              "to"=>"+18022898010",
              "direction"=>"inbound",
              "applicationId"=>"c7447ab1-2057-4413-b125-03504ed48e28",
              "accountId"=>"5007421",
              "startTime"=>"2022-05-04T19:18:06.757Z",
              "eventTime"=>"2022-05-04T19:18:06.768Z",
              "callUrl"=>"https://voice.bandwidth.com/api/v2/accounts/5007421/calls/c-7c4e7185-e904f29f-6039-4f09-b6bf-70173014fd95"
            }

            "<Response>
              <Ring duration=\"20\" />
              <SpeakSentence locale=\"en_US\" voice=\"julie\">No one is available to take your call. Please record your message. When you are finished recording press the pound key or hang up.</SpeakSentence>
              <Pause duration=\"1\" />
              <PlayAudio>https://media.chiirp.com/video/upload/v1645564095/samples/beep.mp3</PlayAudio>
              <Record maxDuration=\"60\" transcribe=\"true\" fileFormat=\"mp3\" recordCompleteUrl=\"https://dev.chiirp.com/voices/bandwidth/in/receive_voicemail?user_id=3\" transcriptionAvailableUrl=\"https://dev.chiirp.com/voices/bandwidth/in/receive_voicemail?user_id=3\"/>
            </Response>"
          end

          def user_answered
             {
              "eventType"=>"answer",
              "callId"=>"c-693ef4a6-8c687751-a5c1-40e1-8aeb-b13fdb552dfe",
              "from"=>"+18027791581",
              "to"=>"+18023455136",
              "direction"=>"outbound",
              "applicationId"=>"c7447ab1-2057-4413-b125-03504ed48e28",
              "accountId"=>"5007421",
              "startTime"=>"2022-05-04T19:18:07.303Z",
              "eventTime"=>"2022-05-04T19:18:10.571Z",
              "callUrl"=>"https://voice.bandwidth.com/api/v2/accounts/5007421/calls/c-693ef4a6-8c687751-a5c1-40e1-8aeb-b13fdb552dfe",
              "answerTime"=>"2022-05-04T19:18:10.570Z",
              "client_phone"=>"8022898010",
              "parent_from_phone"=>"8027791581",
              "user_id"=>"3",
              "parent_call_id"=>"c-7c4e7185-e904f29f-6039-4f09-b6bf-70173014fd95"
            }

            "<Response>
              <Gather gatherUrl=\"https://dev.chiirp.com/voices/bandwidth/in/user_responded/c-7c4e7185-e904f29f-6039-4f09-b6bf-70173014fd95/8027791581?user_id=3\" firstDigitTimeout=\"10\" repeatCount=\"3\" maxDigits=\"1\">
                <SpeakSentence locale=\"en_US\" voice=\"julie\">You have an incoming call from Kevin (Test) Neubert. Press any key to accept. Press star to send to voicemail.</SpeakSentence>
              </Gather>
            </Response>"
          end

          def user_responded
            {
              "eventType"=>"gather",
              "callId"=>"c-693ef4a6-8c687751-a5c1-40e1-8aeb-b13fdb552dfe",
              "from"=>"+18027791581",
              "to"=>"+18023455136",
              "direction"=>"outbound",
              "applicationId"=>"c7447ab1-2057-4413-b125-03504ed48e28",
              "accountId"=>"5007421",
              "startTime"=>"2022-05-04T19:18:07.303Z",
              "eventTime"=>"2022-05-04T19:18:12.816Z",
              "callUrl"=>"https://voice.bandwidth.com/api/v2/accounts/5007421/calls/c-693ef4a6-8c687751-a5c1-40e1-8aeb-b13fdb552dfe",
              "answerTime"=>"2022-05-04T19:18:10.570Z",
              "digits"=>"*",
              "terminatingDigit"=>"",
              "user_id"=>"3",
              "parent_call_id"=>"c-7c4e7185-e904f29f-6039-4f09-b6bf-70173014fd95",
              "parent_from_phone"=>"8027791581"
            }

            "<Response></Response>"
          end

          def offer_voicemail
            {
              "eventType"=>"redirect",
              "callId"=>"c-7c4e7185-e904f29f-6039-4f09-b6bf-70173014fd95",
              "from"=>"+18027791581",
              "to"=>"+18022898010",
              "direction"=>"inbound",
              "applicationId"=>"c7447ab1-2057-4413-b125-03504ed48e28",
              "accountId"=>"5007421",
              "startTime"=>"2022-05-04T19:18:06.757Z",
              "eventTime"=>"2022-05-04T19:18:13.333Z",
              "callUrl"=>"https://voice.bandwidth.com/api/v2/accounts/5007421/calls/c-7c4e7185-e904f29f-6039-4f09-b6bf-70173014fd95",
              "answerTime"=>"2022-05-04T19:18:09.245Z",
              "user_id"=>"3",
              "parent_call_id"=>"c-7c4e7185-e904f29f-6039-4f09-b6bf-70173014fd95"
            }

            "<Response>
              <SpeakSentence locale=\"en_US\" voice=\"julie\">No one is available to take your call. Please leave a message after the tone. Press star to complete or simply hang up.</SpeakSentence>
              <Pause duration=\"1\" />
              <PlayAudio>https://media.chiirp.com/video/upload/v1645564095/samples/beep.mp3</PlayAudio>
              <Record maxDuration=\"60\" transcribe=\"true\" fileFormat=\"mp3\" recordCompleteUrl=\"https://dev.chiirp.com/voices/bandwidth/in/receive_voicemail?user_id=3\" transcriptionAvailableUrl=\"https://dev.chiirp.com/voices/bandwidth/in/receive_voicemail?user_id=3\"/>
              <SpeakSentence locale=\"en_US\" voice=\"julie\">I did not receive a recording.</SpeakSentence>
            </Response>"
          end

          def disconnected_call
             {
              "eventType"=>"disconnect",
              "callId"=>"c-693ef4a6-8c687751-a5c1-40e1-8aeb-b13fdb552dfe",
              "from"=>"+18027791581",
              "to"=>"+18023455136",
              "direction"=>"outbound",
              "applicationId"=>"c7447ab1-2057-4413-b125-03504ed48e28",
              "accountId"=>"5007421",
              "startTime"=>"2022-05-04T19:18:07.303Z",
              "eventTime"=>"2022-05-04T19:18:13.645Z",
              "callUrl"=>"https://voice.bandwidth.com/api/v2/accounts/5007421/calls/c-693ef4a6-8c687751-a5c1-40e1-8aeb-b13fdb552dfe",
              "answerTime"=>"2022-05-04T19:18:10.570Z",
              "endTime"=>"2022-05-04T19:18:13.645Z",
              "cause"=>"hangup",
              "client_phone"=>"8022898010",
              "parent_call_id"=>"c-7c4e7185-e904f29f-6039-4f09-b6bf-70173014fd95"
            }

            "<Response></Response>"
          end

          def voice_complete
            {
              "eventType"=>"disconnect",
              "callId"=>"c-7c4e7185-e904f29f-6039-4f09-b6bf-70173014fd95",
              "from"=>"+18027791581",
              "to"=>"+18022898010",
              "direction"=>"inbound",
              "applicationId"=>"c7447ab1-2057-4413-b125-03504ed48e28",
              "accountId"=>"5007421",
              "startTime"=>"2022-05-04T19:18:06.757Z",
              "eventTime"=>"2022-05-04T19:18:27.275Z",
              "callUrl"=>"https://voice.bandwidth.com/api/v2/accounts/5007421/calls/c-7c4e7185-e904f29f-6039-4f09-b6bf-70173014fd95",
              "answerTime"=>"2022-05-04T19:18:09.245Z",
              "endTime"=>"2022-05-04T19:18:27.275Z",
              "cause"=>"hangup"
            }

            "<Response></Response>"
          end

          def receive_voicemail
            {
              "callId"=>"c-7c4e7185-e904f29f-6039-4f09-b6bf-70173014fd95",
              "callUrl"=>"https://voice.bandwidth.com/api/v2/accounts/5007421/calls/c-7c4e7185-e904f29f-6039-4f09-b6bf-70173014fd95",
              "mediaUrl"=>"https://voice.bandwidth.com/api/v2/accounts/5007421/calls/c-7c4e7185-e904f29f-6039-4f09-b6bf-70173014fd95/recordings/r-fbe17a78-fe49c3b0-bb35-4f76-acbf-e8e6286d44a4/media",
              "transcription"=>{
                "id"=>"t-be9d121a-cc0b-4b57-89eb-b8575d30cda7",
                "status"=>"available",
                "url"=>"https://voice.bandwidth.com/api/v2/accounts/5007421/calls/c-7c4e7185-e904f29f-6039-4f09-b6bf-70173014fd95/recordings/r-fbe17a78-fe49c3b0-bb35-4f76-acbf-e8e6286d44a4/transcription", "completeTime"=>"2022-05-04T19:18:45.932Z"
              },
              "eventType"=>"transcriptionAvailable",
              "duration"=>"PT3.5S",
              "accountId"=>"5007421",
              "eventTime"=>"2022-05-04T19:19:28.206905490Z",
              "startTime"=>"2022-05-04T19:18:23.696Z",
              "from"=>"+18027791581",
              "endTime"=>"2022-05-04T19:18:27.274Z",
              "to"=>"+18022898010",
              "applicationId"=>"c7447ab1-2057-4413-b125-03504ed48e28",
              "recordingId"=>"r-fbe17a78-fe49c3b0-bb35-4f76-acbf-e8e6286d44a4",
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
