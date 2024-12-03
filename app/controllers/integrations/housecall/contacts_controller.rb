# frozen_string_literal: true

# app/controllers/integrations/housecall/contacts_controller.rb
module Integrations
  module Housecall
    class ContactsController < Housecall::IntegrationsController
      before_action :contact
      # (GET)
      # /integrations/housecall/contacts/:id/edit
      # edit_integrations_housecall_contact_path(:id)
      # edit_integrations_housecall_contact_url(:id)
      def edit
        respond_to do |format|
          format.js { render partial: 'integrations/housecall/js/show', locals: { cards: %w[contact_edit] } }
          format.html { redirect_to integrations_housecall_path }
        end
      end

      private

      def contact
        return if (@contact = @client.contacts.find_by(id: params.dig(:id)))

        respond_to do |format|
          format.js { render js: "window.location = '#{root_path}'" and return false }
          format.html { redirect_to root_path and return false }
        end
      end
    end
  end
end
