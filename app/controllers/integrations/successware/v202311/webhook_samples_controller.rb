# frozen_string_literal: true

# app/controllers/integrations/successware/v202311/webhook_samples_controller.rb
# rubocop:disable all
module Integrations
  module Successware
    module V202311
      # sample data received from Housecall Pro
      class WebhookSamplesController < Successware::IntegrationsController
        def app_connect
          {
            "data"=>{
              "webHookEvent"=>{
                "topic"=>"APP_CONNECT",
                "appId"=>"51fb685a-f9d9-4512-882a-b39a05570d5e",
                "accountId"=>"Z2lkOi8vSm9iYmVyL0FjY291bnQvNjg5OTQy",
                "itemId"=>"NzU0MTk=",
                "occuredAt"=>"2022-10-27T18:22:16Z"
              }
            }
          }
        end

        def client_create
          {
            "data"=>{
              "webHookEvent"=>{
                "topic"=>"CLIENT_CREATE",
                "appId"=>"51fb685a-f9d9-4512-882a-b39a05570d5e",
                "accountId"=>"Z2lkOi8vSm9iYmVyL0FjY291bnQvNjg5OTQy",
                "itemId"=>"Z2lkOi8vSm9iYmVyL0NsaWVudC81OTc0MDgwNA==",
                "occuredAt"=>"2022-11-01T14:58:24Z"
              }
            }
          }
        end
      end
    end
  end
end
