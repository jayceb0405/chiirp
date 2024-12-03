# frozen_string_literal: true

# app/controllers/integrations/xencall/integrations_controller.rb
module Integrations
  module Xencall
    # endpoints supporting Xencall integrations
    class IntegrationsController < ApplicationController
      skip_before_action :verify_authenticity_token, only: [:endpoint]
      before_action :authenticate_user!, except: [:endpoint]
      before_action :authorize_user!, except: [:endpoint]
      before_action :client, except: [:endpoint]
      before_action :client_api_integration, except: [:endpoint]
      before_action :set_contact, only: %i[edit_contact update_contact]

      # (GET) Xencall integration edit screen
      # /integrations/xencall
      # integrations_xencall_edit_path
      # integrations_xencall_edit_url
      def edit
        link = params.include?(:link) ? params[:link].to_s.downcase : ''

        cards = case link
                when 'instructions'
                  [0]
                when 'api_key'
                  [1]
                when 'channel_assign'
                  [3]
                else
                  %w[overview]
                end

        respond_to do |format|
          format.js   { render partial: 'integrations/xencall/js/show', locals: { cards: } }
          format.html { render 'integrations/xencall/edit' }
        end
      end

      # (GET) edit Contact data from Xencall
      # /integrations/xencall/contact/:contact_id
      # integrations_xencall_contact_edit_path(:contact_id)
      # integrations_xencall_contact_edit_url(:contact_id)
      def edit_contact
        @contact_api_integration = @contact.contact_api_integrations.find_by(target: 'xencall')

        respond_to do |format|
          format.js { render partial: 'contacts/js/show', locals: { cards: [11] } }
          format.html { redirect_to central_path }
        end
      end

      # (GET) edit custom field assignment
      # /integrations/xencall/custom_field
      # integrations_xencall_custom_field_edit_path
      # integrations_xencall_custom_field_edit_url
      def edit_custom_field
        respond_to do |format|
          format.js { render partial: 'integrations/xencall/js/show', locals: { cards: [10] } }
          format.html { render 'integrations/xencall/edit' }
        end
      end

      # (POST) data posted from Xencall
      # /integrations/xencall/endpoint
      # integrations_xencall_endpoint_path
      # integrations_xencall_endpoint_url
      def endpoint
        provider = params.dig(:provider).to_s
        phone    = params.dig(:phone)

        if provider.present? && phone.present? && (client_api_integration = ClientApiIntegration.find_by(target: 'xencall', api_key: provider)) &&
           (contact_phones = ContactPhone.find_by_client_and_phone(client_api_integration.client_id, phone)) && contact_phones.first && (contact = contact_phones.first.contact) &&
           (st_client_api_integration = ClientApiIntegration.find_by(client_id: client_api_integration.client_id, target: 'servicetitan', name: ''))

          start_time = params.dig(:appt).to_s.present? ? Time.use_zone(client_api_integration.client.time_zone) { Chronic.parse(params[:appt].to_s) }.utc : Time.current

          Integration::Servicetitan::V2::Base.new(st_client_api_integration).delay(
            run_at:              Time.current,
            priority:            DelayedJob.job_priority('package_job'),
            queue:               DelayedJob.job_queue('package_job'),
            contact_id:          contact.id,
            user_id:             contact.user_id,
            triggeraction_id:    0,
            contact_campaign_id: 0,
            process:             'package_job'
          ).package_post_job(
            contact:,
            business_unit_string: client_api_integration.bu_field_name.present? && params.include?(client_api_integration.bu_field_name.to_sym) ? params[client_api_integration.bu_field_name.to_sym].to_s : '',
            job_type_string:      client_api_integration.job_field_name.present? && params.include?(client_api_integration.job_field_name.to_sym) ? params[client_api_integration.job_field_name.to_sym].to_s : '',
            technician_string:    client_api_integration.tech_field_name.present? && params.include?(client_api_integration.tech_field_name.to_sym) ? params[client_api_integration.tech_field_name.to_sym].to_s : '',
            campaign_string:      client_api_integration.campaign_field_name.present? && params.include?(client_api_integration.campaign_field_name.to_sym) ? params[client_api_integration.campaign_field_name.to_sym].to_s : '',
            tag_string:           client_api_integration.tag_field_name.present? && params.include?(client_api_integration.tag_field_name.to_sym) ? params[client_api_integration.tag_field_name.to_sym].to_s : '',
            start_time:,
            end_time:             start_time + 2.hours,
            description:          client_api_integration.desc_field_name.present? && params.include?(client_api_integration.desc_field_name.to_sym) ? params[client_api_integration.desc_field_name.to_sym].to_s : ''
          )
        end

        respond_to do |format|
          format.html { render plain: 'Success!', content_type: 'text/plain', layout: false, status: :ok }
        end
      end
      # {
      # 	"name"=>"Xen Call",
      # 	"email"=>"test@test.com",
      # 	"phone"=>"(800) 694-1049",
      # 	"address"=>"123 XenStreet",
      # 	"city"=>"Vancouver",
      # 	"state"=>"CA",
      # 	"zip"=>"12345",
      # 	"url"=>"123",
      # 	"appt"=>"Mar 17, 2020 8:30am"
      # }

      # (PUT) update the Xencall api key
      # /integrations/xencall/apikey
      # integrations_xencall_apikey_update_path
      # integrations_xencall_apikey_update_url
      def update_api_key
        @client_api_integration.update(api_key_params)

        respond_to do |format|
          format.js { render partial: 'integrations/xencall/js/show', locals: { cards: [1, 2, 4] } }
          format.html { render 'integrations/xencall/edit' }
        end
      end

      # (PUT) update Xencall channel to Brand Tag assignments
      # /integrations/xencall/channel_assign
      # integrations_xencall_channel_assign_update_path
      # integrations_xencall_channel_assign_update_url
      def update_channel_assign
        if params.dig(:commit).to_s == 'delete_channel' && params.dig(:channel_id).to_s.present?
          @client_api_integration.channels.delete(params[:channel_id].to_s)
          @client_api_integration.save
        else
          @client_api_integration.update(channel_assign_params)
        end

        respond_to do |format|
          format.js { render partial: 'integrations/xencall/js/show', locals: { cards: [3] } }
          format.html { render 'integrations/xencall/edit' }
        end
      end

      # (PATCH) update a ContactApiIntegration
      # /integrations/xencall/contact/:contact_id
      # integrations_xencall_contact_update_path(:contact_id)
      # integrations_xencall_contact_update_url(:contact_id)
      def update_contact
        @contact_api_integration = @contact.contact_api_integrations.find_by(target: 'xencall')
        @contact_api_integration.update(contact_params)

        respond_to do |format|
          format.js { render partial: 'contacts/js/show', locals: { cards: [8] } }
          format.html { redirect_to central_path }
        end
      end

      # (PUT/PATCH) update custom field assignment
      # /integrations/xencall/custom_field
      # integrations_xencall_custom_field_update_path
      # integrations_xencall_custom_field_update_url
      def update_custom_field
        @client_api_integration.update(custom_field_params)

        respond_to do |format|
          format.js { render partial: 'integrations/xencall/js/show', locals: { cards: [10] } }
          format.html { render 'integrations/xencall/edit' }
        end
      end

      private

      def api_key_params
        response = params.permit(:api_key, :live_mode)

        response[:api_key]      ||= ''
        response[:live_mode]    ||= 0

        response
      end

      def authorize_user!
        super

        return if current_user.access_controller?('integrations', 'client', session) && current_user.client.integrations_allowed.include?('xencall')

        sweetalert_error('Unathorized Access!', 'Your account is NOT authorized to access Xencall Integrations. Please contact your account admin.', '', { persistent: 'OK' })

        respond_to do |format|
          format.js { render js: "window.location = '#{root_path}'" and return false }
          format.html { redirect_to root_path and return false }
        end
      end

      def channel_assign_params
        new_channel = params.require(:new_channel).permit(:channel_id, :tag_id)

        response = { channels: {} }
        response[:channels][new_channel[:channel_id]] = new_channel[:tag_id] if new_channel[:channel_id].to_s.present?

        channels = params.include?(:channels) ? params.require(:channels).permit(params[:channels].keys) : {}

        channels.each do |channel_id, tag_id|
          response[:channels][channel_id] = tag_id if channel_id.to_s.present?
        end

        response
      end

      def contact_params
        params.require(:contact_api_integration).permit(:xencall_lead_id)
      end

      def custom_field_params
        response = params.require(:custom_field).permit(:gen_field_id, :gen_field_string, :bu_field_name, :job_field_name, :tech_field_name, :campaign_field_name, :tag_field_name, :desc_field_name)

        response[:gen_field_id]        ||= ''
        response[:gen_field_string]    ||= ''
        response[:bu_field_name]       ||= ''
        response[:job_field_name]      ||= ''
        response[:tech_field_name]     ||= ''
        response[:campaign_field_name] ||= ''
        response[:tag_field_name]      ||= ''
        response[:desc_field_name]     ||= ''

        response
      end

      def client
        if defined?(current_user)
          @client = current_user.client

          unless @client
            # current User is NOT authorized
            sweetalert_error('Unathorized Access!', 'Your account could NOT be confirmed.', '', { persistent: 'OK' })
          end
        else
          # only logged in Users may access any PackagePage actions
          sweetalert_error('Unathorized Access!', 'Your account could NOT be confirmed.', '', { persistent: 'OK' })
        end

        return if @client

        respond_to do |format|
          format.js { render js: "window.location = '#{root_path}'" and return false }
          format.html { redirect_to root_path and return false }
        end
      end

      def client_api_integration
        @client_api_integration = current_user.client.client_api_integrations.find_or_create_by(target: 'xencall', name: '')
      end

      def set_contact
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
    end
  end
end
