# frozen_string_literal: true

# app/controllers/integrations/sunbasedata/integrations_controller.rb
module Integrations
  module Sunbasedata
    # endpoints supporting Sunbasedata integrations
    class IntegrationsController < ApplicationController
      before_action :authenticate_user!
      before_action :authorize_user!
      before_action :client_api_integration

      # (POST) create an SunbaseData appointment for a Contact
      # /integrations/sunbasedata/integration?contact_id=Integer
      # integrations_sunbasedata_integration_path( contact_id: Integer )
      # integrations_sunbasedata_integration_url( contact_id: Integer )
      def create
        @contact = current_user.client.contacts.find_by(id: params[:contact_id] || 0)

        if @contact
          respond_to do |format|
            format.js { render partial: 'integrations/sunbasedata/js/show', locals: { cards: [10] } }
            format.html { redirect_to central_path }
          end
        else
          respond_to do |format|
            format.js { render js: '', layout: false, status: :ok }
            format.html { redirect_to central_path }
          end
        end
      end

      # (GET) edit SunbaseData integration
      # /integrations/sunbasedata/integration/edit
      # edit_integrations_sunbasedata_integration_path
      # edit_integrations_sunbasedata_integration_url
      def edit
        respond_to do |format|
          format.js { render partial: 'integrations/sunbasedata/js/show', locals: { cards: [1] } }
          format.html { redirect_to central_path }
        end
      end

      # (PUT) send appointment data to SunbaseData
      # /integrations/sunbasedata/integration/sendappt/:contact_id
      # integrations_sunbasedata_integration_send_appt_path(:contact_id)
      # integrations_sunbasedata_integration_send_appt_url(:contact_id)
      def send_appt
        @contact          = current_user.client.contacts.find_by(id: params[:contact_id] || 0)
        appointment_date  = (params[:appointment_date] || '').to_s
        campaign_id       = (params[:campaign_id] || 0).to_i
        group_id          = (params[:group_id] || 0).to_i
        stage_id          = (params[:stage_id] || 0).to_i
        tag_id            = (params[:tag_id] || 0).to_i
        stop_campaign_ids = params[:stop_campaign_ids]&.compact_blank
        stop_campaign_ids = [0] if stop_campaign_ids&.include?('0')

        if @contact
          # Contact was found

          if appointment_date.present?
            # appointment_date was received

            # convert appointment_date from Client time zone to UTC
            # appointment_date = Time.use_zone(@contact.client.time_zone) do Chronic.parse(appointment_date) end.utc

            # do NOT convert appointment_date to UTC
            appointment_date = Chronic.parse(appointment_date)

            SunbaseData.send_appt(
              api_key:        @client_api_integration.api_key,
              sales_rep_id:   @client_api_integration.sales_rep_id,
              appt_setter_id: @client_api_integration.appt_setter_id,
              appt:           appointment_date,
              firstname:      @contact.firstname,
              lastname:       @contact.lastname,
              address1:       @contact.address1,
              address2:       @contact.address2,
              city:           @contact.city,
              state:          @contact.state,
              zipcode:        @contact.zipcode,
              phone:          @contact.primary_phone&.phone.to_s,
              email:          @contact.email
            )
          end

          @contact.process_actions(
            campaign_id:,
            group_id:,
            stage_id:,
            tag_id:,
            stop_campaign_ids:
          )
        end

        respond_to do |format|
          format.js { render partial: 'integrations/sunbasedata/js/show', locals: { cards: [11] } }
          format.html { redirect_to central_path }
        end
      end

      # (GET) show SunbaseData integration
      # /integrations/sunbasedata/integration
      # integrations_sunbasedata_integration_path
      # integrations_sunbasedata_integration_url
      def show
        respond_to do |format|
          format.js { render js: "window.location = '#{root_path}'" }
          format.html { render 'integrations/sunbasedata/show' }
        end
      end

      # (PUT/PATCH) update SunbaseData integration
      # /integrations/sunbasedata/integration
      # integrations_sunbasedata_integration_path
      # integrations_sunbasedata_integration_url
      def update
        @client_api_integration.update(api_key_params)

        respond_to do |format|
          format.js { render partial: 'integrations/sunbasedata/js/show', locals: { cards: [1, 2] } }
          format.html { redirect_to central_path }
        end
      end

      private

      def api_key_params
        response = params.permit(:api_key, :sales_rep_id, :appt_setter_id)

        response[:api_key] ||= ''

        response
      end

      def authorize_user!
        super

        return if current_user.access_controller?('integrations', 'client', session) && current_user.client.integrations_allowed.include?('sunbasedata')

        sweetalert_error('Unathorized Access!', 'Your account is NOT authorized to access SunbaseData Integrations. Please contact your account admin.', '', { persistent: 'OK' })

        respond_to do |format|
          format.js { render js: "window.location = '#{root_path}'" and return false }
          format.html { redirect_to root_path and return false }
        end
      end

      def client_api_integration
        @client_api_integration = current_user.client.client_api_integrations.find_or_create_by(target: 'sunbasedata', name: '')
      end
    end
  end
end
