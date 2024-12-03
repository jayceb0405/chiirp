# frozen_string_literal: true

# app/controllers/integrations/salesrabbit/users_controller.rb
module Integrations
  module Salesrabbit
    class UsersController < Integrations::Salesrabbit::IntegrationsController
      # (GET) show SalesRabbit users_users
      # /integrations/salesrabbit/user
      # integrations_salesrabbit_user_path
      # integrations_salesrabbit_user_url
      def show
        respond_to do |format|
          format.js   { render partial: 'integrations/salesrabbit/js/show', locals: { cards: %w[users] } }
          format.html { render 'integrations/salesrabbit/edit' }
        end
      end

      # (PUT/Patch) save SalesRabbit users_users
      # /integrations/salesrabbit/user
      # integrations_salesrabbit_user_path
      # integrations_salesrabbit_user_url
      def update
        @client_api_integration.update(users_users: params_users)

        respond_to do |format|
          format.js   { render partial: 'integrations/salesrabbit/js/show', locals: { cards: %w[users] } }
          format.html { render 'integrations/salesrabbit/edit' }
        end
      end

      private

      def params_users
        params.require(:users_users).permit(@client_api_integration.users.pluck('id')).to_h.invert
      end
    end
  end
end
