# frozen_string_literal: true

# app/controllers/integrations/housecall/update_contacts_controller.rb
module Integrations
  module Housecall
    class UpdateContactsController < Housecall::IntegrationsController
      # (GET) show Price Book import
      # /integrations/housecall/update_contacts
      # integrations_housecall_update_contacts_path
      # integrations_housecall_update_contacts_url
      def show
        respond_to do |format|
          format.js { render partial: 'integrations/housecall/js/show', locals: { cards: %w[update_contacts_show] } }
          format.html { redirect_to integrations_housecall_path }
        end
      end

      # (PUT/PATCH) import Price Book
      # /integrations/housecall/update_contacts
      # integrations_housecall_update_contacts_path
      # integrations_housecall_update_contacts_url
      def update
        sanitized_params = params.permit(:new_contacts_only)

        Integration::Housecallpro::V1::Base.new(@client_api_integration).delay(
          run_at:              Time.current,
          priority:            DelayedJob.job_priority('housecallpro_import_customers'),
          queue:               DelayedJob.job_queue('housecallpro_import_customers'),
          contact_id:          0,
          contact_campaign_id: 0,
          user_id:             current_user.id,
          triggeraction_id:    0,
          process:             'housecallpro_import_customers',
          group_process:       0,
          data:                { user_id: current_user.id, new_contacts_only: sanitized_params.dig(:new_contacts_only).to_bool }
        ).import_customers(user_id: current_user.id, new_contacts_only: sanitized_params.dig(:new_contacts_only).to_bool)

        respond_to do |format|
          format.json { render json: response, status: (response[:error].present? ? 415 : :ok) }
          format.js { render partial: 'integrations/housecall/js/show', locals: { cards: %w[update_contacts_show] } }
          format.html { redirect_to integrations_housecall_path }
        end
      end
    end
  end
end
