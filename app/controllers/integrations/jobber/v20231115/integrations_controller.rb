# frozen_string_literal: true

# app/controllers/integrations/jobber/v20231115/integrations_controller.rb
module Integrations
  module Jobber
    module V20231115
      class IntegrationsController < Jobber::IntegrationsController
        # (GET) show main Jobber integration screen
        # /integrations/jobber/v20231115
        # integrations_jobber_v20231115_path
        # integrations_jobber_v20231115_url
        def show
          respond_to do |format|
            format.js { render partial: 'integrations/jobber/v20231115/js/show', locals: { cards: %w[overview] } }
            format.html { render 'integrations/jobber/v20231115/show', locals: { partial_to_show: params.dig(:card).present? ? "integrations/jobber/v20231115/#{params[:card]}/index" : '' } }
          end
        end
      end
    end
  end
end
