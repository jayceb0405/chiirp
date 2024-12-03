# frozen_string_literal: true

# app/controllers/integrations/dropfunnels/api_keys_controller.rb
module Integrations
  module Dropfunnels
    # DropFunnels integration endpoints supporting API Key
    class ApiKeysController < Dropfunnels::IntegrationsController
      # (GET) show ApiKey
      # /integrations/dropfunnels/api_key
      # integrations_dropfunnels_api_key_path
      # integrations_dropfunnels_api_key_url
      def show
        respond_to do |format|
          format.js { render partial: 'integrations/dropfunnels/js/show', locals: { cards: %w[api_key_show] } }
          format.html { redirect_to root_path }
        end
      end
    end
  end
end
