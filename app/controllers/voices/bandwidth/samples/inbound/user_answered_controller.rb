# frozen_string_literal: true

# app/controllers/voices/bandwidth/samples/inbound/user_answered_controller.rb
# rubocop:disable all
module Voices
  module Bandwidth
    module Samples
      module Inbound
        # sample data received/returned from Bandwidth for inbound calls to a User without "press a key" where calls are answered
        class UserAnsweredController < Voices::Bandwidth::VoiceController
          def voice_in
            {
              "eventType"=>"initiate",
              "callId"=>"c-bda05942-32c4561b-c9bd-4c87-9554-237c6eac8b36",
              "from"=>"+18027791581",
              "to"=>"+18022898010",
              "direction"=>"inbound",
              "applicationId"=>"c7447ab1-2057-4413-b125-03504ed48e28",
              "accountId"=>"5007421",
              "startTime"=>"2022-05-04T18:37:25.406Z",
              "eventTime"=>"2022-05-04T18:37:25.416Z",
              "callUrl"=>"https://voice.bandwidth.com/api/v2/accounts/5007421/calls/c-bda05942-32c4561b-c9bd-4c87-9554-237c6eac8b36"
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
              "callId"=>"c-693ef4a6-c25a8ac9-bdee-4633-8cff-fd3afc304ea8",
              "from"=>"+18027791581",
              "to"=>"+18023455136",
              "direction"=>"outbound",
              "applicationId"=>"c7447ab1-2057-4413-b125-03504ed48e28",
              "accountId"=>"5007421",
              "startTime"=>"2022-05-04T18:37:26.881Z",
              "eventTime"=>"2022-05-04T18:37:30.882Z",
              "callUrl"=>"https://voice.bandwidth.com/api/v2/accounts/5007421/calls/c-693ef4a6-c25a8ac9-bdee-4633-8cff-fd3afc304ea8",
              "answerTime"=>"2022-05-04T18:37:30.881Z",
              "client_phone"=>"8022898010",
              "parent_call_id"=>"c-bda05942-32c4561b-c9bd-4c87-9554-237c6eac8b36"
            }

            "<Response>
              <Bridge bridgeTargetCompleteUrl=\"https://dev.chiirp.com/voices/bandwidth/in/bridge_target_complete\" bridgeCompleteUrl=\"https://dev.chiirp.com/voices/bandwidth/in/bridge_complete/c-bda05942-32c4561b-c9bd-4c87-9554-237c6eac8b36?user_phone=\">c-bda05942-32c4561b-c9bd-4c87-9554-237c6eac8b36</Bridge>
            </Response>"
          end

          def disconnected_call
            {
              "eventType"=>"disconnect",
              "callId"=>"c-693ef4a6-c25a8ac9-bdee-4633-8cff-fd3afc304ea8",
              "from"=>"+18027791581",
              "to"=>"+18023455136",
              "direction"=>"outbound",
              "applicationId"=>"c7447ab1-2057-4413-b125-03504ed48e28",
              "accountId"=>"5007421",
              "startTime"=>"2022-05-04T18:37:26.881Z",
              "eventTime"=>"2022-05-04T18:37:38.257Z",
              "callUrl"=>"https://voice.bandwidth.com/api/v2/accounts/5007421/calls/c-693ef4a6-c25a8ac9-bdee-4633-8cff-fd3afc304ea8",
              "answerTime"=>"2022-05-04T18:37:30.881Z",
              "endTime"=>"2022-05-04T18:37:38.257Z",
              "cause"=>"hangup",
              "client_phone"=>"8022898010",
              "parent_call_id"=>"c-bda05942-32c4561b-c9bd-4c87-9554-237c6eac8b36"
            }

            "<Response></Response>"
          end

          def bridge_target_complete
            # will happen if carrier voicemail answers call to User
            {
              "eventType"=>"bridgeTargetComplete",
              "callId"=>"c-bda05942-32c4561b-c9bd-4c87-9554-237c6eac8b36",
              "from"=>"+18027791581",
              "to"=>"+18022898010",
              "direction"=>"inbound",
              "applicationId"=>"c7447ab1-2057-4413-b125-03504ed48e28",
              "accountId"=>"5007421",
              "startTime"=>"2022-05-04T18:37:25.406Z",
              "eventTime"=>"2022-05-04T18:37:38.266Z",
              "callUrl"=>"https://voice.bandwidth.com/api/v2/accounts/5007421/calls/c-bda05942-32c4561b-c9bd-4c87-9554-237c6eac8b36",
              "answerTime"=>"2022-05-04T18:37:28.319Z"
            }

            "<Response></Response>"
          end

          def voice_complete
            {
              "eventType"=>"disconnect",
              "callId"=>"c-bda05942-32c4561b-c9bd-4c87-9554-237c6eac8b36",
              "from"=>"+18027791581",
              "to"=>"+18022898010",
              "direction"=>"inbound",
              "applicationId"=>"c7447ab1-2057-4413-b125-03504ed48e28",
              "accountId"=>"5007421",
              "startTime"=>"2022-05-04T18:37:25.406Z",
              "eventTime"=>"2022-05-04T18:37:39.047Z",
              "callUrl"=>"https://voice.bandwidth.com/api/v2/accounts/5007421/calls/c-bda05942-32c4561b-c9bd-4c87-9554-237c6eac8b36",
              "answerTime"=>"2022-05-04T18:37:28.319Z",
              "endTime"=>"2022-05-04T18:37:39.046Z",
              "cause"=>"hangup"
            }

            "<Response></Response>"
          end
        end
      end
    end
  end
end
