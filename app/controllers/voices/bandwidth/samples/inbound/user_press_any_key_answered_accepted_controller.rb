# frozen_string_literal: true

# app/controllers/voices/bandwidth/samples/inbound/user_press_any_key_answered_accepted_controller.rb
# rubocop:disable all
module Voices
  module Bandwidth
    module Samples
      module Inbound
        # sample data received/returned from Bandwidth for inbound calls to a User with "press a key" where calls are answered & accepted
        class UserPressAnyKeyAnsweredAcceptedController < Voices::Bandwidth::VoiceController
          def voice_in
            {
              "eventType"=>"initiate",
              "callId"=>"c-bda05942-40b53b10-27a3-4504-a7ca-0d51ee899c07",
              "from"=>"+18027791581",
              "to"=>"+18022898010",
              "direction"=>"inbound",
              "applicationId"=>"c7447ab1-2057-4413-b125-03504ed48e28",
              "accountId"=>"5007421",
              "startTime"=>"2022-05-04T19:04:16.901Z",
              "eventTime"=>"2022-05-04T19:04:16.912Z",
              "callUrl"=>"https://voice.bandwidth.com/api/v2/accounts/5007421/calls/c-bda05942-40b53b10-27a3-4504-a7ca-0d51ee899c07"
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
              "callId"=>"c-93085a28-fbb29658-5c14-4c97-8587-eff15792de54",
              "from"=>"+18027791581",
              "to"=>"+18023455136",
              "direction"=>"outbound",
              "applicationId"=>"c7447ab1-2057-4413-b125-03504ed48e28",
              "accountId"=>"5007421", "startTime"=>"2022-05-04T19:04:18.381Z",
              "eventTime"=>"2022-05-04T19:04:21.630Z",
              "callUrl"=>"https://voice.bandwidth.com/api/v2/accounts/5007421/calls/c-93085a28-fbb29658-5c14-4c97-8587-eff15792de54",
              "answerTime"=>"2022-05-04T19:04:21.629Z",
              "client_phone"=>"8022898010",
              "parent_from_phone"=>"8027791581",
              "user_id"=>"3",
              "parent_call_id"=>"c-bda05942-40b53b10-27a3-4504-a7ca-0d51ee899c07"
            }

            "<Response>
              <Gather gatherUrl=\"https://dev.chiirp.com/voices/bandwidth/in/user_responded/c-bda05942-40b53b10-27a3-4504-a7ca-0d51ee899c07/8027791581?user_id=3\" firstDigitTimeout=\"10\" repeatCount=\"3\" maxDigits=\"1\">
                <SpeakSentence locale=\"en_US\" voice=\"julie\">You have an incoming call from Kevin (Test) Neubert. Press any key to accept. Press star to send to voicemail.</SpeakSentence>
              </Gather>
            </Response>"
          end

          def user_responded
            {
              "eventType"=>"gather",
              "callId"=>"c-93085a28-fbb29658-5c14-4c97-8587-eff15792de54",
              "from"=>"+18027791581",
              "to"=>"+18023455136",
              "direction"=>"outbound",
              "applicationId"=>"c7447ab1-2057-4413-b125-03504ed48e28",
              "accountId"=>"5007421",
              "startTime"=>"2022-05-04T19:04:18.381Z",
              "eventTime"=>"2022-05-04T19:04:30.899Z",
              "callUrl"=>"https://voice.bandwidth.com/api/v2/accounts/5007421/calls/c-93085a28-fbb29658-5c14-4c97-8587-eff15792de54",
              "answerTime"=>"2022-05-04T19:04:21.629Z",
              "digits"=>"5",
              "terminatingDigit"=>"",
              "user_id"=>"3",
              "parent_call_id"=>"c-bda05942-40b53b10-27a3-4504-a7ca-0d51ee899c07",
              "parent_from_phone"=>"8027791581"
            }

            "<Response>
              <SpeakSentence locale=\"en_US\" voice=\"julie\">Connecting you now.</SpeakSentence>
              <Bridge bridgeTargetCompleteUrl=\"https://dev.chiirp.com/voices/bandwidth/in/bridge_target_complete\" bridgeCompleteUrl=\"https://dev.chiirp.com/voices/bandwidth/in/bridge_complete/c-bda05942-40b53b10-27a3-4504-a7ca-0d51ee899c07\">c-bda05942-40b53b10-27a3-4504-a7ca-0d51ee899c07</Bridge>
            </Response>"
          end

          def bridge_target_complete
            {
              "eventType"=>"bridgeTargetComplete",
              "callId"=>"c-bda05942-40b53b10-27a3-4504-a7ca-0d51ee899c07",
              "from"=>"+18027791581",
              "to"=>"+18022898010",
              "direction"=>"inbound",
              "applicationId"=>"c7447ab1-2057-4413-b125-03504ed48e28",
              "accountId"=>"5007421",
              "startTime"=>"2022-05-04T19:04:16.901Z",
              "eventTime"=>"2022-05-04T19:04:39.931Z",
              "callUrl"=>"https://voice.bandwidth.com/api/v2/accounts/5007421/calls/c-bda05942-40b53b10-27a3-4504-a7ca-0d51ee899c07",
              "answerTime"=>"2022-05-04T19:04:20.050Z"
            }

            "<Response></Response>"
          end

          def disconnected_call
            {
              "eventType"=>"disconnect",
              "callId"=>"c-93085a28-fbb29658-5c14-4c97-8587-eff15792de54",
              "from"=>"+18027791581",
              "to"=>"+18023455136",
              "direction"=>"outbound",
              "applicationId"=>"c7447ab1-2057-4413-b125-03504ed48e28",
              "accountId"=>"5007421", "startTime"=>"2022-05-04T19:04:18.381Z",
              "eventTime"=>"2022-05-04T19:04:39.917Z",
              "callUrl"=>"https://voice.bandwidth.com/api/v2/accounts/5007421/calls/c-93085a28-fbb29658-5c14-4c97-8587-eff15792de54",
              "answerTime"=>"2022-05-04T19:04:21.629Z",
              "endTime"=>"2022-05-04T19:04:39.917Z",
              "cause"=>"hangup",
              "client_phone"=>"8022898010",
              "parent_call_id"=>"c-bda05942-40b53b10-27a3-4504-a7ca-0d51ee899c07"
            }

            "<Response></Response>"
          end

          def voice_complete
            {
              "eventType"=>"disconnect",
              "callId"=>"c-bda05942-40b53b10-27a3-4504-a7ca-0d51ee899c07",
              "from"=>"+18027791581",
              "to"=>"+18022898010",
              "direction"=>"inbound",
              "applicationId"=>"c7447ab1-2057-4413-b125-03504ed48e28",
              "accountId"=>"5007421",
              "startTime"=>"2022-05-04T19:04:16.901Z",
              "eventTime"=>"2022-05-04T19:04:40.399Z",
              "callUrl"=>"https://voice.bandwidth.com/api/v2/accounts/5007421/calls/c-bda05942-40b53b10-27a3-4504-a7ca-0d51ee899c07",
              "answerTime"=>"2022-05-04T19:04:20.050Z",
              "endTime"=>"2022-05-04T19:04:40.399Z",
              "cause"=>"hangup"
            }

            "<Response></Response>"
          end
        end
      end
    end
  end
end
