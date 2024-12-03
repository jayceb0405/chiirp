# frozen_string_literal: true

# app/controllers/integrations/servicetitan/contacts_controller.rb
module Integrations
  module Servicetitan
    class ContactsController < Servicetitan::IntegrationsController
      before_action :client_api_integration, except: %i[search]
      before_action :contact, only: %i[import_jobs]

      # (POST) import ServiceTitan jobs for Contact
      # /integrations/servicetitan/contacts/import_jobs/:contact_id
      # integrations_servicetitan_contacts_import_jobs_path(:contact_id)
      # integrations_servicetitan_contacts_import_jobs_url(:contact_id)
      def import_jobs
        Integration::Servicetitan::V2::Base.new(@client_api_integration).import_contact_jobs(api_key: @client_api_integration.api_key, contact: @contact, user_id: current_user.id)

        sweetalert_success('Jobs Import Queued!', "Jobs for #{@contact.fullname} were successfully queued for import.", '', {})

        respond_to do |format|
          format.js { render partial: 'integrations/servicetitan/js/show', locals: { cards: [] } }
          format.html { redirect_to central_path }
        end
      end

      # (GET)
      # /integrations/servicetitan/contacts/balances
      # integrations_servicetitan_contacts_balances_path
      # integrations_servicetitan_contacts_balances_url
      def index_balances
        @contacts = @client_api_integration.client.contacts.joins(:contact_api_integrations).where("(contact_api_integrations.data->>'account_balance')::numeric <> ?", 0).includes(:contact_api_integrations)

        render 'integrations/servicetitan/contacts/balances/index'
      end

      # (GET) create a list of Contacts based on search criteria
      # /integrations/servicetitan/contacts/search
      # integrations_servicetitan_contacts_search_path
      # integrations_servicetitan_contacts_search_url
      def search
        sanitized_params = params_search
        response = []

        response = Contact.where(client_id: sanitized_params[:client_id]).where('lastname ILIKE ? OR firstname ILIKE ?', "%#{sanitized_params[:searchchars]}%", "%#{sanitized_params[:searchchars]}%").map { |c| [['value', c.id.to_s], ['text', c.fullname]].to_h } if sanitized_params.dig(:client_id).positive? && sanitized_params.dig(:searchchars).to_s.length > 2

        render json: response
      end

      private

      def params_search
        sanitized_params = params.permit(:client_id, :searchchars)

        sanitized_params[:client_id] = sanitized_params.dig(:client_id).to_i

        sanitized_params
      end
    end
  end
end
