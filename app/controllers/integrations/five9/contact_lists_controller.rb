# frozen_string_literal: true

# app/controllers/integrations/five9/contact_lists_controller.rb
module Integrations
  module Five9
    # integration endpoints supporting Five9 Contacts configuration
    class ContactListsController < Five9::IntegrationsController
      before_action :client_api_integration

      def edit
        # (GET) edit Contact List assignments for Five9 integration
        # /integrations/five9/contact_lists/edit
        # edit_integrations_five9_contact_lists_path
        # edit_integrations_five9_contact_lists_url
        cards = params.dig(:form).to_bool ? %w[contact_lists_form] : %w[contact_lists_edit]

        respond_to do |format|
          format.js { render partial: 'integrations/five9/js/show', locals: { cards: } }
          format.html { redirect_to central_path }
        end
      end

      def update
        # (PUT/PATCH) save Contact List assignments for Five9 integration
        # /integrations/five9/contact_lists
        # integrations_five9_contact_lists_path
        # integrations_five9_contact_lists_url
        contact_lists = params.require(:contact_lists).permit(:book, :create, :update)
        @client_api_integration.update(contact_lists:)

        respond_to do |format|
          format.js { render partial: 'integrations/five9/js/show', locals: { cards: %w[contact_lists_edit] } }
          format.html { redirect_to central_path }
        end
      end
    end
  end
end
