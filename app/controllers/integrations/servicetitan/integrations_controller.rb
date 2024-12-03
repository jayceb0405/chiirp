# frozen_string_literal: true

# app/controllers/integrations/servicetitan/integrations_controller.rb
module Integrations
  module Servicetitan
    class IntegrationsController < ApplicationController
      skip_before_action :verify_authenticity_token, only: %i[endpoint]
      before_action :authenticate_user!, except: %i[endpoint]
      before_action :authorize_user!, except: %i[endpoint]
      before_action :client_api_integration, except: %i[endpoint]

      # (GET) ServiceTitan integration overview
      # /integrations/servicetitan
      # integrations_servicetitan_path
      # integrations_servicetitan_url
      def show
        respond_to do |format|
          format.js { render partial: 'integrations/servicetitan/js/show', locals: { cards: %w[overview] } }
          format.html { render 'integrations/servicetitan/edit', locals: { partial_to_show: params.dig(:card).present? ? "integrations/servicetitan/#{params[:card]}/show" : '' } }
        end
      end

      # (POST) webhook used to accept ServiceTitan data
      # Endpoint
      # /integrations/servicetitan/endpoint
      # integrations_servicetitan_endpoint_path
      # integrations_servicetitan_endpoint_url
      # Legacy Endpoint
      # /integrations/servicetitan/endpoint/:webhook/:api_key
      # integrations_servicetitan_endpoint_path(:webhook, :api_key)
      # integrations_servicetitan_endpoint_url(:webhook, :api_key)
      def endpoint
        if params.dig(:__tenantInfo, :id).present? &&
           (client_api_integration = ClientApiIntegration.where(target: 'servicetitan', name: '').find_by("data #>> '{credentials, tenant_id}' = ?", params[:__tenantInfo][:id].to_s)) &&
           client_api_integration&.client&.active?

          respond_to do |format|
            format.json { render json: { status: :ok, message: 'success' } }
            format.html { render plain: 'success', content_type: 'text/plain', layout: false, status: :ok }
          end
        else

          if client_api_integration.nil?
            message = 'Client not found.'
            status  = :forbidden
          else
            message = 'Client not active.'
            status  = :unauthorized
          end

          respond_to do |format|
            format.json { render json: { status:, message: } and return false }
            format.html { render plain: message, content_type: 'text/plain', layout: false, status: and return false }
          end
        end

        case params.dig(:__eventInfo, :webhookType).to_s.strip.downcase
        when 'callcompleted'
          Integrations::Servicetitan::V2::Calls::CallCompletedWebhookJob.set(wait_until: client_api_integration.call_event_delay.to_i.seconds.from_now).perform_later(
            **params.merge({ client_id: client_api_integration.client_id }).normalize_non_ascii.deep_symbolize_keys
          )
        when 'jobscheduled'
          Integration::Servicetitan::V2::Base.new(client_api_integration).delay(
            priority: DelayedJob.job_priority('servicetitan_update_contact_webhook'),
            queue:    DelayedJob.job_queue('servicetitan_update_contact_webhook'),
            user_id:  0,
            process:  'servicetitan_update_contact_webhook',
            data:     params.normalize_non_ascii
          ).update_contact_from_job_scheduled_webhook(params.normalize_non_ascii)
        when 'jobrescheduled'
          Integration::Servicetitan::V2::Base.new(client_api_integration).delay(
            priority: DelayedJob.job_priority('servicetitan_update_contact_webhook'),
            queue:    DelayedJob.job_queue('servicetitan_update_contact_webhook'),
            user_id:  0,
            process:  'servicetitan_update_contact_webhook',
            data:     params.normalize_non_ascii
          ).update_contact_from_job_rescheduled_webhook(params.normalize_non_ascii)
        when 'techniciandispatched'
          Integration::Servicetitan::V2::Base.new(client_api_integration).delay(
            priority: DelayedJob.job_priority('servicetitan_update_contact_webhook'),
            queue:    DelayedJob.job_queue('servicetitan_update_contact_webhook'),
            user_id:  0,
            process:  'servicetitan_update_contact_webhook',
            data:     params.normalize_non_ascii
          ).update_contact_from_technician_dispatched_webhook(params.normalize_non_ascii)
        when 'jobcomplete', 'jobcompleted'
          Integration::Servicetitan::V2::Base.new(client_api_integration).delay(
            priority: DelayedJob.job_priority('servicetitan_update_contact_webhook'),
            queue:    DelayedJob.job_queue('servicetitan_update_contact_webhook'),
            user_id:  0,
            process:  'servicetitan_update_contact_webhook',
            data:     params.normalize_non_ascii
          ).update_contact_from_job_completed_webhook(params.normalize_non_ascii)
        end
      end
      # example of webhook data for CallCompleted with no customer id
      # {
      #   id:           53187007,
      #   receivedOn:   '2024-09-30T16:10:51.4315884',
      #   duration:     '00:05:03',
      #   from:         '9492782612',
      #   to:           '4809002058',
      #   direction:    'Inbound',
      #   callType:     'Unbooked',
      #   reason:       nil,
      #   recordingUrl: nil,
      #   voiceMailUrl: nil,
      #   createdBy:    nil,
      #   customer:     nil,
      #   campaign:     {
      #     category:     { id: 21111, name: 'PPC', active: false },
      #     source:       'Google',
      #     otherSource:  nil,
      #     businessUnit: nil,
      #     medium:       'LSA',
      #     otherMedium:  nil,
      #     dnis:         '4809002058',
      #     id:           357000,
      #     name:         'Google Local Service Ads AZ Best',
      #     modifiedOn:   '2023-02-23T16:12:47.0406523',
      #     createdOn:    '2018-10-11T23:21:58.2812143',
      #     active:       true
      #   },
      #   modifiedOn:   '2024-09-30T16:15:56.1251469',
      #   agent:        { externalId: nil, id: 51784179, name: 'Arianna Dann' },
      #   eventId:      '2024-09-30T16:15:56.6122411Z',
      #   webhookId:    44438357,
      #   __eventInfo:  { eventId: '2024-09-30T16:15:56.6122411Z', webhookId: 44438357, webhookType: 'CallCompleted' },
      #   __tenantInfo: { id: 421300872, name: 'azbestgaragedoor' }
      # }

      private

      def authorize_user!
        super

        return if current_user.access_controller?('integrations', 'client', session) && current_user.client.integrations_allowed.include?('servicetitan')

        sweetalert_error('Unathorized Access!', 'Your account is NOT authorized to access ServiceTitan Integrations. Please contact your account admin.', '', { persistent: 'OK' })

        respond_to do |format|
          format.js { render js: "window.location = '#{root_path}'" and return false }
          format.html { redirect_to root_path and return false }
        end
      end

      def client_api_integration
        @client_api_integration = current_user.client.client_api_integrations.find_or_create_by(target: 'servicetitan', name: '')
        Integration::Servicetitan::V2::Base.new(@client_api_integration).valid_credentials?
      end

      def contact
        if defined?(current_user) && params.include?(:contact_id)
          @contact = current_user.client.contacts.find_by(id: params[:contact_id].to_i)

          unless @contact
            # Contact was NOT found
            sweetalert_error('Unknown Contact!', 'The Contact you requested could not be found.', '', { persistent: 'OK' })
          end
        else
          # only logged in Users may access any PackagePage actions
          sweetalert_error('Unknown Contact!', 'A Contact was NOT requested.', '', { persistent: 'OK' })
        end

        return if @contact

        respond_to do |format|
          format.js { render js: "window.location = '#{root_path}'" and return false }
          format.html { redirect_to root_path and return false }
        end
      end

      def contact_api_integration
        if defined?(@contact)
          @contact_api_integration = @contact.contact_api_integrations.find_or_create_by(target: 'servicetitan', name: '')
        else
          sweetalert_error('Unknown Contact!', 'A Contact was NOT defined.', '', { persistent: 'OK' })
        end

        return if @contact_api_integration

        respond_to do |format|
          format.js { render js: "window.location = '#{root_path}'" and return false }
          format.html { redirect_to root_path and return false }
        end
      end
    end
  end
end
