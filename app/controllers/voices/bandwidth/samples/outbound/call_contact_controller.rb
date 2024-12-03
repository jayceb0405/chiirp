# frozen_string_literal: true

# app/controllers/voices/bandwidth/samples/outbound/call_contact_controller.rb
# rubocop:disable all
module Voices
  module Bandwidth
    module Samples
      module Outbound
        # sample data received/returned from Bandwidth for outbound calls to a Contact
        class CallContactController < Voices::Bandwidth::VoiceController
          def user_answered
            {
              "eventType"=>"answer",
              "callId"=>"c-52850c03-46ca390e-8f17-457c-b1c7-487a94ce98d1",
              "from"=>"+18022898010",
              "to"=>"+18023455136",
              "direction"=>"outbound",
              "applicationId"=>"c7447ab1-2057-4413-b125-03504ed48e28",
              "accountId"=>"5007421",
              "startTime"=>"2022-05-04T23:27:25.131Z",
              "eventTime"=>"2022-05-04T23:27:28.082Z",
              "callUrl"=>"https://voice.bandwidth.com/api/v2/accounts/5007421/calls/c-52850c03-46ca390e-8f17-457c-b1c7-487a94ce98d1",
              "answerTime"=>"2022-05-04T23:27:28.082Z",
              "contact_id"=>"27033"
            }

            "<Response>
              <Pause duration=\"1\" />
              <SpeakSentence locale=\"en_US\" voice=\"julie\">Please hold while we connect to Kevin (Test) Neubert.</SpeakSentence>
              <Ring duration=\"20\" />
            </Response>"
          end

          def contact_answered
            {
              "eventType"=>"answer",
              "callId"=>"c-fe23a767-b84d5171-f120-48d1-ab9d-b5e0d225b356",
              "from"=>"+18022898010",
              "to"=>"+18027791581",
              "direction"=>"outbound",
              "applicationId"=>"c7447ab1-2057-4413-b125-03504ed48e28",
              "accountId"=>"5007421",
              "startTime"=>"2022-05-04T23:27:29.095Z",
              "eventTime"=>"2022-05-04T23:27:34.678Z",
              "callUrl"=>"https://voice.bandwidth.com/api/v2/accounts/5007421/calls/c-fe23a767-b84d5171-f120-48d1-ab9d-b5e0d225b356",
              "answerTime"=>"2022-05-04T23:27:34.678Z",
              "user_phone"=>"8023455136",
              "parent_call_id"=>"c-52850c03-46ca390e-8f17-457c-b1c7-487a94ce98d1"
            }

            "<Response>
              <Bridge bridgeTargetCompleteUrl=\"https://dev.chiirp.com/voices/bandwidth/out/bridge_target_complete\" bridgeCompleteUrl=\"https://dev.chiirp.com/voices/bandwidth/out/bridge_complete/c-52850c03-46ca390e-8f17-457c-b1c7-487a94ce98d1?user_phone=8023455136\">c-52850c03-46ca390e-8f17-457c-b1c7-487a94ce98d1</Bridge>
            </Response>"
          end

          def bridge_target_complete
            {
              "eventType"=>"bridgeTargetComplete",
              "callId"=>"c-52850c03-46ca390e-8f17-457c-b1c7-487a94ce98d1",
              "from"=>"+18022898010",
              "to"=>"+18023455136",
              "direction"=>"outbound",
              "applicationId"=>"c7447ab1-2057-4413-b125-03504ed48e28",
              "accountId"=>"5007421",
              "startTime"=>"2022-05-04T23:27:25.131Z",
              "eventTime"=>"2022-05-04T23:27:41.466Z",
              "callUrl"=>"https://voice.bandwidth.com/api/v2/accounts/5007421/calls/c-52850c03-46ca390e-8f17-457c-b1c7-487a94ce98d1",
              "answerTime"=>"2022-05-04T23:27:28.082Z"
            }

            "<Response></Response>"
          end
        end
      end
    end
  end
end
