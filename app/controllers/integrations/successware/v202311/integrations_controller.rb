# frozen_string_literal: true

# app/controllers/integrations/successware/v202311/integrations_controller.rb
module Integrations
  module Successware
    module V202311
      class IntegrationsController < Successware::IntegrationsController
        # (GET) show main Successware integration screen
        # /integrations/successware/v202311
        # integrations_successware_v202311_path
        # integrations_successware_v202311_url
        def show
          respond_to do |format|
            format.js { render partial: 'integrations/successware/v202311/js/show', locals: { cards: %w[overview] } }
            format.html { render 'integrations/successware/v202311/show', locals: { partial_to_show: params.dig(:card).present? ? "integrations/successware/v202311/#{params[:card]}/index" : '' } }
          end
        end
      end
    end
  end
end
