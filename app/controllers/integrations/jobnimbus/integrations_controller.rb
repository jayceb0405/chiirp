# frozen_string_literal: true

# app/controllers/integrations/jobnimbus/integrations_controller.rb
module Integrations
  module Jobnimbus
    # Support for all general JobNimbus integration endpoints used with Chiirp
    class IntegrationsController < ApplicationController
      skip_before_action :verify_authenticity_token, only: %i[webhook]
      before_action :authenticate_user!, except: %i[webhook]
      before_action :authorize_user!, except: %i[webhook]
      before_action :client_api_integration, except: %i[webhook]
      before_action :client_api_integration_from_api_key, only: %i[webhook]

      # (POST) webhook from JobNimbus
      # /integrations/jobnimbus/endpoint/webhook/:webhook_api_key
      # integrations_jobnimbus_endpoint_path(:webhook_api_key)
      # integrations_jobnimbus_endpoint_url(:webhook_api_key)
      def webhook
        respond_to do |format|
          format.json { render json: { status: 200, message: 'Success' } }
          format.html { render plain: 'Success', content_type: 'text/plain', layout: false, status: :ok }
        end

        begin
          jn_client = Integrations::JobNimbus::V1::Base.new(@client_api_integration.api_key)
          parsed_webhook = jn_client.parse_webhook(params.to_unsafe_h)

          if jn_client.success? && (contact = Contact.find_or_initialize_by_phone_or_email_or_ext_ref(client_id: @client_api_integration.client_id, phones: parsed_webhook.dig(:contact, :phones), emails: parsed_webhook.dig(:contact, :email), ext_refs: { 'jobnimbus' => parsed_webhook.dig(:contact, :id) }))
            contact.lastname   = parsed_webhook.dig(:contact, :lastname) if parsed_webhook.dig(:contact, :lastname).present?
            contact.firstname  = parsed_webhook.dig(:contact, :firstname) if parsed_webhook.dig(:contact, :firstname).present?
            contact.address1   = parsed_webhook.dig(:contact, :address_01) if parsed_webhook.dig(:contact, :address_01).present?
            contact.address2   = parsed_webhook.dig(:contact, :address_02) if parsed_webhook.dig(:contact, :address_02).present?
            contact.city       = parsed_webhook.dig(:contact, :city) if parsed_webhook.dig(:contact, :city).present?
            contact.state      = parsed_webhook.dig(:contact, :state) if parsed_webhook.dig(:contact, :state).present?
            contact.zipcode    = parsed_webhook.dig(:contact, :zipcode) if parsed_webhook.dig(:contact, :zipcode).present?

            if contact.save

              if parsed_webhook.dig(:contact, :id).present?
                contact_ext_reference = contact.ext_references.find_or_initialize_by(target: 'jobnimbus')
                contact_ext_reference.update(ext_id: parsed_webhook.dig(:contact, :id))
              end

              jobnimbus_id = case parsed_webhook.dig(:event_status).split('_').first
                             when 'contact'
                               parsed_webhook.dig(:contact, :id)
                             when 'estimate'
                               parsed_webhook.dig(:estimate, :id)
                             when 'job'
                               parsed_webhook.dig(:job, :id)
                             when 'invoice'
                               parsed_webhook.dig(:invoice, :id)
                             when 'workorder'
                               parsed_webhook.dig(:work_order, :id)
                             when 'task'
                               parsed_webhook.dig(:task, :id)
                             end

              process_actions_data = {
                event_new:    contact.raw_posts.where(ext_source: 'jobnimbus', ext_id: parsed_webhook.dig(:event_status)).where('data @> ?', { jnid: jobnimbus_id }.to_json).order(created_at: :desc).blank?,
                event_status: parsed_webhook.dig(:event_status)
              }

              # save params to Contact::RawPosts
              contact.raw_posts.create(ext_source: 'jobnimbus', ext_id: parsed_webhook.dig(:event_status), data: params.except(:integration))

              jn_model = Integration::Jobnimbus::V1::Base.new(@client_api_integration)
              jn_model.sales_rep_update(
                id:    parsed_webhook.dig(:contact, :sales_rep),
                name:  parsed_webhook.dig(:contact, :sales_rep_name),
                email: parsed_webhook.dig(:contact, :sales_rep_email)
              )

              case parsed_webhook.dig(:event_status).split('_').first
              when 'contact'
                jn_model.contact_status_update(status: parsed_webhook.dig(:contact, :status))
                process_actions_data[:status] = parsed_webhook.dig(:contact, :status).to_s
              when 'estimate'
                jn_model.estimate_status_update(status: parsed_webhook.dig(:estimate, :status))
                process_actions_data[:status] = parsed_webhook.dig(:estimate, :status).to_s
                process_actions_data[:contact_estimate_id] = update_estimate(contact, parsed_webhook)
              when 'invoice'
                jn_model.invoice_status_update(status: parsed_webhook.dig(:invoice, :status))
                process_actions_data[:status] = parsed_webhook.dig(:invoice, :status).to_s
              when 'job'
                jn_model.job_status_update(status: parsed_webhook.dig(:job, :status))
                process_actions_data[:status] = parsed_webhook.dig(:job, :status).to_s
                process_actions_data[:contact_job_id] = update_job(contact, parsed_webhook)
              when 'task'
                jn_model.task_type_update(type: parsed_webhook.dig(:task, :type))
                process_actions_data[:status]    = parsed_webhook.dig(:task, :completed).to_bool ? 'Completed' : 'Not Completed'
                process_actions_data[:task_type] = parsed_webhook.dig(:task, :type).to_s
                process_actions_data[:contact_estimate_id] = update_task_estimate(contact, parsed_webhook)
              when 'workorder'
                jn_model.workorder_status_update(status: parsed_webhook.dig(:workorder, :status))
                process_actions_data[:status] = parsed_webhook.dig(:workorder, :status).to_s
                process_actions_data[:contact_job_id] = update_job(contact, parsed_webhook)
              end

              # process defined actions for webhook
              Integrations::Jobnimbus::V1::Imports::ContactActionsJob.perform_later(
                criteria:   process_actions_data,
                client_id:  contact.client_id,
                contact_id: contact.id,
                user_id:    contact.user_id
              )
            end
          end
        rescue StandardError => e
          e.set_backtrace(BC.new.clean(caller))

          Appsignal.report_error(e) do |transaction|
            # Only needed if it needs to be different or there's no active transaction from which to inherit it
            Appsignal.set_action('Integrations::Jobnimbus::IntegrationsController#webhook')

            # Only needed if you want to set different arguments or there's no active transaction from which to inherit it
            Appsignal.add_params(params)

            Appsignal.set_tags(
              error_level: 'error',
              error_code:  0
            )
            Appsignal.add_custom_data(
              file: __FILE__,
              line: __LINE__
            )
          end
        end
      end

      # (GET) show JobNimbus integration
      # /integrations/jobnimbus
      # integrations_jobnimbus_path
      # integrations_jobnimbus_url
      def show
        respond_to do |format|
          format.js { render partial: 'integrations/jobnimbus/js/show', locals: { cards: %w[overview] } }
          format.html { render 'integrations/jobnimbus/show' }
        end
      end

      private

      def authorize_user!
        super

        return if current_user.access_controller?('integrations', 'client', session) && current_user.client.integrations_allowed.include?('jobnimbus')

        sweetalert_error('Unathorized Access!', 'Your account is NOT authorized to access JobNimbus Integrations. Please contact your account admin.', '', { persistent: 'OK' })

        respond_to do |format|
          format.js { render js: "window.location = '#{root_path}'" and return false }
          format.html { redirect_to root_path and return false }
        end
      end

      def client_api_integration
        return if (@client_api_integration = current_user.client.client_api_integrations.find_or_create_by(target: 'jobnimbus', name: ''))

        respond_to do |format|
          format.js { render js: "window.location = '#{root_path}'" and return false }
          format.html { redirect_to root_path and return false }
        end
      end

      def client_api_integration_from_api_key
        webhook_api_key = params.permit(:webhook_api_key).dig(:webhook_api_key).to_s
        return if webhook_api_key.present? && (@client_api_integration = ClientApiIntegration.where(target: 'jobnimbus', name: '').find_by('data @> ?', { webhook_api_key: }.to_json))

        respond_to do |format|
          format.json { render json: { status: 404, message: 'Company not found.' } and return false }
          format.html { render plain: 'Company not found.', content_type: 'text/plain', layout: false, status: :not_found and return false }
        end
      end

      def update_estimate(contact, parsed_webhook)
        return nil unless parsed_webhook.dig(:estimate, :id).present? && (contact_estimate = contact.estimates.find_or_initialize_by(ext_source: 'jobnimbus', ext_id: parsed_webhook.dig(:estimate, :id)))

        contact_estimate.update(
          address_01:         parsed_webhook.dig(:contact, :address_01).to_s,
          address_02:         parsed_webhook.dig(:contact, :address_02).to_s,
          city:               parsed_webhook.dig(:contact, :city).to_s,
          country:            parsed_webhook.dig(:contact, :country).to_s,
          ext_sales_rep_id:   parsed_webhook.dig(:contact, :sales_rep).to_s,
          job_id:             contact.jobs.find_by(ext_source: 'jobnimbus', ext_id: parsed_webhook.dig(:workorder, :id))&.id,
          notes:              parsed_webhook.dig(:estimate, :notes).to_s,
          postal_code:        parsed_webhook.dig(:contact, :postal_code).to_s,
          scheduled_end_at:   parsed_webhook.dig(:estimate, :date_end),
          scheduled_start_at: parsed_webhook.dig(:estimate, :date_start),
          state:              parsed_webhook.dig(:contact, :state).to_s,
          status:             parsed_webhook.dig(:event_status).to_s.split('_').last
        )

        contact_estimate.id
      end

      def update_job(contact, parsed_webhook)
        return nil unless parsed_webhook.dig(:workorder, :id).present? && (contact_job = contact.jobs.find_or_initialize_by(ext_source: 'jobnimbus', ext_id: parsed_webhook.dig(:workorder, :id)))

        contact_job.update(
          status:             parsed_webhook.dig(:event_status).to_s.split('_').last,
          address_01:         parsed_webhook.dig(:contact, :address_01).to_s,
          address_02:         parsed_webhook.dig(:contact, :address_02).to_s,
          city:               parsed_webhook.dig(:contact, :city).to_s,
          state:              parsed_webhook.dig(:contact, :state).to_s,
          postal_code:        parsed_webhook.dig(:contact, :postal_code).to_s,
          country:            parsed_webhook.dig(:contact, :country).to_s,
          scheduled_start_at: parsed_webhook.dig(:workorder, :date_start) || parsed_webhook.dig(:job, :date_start),
          scheduled_end_at:   parsed_webhook.dig(:workorder, :date_end) || parsed_webhook.dig(:job, :date_end),
          notes:              (parsed_webhook.dig(:workorder, :notes) || parsed_webhook.dig(:job, :description)).to_s,
          ext_sales_rep_id:   parsed_webhook.dig(:contact, :sales_rep).to_s
        )

        contact_job.id
      end

      def update_task_estimate(contact, parsed_webhook)
        return nil unless parsed_webhook.dig(:task, :type).to_s.casecmp?('appointment') && parsed_webhook.dig(:task, :id).present? && (contact_estimate = contact.estimates.find_or_initialize_by(ext_source: 'jobnimbus', ext_id: parsed_webhook.dig(:task, :id)))

        contact_estimate.update(
          address_01:         parsed_webhook.dig(:contact, :address_01).to_s,
          address_02:         parsed_webhook.dig(:contact, :address_02).to_s,
          city:               parsed_webhook.dig(:contact, :city).to_s,
          country:            parsed_webhook.dig(:contact, :country).to_s,
          ext_sales_rep_id:   parsed_webhook.dig(:contact, :sales_rep).to_s,
          notes:              parsed_webhook.dig(:task, :title).to_s,
          postal_code:        parsed_webhook.dig(:contact, :postal_code).to_s,
          scheduled_end_at:   parsed_webhook.dig(:task, :date_end),
          scheduled_start_at: parsed_webhook.dig(:task, :date_start),
          state:              parsed_webhook.dig(:contact, :state).to_s,
          status:             parsed_webhook.dig(:event_status).to_s.split('_').last
        )

        contact_estimate.id
      end
    end
  end
end
