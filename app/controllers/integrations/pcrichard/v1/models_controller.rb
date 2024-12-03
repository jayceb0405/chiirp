# frozen_string_literal: true

# app/controllers/integrations/pcrichard/v1/models_controller.rb
module Integrations
  module Pcrichard
    module V1
      class ModelsController < Pcrichard::V1::IntegrationsController
        # (GET) edit custom fields used to hold PC Richard model options
        # /integrations/pcrichard/v1/models
        # integrations_pcrichard_v1_models_path
        # integrations_pcrichard_v1_models_url
        def show
          render partial: 'integrations/pcrichard/v1/js/show', locals: { cards: %w[models_show] }
        end

        # (PATCH/PUT) update custom fields used to hold PC Richard model options
        # /integrations/pcrichard/v1/models
        # integrations_pcrichard_v1_models_path
        # integrations_pcrichard_v1_models_url
        def update
          Integration::Pcrichard::V1::Base.new(@client_api_integration).update_custom_fields_with_current_models

          render partial: 'integrations/pcrichard/v1/js/show', locals: { cards: %w[models_show] }
        end
      end
    end
  end
end
