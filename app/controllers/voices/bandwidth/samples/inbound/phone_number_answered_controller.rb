# frozen_string_literal: true

# app/controllers/voices/bandwidth/samples/inbound/phone_number_answered_controller.rb
# rubocop:disable all
module Voices
  module Bandwidth
    module Samples
      module Inbound
        # sample data received/returned from Bandwidth for inbound calls to a phone number where calls are answered
        class PhoneNumberAnsweredController < Voices::Bandwidth::VoiceController
          def voice_in
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

          def bridge_call
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

          def disconnected_call
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

          def bridge_target_complete
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

          def voice_complete
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
        end
      end
    end
  end
end
