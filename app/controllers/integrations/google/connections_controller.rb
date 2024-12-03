# frozen_string_literal: true

# app/controllers/integrations/google/connections_controller.rb
module Integrations
  module Google
    class ConnectionsController < Google::IntegrationsController
      # (DELETE) revoke Google token
      # /integrations/google/connections
      # integrations_google_connections_path
      # integrations_google_connections_url
      def destroy
        Integration::Google.revoke_token(@user_api_integration)

        respond_to do |format|
          format.js { render partial: 'integrations/google/js/show', locals: { cards: %w[connections_edit] } }
          format.html { redirect_to integrations_google_integrations_path }
        end
      end

      # (GET) Google calendar integration configuration screen
      # /integrations/google/connections/edit
      # edit_integrations_google_connections_path
      # edit_integrations_google_connections_url
      def edit
        respond_to do |format|
          format.js { render partial: 'integrations/google/js/show', locals: { cards: %w[connections_edit] } }
          format.html { redirect_to integrations_google_integrations_path }
        end
      end

      # (PATCH) Update Google account administrator
      # /integrations/google/connections/edit
      # integrations_google_connections_path
      # integrations_google_connections_url
      def update
        presenter = Integrations::Google::Presenter.new(user_api_integration: @user_api_integration)
        return unless current_user.client.def_user == current_user || presenter.google_account_admin == current_user

        user_id = params.require(:google).permit(:account_administrator_id)[:account_administrator_id]&.to_i
        if user_id != @client_api_integration.user_id
          # set new user
          @client_api_integration.update(user_id:)
        end
        respond_to do |format|
          format.js { render partial: 'integrations/google/js/show', locals: { cards: %w[connections_edit] } }
          format.html { redirect_to integrations_google_integrations_path }
        end
      end
    end
  end
end
