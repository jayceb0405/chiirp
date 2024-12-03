# frozen_string_literal: true

# app/controllers/integrations/outreach/users_controller.rb
module Integrations
  module Outreach
    # support for connecting Outreach Users with internal Users
    class UsersController < Outreach::IntegrationsController
      def show
        # (GET) show Outreach users_users
        # /integrations/outreach/users
        # integrations_outreach_users_path
        # integrations_outreach_users_url
        respond_to do |format|
          format.js   { render partial: 'integrations/outreach/js/show', locals: { cards: %w[users] } }
          format.html { render 'integrations/outreach/edit' }
        end
      end

      def update
        # (PUT/Patch) save Outreach users_users
        # /integrations/outreach/users
        # integrations_outreach_users_path
        # integrations_outreach_users_url
        @client_api_integration.users = params_users.dig(:users).to_h.invert
        @client_api_integration.users.each { |k, v| @client_api_integration.users[k] = v.to_i }
        @client_api_integration.users.each_key { |k| @client_api_integration.users.delete(k) if k.blank? }
        @client_api_integration.save

        respond_to do |format|
          format.js   { render partial: 'integrations/outreach/js/show', locals: { cards: %w[users] } }
          format.html { render 'integrations/outreach/edit' }
        end
      end

      private

      def params_users
        params.permit(users: {})
      end
    end
  end
end
