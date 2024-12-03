# frozen_string_literal: true

# app/controllers/integrations/jobber/v20231115/connections_controller.rb
module Integrations
  module Jobber
    module V20231115
      class ConnectionsController < Jobber::IntegrationsController
        # (DELETE) delete a Jobber integration
        # /integrations/jobber/v20231115/connections
        # integrations_jobber_v20231115_connections_path
        # integrations_jobber_v20231115_connections_url
        def destroy
          Integration::Jobber::V20231115::Base.new(@client_api_integration).disconnect_account

          render partial: 'integrations/jobber/v20231115/js/show', locals: { cards: %w[connections_edit] }
        end

        # (GET) Jobber integration configuration screen
        # /integrations/jobber/v20231115/connections/edit
        # edit_integrations_jobber_v20231115_connections_path
        # edit_integrations_jobber_v20231115_connections_url
        def edit
          render partial: 'integrations/jobber/v20231115/js/show', locals: { cards: %w[connections_edit] }
        end
      end
    end
  end
end
