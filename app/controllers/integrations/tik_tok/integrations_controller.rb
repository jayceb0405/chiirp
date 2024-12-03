# frozen_string_literal: true

# app/controllers/integrations/tik_tok/integrations_controller.rb
module Integrations
  module TikTok
    # Support for all general Facebook integration endpoints
    class IntegrationsController < ApplicationController
      skip_before_action :verify_authenticity_token, only: %i[endpoint]
      before_action :authenticate_user!, except: %i[endpoint]
      before_action :authorize_user!, except: %i[endpoint]

      # (GET) TikTok endpoint
      # /integrations/tik_tok/endpoint
      # integrations_tik_tok_endpoint_path
      # integrations_tik_tok_endpoint_url
      def endpoint
        render plain: 'Success', content_type: 'text/plain', status: :ok, layout: false
      end
    end
  end
end
